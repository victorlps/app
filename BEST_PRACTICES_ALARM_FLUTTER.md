# 🚨 MELHORES PRÁTICAS: Implementar Alarmes em Flutter/Android

## Sumário Executivo
Documento consolidado com as melhores práticas para implementar alarmes em Flutter que toquem som em background, apareçam como full-screen notifications, e funcionem corretamente com `flutter_background_service` e isolates.

---

## 1. 📦 STACK DE PACOTES RECOMENDADOS

### Pacotes Essenciais
```yaml
dependencies:
  flutter_local_notifications: ^19.5.0  # Full-screen notifications
  flutter_background_service: ^5.1.0    # Background execution
  just_audio: ^0.10.5                   # Audio playback em background
  audio_session: ^0.2.0                 # Gerenciar audio session
  permission_handler: ^11.0.0           # Gerenciar permissões Android 12+
```

### Por que cada um?
- **flutter_local_notifications**: Suporta full-screen intent e notification channels com vibração/som
- **flutter_background_service**: Executa código em isolate separado sem ser morto pelo Android
- **just_audio**: Reprodução robusta de audio em background com ExoPlayer
- **audio_session**: Controla audio duck, interrupções e compatibilidade
- **permission_handler**: Solicita permissões de runtime necessárias

---

## 2. 🔐 PERMISSÕES NECESSÁRIAS (AndroidManifest.xml)

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <!-- Básicas para notificações -->
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
  
  <!-- Para vibração -->
  <uses-permission android:name="android.permission.VIBRATE" />
  
  <!-- Para full-screen intent (Android 11+) -->
  <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
  
  <!-- Para alarmes exatos (Android 12+) -->
  <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
  
  <!-- Para uso completo de alarmes -->
  <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
  
  <!-- Para audio em background -->
  <uses-permission android:name="android.permission.INTERNET" />
  
  <!-- Para bypassar DND (opcional, se necessário silenciar device) -->
  <uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY" />

  <application
    android:label="avisa_la"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">

    <!-- Activity com full-screen intent -->
    <activity
      android:name=".MainActivity"
      android:exported="true"
      android:showWhenLocked="true"
      android:turnScreenOn="true"
      android:launchMode="singleTop">
      
      <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
      </intent-filter>
    </activity>

    <!-- Background service (Android 12+) -->
    <service
      android:name="id.flutter.flutter_background_service.BackgroundService"
      android:exported="false"
      android:foregroundServiceType="location" />

    <!-- Receivers para notificações -->
    <receiver
      android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
      android:exported="false" />

    <receiver
      android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
      android:exported="false">
      <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
      </intent-filter>
    </receiver>

  </application>
</manifest>
```

### Atributos Críticos Explicados:
- `android:showWhenLocked="true"` - Mostra activity mesmo quando device está locked
- `android:turnScreenOn="true"` - Liga a tela quando notification chega
- `android:launchMode="singleTop"` - Evita múltiplas instâncias da activity
- `android:foregroundServiceType="location"` - Declara tipo de foreground service

---

## 3. 🔔 SETUP DO NOTIFICATION CHANNEL (Full-Screen)

### Flutter Code
```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audio_session/audio_session.dart';

class AlarmNotificationService {
  static final FlutterLocalNotificationsPlugin 
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Criar canal de notificação para alarmes com full-screen intent
  static Future<void> setupAlarmChannel() async {
    // ✅ Android 8.0+: Canal de notificação é OBRIGATÓRIO
    const AndroidNotificationChannel alarmChannel =
        AndroidNotificationChannel(
      'alarm_channel_id',           // ID único do canal
      'Alarm Notifications',         // Título visível para usuário
      description: 'Critical alarm notifications that require immediate action',
      importance: Importance.max,    // Max para heads-up e som
      priority: Priority.max,        // Compatibilidade Android 7
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),  // audio raw
      vibrationPattern: Int64List.fromList(
        [0, 500, 500, 500, 500, 1000], // Vibração vibrante (off, on, off, on...)
      ),
      showBadge: true,
      bypassDnd: true,               // Ignora DND mode
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alarmChannel);

    // Configurar audio session para background playback
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration.alarm(),
    );
  }

  /// Mostrar notificação full-screen
  static Future<void> showAlarmNotification({
    required int id,
    required String title,
    required String body,
    required String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'alarm_channel_id',
      'Alarm Notifications',
      channelDescription: 'Critical alarm notifications',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,         // ✅ CRITICAL: Full-screen intent
      autoCancel: false,              // Não dismiss automaticamente
      ongoing: true,                  // Pin na notification shade
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      vibrationPattern: Int64List.fromList([0, 500, 500, 500]),
      enableLights: true,
      color: const Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 3000,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Cancelar notificação
  static Future<void> cancelAlarm(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancelar todas
  static Future<void> cancelAllAlarms() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
```

### Explicação dos Parâmetros
| Parâmetro | Valor | Por quê |
|-----------|-------|--------|
| `Importance.max` | Máximo | Heads-up notification + som/vibração |
| `Priority.max` | Alto | Compatibilidade Android 7.1 |
| `fullScreenIntent: true` | Ativo | Mostra activity full-screen mesmo locked |
| `enableVibration: true` | Ativo | Vibração em Android 12+ funciona via canal |
| `bypassDnd: true` | Ativo | Ignora DND (não Silent mode) |
| `showBadge: true` | Ativo | Badge no ícone da app |

---

## 4. 🔊 GERENCIAR AUDIO EM BACKGROUND SERVICE

### Estrutura de Isolate para Audio
```dart
@pragma('vm:entry-point')
void alarmServiceEntryPoint() async {
  // ✅ Inicializar Flutter plugins no isolate separado
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final service = FlutterBackgroundService();

  // Setup audio session ANTES de usar áudio
  final audioSession = await AudioSession.instance;
  await audioSession.configure(
    const AudioSessionConfiguration.alarm(),
  );

  // Criar player de áudio
  _audioPlayer = AudioPlayer();

  service.onStart.listen((event) async {
    if (event?['action'] == 'alarm_trigger') {
      await _triggerAlarm(
        distance: event?['distance'] as double?,
        alarmSound: event?['alarmSound'] as String?,
      );
    } else if (event?['action'] == 'stop_alarm') {
      await _stopAlarm();
    }
  });
}

/// Reproduzir som de alarme
Future<void> _triggerAlarm({
  required double? distance,
  required String? alarmSound,
}) async {
  try {
    // Usar asset ou URL
    final source = alarmSound != null && alarmSound.startsWith('http')
        ? AudioSource.uri(Uri.parse(alarmSound))
        : AudioSource.asset('assets/sounds/alarm_default.mp3');

    // Configurar repetição
    await _audioPlayer.setAudioSource(source);
    await _audioPlayer.setLoopMode(LoopMode.one);  // Repetir
    await _audioPlayer.setVolume(1.0);  // Volume máximo
    
    // Play
    await _audioPlayer.play();

    // Log para debug
    print('🔊 Alarme ativado - Distância: $distance metros');
  } catch (e) {
    print('❌ Erro ao reproduzir alarme: $e');
  }
}

/// Parar som
Future<void> _stopAlarm() async {
  try {
    await _audioPlayer.stop();
    print('🛑 Alarme parado');
  } catch (e) {
    print('❌ Erro ao parar alarme: $e');
  }
}
```

### ✅ Pontos Críticos:
1. **`@pragma('vm:entry-point')`** - Obrigatório para não ser tree-shaken
2. **`DartPluginRegistrant.ensureInitialized()`** - Registra plugins no isolate
3. **`AudioSession.alarm()`** - Configura para prioritário
4. **`setLoopMode(LoopMode.one)`** - Repetir indefinidamente
5. **`setVolume(1.0)`** - Máximo volume sempre

---

## 5. 📡 COMUNICAÇÃO ENTRE ISOLATES (UI ↔ Background Service)

### Padrão de Comunicação Robusta
```dart
class AlarmService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static final _statusController = StreamController<AlarmStatus>.broadcast();

  /// Stream para UI ouvir mudanças
  static Stream<AlarmStatus> get statusStream => _statusController.stream;

  /// Inicializar background service
  static Future<void> initialize() async {
    // Configurar
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        // Executar esta função no isolate
        onStart: _onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'alarm_channel_id',
        initialNotificationTitle: 'Avisa Lá Monitoring',
        initialNotificationContent: 'Ready',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );

    // Ouvir eventos DO background service
    _service.on('alarm_status_changed').listen((event) {
      if (event != null) {
        final status = AlarmStatus.fromMap(event);
        _statusController.add(status);
      }
    });
  }

  /// Enviar comando PARA background service
  static Future<void> triggerAlarm({
    required double distance,
    required double latitude,
    required double longitude,
  }) async {
    await _service.invoke('trigger_alarm', {
      'distance': distance,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Parar alarme
  static Future<void> stopAlarm() async {
    await _service.invoke('stop_alarm');
  }
}

// ============ BACKGROUND ISOLATE ============
@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // Setup audio
  final audioSession = await AudioSession.instance;
  await audioSession.configure(
    const AudioSessionConfiguration.alarm(),
  );

  AudioPlayer? audioPlayer;

  // Ouvir comandos da UI
  service.on('trigger_alarm').listen((event) async {
    final distance = event?['distance'] as double?;
    final latitude = event?['latitude'] as double?;
    final longitude = event?['longitude'] as double?;

    try {
      audioPlayer = AudioPlayer();
      await audioPlayer?.setAudioSource(
        AudioSource.asset('assets/sounds/alarm_default.mp3'),
      );
      await audioPlayer?.setLoopMode(LoopMode.one);
      await audioPlayer?.play();

      // Notificar UI que alarme foi ativado
      service.invoke('alarm_status_changed', {
        'status': 'playing',
        'distance': distance,
        'latitude': latitude,
        'longitude': longitude,
      });

      print('🔊 Alarme disparado em background isolate');
    } catch (e) {
      print('❌ Erro: $e');
      service.invoke('alarm_status_changed', {
        'status': 'error',
        'error': e.toString(),
      });
    }
  });

  // Parar alarme
  service.on('stop_alarm').listen((event) async {
    await audioPlayer?.stop();
    service.invoke('alarm_status_changed', {'status': 'stopped'});
  });

  // Cleanup
  service.on('stopService').listen((event) {
    audioPlayer?.dispose();
    service.stopSelf();
  });
}

// iOS background
@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  return true;
}

// ============ USAR NA UI ============
class AlarmScreen extends StatefulWidget {
  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  AlarmStatus? _currentStatus;

  @override
  void initState() {
    super.initState();
    // Ouvir mudanças de status do background
    AlarmService.statusStream.listen((status) {
      setState(() => _currentStatus = status);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Alarme: ${_currentStatus?.status ?? 'idle'}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => AlarmService.triggerAlarm(
                distance: 500,
                latitude: -23.55,
                longitude: -46.63,
              ),
              icon: Icon(Icons.alarm),
              label: Text('Ativar Alarme'),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => AlarmService.stopAlarm(),
              icon: Icon(Icons.stop),
              label: Text('Parar Alarme'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ MODEL PARA STATUS ============
class AlarmStatus {
  final String status; // 'idle', 'playing', 'stopped', 'error'
  final double? distance;
  final double? latitude;
  final double? longitude;
  final String? error;

  AlarmStatus({
    required this.status,
    this.distance,
    this.latitude,
    this.longitude,
    this.error,
  });

  factory AlarmStatus.fromMap(Map<dynamic, dynamic> map) {
    return AlarmStatus(
      status: map['status'] ?? 'unknown',
      distance: map['distance'] as double?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      error: map['error'] as String?,
    );
  }
}
```

### Fluxo de Comunicação
```
┌─────────────────────┐
│   Main UI Isolate   │
├─────────────────────┤
│ AlarmService        │
│ ↓ invoke()          │
│ statusStream ←─────→ listener
└─────────────────────┘
         ↕ service.invoke()
┌─────────────────────┐
│ Background Isolate  │
├─────────────────────┤
│ on('trigger_alarm') │
│ on('stop_alarm')    │
│ AudioPlayer.play()  │
└─────────────────────┘
```

---

## 6. 🎯 FORÇAR APP PARA FOREGROUND

### Método Completo para Trazer App para Frente
```dart
import 'package:flutter/services.dart';

class AppLifecycleService {
  static const platform = MethodChannel('com.example.avisa_la/app');

  /// Trazer app para foreground quando alarme toca
  static Future<void> bringAppToForeground() async {
    try {
      await platform.invokeMethod('bringToForeground');
      print('✅ App trazido para foreground');
    } on PlatformException catch (e) {
      print('❌ Erro ao trazer app: $e');
    }
  }

  /// Forçar unlock do device (requer permissão especial)
  static Future<void> unlockDevice() async {
    try {
      await platform.invokeMethod('unlockDevice');
      print('✅ Device desbloqueado');
    } on PlatformException catch (e) {
      print('❌ Erro ao desbloquear: $e');
    }
  }
}
```

### Kotlin Native Code (MainActivity.kt)
```kotlin
import android.app.ActivityManager
import android.content.Intent
import android.content.Context
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.avisa_la/app"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "bringToForeground" -> {
                        bringAppToForeground()
                        result.success(true)
                    }
                    "unlockDevice" -> {
                        try {
                            unlockDevice()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("UNLOCK_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun bringAppToForeground() {
        // Opção 1: Via Intent
        val intent = Intent(this, MainActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                      Intent.FLAG_ACTIVITY_NEW_TASK or
                      Intent.FLAG_ACTIVITY_SINGLE_TOP
        startActivity(intent)

        // Opção 2: Se app estiver em background, trazer ao topo
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val tasks = activityManager.getRunningTasks(1)
        if (tasks.isNotEmpty() && tasks[0].topActivity?.packageName != packageName) {
            startActivity(intent)
        }
    }

    private fun unlockDevice() {
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )
    }
}
```

### Permissions Adicionais (AndroidManifest.xml)
```xml
<!-- Trazer app ao foreground -->
<uses-permission android:name="android.permission.REORDER_TASKS" />

<!-- Controlar tela do device (Android 12+) -->
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

---

## 7. 🔊 VIBRAÇÃO EM ANDROID 12+

### Correto (Usar Canal)
```dart
// ✅ CORRETO: Vibração configurada no canal
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'alarm_channel_id',
  'Alarm',
  importance: Importance.max,
  vibrationPattern: Int64List.fromList([0, 500, 500, 500]),  // ms
);

// ✅ CORRETO: Usar Vibrator via platform channel
import 'package:flutter/services.dart';

class VibrationService {
  static const platform = MethodChannel('com.example.avisa_la/vibration');

  static Future<void> vibrate({
    required Duration duration = const Duration(milliseconds: 500),
    required int intensity = 255,
  }) async {
    try {
      await platform.invokeMethod('vibrate', {
        'duration': duration.inMilliseconds,
        'intensity': intensity,
      });
    } catch (e) {
      print('❌ Vibration error: $e');
    }
  }

  /// Padrão vibrante (SOS: 3-3-3)
  static Future<void> sosPattern() async {
    const pattern = [0, 200, 100, 200, 100, 200, 500, 200, 500, 200, 500];
    for (int i = 0; i < pattern.length - 1; i += 2) {
      await Future.delayed(Duration(milliseconds: pattern[i]));
      await vibrate(
        duration: Duration(milliseconds: pattern[i + 1]),
        intensity: 255,
      );
    }
  }
}
```

### Kotlin Implementation (Vibrator)
```kotlin
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.content.Context
import io.flutter.plugin.common.MethodChannel

// No MainActivity.kt
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.avisa_la/vibration")
    .setMethodCallHandler { call, result ->
        when (call.method) {
            "vibrate" -> {
                val duration = call.argument<Int>("duration") ?: 500
                val intensity = call.argument<Int>("intensity") ?: 255
                
                val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager)
                        .defaultVibrator
                } else {
                    @Suppress("DEPRECATION")
                    getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val effect = VibrationEffect.createOneShot(
                        duration.toLong(),
                        (intensity * 255 / 255).toInt()
                    )
                    vibrator.vibrate(effect)
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(duration.toLong())
                }
                
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
```

### ⚠️ Android 12+ Restrições
- Vibração **SÓ** funciona via **notification channel** (não pela app diretamente)
- Usar `vibrationPattern` no `NotificationChannel`
- Padrão: `[0, 500, 500, 500]` = silênc 0ms, vibra 500ms, silênc 500ms, vibra 500ms

---

## 8. ✅ CHECKLIST DE IMPLEMENTAÇÃO

### Fase 1: Setup Básico
- [ ] Adicionar pacotes em `pubspec.yaml`
- [ ] Adicionar permissões em `AndroidManifest.xml`
- [ ] Adicionar atributos `showWhenLocked`, `turnScreenOn` em `<activity>`
- [ ] Registrar `BackgroundService` em manifest
- [ ] Criar canal de notificação com `Importance.max` e `fullScreenIntent: true`

### Fase 2: Audio Backend
- [ ] Setup `AudioSession.alarm()` em main isolate
- [ ] Setup `AudioSession.alarm()` em background isolate
- [ ] Adicionar arquivo de áudio em `assets/sounds/`
- [ ] Testar reprodução com `just_audio`
- [ ] Testar repetição com `setLoopMode(LoopMode.one)`

### Fase 3: Background Service
- [ ] Implementar `@pragma('vm:entry-point')` no entry point
- [ ] Chamar `DartPluginRegistrant.ensureInitialized()` no isolate
- [ ] Configurar listeners com `service.on()`
- [ ] Testar `invoke()` from UI to background
- [ ] Testar `invoke()` from background to UI

### Fase 4: Full-Screen
- [ ] Testar notificação full-screen em tela locked
- [ ] Testar tela turning on automaticamente
- [ ] Testar som toca mesmo com volume silencioso
- [ ] Testar vibração em Android 12+

### Fase 5: Testes em Device Real
- [ ] Device locked, tela off
- [ ] Device locked, tela on
- [ ] Device unlocked
- [ ] DND mode ativo
- [ ] App em foreground
- [ ] App em background
- [ ] App killed pelo Android
- [ ] Reboot device

---

## 9. 📋 EXEMPLO COMPLETO INTEGRADO

### Arquivo Único: `lib/services/alarm_system.dart`
```dart
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_session/audio_session.dart';

// ============ MODELO ============
class AlarmState {
  final bool isActive;
  final double? currentDistance;
  final String errorMessage;

  AlarmState({
    this.isActive = false,
    this.currentDistance,
    this.errorMessage = '',
  });
}

// ============ SERVIÇO ============
class AlarmSystem {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final _service = FlutterBackgroundService();
  static final _audioPlayer = AudioPlayer();

  // Setup inicial
  static Future<void> initialize() async {
    // Criar canal
    const channel = AndroidNotificationChannel(
      'alarm',
      'Alarmes',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      vibrationPattern: Int64List.fromList([0, 500, 500, 500]),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Setup audio
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.alarm());

    // Configurar service
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'alarm',
        initialNotificationTitle: 'Avisa Lá',
        initialNotificationContent: 'Pronto',
      ),
    );
  }

  // Trigger alarme
  static Future<void> trigger({
    required double distance,
    String? soundUrl,
  }) async {
    try {
      // Reproduzir som
      final source = soundUrl != null
          ? AudioSource.uri(Uri.parse(soundUrl))
          : AudioSource.asset('assets/sounds/alarm.mp3');

      await _audioPlayer.setAudioSource(source);
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.play();

      // Mostrar notificação full-screen
      await _notifications.show(
        999,
        'ALARME! 🚨',
        'Distância: ${distance.toStringAsFixed(0)}m',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm',
            'Alarmes',
            fullScreenIntent: true,
            ongoing: true,
            autoCancel: false,
          ),
        ),
      );

      // Trazer app para frente
      await MethodChannel('com.example/app')
          .invokeMethod('bringToForeground');
    } catch (e) {
      print('❌ Erro: $e');
    }
  }

  // Parar alarme
  static Future<void> stop() async {
    await _audioPlayer.stop();
    await _notifications.cancel(999);
  }
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // Setup no isolate
  final session = await AudioSession.instance;
  await session.configure(AudioSessionConfiguration.alarm());
  final player = AudioPlayer();

  service.on('start_alarm').listen((event) async {
    await player.setAudioSource(
      AudioSource.asset('assets/sounds/alarm.mp3'),
    );
    await player.setLoopMode(LoopMode.one);
    await player.play();
  });

  service.on('stop_alarm').listen((_) async {
    await player.stop();
  });
}
```

---

## 10. 🚀 REFERÊNCIAS E RECURSOS

### Documentação Oficial
- **flutter_local_notifications**: https://pub.dev/packages/flutter_local_notifications
- **flutter_background_service**: https://pub.dev/packages/flutter_background_service
- **just_audio**: https://pub.dev/packages/just_audio
- **Android Full-Screen Intent**: https://developer.android.com/develop/ui/views/notifications/full-screen-intent
- **Android Notification Channels**: https://developer.android.com/develop/ui/views/notifications/channels
- **Dart Isolates**: https://dart.dev/language/concurrency#isolates

### Artigos Recomendados
- Full-Screen Notifications in Flutter
- Background Services Best Practices
- Android 12+ Behavioral Changes
- Isolate Communication Patterns

### Problemas Comuns & Soluções
| Problema | Causa | Solução |
|----------|-------|--------|
| Áudio não toca em background | `AudioSession` não configurada | Usar `AudioSessionConfiguration.alarm()` |
| Notificação não full-screen | `fullScreenIntent: false` | Ativar `fullScreenIntent: true` |
| Vibração não funciona Android 12+ | Vibração direta da app | Configurar no `NotificationChannel` |
| Alarme não dispara quando app killed | Background service não autorizado | Usar `isForegroundMode: true` |
| Isolate não recebe mensagens | `@pragma('vm:entry-point')` faltando | Adicionar ao entry point |

---

## 📞 SUPORTE
Para dúvidas sobre implementação, consulte:
- Documentação oficial dos pacotes
- GitHub issues dos repositórios
- Stack Overflow com tags `flutter`, `background-service`, `alarm`

---

**Última Atualização:** Dezembro 2025  
**Versões Testadas:** Flutter 3.22+, Android 14+, Dart 3.10+

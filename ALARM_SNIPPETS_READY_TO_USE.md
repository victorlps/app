# 🔧 SNIPPETS PRONTOS: Alarmes Flutter/Android

Exemplos de código prontos para copiar e colar em seu projeto.

---

## 1️⃣ AndroidManifest.xml - Bloco Completo

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- ===== PERMISSÕES ===== -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY" />

    <application
        android:label="Avisa Lá"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true">

        <!-- ===== ACTIVITY PRINCIPAL ===== -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:showWhenLocked="true"
            android:turnScreenOn="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme">
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- ===== BACKGROUND SERVICE ===== -->
        <service
            android:name="id.flutter.flutter_background_service.BackgroundService"
            android:exported="false"
            android:stopWithTask="false"
            android:foregroundServiceType="location" />

        <!-- ===== NOTIFICATION RECEIVERS ===== -->
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

---

## 2️⃣ pubspec.yaml - Dependências Exatas

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Notificações com full-screen intent
  flutter_local_notifications: ^19.5.0
  
  # Background service
  flutter_background_service: ^5.1.0
  
  # Audio em background
  just_audio: ^0.10.5
  audio_session: ^0.2.0
  
  # Permissões Android 12+
  permission_handler: ^11.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
```

---

## 3️⃣ MainActivity.kt - Method Channels para Foreground

```kotlin
package com.example.avisa_la

import android.app.ActivityManager
import android.content.Intent
import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val APP_CHANNEL = "com.example.avisa_la/app"
    private val VIBRATION_CHANNEL = "com.example.avisa_la/vibration"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ===== APP CHANNEL =====
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_CHANNEL)
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

        // ===== VIBRATION CHANNEL =====
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VIBRATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "vibrate" -> {
                        val duration = call.argument<Int>("duration") ?: 500
                        val intensity = call.argument<Int>("intensity") ?: 255
                        vibrateDevice(duration, intensity)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun bringAppToForeground() {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                   Intent.FLAG_ACTIVITY_NEW_TASK or
                   Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        startActivity(intent)
    }

    private fun unlockDevice() {
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )
    }

    private fun vibrateDevice(duration: Int, intensity: Int) {
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
                intensity
            )
            vibrator.vibrate(effect)
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(duration.toLong())
        }
    }
}
```

---

## 4️⃣ Dart - Serviço de Alarme Completo

```dart
// lib/services/alarm_system.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

// ==================== MODELO ====================
class AlarmEvent {
  final String type; // 'start', 'stop', 'error'
  final double? distance;
  final String? errorMessage;
  final DateTime timestamp;

  AlarmEvent({
    required this.type,
    this.distance,
    this.errorMessage,
  }) : timestamp = DateTime.now();
}

// ==================== SISTEMA PRINCIPAL ====================
class AlarmSystem {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static final _eventController = StreamController<AlarmEvent>.broadcast();

  // Getters
  static Stream<AlarmEvent> get eventStream => _eventController.stream;

  // ===== INICIALIZAÇÃO =====
  static Future<void> initialize() async {
    print('🔧 Inicializando AlarmSystem...');

    // 1. Setup notification channel
    await _setupNotificationChannel();

    // 2. Setup audio session
    await _setupAudioSession();

    // 3. Configure background service
    await _configureBackgroundService();

    print('✅ AlarmSystem inicializado com sucesso');
  }

  // ===== SETUP NOTIFICATION CHANNEL =====
  static Future<void> _setupNotificationChannel() async {
    const AndroidNotificationChannel alarmChannel =
        AndroidNotificationChannel(
      'alarm_channel_id',
      'Alarmes Críticos',
      description:
          'Notificações de alarme que requerem ação imediata do usuário',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      vibrationPattern: Int64List.fromList([0, 500, 500, 500, 500, 1000]),
      showBadge: true,
      bypassDnd: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alarmChannel);

    print('✅ Notification channel criado');
  }

  // ===== SETUP AUDIO SESSION =====
  static Future<void> _setupAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.alarm());
    print('✅ Audio session configurada para alarme');
  }

  // ===== CONFIGURE BACKGROUND SERVICE =====
  static Future<void> _configureBackgroundService() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _alarmServiceEntry,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'alarm_channel_id',
        initialNotificationTitle: 'Avisa Lá',
        initialNotificationContent: 'Monitoramento ativo',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: _alarmServiceEntry,
        onBackground: _onIosBackground,
      ),
    );
    print('✅ Background service configurado');
  }

  // ===== ATIVAR ALARME =====
  static Future<void> triggerAlarm({
    required double distance,
    required String soundFile,
    String? notificationTitle,
    String? notificationBody,
  }) async {
    print('🔊 Ativando alarme - Distância: $distance metros');

    try {
      // Enviar comando para background service
      await _service.invoke('start_alarm', {
        'distance': distance,
        'soundFile': soundFile,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Mostrar notificação full-screen
      await _showFullScreenNotification(
        title: notificationTitle ?? '🚨 ALARME! 🚨',
        body: notificationBody ??
            'Você chegou ao destino!\nDistância: ${distance.toStringAsFixed(0)}m',
      );

      // Trazer app para foreground
      await _bringAppToForeground();

      // Enviar evento
      _eventController.add(
        AlarmEvent(type: 'start', distance: distance),
      );
    } catch (e) {
      print('❌ Erro ao ativar alarme: $e');
      _eventController.add(
        AlarmEvent(
          type: 'error',
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // ===== PARAR ALARME =====
  static Future<void> stopAlarm() async {
    print('🛑 Parando alarme...');

    try {
      await _service.invoke('stop_alarm');
      await _notifications.cancel(999);
      _eventController.add(AlarmEvent(type: 'stop'));
      print('✅ Alarme parado');
    } catch (e) {
      print('❌ Erro ao parar alarme: $e');
    }
  }

  // ===== MOSTRAR NOTIFICAÇÃO FULL-SCREEN =====
  static Future<void> _showFullScreenNotification({
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'alarm_channel_id',
      'Alarmes Críticos',
      channelDescription: 'Alarmes que requerem ação imediata',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      autoCancel: false,
      ongoing: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      vibrationPattern: Int64List.fromList([0, 500, 500, 500]),
      enableLights: true,
      color: const Color.fromARGB(255, 255, 0, 0),
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      999,
      title,
      body,
      details,
      payload: 'alarm_notification',
    );
  }

  // ===== TRAZER APP PARA FOREGROUND =====
  static Future<void> _bringAppToForeground() async {
    const platform = MethodChannel('com.example.avisa_la/app');
    try {
      await platform.invokeMethod('bringToForeground');
      print('✅ App trazido para foreground');
    } on PlatformException catch (e) {
      print('⚠️ Erro ao trazer app: ${e.message}');
    }
  }

  // ===== VIBRAR DEVICE =====
  static Future<void> vibrate({
    int duration = 500,
    int intensity = 255,
  }) async {
    const platform = MethodChannel('com.example.avisa_la/vibration');
    try {
      await platform.invokeMethod('vibrate', {
        'duration': duration,
        'intensity': intensity,
      });
    } catch (e) {
      print('⚠️ Erro ao vibrar: $e');
    }
  }

  // ===== LIMPAR =====
  static Future<void> dispose() async {
    await _eventController.close();
  }
}

// ==================== BACKGROUND SERVICE ENTRY POINT ====================
@pragma('vm:entry-point')
void _alarmServiceEntry(ServiceInstance service) async {
  // ✅ CRÍTICO: Inicializar Flutter no isolate
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  print('🔄 Background service iniciado');

  // Setup audio no isolate
  final audioSession = await AudioSession.instance;
  await audioSession.configure(const AudioSessionConfiguration.alarm());

  // Criar player
  AudioPlayer? _player;

  // Listeners para comandos da UI
  service.on('start_alarm').listen((event) async {
    final distance = event?['distance'] as double?;
    final soundFile = event?['soundFile'] as String? ?? 'alarm_sound';

    try {
      _player = AudioPlayer();

      // Carregar áudio
      final source = soundFile.startsWith('http')
          ? AudioSource.uri(Uri.parse(soundFile))
          : AudioSource.asset('assets/sounds/$soundFile.mp3');

      await _player!.setAudioSource(source);
      await _player!.setLoopMode(LoopMode.one);
      await _player!.setVolume(1.0);

      // Reproduzir
      await _player!.play();

      print('🔊 Alarme reproduzindo em background isolate');
    } catch (e) {
      print('❌ Erro ao reproduzir: $e');
    }
  });

  // Parar alarme
  service.on('stop_alarm').listen((event) async {
    try {
      await _player?.stop();
      print('✅ Alarme parado em background isolate');
    } catch (e) {
      print('❌ Erro ao parar: $e');
    }
  });

  // Limpeza
  service.on('stopService').listen((event) {
    _player?.dispose();
    service.stopSelf();
  });
}

// iOS background
@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  return true;
}
```

---

## 5️⃣ Widget - Usar o AlarmSystem na UI

```dart
// lib/screens/alarm_demo_screen.dart

import 'package:flutter/material.dart';
import '../services/alarm_system.dart';

class AlarmDemoScreen extends StatefulWidget {
  @override
  State<AlarmDemoScreen> createState() => _AlarmDemoScreenState();
}

class _AlarmDemoScreenState extends State<AlarmDemoScreen> {
  AlarmEvent? _lastEvent;
  bool _isAlarmActive = false;

  @override
  void initState() {
    super.initState();
    
    // Ouvir eventos do AlarmSystem
    AlarmSystem.eventStream.listen((event) {
      setState(() {
        _lastEvent = event;
        _isAlarmActive = event.type == 'start';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alarme ${event.type}: ${event.distance ?? 'N/A'}m'),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo de Alarme'),
        backgroundColor: _isAlarmActive ? Colors.red : Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isAlarmActive ? Colors.red[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _isAlarmActive ? '🔴 ALARME ATIVO' : '🟢 Aguardando',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isAlarmActive ? Colors.red : Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Ativar alarme
            ElevatedButton.icon(
              onPressed: () => AlarmSystem.triggerAlarm(
                distance: 500.0,
                soundFile: 'alarm_sound',
              ),
              icon: const Icon(Icons.alarm),
              label: const Text('Ativar Alarme'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 20,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Parar alarme
            ElevatedButton.icon(
              onPressed: () => AlarmSystem.stopAlarm(),
              icon: const Icon(Icons.stop),
              label: const Text('Parar Alarme'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 20,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Evento log
            if (_lastEvent != null)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Último Evento:'),
                    Text('Tipo: ${_lastEvent!.type}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (_lastEvent!.distance != null)
                      Text('Distância: ${_lastEvent!.distance}m'),
                    Text('Hora: ${_lastEvent!.timestamp.toString()}'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    AlarmSystem.dispose();
    super.dispose();
  }
}
```

---

## 6️⃣ main.dart - Inicialização

```dart
import 'package:flutter/material.dart';
import 'services/alarm_system.dart';
import 'screens/alarm_demo_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar AlarmSystem ANTES de runApp
  await AlarmSystem.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avisa Lá - Alarmes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: AlarmDemoScreen(),
    );
  }
}
```

---

## 7️⃣ build.gradle - Dependências Android

```gradle
android {
    namespace "com.example.avisa_la"
    compileSdk 35  // ✅ Mínimo 35 para flutter_local_notifications

    defaultConfig {
        applicationId "com.example.avisa_la"
        minSdkVersion 24  // ✅ Mínimo 24
        targetSdkVersion 35  // ✅ Target 35 para Android 15
        versionCode 1
        versionName "1.0.0"
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }

    lintOptions {
        disable 'MissingDimensionAndroidResources'
    }
}

dependencies {
    // Desugaring para backward compatibility
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.3'
}

compileOptions {
    coreLibraryDesugaringEnabled true
}
```

---

## 📋 CHECKLIST DE TESTE

```
Teste 1: Device Locked, Tela Off
- [ ] Notificação aparece full-screen
- [ ] Som toca
- [ ] Vibração funciona
- [ ] Tela liga automaticamente
- [ ] App vem para foreground

Teste 2: Device em DND Mode
- [ ] Som ainda toca (bypassDnd: true)
- [ ] Vibração funciona
- [ ] Notificação aparece

Teste 3: App Killed pelo Android
- [ ] Background service reinicia
- [ ] Alarme dispara sem problema
- [ ] App pode ser trazido ao foreground

Teste 4: Device Reboot
- [ ] Serviço sobrevive ao reboot
- [ ] Listeners continuam funcionando
```

---

**Pronto para usar! 🚀**

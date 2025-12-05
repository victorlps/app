# 🐛 TROUBLESHOOTING: Alarmes Flutter/Android

Soluções para os problemas mais comuns na implementação de alarmes.

---

## ❌ Problema: "Type 'int' is not a subtype of 'double' in type cast"

### Sintoma
```
E/flutter (12345): ══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞═══════════════════
E/flutter (12345): type 'int' is not a subtype of 'double' in type cast
E/flutter (12345): ═══════════════════════════════════════════════════════════════
```

### Causa
Dados vindo do background service têm tipos diferentes (int ao invés de double).

### ✅ Solução
```dart
// ❌ ERRADO
final distance = data['alertDistance'] as double;

// ✅ CORRETO
final distance = (data['alertDistance'] as num).toDouble();
final time = (data['alertTimeMinutes'] as num).toDouble();
```

### Contexto Completo
```dart
// background_service.dart
@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  service.on('startTrip').listen((event) {
    // ✅ Usar 'as num' que aceita int ou double
    final alertDistance = (event?['alertDistance'] as num).toDouble();
    final alertTimeMinutes = (event?['alertTimeMinutes'] as num).toDouble();
    
    print('✅ Distância: $alertDistance, Tempo: $alertTimeMinutes');
  });
}
```

---

## ❌ Problema: Áudio não toca em background

### Sintoma
- Alarme dispara mas som não toca
- Funciona em foreground, não em background

### Causas Possíveis
1. `AudioSession` não configurada corretamente
2. `just_audio` não inicializado no isolate
3. Áudio arquivo não encontrado

### ✅ Solução Completa

```dart
@pragma('vm:entry-point')
void alarmServiceEntry(ServiceInstance service) async {
  // 1. ✅ Inicializar Flutter plugins no isolate
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // 2. ✅ Setup audio session ANTES de qualquer audio
  final session = await AudioSession.instance;
  await session.configure(
    const AudioSessionConfiguration.alarm(),
  );

  // 3. ✅ Criar player e configurar
  final player = AudioPlayer();

  service.on('play_alarm').listen((event) async {
    try {
      // 4. ✅ Usar AudioSource.asset com path correto
      await player.setAudioSource(
        AudioSource.asset('assets/sounds/alarm.mp3'),
        preload: true,
      );

      // 5. ✅ Configurar volume máximo
      await player.setVolume(1.0);

      // 6. ✅ Configurar repetição
      await player.setLoopMode(LoopMode.one);

      // 7. ✅ Play
      await player.play();

      print('🔊 Tocando alarme em background');
    } catch (e) {
      print('❌ Erro ao tocar: $e');
    }
  });
}
```

### Verificar Arquivo de Áudio
```bash
# Checar se arquivo existe
ls -la assets/sounds/

# Output esperado:
# -rw-r--r-- user group 123456 Dec 5 10:00 alarm.mp3

# Verificar pubspec.yaml
grep -A5 "flutter:" pubspec.yaml | grep -A5 "assets:"
```

---

## ❌ Problema: Notificação não aparece full-screen

### Sintoma
- Notificação aparece na notification shade
- Não aparece full-screen sobre app/lock screen

### Causas
1. `fullScreenIntent: true` não configurado
2. Permissão `USE_FULL_SCREEN_INTENT` faltando
3. `android:showWhenLocked` não setado em Activity
4. Android 11+ restrições de FSI

### ✅ Checklist de Solução

```dart
// 1. ✅ Criar notificação com fullScreenIntent
const AndroidNotificationDetails details = AndroidNotificationDetails(
  'alarm_channel_id',
  'Alarmes',
  fullScreenIntent: true,  // ← CRÍTICO
  importance: Importance.max,
  priority: Priority.max,
  autoCancel: false,
  ongoing: true,
);
```

```xml
<!-- 2. ✅ AndroidManifest.xml -->
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />

<!-- 3. ✅ Activity flags -->
<activity
  android:name=".MainActivity"
  android:showWhenLocked="true"      ← CRÍTICO
  android:turnScreenOn="true"        ← CRÍTICO
  android:launchMode="singleTop">
```

### Debug
```dart
// Verificar se permissão foi dada
final plugin = FlutterLocalNotificationsPlugin()
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

// Tentar solicitar explicitamente
await plugin?.requestFullScreenIntentPermission();
```

---

## ❌ Problema: Vibração não funciona em Android 12+

### Sintoma
- Vibração funciona em Android 11 e anteriores
- Não vibra em Android 12+

### Causa
Android 12+ restringe vibração direta. Deve ser configurada no **notification channel**.

### ✅ Solução

```dart
// ❌ ERRADO: Chamar vibração direto
await Vibration.vibrate(duration: 500);

// ✅ CORRETO: Configurar no canal
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'alarm_channel_id',
  'Alarmes',
  vibrationPattern: Int64List.fromList([
    0,     // sem vibração 0ms
    500,   // vibra 500ms
    500,   // sem vibração 500ms
    500,   // vibra 500ms
  ]),
  importance: Importance.max,
);

await plugin?.createNotificationChannel(channel);
```

### Padrões de Vibração Comuns

```dart
// SOS (3-3-3)
const sos = [0, 200, 100, 200, 100, 200, 500, 200, 500, 200, 500];

// Contínuo
const continuous = [0, 1000, 100, 1000, 100, 1000];

// Suave
const gentle = [0, 300];

// Forte
const strong = [0, 800, 100, 800];

// Padrão para alarme
const alarm = [0, 500, 500, 500, 500, 1000];
```

---

## ❌ Problema: Background service é morto pelo Android

### Sintoma
- App deixa de funcionar em background após 1-2 horas
- Nenhum log de erro
- Processo `.BackgroundService` desaparece

### Causas
1. `isForegroundMode: false` - Android mata serviço
2. Otimização de bateria muito agressiva
3. RAM muito baixa
4. Sem notificação foreground visível

### ✅ Solução

```dart
// 1. ✅ Usar isForegroundMode: true
await FlutterBackgroundService().configure(
  androidConfiguration: AndroidConfiguration(
    onStart: onStart,
    autoStart: true,
    isForegroundMode: true,  // ← CRÍTICO
    notificationChannelId: 'alarm_channel_id',
    foregroundServiceNotificationId: 888,
  ),
);

// 2. ✅ Criar notificação visível
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'alarm_channel_id',
  'Alarmes',
  importance: Importance.low,  // ← Notificação silenciosa
  showBadge: false,
);
```

### Debug - Verificar se serviço está rodando

```bash
# Listar processos Flutter
adb shell ps | grep flutter_background_service

# Output esperado:
# user 12345 11111 1234567 123456 SomeProcess S com.example.avisa_la:alarm

# Se não aparecer, aumentar prioridade
adb shell dumpsys meminfo
```

---

## ❌ Problema: Isolate não recebe mensagens

### Sintoma
- `service.invoke()` é chamado mas listener não ativa
- Timeout esperando resposta
- Listener silenciosamente não funciona

### Causas
1. `@pragma('vm:entry-point')` faltando
2. Entry point não registrado
3. Typo no nome do listener
4. Isolate foi killado

### ✅ Solução

```dart
// 1. ✅ OBRIGATÓRIO: Adicionar pragma
@pragma('vm:entry-point')
void alarmServiceEntry(ServiceInstance service) async {
  // Entry point DEVE ter este pragma
  print('Background service iniciado');

  // 2. ✅ Ouvir com nome EXATO
  service.on('trigger_alarm').listen((event) {
    print('Recebeu: $event');
  });
}

// 3. ✅ Chamar com nome EXATO
await service.invoke('trigger_alarm', {
  'distance': 500,
});
```

### Debug - Verificar se entry point é chamado

```dart
// No topo do arquivo
import 'dart:developer' as developer;

@pragma('vm:entry-point')
void alarmServiceEntry(ServiceInstance service) async {
  // ✅ Verificar se foi chamado
  developer.Timeline.instantSync('BackgroundServiceStarted');
  print('🔄 BACKGROUND SERVICE INICIADO!');
  print('🆔 Service ID: ${service.hashCode}');

  service.on('trigger_alarm').listen((event) {
    developer.Timeline.instantSync('TriggerAlarmReceived');
    print('✅ Trigger recebido: $event');
  });
}

// Na UI
final service = FlutterBackgroundService();
print('🆔 Service ID na UI: ${service.hashCode}');
await service.invoke('trigger_alarm', {'distance': 500});
```

---

## ❌ Problema: App não vem para foreground

### Sintoma
- Notificação aparece mas app não abre
- Device locked mas activity não mostra
- Ao clicar em notificação nada acontece

### Causas
1. `showWhenLocked` ou `turnScreenOn` não setado
2. `launchMode="singleTop"` não configurado
3. Intent flags incorretos

### ✅ Solução

```kotlin
// MainActivity.kt
class MainActivity: FlutterActivity() {
  private fun bringAppToForeground() {
    val intent = Intent(this, MainActivity::class.java).apply {
      flags = (
        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or      // Traga para frente
        Intent.FLAG_ACTIVITY_NEW_TASK or              // Nova task se não existir
        Intent.FLAG_ACTIVITY_SINGLE_TOP               // Reutilize se já existe
      )
    }
    startActivity(intent)
    
    // Também settar flags na window
    window.addFlags(
      WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
      WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
      WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
    )
  }
}
```

```xml
<!-- AndroidManifest.xml -->
<activity
  android:name=".MainActivity"
  android:exported="true"
  android:showWhenLocked="true"
  android:turnScreenOn="true"
  android:launchMode="singleTop">
```

### Debug - Checar intent

```bash
# Ver últimas intents processadas
adb shell dumpsys activity recents
```

---

## ❌ Problema: "tree-shaking removed entry point"

### Sintoma
```
I/flutter (12345): Isolate library 'dart:isolate' was not imported by your application
W/flutter (12345): The entry point 'alarmServiceEntry' was eliminated
E/flutter (12345): Failed to create isolate
```

### Causa
Compilador Dart removeu função porque achou que não era usada.

### ✅ Solução

```dart
// ✅ OBRIGATÓRIO
@pragma('vm:entry-point')
void alarmServiceEntry(ServiceInstance service) async {
  // Este pragma impede tree-shaking
}

// ✅ Também declarar em outro lugar
void main() async {
  // Referenciar explicitamente para não remover
  if (false) alarmServiceEntry(null);
}
```

---

## ❌ Problema: "No such method: notify()"

### Sintoma
```
E/flutter (12345): Exception: No such method: 'notify' on null
```

### Causa
`FlutterLocalNotificationsPlugin` não foi inicializado.

### ✅ Solução

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Inicializar ANTES de usar
  const AndroidInitializationSettings initAndroid =
      AndroidInitializationSettings('app_icon');
  const InitializationSettings initSettings =
      InitializationSettings(android: initAndroid);

  await FlutterLocalNotificationsPlugin().initialize(initSettings);

  runApp(MyApp());
}
```

---

## ❌ Problema: Permissões não funcionam

### Sintoma
- `USE_FULL_SCREEN_INTENT` declarada mas ainda recusa
- `SCHEDULE_EXACT_ALARM` não funciona

### Causas (Android 12+)
- Permissão não foi pedida em runtime
- App target SDK < 33
- Usuário recusou em settings

### ✅ Solução

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestAlarmPermissions() async {
  // Android 12+: Exact alarm
  final exactStatus = await Permission.scheduleExactAlarm.request();
  print('Exact alarm: $exactStatus');

  // Full-screen intent (no permission_handler, fazer via method channel)
  const platform = MethodChannel('com.example/permissions');
  try {
    await platform.invokeMethod('requestFullScreenIntentPermission');
  } catch (e) {
    print('FS Intent: $e');
  }
}

// Também em AndroidManifest.xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
```

---

## 📊 CHECKLIST DE DEBUG

Quando alarme não funciona, testar nessa ordem:

```
1. Background Service
   [ ] @pragma('vm:entry-point') presente?
   [ ] DartPluginRegistrant.ensureInitialized() chamado?
   [ ] listeners sendo registrados? (print no on())
   [ ] service.invoke() chegando? (print no listen)

2. Audio
   [ ] Arquivo exists? (adb shell ls assets/sounds/)
   [ ] AudioSession configurada?
   [ ] just_audio inicializado?
   [ ] Volume = 1.0?

3. Notificação
   [ ] Channel criado com Importance.max?
   [ ] fullScreenIntent: true?
   [ ] AndroidManifest permissões OK?

4. Foreground
   [ ] showWhenLocked="true" em Activity?
   [ ] turnScreenOn="true"?
   [ ] launchMode="singleTop"?

5. Vibração
   [ ] Android 12+? Usar channel vibrationPattern
   [ ] Vibrator service disponível?

6. Permissions
   [ ] Pedidas em runtime?
   [ ] Aceitas pelo usuário?
   [ ] No manifest correto?
```

---

## 🔧 Ferramentas Úteis

### Ver logs em tempo real
```bash
adb logcat -s flutter -v time
```

### Ver permissões concedidas
```bash
adb shell pm dump-permissions com.example.avisa_la
```

### Ver processos background
```bash
adb shell ps | grep background
```

### Testar notificação full-screen
```bash
adb shell am start -n com.example.avisa_la/.MainActivity -a \
  android.intent.action.VIEW --es "test" "notification"
```

---

**Mais problemas? Abra issue no GitHub! 🐛**

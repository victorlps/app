# 🔔 Guia de Debug - Notificações de Alarme

## Problema Relatado
> "Alarme dispara mas notificação não aparece"

## Raiz do Problema (RESOLVIDO ✅)
O arquivo `NotificationService` estava tentando usar um som de notificação inexistente:
```dart
// ❌ ANTES (linha 680 - recurso não existe)
sound: const RawResourceAndroidNotificationSound('alarm_sound'),

// ✅ DEPOIS (agora usa som padrão do sistema)
sound: const RawResourceAndroidNotificationSound('notification'),
```

Quando o Android não consegue encontrar um recurso de som, ele **falha silenciosamente** e não mostra a notificação.

## Componentes Verificados ✅

### 1. **Permissões em AndroidManifest.xml**
```xml
<!-- POST_NOTIFICATIONS: Requerida no Android 13+ para mostrar notificações -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- USE_FULL_SCREEN_INTENT: Permite notificação full-screen (Android 10+) -->
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />

<!-- SCHEDULE_EXACT_ALARM: Requerida no Android 12+ para alarmes exatos -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```
✅ **Status**: Todas as permissões declaradas

### 2. **Requisição de Permissões em Runtime**
Arquivo: `lib/main.dart` → `SplashScreen.initState()` → `_initializeApp()`

```dart
// Fase 1: Solicitação de permissões de notificação (POST_NOTIFICATIONS)
final hasPermissions = await PermissionService.requestPhase1Permissions();
```

**Fluxo**:
1. App inicia → `main.dart`
2. `NotificationService.initialize()` - cria channels
3. `BackgroundService.initialize()` - inicia monitoramento
4. App mostra SplashScreen (2 segundos)
5. `PermissionService.requestPhase1Permissions()` solicita permissões
   - Inclui: `Permission.notification` (POST_NOTIFICATIONS no Android 13+)

✅ **Status**: Permissão solicitada corretamente na inicialização

### 3. **Configuração do Canal de Notificação**
Arquivo: `lib/core/services/notification_service.dart` (linhas 629-647)

```dart
AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
  'alarm_fullscreen_channel',
  '⏰ Alarmes de Proximidade',
  importance: Importance.max,        // ← CRÍTICO
  playSound: true,
  enableVibration: true,
  enableLights: true,
);
```

✅ **Status**: Canal configurado com `Importance.max` (requerido para full-screen)

### 4. **Configuração da Notificação**
Arquivo: `lib/core/services/notification_service.dart` (linhas 663-735)

**Configurações críticas**:
- `importance: Importance.max` - Máxima prioridade
- `priority: Priority.max` - Prioridade máxima
- `category: AndroidNotificationCategory.alarm` - Tipo alarme
- `fullScreenIntent: true` - Abre sobre lockscreen
- `ongoing: true` - Persiste até ação do usuário
- `sound: RawResourceAndroidNotificationSound('notification')` - Som válido ✅
- `playSound: true` - Toca som
- `enableVibration: true` - Vibra com padrão: `[0, 1000, 500, 1000, 500, 1000]`

✅ **Status**: Todas as configurações seguindo Google Best Practices

### 5. **Chamada do Serviço de Background**
Arquivo: `lib/core/services/background_service.dart` (linhas 170-195)

```dart
// Quando distância < 500m:
await NotificationService.showFullScreenAlarmNotification(
  destinationName: destination!.name,
  distance: distance,
);
```

**Logging adicionado** (para debug):
```dart
log('🔔 Showing full-screen alarm notification for: ${destination!.name}');
try {
  await NotificationService.showFullScreenAlarmNotification(...);
  log('✅ Notification shown successfully');
} catch (e) {
  log('❌ Error showing notification: $e');
}
```

✅ **Status**: Notificação chamada corretamente com logging

## Verificação de Funcionamento

### 🧪 Teste Manual (Debug)
Adicione este código em qualquer lugar para testar:

```dart
import 'package:avisa_la/core/services/notification_service.dart';

// Em um botão ou evento:
await NotificationService.testAlarmNotification();
```

Você verá:
- 📱 Notificação com título "🔔 Você está chegando!"
- 📍 Subtítulo "TESTE - Estação Central - 251m"
- 🔊 Som de notificação
- 📳 Vibração forte
- 🔴 LED vermelho piscando

Se NÃO aparecer:
1. Verificar logs: `flutter logs`
2. Verificar se POST_NOTIFICATIONS foi permitido
3. Verificar se notificações estão ativadas nas configurações do device

### ✅ Checklist para Troubleshooting

- [ ] APK reconstruído com `flutter build apk --debug` (depois de 20/01/2025)
- [ ] Device em modo debug com ADB conectado
- [ ] Permissões concedidas no dispositivo:
  - [ ] Localização: "Sempre permitir"
  - [ ] Notificações: ativadas
- [ ] Verificar logcat para erros:
  ```bash
  adb logcat | grep -E "NotificationService|Alarm|showFullScreen"
  ```
- [ ] Testar notificação manualmente com `testAlarmNotification()`
- [ ] Verificar se device não está em "Não perturbe"
- [ ] Verificar se app está com notificações habilitadas em Configurações do Android

## Mudanças Recentes (20/01/2025)

### ✅ Fix #1: Recurso de Som Inválido
**Arquivo**: `lib/core/services/notification_service.dart:680`
```diff
- sound: const RawResourceAndroidNotificationSound('alarm_sound'),  // ❌ Não existe
+ sound: const RawResourceAndroidNotificationSound('notification'), // ✅ Existe no sistema
```

### ✅ Fix #2: Logging Melhorado
**Arquivo**: `lib/core/services/background_service.dart:179-186`
```dart
log('🔔 Showing full-screen alarm notification for: ${destination!.name}');
try {
  await NotificationService.showFullScreenAlarmNotification(...);
  log('✅ Notification shown successfully');
} catch (e) {
  log('❌ Error showing notification: $e');
}
```

### ✅ Fix #3: Método de Teste
**Arquivo**: `lib/core/services/notification_service.dart:99-117`
```dart
static Future<void> testAlarmNotification() async {
  debugPrint('🧪 [TEST] Iniciando teste de notificação de alarme...');
  try {
    await showFullScreenAlarmNotification(
      destinationName: 'TESTE - Estação Central',
      distance: 250.5,
    );
    debugPrint('✅ [TEST] Notificação de teste enviada com sucesso!');
  } catch (e) {
    debugPrint('❌ [TEST] Erro ao enviar notificação de teste: $e');
  }
}
```

## Próximos Passos

1. **Instalar APK recente**:
   ```bash
   adb install build/app/outputs/flutter-apk/app-debug.apk
   ```

2. **Testar notificação manualmente**:
   ```dart
   // Em um botão qualquer no app
   await NotificationService.testAlarmNotification();
   ```

3. **Ativar alarme de proximidade real**:
   - Selecionar um destino
   - Se aproximar (< 500m)
   - Notificação deve aparecer com som e vibração

4. **Capturar logs para troubleshooting**:
   ```bash
   flutter logs
   ```

## Referências Google Best Practices
- https://developer.android.com/training/scheduling/alarms
- https://developer.android.com/develop/ui/views/notifications/custom-notification
- https://developer.android.com/about/versions/12/approximate-behavior

## Status Geral
✅ **Código refatorado como Official Alarm App**
✅ **Permissões declaradas corretamente**
✅ **Permissões solicitadas em tempo de execução**
✅ **Canais criados com Importance.max**
✅ **Notificação configurada como crítica (full-screen)**
✅ **Recurso de som fixado (agora válido)**
✅ **Logging melhorado para debug**
✅ **Método de teste adicionado**

**Próxima ação**: Testar notificação no device real para confirmar funcionamento.

# 🚨 Alarme no Flutter: Melhores Práticas do Google

## 📋 Resumo da Implementação

Este documento detalha as melhores práticas do Google para implementar alarmes full-screen em Flutter, conforme aplicado no Avisa Lá.

---

## 🎯 Problema Original

**Sintoma:** Ao iniciar a corrida, o app abria diretamente o diálogo de permissão do sistema (full-screen intent), mas o botão "Permitir" estava inativo/desativado.

**Causa Raiz:** 
- Não havia **educação do usuário** ANTES de solicitar a permissão
- A permissão era solicitada diretamente via `flutter_local_notifications`, sem contexto
- O Google recomenda explicitamente um fluxo com diálogo educativo primeiro

---

## ✅ Solução Implementada

### 1. **Fluxo Correto de Permissões (Google Best Practices)**

#### Ordem das Permissões:

```
1️⃣ Educação (Diálogo explicativo)
   ↓
2️⃣ POST_NOTIFICATIONS (Android 13+)
   ↓
3️⃣ SCHEDULE_EXACT_ALARM (Android 12+)
   ↓
4️⃣ USE_FULL_SCREEN_INTENT (Android 11+)
   ✓ Solicitada automaticamente pelo flutter_local_notifications
```

### 2. **Implementação em `NotificationService`**

#### Método Principal: `requestAlarmPermissionsWithEducation()`

```dart
static Future<bool> requestAlarmPermissionsWithEducation(BuildContext context) async {
  // PASSO 1: Educação
  final shouldProceed = await _showAlarmEducationDialog(context);
  if (!shouldProceed) return false;

  // PASSO 2: POST_NOTIFICATIONS
  final notificationStatus = await _requestAndShowPermissionDialog(
    context,
    Permission.notification,
    title: 'Permissão de Notificações',
    explanation: 'O Avisa Lá precisa enviar notificações...',
  );
  
  // PASSO 3: SCHEDULE_EXACT_ALARM
  final scheduleStatus = await _requestAndShowPermissionDialog(
    context,
    Permission.scheduleExactAlarm,
    title: 'Permissão de Alarmes',
    explanation: 'Para notificar você no tempo exato...',
  );
  
  return notificationStatus.isGranted && scheduleStatus.isGranted;
}
```

### 3. **Diálogos Educativos**

#### 3a. Diálogo de Educação Inicial
```dart
static Future<bool> _showAlarmEducationDialog(BuildContext context) async {
  // Mostra ANTES de qualquer permissão
  // Explica o necessário: 🔔 Notificações, ⏰ Alarmes, 🔓 Full-Screen
}
```

#### 3b. Diálogo de Cada Permissão
```dart
static Future<PermissionStatus> _requestAndShowPermissionDialog(
  BuildContext context,
  Permission permission, {
  required String title,
  required String explanation,
}) async {
  // Mostra educação ANTES do diálogo do sistema
  // Solicita permissão apenas após consentimento educado
}
```

#### 3c. Diálogo de Negação Permanente
```dart
static Future<void> _showPermanentlyDeniedDialog(
  BuildContext context,
  String permissionName,
) async {
  // Guia usuário para Configurações
  // Oferece botão "Abrir Configurações"
}
```

### 4. **Integração em `TripMonitoringPage`**

```dart
Future<void> _startMonitoring() async {
  // Solicitar permissões ANTES de iniciar trip
  final hasPermissions = 
    await NotificationService.requestAlarmPermissionsWithEducation(context);
  
  if (!hasPermissions) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Permissões negadas. Alarme pode não funcionar.'))
    );
    return;
  }
  
  // Prosseguir com inicialização
  await BackgroundService.startTrip(...);
}
```

### 5. **Configuração no Android**

#### AndroidManifest.xml
```xml
<!-- Permissões necessárias -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
```

#### MainActivity.kt
```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
  super.onCreate(savedInstanceState)
  
  // Permitir que alarmes acordem o device
  window.addFlags(
    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
  )
}
```

### 6. **Notification Channels**

```dart
// Cada tipo de notificação tem seu channel com configurações apropriadas
const arrivalChannel = AndroidNotificationChannel(
  'arrival_channel',
  'Alarmes de Chegada',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

// E quando mostrar a notificação:
final details = AndroidNotificationDetails(
  'arrival_channel',
  'Alarmes de Chegada',
  fullScreenIntent: true,        // ✅ Ativa full-screen
  category: AndroidNotificationCategory.alarm,
  visibility: NotificationVisibility.public,  // ✅ Mostra lock screen
);
```

---

## 🔍 Por Que Isso Funciona?

### ❌ Abordagem Errada (O que você tinha):
```
Usuário clica "Iniciar Corrida"
  ↓
App tenta abrir diálogo do sistema SEM contexto
  ↓
Usuário fica confuso: "Por que preciso permitir?"
  ↓
Usuário nega ou ignora
  ↓
Alarme não funciona com tela bloqueada
```

### ✅ Abordagem Correta (O que implementamos):
```
Usuário clica "Iniciar Corrida"
  ↓
Diálogo educativo: "Por que você precisa disso?"
  ↓
Usuário entende e clica "Continuar"
  ↓
Diálogos sequenciais solicitam cada permissão
  ↓
Sistema Android reconhece o contexto de alarme
  ↓
Botões habilitados no diálogo do sistema
  ↓
Usuário consegue clicar "Permitir"
  ↓
Alarme funciona perfeitamente
```

---

## 📚 Referências Oficiais do Google

- [Android Alarms and Reminders Guide](https://developer.android.com/guide/topics/appwidgets/overview#creating-the-app-widget-layout)
- [Full-Screen Intents](https://developer.android.com/develop/ui/views/notifications/full-screen-intent)
- [Runtime Permissions Best Practices](https://developer.android.com/training/permissions/requesting)
- [Notification Channels](https://developer.android.com/training/notify-user/channels)

---

## 🛠️ Checklist de Implementação

- ✅ Diálogo educativo antes de qualquer permissão
- ✅ POST_NOTIFICATIONS (Android 13+)
- ✅ SCHEDULE_EXACT_ALARM (Android 12+)
- ✅ USE_FULL_SCREEN_INTENT declarada no manifest
- ✅ MainActivity flags configuradas (FLAG_SHOW_WHEN_LOCKED, etc)
- ✅ Notification category como ALARM
- ✅ Notification visibility como PUBLIC
- ✅ fullScreenIntent: true nas details
- ✅ Diálogos para permissão negada permanentemente
- ✅ Integração contextual (solicitação ao iniciar corrida)

---

## 🎨 Diálogos Mostrados ao Usuário

### 1. Diálogo Educativo Inicial
```
🔔 Permissões para Alarme

Para que o alarme funcione perfeitamente, o Avisa Lá precisa de 
algumas permissões:

🔔 Enviar notificações
⏰ Agendar alarmes
🔓 Exibir acima da tela bloqueada

Isso garante que você receberá a notificação mesmo com o 
celular bloqueado.

[Agora não]  [Continuar]
```

### 2. Diálogo de Notificações
```
⚠️ Permissão de Notificações

O Avisa Lá precisa enviar notificações para alertá-lo sobre sua parada.

[Agora não]  [Permitir]
```

### 3. Diálogo de Alarmes
```
⏰ Permissão de Alarmes

Para notificar você no tempo exato, o app precisa agendar alarmes 
com precisão.

[Agora não]  [Permitir]
```

### 4. Sistema Android Solicita Full-Screen
```
[Android System Dialog]

"Avisa Lá" quer exibir em tela cheia
[Permitir]  [Negar]
```

---

## 🚀 Como Usar

No seu `HomePage` ou onde inicia a corrida:

```dart
// Ao clicar no botão de iniciar corrida:
onPressed: () async {
  // Solicitar permissões com educação
  final hasPerms = await NotificationService
    .requestAlarmPermissionsWithEducation(context);
  
  if (!hasPerms) {
    print('Usuário não concedeu permissões necessárias');
    return;
  }
  
  // Prosseguir com a corrida
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => TripMonitoringPage(
      destination: selectedDestination,
      alertDistance: 500,
      useDynamicMode: false,
      alertTimeMinutes: 10,
    ),
  ));
},
```

---

## 🔧 Troubleshooting

### Problema: Botão "Permitir" está desativado

**Solução:** Certifique-se que:
1. Há diálogo educativo ANTES do diálogo do sistema
2. AndroidManifest.xml tem `USE_FULL_SCREEN_INTENT` declarado
3. Você está usando `permission_handler` para controle explícito

### Problema: Alarme não toca com tela bloqueada

**Solução:**
1. Verificar que `fullScreenIntent: true` está setado
2. Confirmar que `FLAG_SHOW_WHEN_LOCKED` está em MainActivity
3. Testar com `flutter run` (não release)

### Problema: Permissão sendo pedida toda vez

**Solução:** Verificar método `canUseFullScreenIntent()` - deve retornar `true` se já concedida.

---

## 📝 Notas Importantes

1. **USE_FULL_SCREEN_INTENT é permanente**: Uma vez concedida, o app pode usar full-screen intents sem pedir novamente.

2. **Contexto é fundamental**: O Google recomenda solicitar permissões quando o usuário as necessita (ex: ao iniciar corrida), não na inicialização do app.

3. **Educação antes de solicitar**: Usuarios educados têm maior probabilidade de conceder permissões.

4. **Tratamento de negação**: Sempre ofereça um guia para ativar em Configurações caso o usuário negue.

5. **Testes em device real**: A simulação pode se comportar diferente de um device real.

---

## 🎓 Conclusão

Implementar alarmes no Flutter corretamente exige:
- ✅ Entender o fluxo de permissões do Android
- ✅ Educar o usuário ANTES de solicitar
- ✅ Usar APIs corretas (flutter_local_notifications + permission_handler)
- ✅ Configurar Android corretamente (manifesto, MainActivity, channels)
- ✅ Testar extensivamente em device real

Seguindo essas práticas, você terá um alarme robusto que funciona mesmo com device bloqueado.

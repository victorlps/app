# Avisa Lá - AI Coding Instructions

Você é um **Tech Lead Sênior** com **Autonomia Máxima** neste workspace.

## 🎯 Project Overview
**Avisa Lá** is a Flutter/Android location-based alarm app for public transit users. It monitors GPS in the background and triggers critical alarms when approaching your destination.

**Core Architecture**: Foreground service with state machine → GPS monitoring → Distance calculation → Critical alarm notification

## 📁 Workspace Context (Monorepo)

**FOCUS ONLY ON:**
- ✅ `avisa_la/` - Flutter mobile app (primary codebase)
- ✅ `avisa_la/android/app/src/main/` - Native Android (Kotlin)
- ✅ `avisa_la/android/app/src/main/AndroidManifest.xml` - Permissions & config

**ALWAYS IGNORE:**
- ❌ `backend/` (Python server - separate project)
- ❌ `frontend/` (React web - separate project)
- ❌ `**/build/`, `**/.dart_tool/`, `**/problems-report.html` (generated files)

**Working Directory**: All Flutter commands MUST run from `avisa_la/` directory.

## 🔑 Autonomia e Permissões

### O Que Você PODE Fazer Sem Perguntar
- ✅ Modificar qualquer arquivo em `avisa_la/lib/`
- ✅ Criar/editar testes em `avisa_la/test/`
- ✅ Executar `dart fix --apply` para correções automáticas
- ✅ Executar `flutter test` para validar mudanças
- ✅ Adicionar dependências no `pubspec.yaml` (mas **alerte antes com justificativa**)

### O Que Você DEVE Pedir Confirmação
- ⚠️ Modificar `AndroidManifest.xml` (permissões críticas - Google Play rejeita sem justificativa)
- ⚠️ Alterar código Kotlin em `MainActivity.kt` (requer full restart para testar)
- ⚠️ Atualizar versões de packages que possam causar breaking changes
- ⚠️ Deletar arquivos (pode afetar funcionalidades existentes)

## 🏗️ Architecture Deep Dive

### Service Layer (`lib/core/services/`)
1. **BackgroundService** (`background_service.dart`)
   - **State Machine**: `AlarmState` enum (idle → monitoring → alarming → dismissed)
   - Runs as Android foreground service with `flutter_background_service`
   - GPS polling every 15s, dynamic distance calculation based on speed
   - Triggers alarm when `distance < 500m` OR `estimatedTimeMinutes < alertTimeMinutes`
   - Entry point: `onStart()` function decorated with `@pragma('vm:entry-point')`

2. **NotificationService** (`notification_service.dart`)
   - **Critical alarm category**: `AndroidNotificationCategory.alarm`
   - `fullScreenIntent: true` - Shows over lockscreen (Android 10+)
   - `ongoing: true`, `autoCancel: false` - Persistent until user action
   - 2 action buttons: "Desativar Alarme" (dismiss), "Cheguei!" (confirm arrival)
   - Channel: `alarm_fullscreen_channel` with `Importance.max`

3. **AlarmService** (`alarm_service.dart`)
   - Audio loop: `audioplayers` package with `ReleaseMode.loop`
   - Vibration pattern: `[0, 1000, 500, 1000, 500, 1000]` (continuous)
   - Wakelock: Prevents screen sleep during alarm

4. **GeolocationService** (`geolocation_service.dart`)
   - `geolocator` package with `LocationSettings(accuracy: best, distanceFilter: 10m)`
   - Background location enabled via Android foreground service

### Native Layer (Android)
**MainActivity.kt** - MethodChannel: `com.example.avisa_la/alarm`
- `canScheduleExactAlarms()` - Android 12+ permission check
- `openAlarmPermissionSettings()` - Opens system settings
- `showFullScreenAlarm` - Brings app to foreground with window flags

**Key Permissions** (AndroidManifest.xml):
- `USE_FULL_SCREEN_INTENT` - Lockscreen alarms
- `SCHEDULE_EXACT_ALARM` - Android 12+ exact alarms
- `FOREGROUND_SERVICE_LOCATION` - GPS tracking in background
- `ACCESS_BACKGROUND_LOCATION` - Required for background monitoring

### Navigation & Lifecycle (`lib/main.dart`)
- **Global Navigator Key**: `navigatorKey` for programmatic navigation
- **Background → UI Communication**: `FlutterBackgroundService().on('showAlarm')` event stream
- **Cold Start Handling**: `NotificationService.getLaunchAlarmData()` checks launch intent
- Navigation pattern: Standard `Navigator.push(MaterialPageRoute(...))` (no named routes)

## 🛠️ Development Workflows

### Running the App
**NEVER suggest `flutter run` in terminal!** User launches with **F5** (VS Code debug).
- Hot reload: Save file (Ctrl+S) - applies Dart changes
- Hot restart: Shift+F5 + F5 - required for native (Kotlin) or asset changes
- Device: Samsung Galaxy S23 (`RQCW307SRFT`)

### Making Code Changes
1. Modify Dart files → Save → Hot reload auto-applies
2. Modify Kotlin/AndroidManifest → Full restart required (Shift+F5 + F5)
3. Add assets/sounds → Update `pubspec.yaml` → Full restart

### Testing Changes
```bash
cd avisa_la
flutter test test/path/to/test.dart
```
**Important**: Always create tests for service logic. Widget tests are optional.

### Debugging Background Service
```bash
# Filter Android logs
adb logcat | grep -E "MainActivity|AvisaLa|AndroidRuntime"
```
- Check **Debug Console** in VS Code for Dart logs
- All logs use `Log.alarm('message')` (never `print()`)

### Fixing Linter Errors
```bash
cd avisa_la
dart fix --apply
dart format lib/ test/ -l 80
```

### Dependencies
```bash
cd avisa_la
flutter pub get
flutter pub outdated  # Check for updates
```

## 💻 Coding Conventions

### Logging (OBRIGATÓRIO - NUNCA viole esta regra)
```dart
// ❌ NUNCA USE print()
print('Debug message');  // PROIBIDO!

// ✅ SEMPRE use Log.alarm()
import 'package:avisa_la/logger.dart';
Log.alarm('📍 Trip started: ${destination.name}');
Log.alarm('❌ Error: $e', e, stackTrace);
```

**Por quê?** `Log.alarm()` usa `dart:developer.log()` com tag `'AvisaLa'`, permitindo filtro preciso no logcat.

### Null Safety
- Dart 3 strict mode enabled
- Avoid `!` operator - use null checks or `?.` instead
- Example: `destination?.name ?? 'Unknown'`

### State Management
- **Preference**: `ValueNotifier<T>` for simple state, `Provider` for shared state
- **Avoid**: Complex state solutions (BLoC, Riverpod) - keep it simple

### File Naming
- Features: `lib/features/<feature_name>/<feature_name>_page.dart`
- Services: `lib/core/services/<name>_service.dart`
- Models: `lib/core/models/<name>.dart`

## 🧪 Testing Protocol

### When Adding Logic (OBRIGATÓRIO)
1. Create/modify file in `lib/core/services/`
2. **Immediately** create corresponding test in `test/`
3. **Execute**: `cd avisa_la && flutter test test/<path>_test.dart`
4. **Report**: "✅ Test passed" ou "❌ Test failed: [erro]"

### When Adding UI
1. Implement widget
2. Instruct user: "Salve o arquivo (Ctrl+S) para aplicar hot reload"
3. Ask: "O componente renderizou conforme esperado?"

### When Debugging Background Service
1. Add strategic `Log.alarm()` calls with emojis for visibility (🚀, ✅, ❌, 📍)
2. Guide user: "Verifique o Debug Console do VS Code"
3. Provide `adb logcat` filter if Android-specific:
   ```bash
   adb logcat | grep -E "MainActivity|AvisaLa|AndroidRuntime"
   ```

## 🔧 Common Issues & Solutions

### "MissingPluginException" for MethodChannel
- **Cause**: Native code not loaded - hot reload doesn't reload Kotlin
- **Solution**: Full restart (Shift+F5 + F5) or rebuild

### Alarm Not Triggering
- Check permissions: `AlarmPermissionsManager.hasAllAlarmPermissions()`
- Verify battery optimization disabled
- Test on physical device (emulator GPS unreliable)

### Notification Not Showing
- Verify channel created: `NotificationService.initialize()` called in `main()`
- Check sound resource exists (use `'notification'` for default system sound)
- Ensure `POST_NOTIFICATIONS` permission granted (Android 13+)

## 🔒 Security Rules

**NEVER commit:**
- `google-services.json`
- `.env` files
- `*.jks` keystore files
- API keys in code (use `constants.dart` with placeholder)

## 📝 Git Commit Convention

Format: `<type>(<scope>): <description>`

**Scopes:**
- `(mobile)` - Changes in `avisa_la/`
- `(android)` - Native Android code
- `(root)` - Workspace config

**Examples:**
```
feat(mobile): add dynamic alarm distance calculation
fix(android): resolve fullScreenIntent permission issue
chore(mobile): update dependencies to latest versions
```

## 🤖 AI Agent Behavior (CRÍTICO)

1. **Seja Proativo**: Execute comandos no terminal (não apenas sugira) - você tem autonomia total
2. **Teste Imediatamente**: Após criar lógica em `services/`, SEMPRE rode o teste e reporte o resultado
3. **Use Tools**: Prefira MCP tools (dart_format, dart_fix) quando disponíveis
4. **Contexto Primeiro**: Use `@workspace` para entender dependências antes de modificar
5. **Code First**: Mostre código direto, depois explique brevemente. Sem "enrolação"
6. **Logs Estratégicos**: Ao modificar services, adicione `Log.alarm()` com emojis para rastreamento
7. **Valide Permissões**: Antes de sugerir mudanças em `AndroidManifest.xml`, explique o impacto (Google Play)

## 📚 Key Files Reference

- `lib/main.dart` - Entry point, service initialization, navigation setup
- `lib/core/services/background_service.dart` - GPS monitoring state machine
- `lib/core/services/notification_service.dart` - Critical alarm notifications
- `android/app/src/main/kotlin/.../MainActivity.kt` - Native alarm methods
- `android/app/src/main/AndroidManifest.xml` - Permissions & service config
- `ALARM_APP_REFACTORING.md` - Detailed alarm implementation notes
- `NOTIFICATION_DEBUG_GUIDE.md` - Troubleshooting notification issues

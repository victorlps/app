# 🔧 Dicas Avançadas e Otimizações - Avisa Lá

## 🎯 Otimizações de Performance

### 1. Bateria

#### Estratégia Adaptativa de GPS
O app já implementa GPS adaptativo baseado em movimento. Para ajustar:

```dart
// Em lib/core/services/geolocation_service.dart
static LocationSettings _getLocationSettings(bool isMoving) {
  if (isMoving) {
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Ajuste: maior = menos precisão, menos bateria
    );
  } else {
    return const LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 50, // Parado: muito menos atualizações
    );
  }
}
```

#### Reduzir Frequência de Health Check
```dart
// Em lib/core/utils/constants.dart
static const int healthCheckIntervalSeconds = 30; // Aumente para 60 ou 90
```

### 2. Memória

#### Limitar Cache de Mapas
```dart
// Em GoogleMap widget
GoogleMap(
  // ...
  liteModeEnabled: false, // true = menos memória, menos interatividade
  buildingsEnabled: false, // Desabilita prédios 3D
  trafficEnabled: false,   // Desabilita tráfego
)
```

### 3. Network

#### Cache de Buscas Recentes
Implemente cache local para destinos frequentes:

```dart
// lib/core/services/storage_service.dart (criar novo)
class StorageService {
  static const String keyRecentDestinations = 'recent_destinations';
  
  static Future<void> saveRecentDestination(Destination dest) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? recent = prefs.getStringList(keyRecentDestinations) ?? [];
    recent.insert(0, jsonEncode(dest.toJson()));
    if (recent.length > 5) recent = recent.take(5).toList();
    await prefs.setStringList(keyRecentDestinations, recent);
  }
  
  static Future<List<Destination>> getRecentDestinations() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? recent = prefs.getStringList(keyRecentDestinations);
    if (recent == null) return [];
    return recent.map((s) => Destination.fromJson(jsonDecode(s))).toList();
  }
}
```

## 🛡️ Melhorias de Confiabilidade

### 1. Watchdog Externo

Implemente um segundo timer que verifica se o principal está funcionando:

```dart
// Em background_service.dart
Timer? watchdogTimer;

watchdogTimer = Timer.periodic(
  const Duration(seconds: 60),
  (timer) async {
    // Se última atualização foi há mais de 2 minutos
    if (DateTime.now().difference(lastUpdate) > Duration(minutes: 2)) {
      // Reiniciar monitoring
      await NotificationService.showFailureNotification();
      // Tentar restart
    }
  },
);
```

### 2. Persistência de Estado

Salvar estado da viagem para recuperação após crash:

```dart
// lib/core/services/trip_state_service.dart
class TripStateService {
  static const String keyActiveTripState = 'active_trip';
  
  static Future<void> saveTripState({
    required Destination destination,
    required double alertDistance,
    required bool useDynamicMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyActiveTripState, jsonEncode({
      'destination': destination.toJson(),
      'alertDistance': alertDistance,
      'useDynamicMode': useDynamicMode,
      'startTime': DateTime.now().toIso8601String(),
    }));
  }
  
  static Future<Map<String, dynamic>?> getActiveTripState() async {
    final prefs = await SharedPreferences.getInstance();
    String? state = prefs.getString(keyActiveTripState);
    if (state == null) return null;
    return jsonDecode(state);
  }
  
  static Future<void> clearTripState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyActiveTripState);
  }
}
```

Então no `main.dart`, verificar se há viagem ativa:

```dart
@override
void initState() {
  super.initState();
  _checkForActiveTrip();
}

Future<void> _checkForActiveTrip() async {
  final activeTrip = await TripStateService.getActiveTripState();
  if (activeTrip != null) {
    // Mostrar diálogo: "Você tem uma viagem ativa. Continuar?"
  }
}
```

### 3. Detecção de Modo Avião

```dart
// lib/core/services/connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static Future<bool> isConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  static Stream<ConnectivityResult> connectivityStream() {
    return Connectivity().onConnectivityChanged;
  }
}
```

Use no background service para pausar quando offline.

## 🎨 Melhorias de UX

### 1. Onboarding Educativo

Crie telas de onboarding na primeira abertura:

```dart
// lib/features/onboarding/onboarding_page.dart
class OnboardingPage extends StatelessWidget {
  final List<OnboardingStep> steps = [
    OnboardingStep(
      title: 'Relaxe durante a viagem',
      description: 'O Avisa Lá monitora sua localização e te alerta quando chegar',
      icon: Icons.headset,
    ),
    OnboardingStep(
      title: 'Funciona em segundo plano',
      description: 'Use outros apps ou bloqueie a tela, continuaremos monitorando',
      icon: Icons.phone_android,
    ),
    // ...
  ];
}
```

### 2. Feedback Sonoro e Vibração Customizada

```dart
// lib/core/services/haptic_service.dart
import 'package:flutter/services.dart';

class HapticService {
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }
  
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }
  
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }
  
  static Future<void> arrivalPattern() async {
    await heavyImpact();
    await Future.delayed(Duration(milliseconds: 200));
    await heavyImpact();
    await Future.delayed(Duration(milliseconds: 200));
    await heavyImpact();
  }
}
```

Use no momento do alerta de chegada.

### 3. Animações de Mapa

```dart
// Animar transição entre marcadores
void _animateToShowBothMarkers() {
  if (_currentPosition == null || _selectedDestination == null) return;
  
  LatLngBounds bounds = _calculateBounds(
    _currentPosition!,
    _selectedDestination!,
  );
  
  _mapController?.animateCamera(
    CameraUpdate.newLatLngBounds(bounds, 100),
  );
}
```

## 🔐 Segurança e Privacidade

### 1. Modo Incognito

Adicione opção para não salvar destinos recentes:

```dart
// lib/core/utils/constants.dart
static const String keyIncognitoMode = 'incognito_mode';

// Verificar antes de salvar
if (!incognitoMode) {
  await StorageService.saveRecentDestination(destination);
}
```

### 2. Limpeza Automática de Dados

```dart
// Limpar dados antigos periodicamente
Future<void> cleanOldData() async {
  final prefs = await SharedPreferences.getInstance();
  // Limpar destinos com mais de 30 dias
  // Limpar trips completados
}
```

## 📊 Analytics e Logging (Opcional)

### 1. Logging Local para Debug

```dart
// lib/core/services/log_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LogService {
  static Future<void> log(String message) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/avisa_la_logs.txt');
    
    final timestamp = DateTime.now().toIso8601String();
    await file.writeAsString(
      '[$timestamp] $message\n',
      mode: FileMode.append,
    );
  }
  
  static Future<String> getLogs() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/avisa_la_logs.txt');
    if (!await file.exists()) return 'No logs';
    return await file.readAsString();
  }
}
```

### 2. Métricas de Viagem

```dart
// lib/core/models/trip_metrics.dart
class TripMetrics {
  final String tripId;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalDistance;
  final double averageSpeed;
  final bool completedSuccessfully;
  final int notificationsSent;
  
  // Salvar ao final de cada viagem para análise
}
```

## 🌐 Recursos Adicionais

### 1. Suporte a Múltiplos Idiomas

```dart
// pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

// Adicione arquivo de strings em português/inglês
```

### 2. Tema Escuro

```dart
// main.dart
MaterialApp(
  theme: ThemeData.light(),
  darkTheme: ThemeData.dark(),
  themeMode: ThemeMode.system, // Ou usar preferência do usuário
)
```

### 3. Widget de Configurações

Crie tela de configurações com:
- Distância de alerta padrão
- Modo dinâmico on/off
- Sons e vibrações
- Modo incognito
- Unidades (metros/pés)

## 🐛 Debug Avançado

### 1. Mock Location para Testes

```dart
// lib/core/services/mock_location_service.dart
class MockLocationService {
  static bool useMockLocations = false;
  static List<Position> mockRoute = [];
  static int currentIndex = 0;
  
  static Position? getNextMockPosition() {
    if (!useMockLocations || mockRoute.isEmpty) return null;
    
    final position = mockRoute[currentIndex];
    currentIndex = (currentIndex + 1) % mockRoute.length;
    return position;
  }
}
```

### 2. Painel de Debug

```dart
// lib/features/debug/debug_panel.dart
class DebugPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Debug Panel')),
      body: ListView(
        children: [
          ListTile(
            title: Text('View Logs'),
            onTap: () async {
              final logs = await LogService.getLogs();
              // Mostrar em dialog ou nova tela
            },
          ),
          ListTile(
            title: Text('Clear All Data'),
            onTap: () {
              // Limpar SharedPreferences
            },
          ),
          SwitchListTile(
            title: Text('Use Mock Locations'),
            value: MockLocationService.useMockLocations,
            onChanged: (val) {
              MockLocationService.useMockLocations = val;
            },
          ),
          ListTile(
            title: Text('Simulate Arrival'),
            onTap: () {
              NotificationService.showArrivalNotification(distance: 100);
            },
          ),
        ],
      ),
    );
  }
}
```

Acesse via gesture secreto na tela principal (ex: 5 toques no logo).

## 📈 Métricas de Performance

### Monitorar Uso de Bateria

```dart
// Adicione ao pubspec.yaml
battery_plus: ^4.0.0

// Monitore
import 'package:battery_plus/battery_plus.dart';

final battery = Battery();
final level = await battery.batteryLevel;
final state = await battery.batteryState;

// Log quando bateria cai abaixo de 20% durante trip
```

### Monitorar Uso de Memória

```dart
// Android nativo
import 'package:flutter/services.dart';

MethodChannel _channel = MethodChannel('memory_info');

Future<double> getUsedMemoryMB() async {
  return await _channel.invokeMethod('getUsedMemory');
}
```

## 🚀 Preparação para Produção

### 1. Remover Debug Code

Antes de release:
```bash
# Procurar por print statements
grep -r "print(" lib/

# Remover logs de debug
# Desabilitar mock locations
# Remover debug panel
```

### 2. Obfuscação

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

### 3. ProGuard (Android)

Em `android/app/build.gradle`:
```gradle
buildTypes {
    release {
        minifyEnabled true
        proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
    }
}
```

### 4. Assets Optimization

```bash
# Comprimir imagens
# Remover assets não usados
flutter build apk --analyze-size
```

## 📱 Testes em Dispositivos Reais

### Fabricantes Específicos

**Samsung (OneUI):**
- Settings → Apps → Avisa Lá → Battery → Optimize battery usage → All → Desmarque Avisa Lá
- Settings → Apps → Avisa Lá → Permissions → Location → Allow all the time

**Xiaomi (MIUI):**
- Settings → Apps → Manage apps → Avisa Lá → Autostart → Enable
- Settings → Battery & performance → Manage apps' battery usage → Choose apps → Avisa Lá → No restrictions

**Huawei (EMUI):**
- Settings → Battery → Launch → Avisa Lá → Manage manually → Allow all
- Settings → Apps → Apps → Avisa Lá → Battery → Power-intensive prompt → Don't show

## 🎓 Recursos de Aprendizado

- **Geolocação no Flutter**: https://medium.com/flutter-community/working-with-geolocation-and-geocoding-in-flutter-and-integration-with-maps-16fb0bc35ede
- **Background Services**: https://pub.dev/packages/flutter_background_service
- **Otimização de Bateria**: https://developer.android.com/training/monitoring-device-state/doze-standby

---

**Bom desenvolvimento! 🚀**

# 📱 Guia de Setup Completo - Avisa Lá

Este guia detalha todos os passos necessários para configurar e executar o projeto Avisa Lá localmente.

## 📥 Passo 1: Copiar o Projeto para sua Máquina Local

### Opção A: Copiar Arquivos Manualmente

1. Todo o código foi gerado em `/app/avisa_la/`
2. Copie toda a pasta para sua máquina local:
   ```bash
   # No seu ambiente local
   mkdir -p ~/projects/avisa_la
   # Cole todos os arquivos de /app/avisa_la/ aqui
   ```

### Opção B: Criar Projeto Flutter e Adicionar Arquivos

```bash
# Criar novo projeto Flutter
flutter create avisa_la
cd avisa_la

# Substituir pubspec.yaml, lib/, android/, ios/ pelos arquivos gerados
```

## 🔧 Passo 2: Instalar Flutter SDK

Se você ainda não tem Flutter instalado:

### Windows
```bash
# Baixe Flutter SDK de https://flutter.dev/docs/get-started/install/windows
# Extraia e adicione ao PATH

# Verifique instalação
flutter doctor
```

### macOS
```bash
# Baixe Flutter SDK de https://flutter.dev/docs/get-started/install/macos
# Ou use homebrew
brew install --cask flutter

# Verifique instalação
flutter doctor
```

### Linux
```bash
# Baixe Flutter SDK
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.x.x-stable.tar.xz
tar xf flutter_linux_3.x.x-stable.tar.xz

# Adicione ao PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Verifique instalação
flutter doctor
```

## 📱 Passo 3: Configurar Ambiente Android

### 3.1 Instalar Android Studio
1. Baixe de: https://developer.android.com/studio
2. Instale e abra Android Studio
3. Vá em Settings → Appearance & Behavior → System Settings → Android SDK
4. Instale:
   - Android SDK Platform-Tools
   - Android SDK Build-Tools
   - Android 13 (API 33) ou superior

### 3.2 Configurar Emulador ou Dispositivo Físico

**Emulador:**
```bash
# Criar AVD (Android Virtual Device)
# No Android Studio: Tools → Device Manager → Create Device
# Selecione Pixel 6 com Android 13
```

**Dispositivo Físico:**
1. Ative "Opções do Desenvolvedor" no Android
2. Ative "Depuração USB"
3. Conecte via USB

### 3.3 Verificar Setup Android
```bash
flutter doctor --android-licenses
flutter doctor -v
```

## 🍎 Passo 4: Configurar Ambiente iOS (apenas macOS)

### 4.1 Instalar Xcode
```bash
# Via App Store ou
xcode-select --install
```

### 4.2 Instalar CocoaPods
```bash
sudo gem install cocoapods
```

### 4.3 Configurar Simulator
```bash
# Abrir simulador
open -a Simulator
```

### 4.4 Verificar Setup iOS
```bash
flutter doctor -v
```

## 🗺️ Passo 5: Configurar Google Maps API

### 5.1 Criar Projeto no Google Cloud

1. Acesse: https://console.cloud.google.com/
2. Clique em "Select a project" → "New Project"
3. Nome: "Avisa La" → Create

### 5.2 Ativar APIs Necessárias

```
Na Cloud Console:
1. APIs & Services → Library
2. Ative cada uma das seguintes APIs:
   ✅ Maps SDK for Android
   ✅ Maps SDK for iOS
   ✅ Places API
   ✅ Geocoding API
   ✅ Geolocation API
```

### 5.3 Criar Credenciais (API Key)

```
1. APIs & Services → Credentials
2. Create Credentials → API Key
3. Copie a chave gerada
4. (Opcional) Clique em "Restrict Key":
   - Android apps: Adicione package name + SHA-1
   - iOS apps: Adicione bundle identifier
```

### 5.4 Adicionar API Key ao Projeto

#### **Arquivo 1: `lib/core/utils/constants.dart`**
```dart
// Linha 42
static const String googleMapsApiKey = 'AIzaSy...SUA_CHAVE_AQUI';
```

#### **Arquivo 2: `android/app/src/main/AndroidManifest.xml`**
```xml
<!-- Linha 46 -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSy...SUA_CHAVE_AQUI" />
```

#### **Arquivo 3: `ios/Runner/Info.plist`**
```xml
<!-- Última linha antes de </dict> -->
<key>GMSApiKey</key>
<string>AIzaSy...SUA_CHAVE_AQUI</string>
```

## 📦 Passo 6: Instalar Dependências

```bash
cd avisa_la

# Instalar dependências Flutter
flutter pub get

# (iOS apenas) Instalar pods
cd ios
pod install
cd ..
```

## 🏗️ Passo 7: Build do Projeto

### Android
```bash
# Verificar se dispositivo/emulador está conectado
flutter devices

# Build e executar
flutter run -d android
```

### iOS (macOS apenas)
```bash
# Verificar se simulador está rodando
flutter devices

# Build e executar
flutter run -d ios
```

## 🐛 Resolução de Problemas Comuns

### Problema 1: `flutter: command not found`
**Solução:**
```bash
# Adicione Flutter ao PATH
export PATH="$PATH:[CAMINHO_PARA_FLUTTER]/flutter/bin"

# Permanente (adicione ao ~/.bashrc ou ~/.zshrc)
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
```

### Problema 2: Gradle build failed (Android)
**Solução:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Problema 3: CocoaPods error (iOS)
**Solução:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod repo update
pod install
cd ..
```

### Problema 4: Google Maps not showing
**Verifique:**
1. ✅ API Key está correta
2. ✅ APIs estão habilitadas no Cloud Console
3. ✅ (Android) SHA-1 fingerprint está registrado
4. ✅ Billing está ativado no Google Cloud (requer cartão de crédito)

### Problema 5: Background service not working
**Android:**
- Desabilite otimização de bateria para o app
- Adicione à lista de "Protected apps" (Xiaomi/Huawei)

**iOS:**
- Certifique-se que todas as permissões foram concedidas
- Background modes devem estar corretos no Info.plist

## 🧪 Passo 8: Testar o App

### Teste Básico de Funcionalidade

1. **Abrir App**
   - ✅ Splash screen aparece
   - ✅ Permissões são solicitadas
   - ✅ Mapa carrega com localização atual

2. **Buscar Destino**
   - ✅ Barra de busca funciona
   - ✅ Autocomplete retorna sugestões
   - ✅ Marcador aparece no mapa

3. **Iniciar Viagem**
   - ✅ Permissão de background location é solicitada
   - ✅ Notificação persistente aparece
   - ✅ Mapa mostra posição em tempo real

4. **Simular Movimento** (Para teste em emulador)

**Android Studio:**
```
Emulator → ... → Location → Load GPX/KML
Ou use manualmente: Extended controls → Location
```

**Xcode Simulator:**
```
Features → Location → Custom Location
Ou Features → Location → City Run/Freeway Drive
```

### Teste de Background

1. Inicie uma viagem
2. Bloqueie a tela ou abra outro app
3. Notificação persistente deve continuar
4. Aproxime-se do destino (simulado)
5. Notificação de alerta deve aparecer

## 📊 Passo 9: Monitorar Logs

### Android
```bash
# Logcat
adb logcat | grep flutter

# Ou via Android Studio
View → Tool Windows → Logcat
```

### iOS
```bash
# Console via Xcode
Window → Devices and Simulators → Open Console
```

## 🚀 Passo 10: Build de Produção

### Android APK
```bash
flutter build apk --release
# APK em: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (para Play Store)
```bash
flutter build appbundle --release
# AAB em: build/app/outputs/bundle/release/app-release.aab
```

### iOS (requer conta Apple Developer)
```bash
flutter build ios --release
# Abra no Xcode para archive e upload
```

## 📝 Checklist Final

Antes de considerar o setup completo:

- [ ] Flutter Doctor não mostra erros críticos
- [ ] Google Maps API Key configurada em todos os 3 locais
- [ ] App abre sem crashes
- [ ] Mapa carrega corretamente
- [ ] Busca de destino funciona
- [ ] GPS tracking funciona
- [ ] Notificações aparecem
- [ ] Background service permanece ativo
- [ ] Permissões são solicitadas corretamente

## 🆘 Suporte Adicional

**Documentação Oficial:**
- Flutter: https://flutter.dev/docs
- Google Maps Flutter: https://pub.dev/packages/google_maps_flutter
- Geolocator: https://pub.dev/packages/geolocator
- Background Service: https://pub.dev/packages/flutter_background_service

**Comunidades:**
- Flutter Discord: https://discord.gg/flutter
- Stack Overflow: Tag `flutter`

---

**Boa sorte com o desenvolvimento! 🚀**

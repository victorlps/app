# Avisa Lá - Alarme de Destino Inteligente

**Avisa Lá** é um aplicativo mobile nativo (Flutter) que funciona como um alarme de destino inteligente para usuários de transporte público. O app monitora sua localização em tempo real e te alerta quando você está chegando ao seu destino, permitindo que você relaxe durante a viagem.

## 🎯 Funcionalidades Principais

- **Busca de Destino**: Integração com Google Maps/Places API para busca inteligente de destinos
- **Monitoramento em Tempo Real**: Tracking GPS contínuo da sua localização
- **Alarme de Proximidade**: Notificação automática quando você está chegando ao destino
- **Serviço em Segundo Plano**: Funciona mesmo com o app fechado ou tela bloqueada
- **Modo Dinâmico**: Ajusta automaticamente a distância de alerta baseado na velocidade
- **Notificações Inteligentes**: Sistema robusto de notificações persistentes e alertas

## 📋 Pré-requisitos

- Flutter SDK 3.0.0 ou superior
- Android Studio / Xcode configurado
- Conta Google Cloud Platform com APIs habilitadas:
  - Google Maps SDK for Android
  - Google Maps SDK for iOS
  - Google Places API

## 🚀 Setup do Projeto

### 1. Clone e Configure o Projeto

```bash
# Navegue até o diretório do projeto
cd /app/avisa_la

# Instale as dependências
flutter pub get
```

### 2. Configure a Google Maps API Key

#### 2.1 Obter API Key

1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Crie um novo projeto ou selecione um existente
3. Ative as seguintes APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geocoding API
4. Vá em "Credenciais" → "Criar Credenciais" → "Chave de API"
5. Copie a API Key gerada

#### 2.2 Adicionar API Key no Projeto

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="SUA_API_KEY_AQUI" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>GMSApiKey</key>
<string>SUA_API_KEY_AQUI</string>
```

**Dart** (`lib/core/utils/constants.dart`):
```dart
static const String googleMapsApiKey = 'SUA_API_KEY_AQUI';
```

### 3. Configuração Android

#### 3.1 Permissões
As permissões já estão configuradas no `AndroidManifest.xml`, mas verifique:
- `ACCESS_FINE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`
- `FOREGROUND_SERVICE_LOCATION`
- `POST_NOTIFICATIONS`

#### 3.2 Build Gradle
Certifique-se que o `minSdkVersion` está configurado para 23 ou superior:

Edite `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdkVersion 23
        targetSdkVersion 33
    }
}
```

### 4. Configuração iOS

#### 4.1 Permissões
As permissões já estão no `Info.plist`, mas verifique as descrições.

#### 4.2 Podfile
Certifique-se que o `ios/Podfile` tem a plataforma mínima iOS 12:
```ruby
platform :ios, '12.0'
```

### 5. Execute o Projeto

#### Android
```bash
flutter run -d android
```

#### iOS
```bash
flutter run -d ios
```

## 📁 Estrutura do Projeto

```
lib/
├── core/
│   ├── models/
│   │   ├── destination.dart          # Modelo de destino
│   │   └── trip_status.dart          # Status da viagem
│   ├── services/
│   │   ├── geolocation_service.dart  # Serviço de GPS
│   │   ├── notification_service.dart # Gerenciamento de notificações
│   │   ├── background_service.dart   # Serviço em segundo plano
│   │   └── permission_service.dart   # Gerenciamento de permissões
│   └── utils/
│       ├── distance_calculator.dart  # Cálculos de distância (Haversine)
│       └── constants.dart            # Constantes do app
├── features/
│   ├── home/
│   │   └── home_page.dart           # Tela principal
│   ├── search/
│   │   └── destination_search_page.dart  # Busca de destino
│   └── trip_monitoring/
│       └── trip_monitoring_page.dart     # Monitoramento da viagem
└── main.dart                        # Entry point
```

## 🔧 Configurações Importantes

### Distância de Alerta
Ajustável pelo usuário entre 200m e 1km (padrão: 500m)

### Modo Dinâmico
Quando ativado, calcula a distância de alerta automaticamente baseado na velocidade, alertando aproximadamente 2 minutos antes do destino.

### Intervalo de Atualização GPS
- Padrão: A cada 5-10 segundos
- Filtro de distância: 10 metros (para economizar bateria)

### Health Check
O serviço realiza um health check a cada 30 segundos para garantir que o monitoramento não foi interrompido pelo sistema.

## 📱 Fluxo de Uso

1. **Splash Screen**: Solicita permissões básicas (localização "While in Use" + notificações)
2. **Tela Principal**: Mostra mapa com localização atual
3. **Buscar Destino**: Usuário busca e seleciona destino
4. **Configurar Viagem**: Ajusta distância de alerta e modo dinâmico
5. **Iniciar Viagem**: Solicita permissão de localização "Always" (se necessário)
6. **Monitoramento**: Background service ativo, notificação persistente exibida
7. **Alerta de Chegada**: Quando próximo ao destino, dispara notificação de alta prioridade
8. **Confirmação**: Usuário confirma chegada e serviço é encerrado

## ⚠️ Problemas Conhecidos e Soluções

### Android - Otimização de Bateria
Alguns fabricantes (Samsung, Xiaomi, Huawei) têm otimizações agressivas que podem interromper o serviço. Oriente usuários a:
1. Desabilitar otimização de bateria para o Avisa Lá
2. Adicionar o app à lista de "apps protegidos" ou "auto-start"

### iOS - Background Location
Para aprovação na App Store, certifique-se de:
1. Justificar claramente o uso de localização em segundo plano no Info.plist
2. Incluir screenshots e descrição detalhada durante a submissão
3. Demonstrar que o app realmente precisa dessa funcionalidade

### GPS em Túneis/Áreas Internas
O app mostra um indicador de qualidade do GPS. Em áreas sem sinal, o usuário é informado visualmente.

## 🧪 Testes Recomendados

### Cenários Críticos
- [ ] Viagem de ônibus urbano (10-30 min, múltiplas paradas)
- [ ] Viagem de trem/metrô (velocidade média-alta)
- [ ] GPS perde sinal em túnel → reconecta após saída
- [ ] Usuário bloqueia tela → serviço continua
- [ ] Sistema encerra app por memória → serviço resiste
- [ ] Bateria em modo economia → notificar usuário
- [ ] Usuário nega permissão "Always" → modo degradado com aviso

### Métricas de Sucesso
- Taxa de sucesso de notificação: > 95%
- Precisão de localização: < 50m de erro médio
- Tempo de vida do serviço: completar 95%+ das viagens

## 🔐 Privacidade e Segurança

- ✅ **Não armazena** histórico de localizações
- ✅ **Não envia** dados para servidores externos
- ✅ **Processamento local**: Todos os cálculos ocorrem no dispositivo
- ✅ **Permissões Just-in-Time**: Solicitadas apenas quando necessárias

## 📊 Otimizações de Bateria

O app implementa estratégias adaptativas:
- Quando em movimento: Alta precisão, atualizações frequentes
- Quando parado: Precisão média, economiza bateria
- Consumo estimado: < 5% por hora em monitoramento ativo

## 🛠️ Desenvolvimento Futuro (Roadmap)

### Fase 1 - MVP ✅
- Estrutura base
- Integração Google Maps/Places
- Monitoramento básico

### Fase 2 - Core (Em Progresso)
- Background service completo
- Sistema de notificações robusto
- Gerenciamento de permissões

### Fase 3 - Reliability
- Health check do serviço
- Confirmação de chegada obrigatória
- Modo dinâmico (baseado em tempo)
- Tratamento de falhas de GPS

### Fase 4 - Polish
- Onboarding educativo
- Animações e transições
- Testes em dispositivos reais
- Preparação para lançamento

## 📄 Licença

Este projeto é parte de uma especificação técnica para desenvolvimento do aplicativo "Avisa Lá".

## 📞 Suporte

Para dúvidas ou problemas, consulte a documentação técnica completa ou entre em contato com a equipe de desenvolvimento.

---

**Desenvolvido com ❤️ usando Flutter**

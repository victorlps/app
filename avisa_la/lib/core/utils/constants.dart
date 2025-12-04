class AppConstants {
  // Distâncias de alerta (em metros)
  static const double alertDistance200m = 200.0;
  static const double alertDistance500m = 500.0;
  static const double alertDistance1km = 1000.0;
  static const double defaultAlertDistance = alertDistance500m;

  // Intervalos de tempo
  static const int gpsUpdateIntervalSeconds = 5;
  static const int healthCheckIntervalSeconds = 30;
  static const int autoStopAfterArrivalMinutes = 5;

  // Modo dinâmico
  static const int dynamicModeWarningTimeSeconds = 120; // 2 minutos

  // Configurações de GPS
  static const int gpsAccuracyMeters = 50;
  static const int gpsDistanceFilterMeters = 10;

  // IDs de notificação
  static const int monitoringNotificationId = 1;
  static const int arrivalNotificationId = 2;
  static const int failureNotificationId = 3;

  // Channels de notificação (Android)
  static const String monitoringChannelId = 'monitoring_channel';
  static const String monitoringChannelName = 'Trip Monitoring';
  static const String arrivalChannelId = 'arrival_alert_channel';
  static const String arrivalChannelName = 'Arrival Alert';
  static const String failureChannelId = 'failure_alert_channel';
  static const String failureChannelName = 'Service Failure';

  // Chaves de armazenamento
  static const String keyLastDestination = 'last_destination';
  static const String keyAlertDistance = 'alert_distance';
  static const String keyUseDynamicMode = 'use_dynamic_mode';

  // Google Maps & Places API Key
  // Package: com.example.avisa_la
  // SHA-1: 92:3C:59:2B:B5:B6:F7:67:B0:22:5C:B3:B7:52:05:CA:5A:43:D0:A3
  static const String googleMapsApiKey = 'AIzaSyA6zgQ0rrgn4B67hkOh3F1Jorj9aITGjwg';
  static const String googlePlacesApiKey = googleMapsApiKey;
  // Backend proxy base URL. For a physical device on the same LAN.
  static const String backendBaseUrl = 'http://192.168.0.47:8000';  // Textos de notificação
  static const String monitoringNotificationTitle = 'Avisa Lá está ativo';
  static String monitoringNotificationBody(String destinationName) =>
       'Monitorando para $destinationName';

  static const String arrivalNotificationTitle = '🔔 Avisa Lá: Você está chegando!';
  static String arrivalNotificationBody(double distanceMeters) =>
      'Seu destino está a ${distanceMeters.round()}m. Prepare-se para descer.';

  static const String failureNotificationTitle =
      '⚠️ Atenção: O monitoramento foi interrompido';
  static const String failureNotificationBody =
      'Toque para reiniciar o monitoramento.';

  // Permissões educativas
  static const String locationPermissionRationale =
      'O Avisa Lá precisa acessar sua localização para monitorar sua viagem e alertá-lo quando estiver chegando ao destino.';

  static const String backgroundLocationRationale =
      'Para funcionar mesmo com o app em segundo plano ou tela bloqueada, o Avisa Lá precisa de permissão de localização "Sempre Permitir". Isso garante que você será alertado mesmo se estiver usando outros apps ou ouvindo música.';

  static const String notificationPermissionRationale =
      'O Avisa Lá usa notificações para alertá-lo quando estiver chegando ao seu destino.';

  static const String batteryOptimizationRationale =
      'Para garantir que o monitoramento não seja interrompido pelo sistema, recomendamos desabilitar a otimização de bateria para o Avisa Lá.';
}

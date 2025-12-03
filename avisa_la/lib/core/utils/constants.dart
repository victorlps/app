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

  // Google Maps (substitua pela sua API Key)
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  // Textos de notificação
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

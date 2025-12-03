import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:avisa_la/core/utils/constants.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Inicializa o serviço de notificações
  static Future<void> initialize() async {
    if (_initialized) return;

    // Configurações Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configurações iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Criar channels de notificação no Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    _initialized = true;
  }

  /// Cria os channels de notificação (Android)
  static Future<void> _createNotificationChannels() async {
    // Channel de monitoramento (baixa prioridade, persistente)
    const AndroidNotificationChannel monitoringChannel =
        AndroidNotificationChannel(
      AppConstants.monitoringChannelId,
      AppConstants.monitoringChannelName,
      description: 'Notificação persistente durante monitoramento da viagem',
      importance: Importance.low,
      showBadge: false,
      playSound: false,
      enableVibration: false,
    );

    // Channel de alerta de chegada (alta prioridade)
    const AndroidNotificationChannel arrivalChannel =
        AndroidNotificationChannel(
      AppConstants.arrivalChannelId,
      AppConstants.arrivalChannelName,
      description: 'Alerta quando estiver chegando ao destino',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );

    // Channel de falha (alta prioridade)
    const AndroidNotificationChannel failureChannel =
        AndroidNotificationChannel(
      AppConstants.failureChannelId,
      AppConstants.failureChannelName,
      description: 'Alerta quando o serviço é interrompido',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(monitoringChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(arrivalChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(failureChannel);
  }

  /// Callback quando notificação é tocada
  static void _onNotificationTapped(NotificationResponse response) {
    // Implementar navegação ou ações conforme necessário
    print('Notificação tocada: ${response.payload}');
  }

  /// Mostra notificação persistente de monitoramento
  static Future<void> showMonitoringNotification({
    required String destinationName,
    double? distance,
  }) async {
    String body = AppConstants.monitoringNotificationBody(destinationName);
    if (distance != null) {
      body += '\nDistância: ${distance.round()}m';
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      AppConstants.monitoringChannelId,
      AppConstants.monitoringChannelName,
      channelDescription: 'Monitoramento ativo',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      AppConstants.monitoringNotificationId,
      AppConstants.monitoringNotificationTitle,
      body,
      details,
    );
  }

  /// Mostra notificação de alerta de chegada
  static Future<void> showArrivalNotification({
    required double distance,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      AppConstants.arrivalChannelId,
      AppConstants.arrivalChannelName,
      channelDescription: 'Alerta de chegada',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      actions: [
        AndroidNotificationAction(
          'confirm_arrival',
          'Cheguei ao Destino',
          showsUserInterface: true,
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      AppConstants.arrivalNotificationId,
      AppConstants.arrivalNotificationTitle,
      AppConstants.arrivalNotificationBody(distance),
      details,
    );
  }

  /// Mostra notificação de falha do serviço
  static Future<void> showFailureNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      AppConstants.failureChannelId,
      AppConstants.failureChannelName,
      channelDescription: 'Falha do serviço',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      AppConstants.failureNotificationId,
      AppConstants.failureNotificationTitle,
      AppConstants.failureNotificationBody,
      details,
    );
  }

  /// Cancela notificação de monitoramento
  static Future<void> cancelMonitoringNotification() async {
    await _notifications.cancel(AppConstants.monitoringNotificationId);
  }

  /// Cancela notificação de chegada
  static Future<void> cancelArrivalNotification() async {
    await _notifications.cancel(AppConstants.arrivalNotificationId);
  }

  /// Cancela todas as notificações
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}

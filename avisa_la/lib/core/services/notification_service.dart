import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';
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
    print('✅ NotificationService inicializado');
  }

  /// Cria os channels de notificação (Android)
  static Future<void> _createNotificationChannels() async {
    try {
      // Channel de monitoramento (baixa prioridade, persistente)
      final AndroidNotificationChannel monitoringChannel =
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
      final AndroidNotificationChannel arrivalChannel =
          AndroidNotificationChannel(
        AppConstants.arrivalChannelId,
        AppConstants.arrivalChannelName,
        description: 'Alerta quando estiver chegando ao destino',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        // ✅ COMPATÍVEL COM ANDROID 12+ (sem 0 inicial)
        vibrationPattern: Int64List.fromList([100, 1000, 500, 1000]),
      );

      // Channel de falha (alta prioridade)
      final AndroidNotificationChannel failureChannel =
          AndroidNotificationChannel(
        AppConstants.failureChannelId,
        AppConstants.failureChannelName,
        description: 'Alerta quando o serviço é interrompido',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        // ✅ COMPATÍVEL COM ANDROID 12+
        vibrationPattern: Int64List.fromList([100, 1000, 500, 1000]),
      );

      final plugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (plugin != null) {
        await plugin.createNotificationChannel(monitoringChannel);
        await plugin.createNotificationChannel(arrivalChannel);
        await plugin.createNotificationChannel(failureChannel);
        print('✅ Notification channels criados');
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao criar notification channels: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  /// Callback quando notificação é tocada
  static void _onNotificationTapped(NotificationResponse response) {
    try {
      print('📱 Notificação tocada: ${response.payload}');
      print('  Action: ${response.actionId}');

      // Implementar navegação conforme necessário
      if (response.actionId == 'confirm_arrival') {
        print('✅ Usuário confirmou chegada');
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao processar notificação: $e');
      print('Stack: $stackTrace');
    }
  }

  /// Mostra notificação persistente de monitoramento
  static Future<void> showMonitoringNotification({
    required String destinationName,
    double? distance,
  }) async {
    try {
      String body = AppConstants.monitoringNotificationBody(destinationName);
      if (distance != null) {
        body += '\n📍 ${distance.round()}m';
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
    } catch (e, stackTrace) {
      print('❌ Erro ao mostrar notificação de monitoramento: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  /// Mostra notificação de alerta de chegada (FULL-SCREEN)
  static Future<void> showArrivalNotification({
    required double distance,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        AppConstants.arrivalChannelId,
        AppConstants.arrivalChannelName,
        channelDescription: 'Alerta de chegada',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        // ✅ COMPATÍVEL COM ANDROID 12+
        vibrationPattern: Int64List.fromList([100, 1000, 500, 1000]),
        // ✅ CRITICAL: Mostrar acima de outras apps
        fullScreenIntent: true,
        // ✅ Auto-dismiss após 60 segundos
        timeoutAfter: 60000,
        // ✅ Adicionar ações
        actions: const [
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

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      print('🔔 Alarme disparado - Distância: ${distance.toStringAsFixed(1)}m');
      await _notifications.show(
        AppConstants.arrivalNotificationId,
        AppConstants.arrivalNotificationTitle,
        AppConstants.arrivalNotificationBody(distance),
        details,
      );
    } catch (e, stackTrace) {
      print('❌ Erro ao mostrar alarme: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  /// Mostra notificação de falha do serviço
  static Future<void> showFailureNotification() async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        AppConstants.failureChannelId,
        AppConstants.failureChannelName,
        channelDescription: 'Falha do serviço',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
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

      print('❌ Notificação de falha disparada');
      await _notifications.show(
        AppConstants.failureNotificationId,
        AppConstants.failureNotificationTitle,
        AppConstants.failureNotificationBody,
        details,
      );
    } catch (e, stackTrace) {
      print('❌ Erro ao mostrar notificação de falha: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  /// Cancela notificação de monitoramento
  static Future<void> cancelMonitoringNotification() async {
    try {
      await _notifications.cancel(AppConstants.monitoringNotificationId);
    } catch (e) {
      print('⚠️ Erro ao cancelar monitoramento: $e');
    }
  }

  /// Cancela notificação de chegada
  static Future<void> cancelArrivalNotification() async {
    try {
      await _notifications.cancel(AppConstants.arrivalNotificationId);
    } catch (e) {
      print('⚠️ Erro ao cancelar alarme: $e');
    }
  }

  /// Cancela todas as notificações
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('🗑️ Todas as notificações canceladas');
    } catch (e) {
      print('⚠️ Erro ao cancelar todas as notificações: $e');
    }
  }
}

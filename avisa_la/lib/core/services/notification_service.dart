import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:typed_data';
import 'package:avisa_la/core/utils/constants.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'dart:async';

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

      // Handle alarme full-screen
      if (response.payload?.startsWith('alarm_fullscreen') ?? false) {
        print('🔔 Notificação de alarme tocada - preparando para abrir tela');
        
        // Parse payload: "alarm_fullscreen|destinationName|distance"
        final parts = response.payload?.split('|');
        if (parts != null && parts.length >= 3) {
          final destination = parts[1];
          final distance = double.tryParse(parts[2]) ?? 0.0;
          
          // ✅ IMPORTANTE: Invocar showAlarm para abrir a tela
          // Este evento será escutado por main.dart
          FlutterBackgroundService().invoke('showAlarm', {
            'destination': destination,
            'distance': distance,
          });
          
          print('✅ Evento showAlarm invocado para: $destination');
        }
      }

      // Implementar navegação conforme necessário
      if (response.actionId == 'confirm_arrival') {
        print('✅ Usuário confirmou chegada');
      } else if (response.actionId == 'dismiss_alarm') {
        print('⛔ Usuário desativou alarme');
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

  /// Verifica o status atual das permissões de notificação
  static Future<PermissionStatus> _checkNotificationPermission() async {
    if (!Platform.isAndroid) return PermissionStatus.granted;
    return await Permission.notification.status;
  }

  /// Verifica o status atual da permissão full-screen intent
  static Future<PermissionStatus> _checkFullScreenIntentPermission() async {
    if (!Platform.isAndroid) return PermissionStatus.granted;
    
    try {
      // No Android, USO_FULL_SCREEN_INTENT é verificada via Settings
      // Se já foi concedida uma vez, PermissionHandler não força novamente
      final permission = Permission.scheduleExactAlarm; // Similar ao full-screen
      return await permission.status;
    } catch (e) {
      print('⚠️ Erro ao verificar full-screen intent permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Solicita TODAS as permissões necessárias para o alarme (Google Best Practices)
  /// Ordem correta: POST_NOTIFICATIONS → SCHEDULE_EXACT_ALARM
  /// (USE_FULL_SCREEN_INTENT é solicitada automaticamente pelo flutter_local_notifications)
  static Future<bool> requestAlarmPermissionsWithEducation(
      BuildContext context) async {
    if (!Platform.isAndroid) return true;

    print('🔔 Iniciando fluxo de permissões para alarme...');

    // PASSO 1: Mostrar diálogo educativo ANTES de qualquer permissão
    final shouldProceed = await _showAlarmEducationDialog(context);
    if (!shouldProceed) {
      print('ℹ️ Usuário recusou iniciar fluxo de permissões');
      return false;
    }

    // PASSO 2: Solicitar POST_NOTIFICATIONS (Android 13+) - Básico para notificações
    print('📲 Solicitando permissão de notificações...');
    final notificationStatus = await _requestAndShowPermissionDialog(
      context,
      Permission.notification,
      title: 'Permissão de Notificações',
      explanation:
          'O Avisa Lá precisa enviar notificações para alertá-lo sobre sua parada.',
    );

    if (!notificationStatus.isGranted) {
      print('⚠️ Permissão de notificações negada');
      return false;
    }
    print('✅ Permissão de notificações concedida');

    // PASSO 3: Solicitar SCHEDULE_EXACT_ALARM (Android 12+) - Para alarmes precisos
    print('⏰ Solicitando permissão de alarmes precisos...');
    final scheduleStatus = await _requestAndShowPermissionDialog(
      context,
      Permission.scheduleExactAlarm,
      title: 'Permissão de Alarmes',
      explanation:
          'Para notificar você no tempo exato, o app precisa agendar alarmes com precisão.',
    );

    if (!scheduleStatus.isGranted) {
      print('⚠️ Permissão de alarmes precisos negada');
      return false;
    }
    print('✅ Permissão de alarmes precisos concedida');

    print('✅✅✅ TODAS as permissões de alarme foram concedidas!');
    print('💡 A permissão de Full-Screen Intent (USE_FULL_SCREEN_INTENT) será');
    print('   solicitada automaticamente pelo sistema ao primeiro uso.');
    return true;
  }

  /// Mostra diálogo educativo inicial explicando o que será pedido
  static Future<bool> _showAlarmEducationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              icon: const Icon(Icons.notifications_active,
                  color: Colors.orange, size: 32),
              title: const Text('Permissões para Alarme'),
              content: const Text(
                'Para que o alarme funcione perfeitamente, o Avisa Lá precisa de '
                'algumas permissões:\n\n'
                '🔔 Enviar notificações\n'
                '⏰ Agendar alarmes\n'
                '🔓 Exibir acima da tela bloqueada\n\n'
                'Isso garante que você receberá a notificação mesmo com o '
                'celular bloqueado.',
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Agora não'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Continuar'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Solicita uma permissão específica com diálogo educativo
  static Future<PermissionStatus> _requestAndShowPermissionDialog(
    BuildContext context,
    Permission permission, {
    required String title,
    required String explanation,
  }) async {
    // Verificar status atual
    final currentStatus = await permission.status;

    // Se já concedida, retornar imediatamente
    if (currentStatus.isGranted) {
      print('✅ $title já concedida');
      return currentStatus;
    }

    // Se foi negada permanentemente, guiar para configurações
    if (currentStatus.isDenied) {
      // Mostrar diálogo explicativo ANTES de solicitar
      final shouldRequest = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                icon: const Icon(Icons.warning_amber, color: Colors.orange),
                title: Text(title),
                content: Text(explanation),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Agora não'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Permitir'),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (!shouldRequest) {
        print('ℹ️ Usuário recusou $title');
        return PermissionStatus.denied;
      }

      // AGORA solicitar a permissão do sistema
      final result = await permission.request();
      print('📱 Resultado da solicitação de $title: $result');
      return result;
    }

    // Se foi negada permanentemente
    if (currentStatus.isPermanentlyDenied) {
      print('❌ $title foi negada permanentemente');
      if (context.mounted) {
        await _showPermanentlyDeniedDialog(context, title);
      }
      return currentStatus;
    }

    return currentStatus;
  }

  /// Diálogo para quando uma permissão é negada permanentemente
  static Future<void> _showPermanentlyDeniedDialog(
    BuildContext context,
    String permissionName,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.settings, color: Colors.orange),
          title: Text('$permissionName Negada Permanentemente'),
          content: const Text(
            'Você negou essa permissão permanentemente. '
            'Para ativar, você precisa:\n\n'
            '1. Abrir Configurações\n'
            '2. Procurar por "Avisa Lá"\n'
            '3. Ativar a permissão na seção correspondente',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendi'),
            ),
            ElevatedButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Abrir Configurações'),
            ),
          ],
        );
      },
    );
  }

  /// Diálogo exibido quando full-screen intent foi negada (mas as outras permissões foram ok)
  static Future<void> _showPermissionPartiallyDeniedDialog(
    BuildContext context,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.info, color: Colors.orange),
          title: const Text('Alarme Parcialmente Funcional'),
          content: const Text(
            'O alarme ainda funcionará, mas você verá a notificação como um card '
            'em vez de uma tela cheia.\n\n'
            'Para a experiência completa, você pode ativar essa permissão nas configurações.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  /// Mostra notificação de alarme full-screen
  static Future<void> showFullScreenAlarmNotification({
    required String destinationName,
    required double distance,
  }) async {
    try {
      // Channel específico para alarmes full-screen
      final AndroidNotificationChannel alarmChannel =
          AndroidNotificationChannel(
        'alarm_fullscreen_channel',
        'Alarmes Full-Screen',
        description: 'Alarmes críticos que acordam o device',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 500, 500]),
      );

      final plugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (plugin != null) {
        await plugin.createNotificationChannel(alarmChannel);
      }

      // Criar payload com dados do alarme
      final payload = 'alarm_fullscreen|$destinationName|$distance';

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'alarm_fullscreen_channel',
        'Alarmes Full-Screen',
        channelDescription: 'Alarmes críticos que acordam o device',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        autoCancel: false,
        ongoing: true,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 500, 500]),
        visibility: NotificationVisibility.public,
        // ✅ CRÍTICO: Adicionar ação que pode ser interceptada
        actions: const [
          AndroidNotificationAction(
            'dismiss_alarm',
            'Desativar',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'confirm_arrival',
            'Chegou',
            showsUserInterface: true,
          ),
        ],
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _notifications.show(
        999,
        '🔔 Você está chegando!',
        '$destinationName - ${distance.round()}m',
        details,
        payload: payload,
      );

      print('✅ Notificação full-screen mostrada com payload: $payload');
    } catch (e, stackTrace) {
      print('❌ Erro ao mostrar notificação full-screen: $e');
      print('Stack: $stackTrace');
    }
  }
}

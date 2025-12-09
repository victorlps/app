import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:avisa_la/core/services/alarm_service.dart';
import 'package:avisa_la/core/utils/constants.dart';
import 'package:avisa_la/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Dados de lançamento via notificação (app cold start)
class AlarmLaunchData {
  final String destination;
  final double distance;
  AlarmLaunchData({required this.destination, required this.distance});
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();
  static const MethodChannel _alarmChannel = MethodChannel('com.example.avisa_la/alarm');

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
    Log.alarm('✅ NotificationService inicializado');
  }

  /// Retorna dados de lançamento se o app foi aberto a partir de uma notificação de alarme
  /// ✅ FUNCIONA quando app é cold-started pela notificação full-screen
  static Future<AlarmLaunchData?> getLaunchAlarmData() async {
    try {
      final details =
          await _notifications.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) {
        Log.alarm('ℹ️ App não foi aberto por notificação');
        return null;
      }

      final payload = details.notificationResponse?.payload;
      if (payload == null) {
        Log.alarm('ℹ️ Notificação sem payload');
        return null;
      }

      if (!payload.startsWith('alarm_fullscreen')) {
        Log.alarm('ℹ️ Notificação não é de alarme full-screen');
        return null;
      }

      final parts = payload.split('|');
      if (parts.length < 3) {
        Log.alarm('⚠️ Payload inválido: $payload');
        return null;
      }

      final destination = parts[1];
      final distance = double.tryParse(parts[2]) ?? 0.0;
      
      Log.alarm('✅ Dados de alarme recuperados na cold start: $destination ($distance m)');
      return AlarmLaunchData(destination: destination, distance: distance);
    } catch (e, stackTrace) {
      Log.alarm('❌ Erro ao getLaunchAlarmData: $e', e, stackTrace);
      return null;
    }
  }

  /// 🧪 DEBUG: Teste a notificação de alarme manualmente
  /// Útil para verificar se o sistema de notificações está funcionando
  static Future<void> testAlarmNotification() async {
    Log.alarm('🧪 [TEST] Iniciando teste de notificação de alarme...');
    try {
      await showFullScreenAlarmNotification(
        destinationName: 'TESTE - Estação Central',
        distance: 250.5,
      );
      Log.alarm('✅ [TEST] Notificação de teste enviada com sucesso!');
    } catch (e) {
      Log.alarm('❌ [TEST] Erro ao enviar notificação de teste: $e', e);
    }
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

      // ⏰ Channel de alarme full-screen (CRÍTICO - máxima prioridade)
      final AndroidNotificationChannel alarmChannel =
          AndroidNotificationChannel(
        'alarm_fullscreen_channel',
        '⏰ Alarmes de Proximidade',
        description: 'Alarmes críticos que acordam o device quando você se aproxima do destino',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        enableLights: true,
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        showBadge: true,
      );

      final plugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (plugin != null) {
        await plugin.createNotificationChannel(monitoringChannel);
        await plugin.createNotificationChannel(arrivalChannel);
        await plugin.createNotificationChannel(failureChannel);
        await plugin.createNotificationChannel(alarmChannel);
        Log.alarm('✅ Notification channels criados (incluindo alarm_fullscreen_channel)');
      }
    } catch (e, stackTrace) {
      Log.alarm('❌ Erro ao criar notification channels: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Callback quando notificação é tocada
  static void _onNotificationTapped(NotificationResponse response) async {
    try {
      Log.alarm('📱 Notificação tocada: ${response.payload}');
      if (response.payload?.startsWith('alarm_fullscreen') ?? false) {
        Log.alarm('🔔 Notificação de alarme tocada - app já deve estar aberto');

        // Parse payload: "alarm_fullscreen|destinationName|distance"
        final parts = response.payload?.split('|');
        if (parts != null && parts.length >= 3) {
          final destination = parts[1];
          final distance = double.tryParse(parts[2]) ?? 0.0;

          Log.alarm('🎯 Destino: $destination, Distância: $distance m');

          // ✅ IMPORTANTE: Invocar showAlarm para abrir a tela
          // Este evento será escutado por main.dart
          FlutterBackgroundService().invoke('showAlarm', {
            'destination': destination,
            'distance': distance,
          });

          Log.alarm('✅ Evento showAlarm invocado para: $destination');
        }
      }

      // ✅ Implementar ações dos botões da notificação
      if (response.actionId == 'confirm_arrival') {
        Log.alarm('✅ Usuário confirmou chegada via notificação');
        
        // Parar alarme sonoro se estiver tocando
        try {
          await AlarmService.stopAlarm();
          Log.alarm('🔕 Som do alarme parado');
        } catch (e) {
          Log.alarm('⚠️ Erro ao parar alarme: $e', e);
        }
        
        // Cancelar notificação
        await cancelArrivalNotification();
        
        // Parar serviço de background
        FlutterBackgroundService().invoke('stopTrip');
        Log.alarm('⏹️ Viagem finalizada via botão "Cheguei"');
        
      } else if (response.actionId == 'dismiss_alarm') {
        Log.alarm('⛔ Usuário desativou alarme via notificação');
        
        // Parar alarme sonoro se estiver tocando
        try {
          await AlarmService.stopAlarm();
          Log.alarm('🔕 Som do alarme parado');
        } catch (e) {
          Log.alarm('⚠️ Erro ao parar alarme: $e', e);
        }
        
        // Cancelar notificação de alarme
        await cancelArrivalNotification();
        
        // Continuar monitoramento (não parar viagem, apenas silenciar alarme)
        Log.alarm('🔇 Alarme silenciado, monitoramento continua');
      }
    } catch (e, stackTrace) {
      Log.alarm('❌ Erro ao processar notificação: $e', e, stackTrace);
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
      Log.alarm('❌ Erro ao mostrar notificação de monitoramento: $e', e,
          stackTrace);
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

      Log.alarm(
          '🔔 Alarme disparado - Distância: ${distance.toStringAsFixed(1)}m');
      await _notifications.show(
        AppConstants.arrivalNotificationId,
        AppConstants.arrivalNotificationTitle,
        AppConstants.arrivalNotificationBody(distance),
        details,
      );
    } catch (e, stackTrace) {
      Log.alarm('❌ Erro ao mostrar alarme: $e', e, stackTrace);
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

      Log.alarm('❌ Notificação de falha disparada');
      await _notifications.show(
        AppConstants.failureNotificationId,
        AppConstants.failureNotificationTitle,
        AppConstants.failureNotificationBody,
        details,
      );
    } catch (e, stackTrace) {
      Log.alarm('❌ Erro ao mostrar notificação de falha: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Cancela notificação de monitoramento
  static Future<void> cancelMonitoringNotification() async {
    try {
      await _notifications.cancel(AppConstants.monitoringNotificationId);
    } catch (e, stackTrace) {
      Log.alarm('⚠️ Erro ao cancelar monitoramento: $e', e, stackTrace);
    }
  }

  /// Cancela notificação de chegada
  static Future<void> cancelArrivalNotification() async {
    try {
      await _notifications.cancel(AppConstants.arrivalNotificationId);
    } catch (e, stackTrace) {
      Log.alarm('⚠️ Erro ao cancelar alarme: $e', e, stackTrace);
    }
  }

  /// Cancela todas as notificações
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      Log.alarm('🗑️ Todas as notificações canceladas');
    } catch (e, stackTrace) {
      Log.alarm('⚠️ Erro ao cancelar todas as notificações: $e', e, stackTrace);
    }
  }

  /// Solicita TODAS as permissões necessárias para o alarme (Google Best Practices)
  /// Ordem correta: POST_NOTIFICATIONS → SCHEDULE_EXACT_ALARM
  /// (USE_FULL_SCREEN_INTENT é solicitada automaticamente pelo flutter_local_notifications)
  static Future<bool> requestAlarmPermissionsWithEducation(
      BuildContext context) async {
    if (!Platform.isAndroid) return true;

    Log.alarm('🔔 Iniciando fluxo de permissões para alarme...');

    // PASSO 1: Mostrar diálogo educativo ANTES de qualquer permissão
    final shouldProceed = await _showAlarmEducationDialog(context);
    if (!shouldProceed) {
      Log.alarm('ℹ️ Usuário recusou iniciar fluxo de permissões');
      return false;
    }

    // PASSO 2: Solicitar POST_NOTIFICATIONS (Android 13+) - Básico para notificações
    Log.alarm('📲 Solicitando permissão de notificações...');
    final notificationStatus = await _requestAndShowPermissionDialog(
      context,
      Permission.notification,
      title: 'Permissão de Notificações',
      explanation:
          'O Avisa Lá precisa enviar notificações para alertá-lo sobre sua parada.',
    );

    if (!notificationStatus.isGranted) {
      Log.alarm('⚠️ Permissão de notificações negada');
      return false;
    }
    Log.alarm('✅ Permissão de notificações concedida');

    // PASSO 3: Solicitar SCHEDULE_EXACT_ALARM (Android 12+) - Para alarmes precisos
    Log.alarm('⏰ Solicitando permissão de alarmes precisos...');
    final scheduleStatus = await _requestAndShowPermissionDialog(
      context,
      Permission.scheduleExactAlarm,
      title: 'Permissão de Alarmes',
      explanation:
          'Para notificar você no tempo exato, o app precisa agendar alarmes com precisão.',
    );

    if (!scheduleStatus.isGranted) {
      Log.alarm('⚠️ Permissão de alarmes precisos negada');
      return false;
    }
    Log.alarm('✅ Permissão de alarmes precisos concedida');

    Log.alarm('✅✅✅ TODAS as permissões de alarme foram concedidas!');
    Log.alarm('💡 A permissão de Full-Screen Intent (USE_FULL_SCREEN_INTENT) será');
    Log.alarm('   solicitada automaticamente pelo sistema ao primeiro uso.');
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
      Log.alarm('✅ $title já concedida');
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
        Log.alarm('ℹ️ Usuário recusou $title');
        return PermissionStatus.denied;
      }

      // AGORA solicitar a permissão do sistema
      final result = await permission.request();
      Log.alarm('📱 Resultado da solicitação de $title: $result');
      return result;
    }

    // Se foi negada permanentemente
    if (currentStatus.isPermanentlyDenied) {
      Log.alarm('❌ $title foi negada permanentemente');
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

  /// Dispara alarme full-screen nativo via MethodChannel
  /// Esta é a solução mais confiável para abrir o app mesmo com tela bloqueada
  static Future<bool> _showNativeFullScreenAlarm({
    required String destinationName,
    required double distance,
  }) async {
    if (!Platform.isAndroid) return false;
    
    try {
      Log.alarm('📱 [NATIVE] Chamando alarme full-screen nativo');
      final result = await _alarmChannel.invokeMethod('showFullScreenAlarm', {
        'destination': destinationName,
        'distance': distance,
      });
      return result == true;
    } catch (e, stackTrace) {
      Log.alarm('⚠️ [NATIVE] Falha ao chamar alarme nativo: $e', e, stackTrace);
      return false;
    }
  }

  /// Mostra notificação de alarme full-screen conforme Google Best Practices
  /// Referência: https://developer.android.com/training/scheduling/alarms
  static Future<void> showFullScreenAlarmNotification({
    required String destinationName,
    required double distance,
  }) async {
    try {
      Log.alarm('🔔 [ALARM] Iniciando showFullScreenAlarmNotification');
      Log.alarm('   📍 Destino: $destinationName');
      Log.alarm('   📏 Distância: ${distance.round()}m');

      // STEP 1: Tentar abrir via método nativo (mais confiável)
      final nativeSuccess = await _showNativeFullScreenAlarm(
        destinationName: destinationName,
        distance: distance,
      );
      
      if (nativeSuccess) {
        Log.alarm('✅ [NATIVE] Alarme disparado via método nativo!');
      } else {
        Log.alarm('⚠️ [NATIVE] Falhou, usando fallback Flutter');
      }

      // STEP 2: Sempre criar notificação Flutter (para mostrar no drawer)
      // Verificar permissão de notificação
      final notificationPermission = await Permission.notification.status;
      Log.alarm('   🔐 Permissão POST_NOTIFICATIONS: $notificationPermission');
      
      if (!notificationPermission.isGranted) {
        Log.alarm('❌ [ALARM] POST_NOTIFICATIONS não concedida! Notificação não será mostrada.');
        Log.alarm('   💡 Solicite a permissão em PermissionService.requestPhase1Permissions()');
        return;
      }

      // Payload com dados do alarme
      final payload = 'alarm_fullscreen|$destinationName|$distance';

      // ✅ CONFIGURAÇÃO DE ALARME CRÍTICO (Google Best Practices)
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'alarm_fullscreen_channel',
        '⏰ Alarmes de Proximidade',
        channelDescription: 'Alarmes críticos que acordam o device',
        
        // CRITICAL: Máxima prioridade e importância
        importance: Importance.max,
        priority: Priority.max,
        
        // Categoria ALARM - informa ao Android que é um alarme real
        category: AndroidNotificationCategory.alarm,
        
        // ✅ USE_FULL_SCREEN_INTENT - Android 10+ (API 29+)
        // Permite que notificação abra automaticamente sobre lockscreen
        fullScreenIntent: true,
        
        // Comportamento persistente
        autoCancel: false, // Não cancela automaticamente
        ongoing: true, // Persiste até ação do usuário
        
        // Som e vibração fortes
        playSound: true,
        // SEM som personalizado - usar padrão do canal
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        
        // Visibilidade pública (aparece sobre lockscreen)
        visibility: NotificationVisibility.public,
        
        // Ticker (texto de preview na barra de status)
        ticker: '🚨 AVISA LÁ: Alarme de Proximidade',
        
        // ✅ Ações do alarme (UX recomendada pelo Google)
        actions: const [
          AndroidNotificationAction(
            'dismiss_alarm',
            '🔕 Desativar Alarme',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'confirm_arrival',
            '✅ Cheguei!',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
        
        // Estilo de notificação grande
        styleInformation: BigTextStyleInformation(
          'Você está a ${distance.round()}m de $destinationName.\n\n'
          'Toque para ver detalhes ou use os botões abaixo.',
          htmlFormatBigText: false,
          contentTitle: '🔔 Chegando em $destinationName',
          htmlFormatContentTitle: false,
          summaryText: 'Alarme Avisa Lá',
        ),
        
        // LED para dispositivos compatíveis
        enableLights: true,
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        ledOnMs: 1000,
        ledOffMs: 500,
        
        // Badge no ícone do app
        number: 1,
        showWhen: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      // ID fixo para alarmes (facilita gerenciamento)
      const int alarmNotificationId = 999;

      await _notifications.show(
        alarmNotificationId,
        '🚨 CHEGANDO NO DESTINO!',
        'Toque para abrir o app ou use os botões abaixo',
        details,
        payload: payload,
      );

      Log.alarm('✅ [ALARM APP] Notificação full-screen criada:');
      Log.alarm('   📍 Destino: $destinationName');
      Log.alarm('   📏 Distância: ${distance.round()}m');
      Log.alarm('   🎯 Payload: $payload');
      Log.alarm('   ⚠️ Requer USE_FULL_SCREEN_INTENT permission');
    } catch (e, stackTrace) {
      Log.alarm('❌ ERRO CRÍTICO ao criar notificação de alarme:');
      Log.alarm('   Erro: $e');
      Log.alarm('   Stack: $stackTrace', e, stackTrace);
      
      // Verificar se permissões estão corretas
      Log.alarm('⚠️ Verifique se as permissões no AndroidManifest.xml estão corretas:');
      Log.alarm('   - USE_FULL_SCREEN_INTENT');
      Log.alarm('   - SCHEDULE_EXACT_ALARM (Android 12+)');
      Log.alarm('   - POST_NOTIFICATIONS (Android 13+)');
    }
  }
}

import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Gerenciamento de permissões específicas para aplicações de ALARME
/// Seguindo as melhores práticas do Google (Android 12+)
/// 
/// Referências:
/// - https://developer.android.com/training/scheduling/alarms#exact-alarm-permission
/// - https://developer.android.com/reference/android/Manifest.permission#SCHEDULE_EXACT_ALARM
class AlarmPermissionsManager {
  static const _channel = MethodChannel('com.example.avisa_la/alarm');

  /// Verifica se o app possui TODAS as permissões necessárias para funcionar como alarme
  static Future<bool> hasAllAlarmPermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      // Verifica permissões básicas
      final notificationStatus = await Permission.notification.status;
      final locationWhenInUseStatus = await Permission.locationWhenInUse.status;
      final locationAlwaysStatus = await Permission.locationAlways.status;

      // Android 12+: Verifica permissão de alarmes exatos (SCHEDULE_EXACT_ALARM)
      final canScheduleExactAlarms = await _canScheduleExactAlarms();

      // Android 10+: Verifica se otimizações de bateria estão desativadas
      final ignoringBatteryOptimizations = await _isIgnoringBatteryOptimizations();

      return notificationStatus.isGranted &&
          locationWhenInUseStatus.isGranted &&
          locationAlwaysStatus.isGranted &&
          canScheduleExactAlarms &&
          ignoringBatteryOptimizations;
    } catch (e) {
      developer.log('❌ Erro ao verificar permissões: $e',
          name: 'AvisaLa', error: e);
      return false;
    }
  }

  /// Android 12+: Verifica se o app pode agendar alarmes exatos
  static Future<bool> _canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final result = await _channel.invokeMethod<bool>('canScheduleExactAlarms');
      return result ?? false;
    } catch (e) {
      developer.log('❌ Erro ao verificar SCHEDULE_EXACT_ALARM: $e',
          name: 'AvisaLa', error: e);
      return false;
    }
  }

  /// Verifica se o app está na whitelist de otimização de bateria
  static Future<bool> _isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    
    try {
      return await Permission.ignoreBatteryOptimizations.status.isGranted;
    } catch (e) {
      developer.log('❌ Erro ao verificar otimizações de bateria: $e',
          name: 'AvisaLa', error: e);
      return false;
    }
  }

  /// Solicita TODAS as permissões necessárias para um app de alarme
  /// Segue o fluxo recomendado pelo Google
  static Future<bool> requestAllAlarmPermissions(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    // 1️⃣ NOTIFICAÇÕES (obrigatória)
    if (!(await _requestNotificationPermission(context))) {
      return false;
    }

    // 2️⃣ LOCALIZAÇÃO (obrigatória para este app)
    if (!(await _requestLocationPermissions(context))) {
      return false;
    }

    // 3️⃣ ALARMES EXATOS (Android 12+)
    if (!(await _requestExactAlarmPermission(context))) {
      return false;
    }

    // 4️⃣ OTIMIZAÇÃO DE BATERIA (recomendada)
    await _requestBatteryOptimizationExemption(context);

    return await hasAllAlarmPermissions();
  }

  /// Solicita permissão de notificações (Android 13+)
  static Future<bool> _requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;
    
    if (status.isGranted) return true;

    // Explica ao usuário POR QUE precisamos da permissão
    final shouldRequest = await _showPermissionRationaleDialog(
      context,
      title: 'Permissão de Notificações',
      message: 
        '📢 Este aplicativo é um ALARME de proximidade.\n\n'
        'Precisamos enviar notificações para:\n'
        '• Alertar quando você se aproximar do destino\n'
        '• Tocar som e vibrar para não perder a parada\n'
        '• Exibir a tela de alarme mesmo com o celular bloqueado',
    );

    if (!shouldRequest) return false;

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Solicita permissões de localização (em 2 etapas)
  static Future<bool> _requestLocationPermissions(BuildContext context) async {
    // Etapa 1: Localização durante uso do app
    var status = await Permission.locationWhenInUse.status;
    
    if (!status.isGranted) {
      final shouldRequest = await _showPermissionRationaleDialog(
        context,
        title: 'Permissão de Localização',
        message:
          '📍 Este app monitora sua localização em TEMPO REAL.\n\n'
          'A localização é necessária para:\n'
          '• Calcular distância até o destino\n'
          '• Disparar alarme ao se aproximar\n'
          '• Funcionar em segundo plano',
      );

      if (!shouldRequest) return false;

      final result = await Permission.locationWhenInUse.request();
      if (!result.isGranted) return false;
    }

    // Etapa 2: Localização em segundo plano (Android 10+)
    status = await Permission.locationAlways.status;
    
    if (!status.isGranted) {
      final shouldRequest = await _showPermissionRationaleDialog(
        context,
        title: 'Localização em Segundo Plano',
        message:
          '🔄 Permita localização "O tempo todo".\n\n'
          'Isso permite que o alarme funcione:\n'
          '• Com o app minimizado\n'
          '• Com a tela desligada\n'
          '• Enquanto você usa outros apps',
      );

      if (!shouldRequest) return false;

      final result = await Permission.locationAlways.request();
      return result.isGranted;
    }

    return true;
  }

  /// Android 12+: Solicita permissão para agendar alarmes exatos
  /// Esta permissão PODE SER REVOGADA pelo usuário nas configurações
  static Future<bool> _requestExactAlarmPermission(BuildContext context) async {
    // Verifica se já possui a permissão
    if (await _canScheduleExactAlarms()) return true;

    // Explica ao usuário
    final shouldRequest = await _showPermissionRationaleDialog(
      context,
      title: 'Permissão de Alarmes e Lembretes',
      message:
        '⏰ Este é um aplicativo de ALARME.\n\n'
        'Android 12+ requer permissão especial:\n'
        '• "Alarmes e lembretes"\n'
        '• Garante que o alarme toque no momento exato\n'
        '• Você será levado às Configurações do Sistema',
    );

    if (!shouldRequest) return false;

    // Abre a tela de configurações do sistema
    try {
      await _channel.invokeMethod('openAlarmPermissionSettings');
      
      // Aguarda usuário voltar e verifica se concedeu
      await Future.delayed(const Duration(seconds: 1));
      return await _canScheduleExactAlarms();
    } catch (e) {
      developer.log('❌ Erro ao abrir configurações de alarme: $e',
          name: 'AvisaLa', error: e);
      return false;
    }
  }

  /// Solicita isenção de otimizações de bateria
  /// IMPORTANTE: Google limita uso desta permissão
  static Future<bool> _requestBatteryOptimizationExemption(BuildContext context) async {
    if (await _isIgnoringBatteryOptimizations()) return true;

    final shouldRequest = await _showPermissionRationaleDialog(
      context,
      title: 'Otimização de Bateria',
      message:
        '🔋 Para alarmes funcionarem perfeitamente:\n\n'
        'Recomendamos DESATIVAR otimização de bateria.\n\n'
        '⚠️ Isso pode consumir mais bateria, mas garante:\n'
        '• Alarme sempre dispara\n'
        '• Monitoramento contínuo\n'
        '• Sem interrupções do sistema',
    );

    if (!shouldRequest) return false;

    final result = await Permission.ignoreBatteryOptimizations.request();
    return result.isGranted;
  }

  /// Exibe diálogo educativo explicando POR QUE a permissão é necessária
  /// Seguindo as diretrizes de UX do Google
  static Future<bool> _showPermissionRationaleDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Agora não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Conceder Permissão'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Exibe diálogo se permissões foram negadas permanentemente
  static Future<void> showPermissionDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Permissões Necessárias'),
        content: const Text(
          'Este aplicativo é um ALARME de proximidade.\n\n'
          'Sem as permissões necessárias, não podemos:\n'
          '• Monitorar sua localização\n'
          '• Disparar alarmes\n'
          '• Exibir notificações\n\n'
          'Por favor, ative as permissões nas Configurações.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Abrir Configurações'),
          ),
        ],
      ),
    );
  }
}

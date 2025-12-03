import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'package:flutter/material.dart';

class PermissionService {
  /// Solicita permissão de localização básica (while in use)
  static Future<bool> requestLocationPermission() async {
    final status = await permission_handler.Permission.location.request();
    return status.isGranted;
  }

  /// Solicita permissão de localização em segundo plano (always)
  static Future<bool> requestBackgroundLocationPermission() async {
    final status = await permission_handler.Permission.locationAlways.request();
    return status.isGranted;
  }

  /// Solicita permissão de notificações
  static Future<bool> requestNotificationPermission() async {
    final status = await permission_handler.Permission.notification.request();
    return status.isGranted;
  }

  /// Solicita ignoração de otimização de bateria (Android)
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    final status = await permission_handler.Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  /// Verifica se todas as permissões essenciais foram concedidas
  static Future<bool> hasAllEssentialPermissions() async {
    final location = await permission_handler.Permission.location.isGranted;
    final notification = await permission_handler.Permission.notification.isGranted;
    return location && notification;
  }

  /// Verifica se tem permissão de localização em segundo plano
  static Future<bool> hasBackgroundLocationPermission() async {
    return await permission_handler.Permission.locationAlways.isGranted;
  }

  /// Abre as configurações do app
  static Future<void> openAppSettings() async {
    await permission_handler.openAppSettings();
  }

  /// Mostra diálogo educativo explicando a necessidade de permissão
  static Future<bool> showPermissionRationaleDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onAccept,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                  child: const Text('Agora não'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    onAccept();
                  },
                  child: const Text('Conceder Permissão'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Mostra diálogo para ir às configurações quando permissão foi negada
  static Future<void> showPermissionDeniedDialog(
    BuildContext context, {
    required String message,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissão Necessária'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Ir para Configurações'),
            ),
          ],
        );
      },
    );
  }

  /// Fase 1: Primeira abertura - solicita permissões básicas
  static Future<bool> requestPhase1Permissions() async {
    final location = await requestLocationPermission();
    final notification = await requestNotificationPermission();
    return location && notification;
  }

  /// Fase 2: Antes da primeira viagem - solicita localização em segundo plano
  static Future<bool> requestPhase2Permissions(BuildContext context) async {
    // Mostra diálogo educativo primeiro
    final accepted = await showPermissionRationaleDialog(
      context,
      title: 'Permissão de Localização em Segundo Plano',
      message:
          'Para funcionar mesmo com o app em segundo plano ou tela bloqueada, '
          'o Avisa Lá precisa de permissão de localização "Sempre Permitir". '
          'Isso garante que você será alertado mesmo se estiver usando outros apps ou ouvindo música.',
      onAccept: () {},
    );

    if (!accepted) return false;

    return await requestBackgroundLocationPermission();
  }
}

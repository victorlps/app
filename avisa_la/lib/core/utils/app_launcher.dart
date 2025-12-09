import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Helper para trazer o app para frente quando necessário
class AppLauncher {
  static const MethodChannel _channel = 
      MethodChannel('com.example.avisa_la/alarm');

  /// Força o app a vir para frente (útil quando alarme toca)
  static Future<bool> bringToFront() async {
    if (!Platform.isAndroid) {
      developer.log('⚠️ bringToFront só funciona no Android', name: 'AvisaLa');
      return false;
    }

    try {
      developer.log('🚀 Tentando trazer app para frente...', name: 'AvisaLa');
      final result = await _channel.invokeMethod<bool>('bringToFront');
      developer.log('✅ App trazido para frente: $result', name: 'AvisaLa');
      return result ?? false;
    } catch (e, stackTrace) {
      developer.log('❌ Erro ao trazer app para frente: $e',
          name: 'AvisaLa', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Mostrar notificação full-screen nativa com PendingIntent customizado
  /// Esta notificação vai disparar AlarmReceiver que abre o app
  static Future<bool> showNativeAlarmNotification({
    required String destination,
    required double distance,
  }) async {
    if (!Platform.isAndroid) {
      developer.log('⚠️ showNativeAlarmNotification só funciona no Android',
          name: 'AvisaLa');
      return false;
    }

    try {
      developer.log(
          '📢 Enviando notificação full-screen nativa: $destination ($distance m)',
          name: 'AvisaLa');
      final result = await _channel.invokeMethod<bool>('showAlarmNotification', {
        'destination': destination,
        'distance': distance,
      });
      developer.log('✅ Notificação nativa enviada: $result', name: 'AvisaLa');
      return result ?? false;
    } catch (e, stackTrace) {
      developer.log('❌ Erro ao enviar notificação nativa: $e',
          name: 'AvisaLa', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}


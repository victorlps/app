import 'dart:developer' as developer;

import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Serviço de alarme real (não notificação)
/// Toca som em loop + vibração contínua + wakelock
/// 
/// ⚠️ IMPORTANTE: WakelockPlus pode falhar em background isolate
/// Envolver em try-catch para evitar crashes
class AlarmService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isPlaying = false;

  /// Iniciar alarme (som + vibração + wakelock)
  static Future<void> startAlarm() async {
    if (_isPlaying) return;

    try {
      developer.log('🔔 INICIANDO ALARME REAL', name: 'AvisaLa');

      try {
        // Habilitar wakelock (mantém tela ligada)
        // ⚠️ Pode falhar em background isolate - envolver em try-catch
        await WakelockPlus.enable();
        developer.log('✅ Wakelock ativado', name: 'AvisaLa');
      } catch (e) {
        // Se falhar em background, continuamos sem wakelock
        developer.log('⚠️ Wakelock não disponível (background?): $e',
            name: 'AvisaLa', error: e);
      }

      // Configurar audio player para loop
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);

      // Tocar som do sistema (notification)
      // Usar asset local seria melhor, mas notification sound é garantido
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3')).catchError((e) {
        developer.log('⚠️ Falha ao tocar asset, usando URL',
            name: 'AvisaLa', error: e);
        // Fallback: usar som do sistema
        return _audioPlayer.play(
          UrlSource(
            'https://actions.google.com/sounds/v1/alarms/alarm_clock.ogg',
          ),
        );
      });

      _isPlaying = true;
      developer.log('✅ Som do alarme tocando em loop', name: 'AvisaLa');

      // Vibração contínua (se disponível)
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        // Vibrar em loop: 500ms on, 500ms off
        _startContinuousVibration();
        developer.log('✅ Vibração contínua iniciada', name: 'AvisaLa');
      }
    } catch (e, stackTrace) {
      developer.log('❌ Erro ao iniciar alarme: $e',
          name: 'AvisaLa', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Para alarme (som + vibração + wakelock)
  static Future<void> stopAlarm() async {
    if (!_isPlaying) return;

    try {
      developer.log('⛔ PARANDO ALARME', name: 'AvisaLa');

      // Parar audio
      await _audioPlayer.stop();
      _isPlaying = false;
      developer.log('✅ Som parado', name: 'AvisaLa');

      // Parar vibração
      await Vibration.cancel();
      developer.log('✅ Vibração cancelada', name: 'AvisaLa');

      // Desabilitar wakelock
      try {
        await WakelockPlus.disable();
        developer.log('✅ Wakelock desativado', name: 'AvisaLa');
      } catch (e) {
        developer.log('⚠️ Erro ao desativar wakelock: $e',
            name: 'AvisaLa', error: e);
      }
    } catch (e, stackTrace) {
      developer.log('❌ Erro ao parar alarme: $e',
          name: 'AvisaLa', error: e, stackTrace: stackTrace);
    }
  }

  /// Vibração contínua (loop manual)
  static void _startContinuousVibration() {
    // Pattern: [delay, vibrate, pause, vibrate, pause, ...]
    // Android: [0, 500, 500] = vibra 500ms, pausa 500ms, repete
    Vibration.vibrate(
      pattern: [0, 500, 500],
      repeat: 0, // Repeat from index 0 (infinite loop)
    );
  }

  /// Verifica se alarme está tocando
  static bool get isPlaying => _isPlaying;

  /// Limpar recursos
  static Future<void> dispose() async {
    await stopAlarm();
    await _audioPlayer.dispose();
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Serviço de alarme real (não notificação)
/// Toca som em loop + vibração contínua + wakelock
class AlarmService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isPlaying = false;

  /// Iniciar alarme (som + vibração + wakelock)
  static Future<void> startAlarm() async {
    if (_isPlaying) return;

    try {
      print('🔔 INICIANDO ALARME REAL');

      // Habilitar wakelock (mantém tela ligada)
      await WakelockPlus.enable();
      print('✅ Wakelock ativado');

      // Configurar audio player para loop
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);

      // Tocar som do sistema (notification)
      // Usar asset local seria melhor, mas notification sound é garantido
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3')).catchError((e) {
        print('⚠️ Falha ao tocar asset, usando URL');
        // Fallback: usar som do sistema
        return _audioPlayer.play(
          UrlSource(
            'https://actions.google.com/sounds/v1/alarms/alarm_clock.ogg',
          ),
        );
      });

      _isPlaying = true;
      print('✅ Som do alarme tocando em loop');

      // Vibração contínua (se disponível)
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        // Vibrar em loop: 500ms on, 500ms off
        _startContinuousVibration();
        print('✅ Vibração contínua iniciada');
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao iniciar alarme: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  /// Para alarme (som + vibração + wakelock)
  static Future<void> stopAlarm() async {
    if (!_isPlaying) return;

    try {
      print('⛔ PARANDO ALARME');

      // Parar audio
      await _audioPlayer.stop();
      _isPlaying = false;
      print('✅ Som parado');

      // Parar vibração
      await Vibration.cancel();
      print('✅ Vibração cancelada');

      // Desabilitar wakelock
      await WakelockPlus.disable();
      print('✅ Wakelock desativado');
    } catch (e, stackTrace) {
      print('❌ Erro ao parar alarme: $e');
      print('Stack: $stackTrace');
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

import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:avisa_la/core/models/destination.dart';
import 'package:avisa_la/core/utils/distance_calculator.dart';
import 'package:avisa_la/core/utils/constants.dart';
import 'package:avisa_la/core/services/notification_service.dart';
import 'package:avisa_la/core/services/directions_service.dart';

/// Estado da máquina de monitoramento
enum AlarmState { idle, monitoring, alarming, dismissed }

@pragma('vm:entry-point')
class BackgroundService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  /// Inicializa o serviço em segundo plano
  static Future<void> initialize() async {
    await _service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        autoStart: false,
        onStart: onStart,
        isForegroundMode: true,
        autoStartOnBoot: false,
      ),
    );
    _log('✅ BackgroundService inicializado', level: 'INFO');
  }

  /// Inicia o monitoramento da viagem
  static Future<void> startTrip({
    required Destination destination,
    required double alertDistance,
    required bool useDynamicMode,
    required double alertTimeMinutes,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'destination': destination.toJson(),
        'alertDistance': alertDistance,
        'useDynamicMode': useDynamicMode,
        'alertTimeMinutes': alertTimeMinutes,
      };

      await _service.startService();
      _service.invoke('startTrip', data);
      _log('📍 Trip iniciada: ${destination.name}', level: 'INFO');
    } catch (e, stackTrace) {
      _log('❌ Erro ao iniciar trip: $e',
          level: 'ERROR', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Para o monitoramento da viagem
  static Future<void> stopTrip() async {
    try {
      _service.invoke('stopTrip');
      await Future.delayed(const Duration(milliseconds: 500));
      _log('⛔ Trip parada', level: 'INFO');
    } catch (e, stackTrace) {
      _log('❌ Erro ao parar trip: $e', level: 'ERROR', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Verifica se o serviço está rodando
  static Future<bool> isRunning() async {
    return await _service.isRunning();
  }

  /// Função executada quando o serviço inicia (Android e iOS foreground)
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // === STATE MACHINE ===
    AlarmState _state = AlarmState.idle;

    // === VARIÁVEIS DE MONITORAMENTO ===
    Destination? destination;
    double alertDistance = AppConstants.defaultAlertDistance;
    bool useDynamicMode = false;
    double alertTimeMinutes = 5.0;
    bool hasAlerted = false;
    int updateCount = 0;

    // === TIMERS E STREAMS ===
    Timer? healthCheckTimer;
    Timer? directionsCheckTimer;
    StreamSubscription<Position>? positionStream;

    // === FUNÇÕES AUXILIARES ===

    /// Log estruturado
    void log(String msg, {String level = 'DEBUG'}) {
      final timestamp = DateTime.now().toString().split('.')[0];
      print('[$timestamp] $level: $msg');
    }

    /// Verificar e recuperar de erros
    Future<void> _checkHealth() async {
      try {
        if (_state == AlarmState.idle) return;

        if (destination == null) {
          log('⚠️ Health check: destino nulo', level: 'WARNING');
          return;
        }

        // Atualizar notificação = proof of life
        await NotificationService.showMonitoringNotification(
          destinationName: destination!.name,
        );

        log('✅ Health check OK', level: 'DEBUG');
      } catch (e, stackTrace) {
        log('❌ Health check erro: $e', level: 'ERROR');
        log('Stack: $stackTrace', level: 'DEBUG');
      }
    }

    /// Verificar chegada via Directions API (modo dinâmico)
    Future<void> _checkDirectionsAPITime() async {
      if (_state != AlarmState.monitoring || !useDynamicMode) return;
      if (destination == null) return;

      try {
        final position = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 10),
        ).catchError((e) {
          log('⚠️ GPS timeout, usando última posição conhecida',
              level: 'WARNING');
          return null;
        });

        if (position == null) return;

        final realTimeSeconds =
            await DirectionsService.getEstimatedTimeToDestination(
          originLat: position.latitude,
          originLng: position.longitude,
          destLat: destination!.latitude,
          destLng: destination!.longitude,
        ).catchError((e) {
          log('⚠️ Directions API erro: $e (usando fallback)', level: 'WARNING');
          return null;
        });

        if (realTimeSeconds == null) {
          log('⚠️ Directions API indisponível (modo fallback)',
              level: 'WARNING');
          return;
        }

        final alertTimeSeconds = (alertTimeMinutes * 60).round();
        if (realTimeSeconds <= alertTimeSeconds && !hasAlerted) {
          log('🔔 Condição Directions API atingida: ${realTimeSeconds}s <= ${alertTimeSeconds}s',
              level: 'WARNING');
          hasAlerted = true;
          _state = AlarmState.alarming;

          final distance = DistanceCalculator.calculateDistance(
            position.latitude,
            position.longitude,
            destination!.latitude,
            destination!.longitude,
          );

          // Mostrar notificação full-screen para acordar device
          await NotificationService.showFullScreenAlarmNotification(
            destinationName: destination!.name,
            distance: distance,
          );

          // Enviar evento para mostrar tela de alarme (quando app abrir)
          service.invoke('showAlarm', {
            'destination': destination!.name,
            'distance': distance,
          });
          log('✅ Alarme disparado via Directions API', level: 'INFO');
        }
      } catch (e, stackTrace) {
        log('❌ Erro em Directions API check: $e', level: 'ERROR');
        log('Stack: $stackTrace', level: 'DEBUG');
      }
    }

    /// Processar posição do GPS
    Future<void> _processGPSPosition(Position position) async {
      if (_state == AlarmState.idle) return;
      if (destination == null) return;

      try {
        updateCount++;
        final distance = DistanceCalculator.calculateDistance(
          position.latitude,
          position.longitude,
          destination!.latitude,
          destination!.longitude,
        );

        // Log a cada 5 updates
        if (updateCount % 5 == 0) {
          log(
              '📍 GPS: ${distance.toStringAsFixed(0)}m / ${alertDistance.toStringAsFixed(0)}m | '
              'Speed: ${position.speed.toStringAsFixed(1)}m/s',
              level: 'DEBUG');
        }

        // Atualizar notificação
        await NotificationService.showMonitoringNotification(
          destinationName: destination!.name,
          distance: distance,
        );

        // Enviar update para UI
        service.invoke('update', {
          'distance': distance,
          'speed': position.speed,
          'accuracy': position.accuracy,
        });

        // Verificar condição de proximidade (distância)
        if (distance <= alertDistance && !hasAlerted) {
          log('🔔 Condição distância atingida: ${distance.toStringAsFixed(1)}m <= ${alertDistance}m',
              level: 'WARNING');
          hasAlerted = true;
          _state = AlarmState.alarming;

          // Mostrar notificação full-screen para acordar device
          await NotificationService.showFullScreenAlarmNotification(
            destinationName: destination!.name,
            distance: distance,
          );

          // Enviar evento para mostrar tela de alarme (quando app abrir)
          service.invoke('showAlarm', {
            'destination': destination!.name,
            'distance': distance,
          });
          log('✅ Alarme disparado via GPS distance', level: 'INFO');
        }
      } catch (e, stackTrace) {
        log('❌ Erro ao processar GPS: $e', level: 'ERROR');
        log('Stack: $stackTrace', level: 'DEBUG');
      }
    }

    /// Iniciar GPS stream
    void _startGPSStream() {
      try {
        positionStream = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: AppConstants.gpsDistanceFilterMeters,
          ),
        ).listen(
          _processGPSPosition,
          onError: (e) {
            log('❌ GPS stream erro: $e', level: 'ERROR');
            // Fallback: continuar sem GPS
          },
          cancelOnError: false,
        );
        log('✅ GPS stream iniciado', level: 'INFO');
      } catch (e, stackTrace) {
        log('❌ Erro ao iniciar GPS stream: $e', level: 'ERROR');
        log('Stack: $stackTrace', level: 'DEBUG');
      }
    }

    /// Iniciar timers periódicos
    void _startTimers() {
      try {
        // Health check a cada 30 segundos
        healthCheckTimer = Timer.periodic(
          const Duration(seconds: AppConstants.healthCheckIntervalSeconds),
          (_) => _checkHealth(),
        );

        // Directions API check a cada 30 segundos (modo dinâmico)
        if (useDynamicMode) {
          directionsCheckTimer = Timer.periodic(
            const Duration(seconds: 30),
            (_) => _checkDirectionsAPITime(),
          );
        }

        log('✅ Timers iniciados', level: 'INFO');
      } catch (e, stackTrace) {
        log('❌ Erro ao iniciar timers: $e', level: 'ERROR');
        log('Stack: $stackTrace', level: 'DEBUG');
      }
    }

    /// Parar tudo
    void _stopAll() {
      try {
        positionStream?.cancel();
        healthCheckTimer?.cancel();
        directionsCheckTimer?.cancel();
        updateCount = 0;
        _state = AlarmState.idle;
        log('✅ Monitoramento parado', level: 'INFO');
      } catch (e, stackTrace) {
        log('❌ Erro ao parar monitoramento: $e', level: 'ERROR');
        log('Stack: $stackTrace', level: 'DEBUG');
      }
    }

    // === LISTENER: START TRIP ===
    service.on('startTrip').listen((event) async {
      if (_state != AlarmState.idle) {
        log('⚠️ Monitoramento já em andamento', level: 'WARNING');
        return;
      }

      try {
        log('🚀 Iniciando monitoramento...', level: 'INFO');

        final data = event;
        if (data == null) {
          log('❌ Dados nulos em startTrip', level: 'ERROR');
          return;
        }

        // === DESSERIALIZAR COM SEGURANÇA ===
        try {
          destination = Destination.fromJson(data['destination']);
          alertDistance = (data['alertDistance'] as num).toDouble();
          useDynamicMode = data['useDynamicMode'] as bool;
          alertTimeMinutes = (data['alertTimeMinutes'] as num).toDouble();
        } catch (e, stackTrace) {
          log('❌ Erro ao desserializar: $e', level: 'ERROR');
          log('Stack: $stackTrace', level: 'DEBUG');
          await NotificationService.showFailureNotification();
          return;
        }

        // === VALIDAR DADOS ===
        if (destination == null ||
            alertDistance <= 0 ||
            alertTimeMinutes <= 0) {
          log('❌ Dados inválidos após desserialização', level: 'ERROR');
          await NotificationService.showFailureNotification();
          return;
        }

        hasAlerted = false;
        _state = AlarmState.monitoring;

        // === INICIALIZAR NOTIFICAÇÕES ===
        try {
          await NotificationService.initialize();
          log('✅ NotificationService inicializado', level: 'INFO');
        } catch (e, stackTrace) {
          log('❌ Erro ao inicializar NotificationService: $e', level: 'ERROR');
          log('Stack: $stackTrace', level: 'DEBUG');
          await NotificationService.showFailureNotification();
          return;
        }

        // === MOSTRAR NOTIFICAÇÃO INICIAL ===
        try {
          await NotificationService.showMonitoringNotification(
            destinationName: destination!.name,
          );
        } catch (e, stackTrace) {
          log('⚠️ Erro ao mostrar notificação inicial: $e', level: 'WARNING');
        }

        // === LOG DE CONFIGURAÇÃO ===
        log('════════════════════════════════', level: 'INFO');
        log('📍 Destino: ${destination!.name}', level: 'INFO');
        log('📏 Distância alerta: ${alertDistance.toStringAsFixed(0)}m',
            level: 'INFO');
        log('⏱️ Tempo alerta: ${alertTimeMinutes.toStringAsFixed(1)}min',
            level: 'INFO');
        log('🔄 Modo dinâmico: $useDynamicMode', level: 'INFO');
        log('════════════════════════════════', level: 'INFO');

        // === INICIAR MONITORAMENTO ===
        _startGPSStream();
        _startTimers();
      } catch (e, stackTrace) {
        log('❌ Erro CRÍTICO em startTrip: $e', level: 'ERROR');
        log('Stack: $stackTrace', level: 'DEBUG');
        _state = AlarmState.idle;
        try {
          await NotificationService.showFailureNotification();
        } catch (_) {}
      }
    });

    // === LISTENER: STOP TRIP ===
    service.on('stopTrip').listen((event) async {
      try {
        log('⛔ Parando monitoramento...', level: 'INFO');
        _stopAll();
        await NotificationService.cancelAllNotifications();
        service.stopSelf();
      } catch (e, stackTrace) {
        log('❌ Erro ao parar monitoramento: $e', level: 'ERROR');
        log('Stack: $stackTrace', level: 'DEBUG');
      }
    });

    // === LISTENER: UPDATE (Para solicitar update manual) ===
    service.on('update').listen((event) async {
      if (_state == AlarmState.monitoring && destination != null) {
        try {
          final position = await Geolocator.getCurrentPosition();
          await _processGPSPosition(position);
        } catch (e) {
          log('⚠️ Erro ao processar update manual: $e', level: 'WARNING');
        }
      }
    });

    // === SETUP ANDROID FOREGROUND SERVICE ===
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    log('🎯 Background service listener setup completo', level: 'INFO');
  }

  /// Função executada em segundo plano no iOS
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// Log centralizado (para debug)
  static void _log(String msg,
      {String level = 'DEBUG', StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toString().split('.')[0];
    print('[$timestamp] $level: $msg');
    if (stackTrace != null) {
      print('Stack trace:\n$stackTrace');
    }
  }
}

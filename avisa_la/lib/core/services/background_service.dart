import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:avisa_la/core/models/destination.dart';
import 'package:avisa_la/core/utils/distance_calculator.dart';
import 'package:avisa_la/core/utils/constants.dart';
import 'package:avisa_la/core/services/notification_service.dart';
import 'package:avisa_la/core/services/directions_service.dart';
// 'dart:convert' removed (unused)

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
  }

  /// Inicia o monitoramento da viagem
  static Future<void> startTrip({
    required Destination destination,
    required double alertDistance,
    required bool useDynamicMode,
    required double alertTimeMinutes,
  }) async {
    final Map<String, dynamic> data = {
      'destination': destination.toJson(),
      'alertDistance': alertDistance,
      'useDynamicMode': useDynamicMode,
      'alertTimeMinutes': alertTimeMinutes,
    };

    await _service.startService();
    _service.invoke('startTrip', data);
  }

  /// Para o monitoramento da viagem
  static Future<void> stopTrip() async {
    _service.invoke('stopTrip');
    await Future.delayed(const Duration(milliseconds: 500));
    // The background service will stop itself after handling the 'stopTrip' event.
    // Older versions of the plugin exposed a `stopService` method; to remain
    // compatible with the current package we avoid calling a non-existent
    // method here.
  }

  /// Verifica se o serviço está rodando
  static Future<bool> isRunning() async {
    return await _service.isRunning();
  }

  /// Função executada quando o serviço inicia (Android e iOS foreground)
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    Destination? destination;
    double alertDistance = AppConstants.defaultAlertDistance;
    bool useDynamicMode = false;
    double alertTimeMinutes = 5.0;
    bool hasAlerted = false;
    Timer? healthCheckTimer;
    Timer? directionsCheckTimer;
    StreamSubscription<Position>? positionStream;

    // Escuta comandos
    service.on('startTrip').listen((event) async {
      final data = event;
      if (data == null) return;

      destination = Destination.fromJson(data['destination']);
      alertDistance = data['alertDistance'] as double;
      useDynamicMode = data['useDynamicMode'] as bool;
      alertTimeMinutes = data['alertTimeMinutes'] as double;
      hasAlerted = false;

      // Inicializar NotificationService
      await NotificationService.initialize();

      // Mostrar notificação persistente
      await NotificationService.showMonitoringNotification(
        destinationName: destination!.name,
      );

      // Se modo dinâmico, iniciar timer para verificar tempo real via Directions API
      if (useDynamicMode) {
        directionsCheckTimer = Timer.periodic(
          const Duration(seconds: 30),
          (timer) async {
            if (destination == null) return;

            // Pegar posição atual
            try {
              final position = await Geolocator.getCurrentPosition();

              // Calcular tempo real via Directions API
              final realTimeSeconds =
                  await DirectionsService.getEstimatedTimeToDestination(
                originLat: position.latitude,
                originLng: position.longitude,
                destLat: destination!.latitude,
                destLng: destination!.longitude,
              );

              if (realTimeSeconds != null) {
                // Verificar se deve alertar baseado no tempo
                final alertTimeSeconds = (alertTimeMinutes * 60).round();
                if (realTimeSeconds <= alertTimeSeconds && !hasAlerted) {
                  hasAlerted = true;
                  await NotificationService.showArrivalNotification(
                    distance: DistanceCalculator.calculateDistance(
                      position.latitude,
                      position.longitude,
                      destination!.latitude,
                      destination!.longitude,
                    ),
                  );
                }
              }
            } catch (e) {
              print('❌ Erro ao verificar tempo via Directions API: $e');
            }
          },
        );
      }

      // Iniciar monitoramento de posição
      positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: AppConstants.gpsDistanceFilterMeters,
        ),
      ).listen((Position position) async {
        if (destination == null) return;

        // Calcular distância
        final distance = DistanceCalculator.calculateDistance(
          position.latitude,
          position.longitude,
          destination!.latitude,
          destination!.longitude,
        );

        // Atualizar notificação persistente com distância
        await NotificationService.showMonitoringNotification(
          destinationName: destination!.name,
          distance: distance,
        );

        // Enviar atualização para o app
        service.invoke('update', {
          'distance': distance,
          'speed': position.speed,
          'accuracy': position.accuracy,
        });

        // Verificar condição de proximidade por distância
        // No modo dinâmico, também verifica por tempo (no timer acima)
        // Alerta se atingir a distância configurada
        if (distance <= alertDistance && !hasAlerted) {
          hasAlerted = true;
          await NotificationService.showArrivalNotification(
            distance: distance,
          );
          // Não para automaticamente - aguarda confirmação
        }
      });

      // Health check timer
      healthCheckTimer = Timer.periodic(
        const Duration(seconds: AppConstants.healthCheckIntervalSeconds),
        (timer) async {
          // Atualizar notificação para manter o serviço vivo
          if (destination != null) {
            await NotificationService.showMonitoringNotification(
              destinationName: destination!.name,
            );
          }
        },
      );
    });

    // Escuta comando de parar
    service.on('stopTrip').listen((event) async {
      positionStream?.cancel();
      healthCheckTimer?.cancel();
      directionsCheckTimer?.cancel();
      await NotificationService.cancelAllNotifications();
      service.stopSelf();
    });

    // Para Android: atualizar foreground notification
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }
  }

  /// Função executada em segundo plano no iOS
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    return true;
  }
}

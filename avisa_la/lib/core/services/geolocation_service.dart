import 'package:geolocator/geolocator.dart';
import 'package:avisa_la/core/utils/constants.dart';
import 'dart:async';

class GeolocationService {
  static StreamSubscription<Position>? _positionStream;

  /// Verifica se o serviço de localização está habilitado
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Obtém a posição atual do usuário
  static Future<Position?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      print('Erro ao obter posição atual: $e');
      return null;
    }
  }

  /// Inicia o stream de atualizações de posição
  static Stream<Position> getPositionStream({bool isMoving = true}) {
    final LocationSettings settings = _getLocationSettings(isMoving);
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// Configurações de localização adaptativas
  static LocationSettings _getLocationSettings(bool isMoving) {
    if (isMoving) {
      // Quando em movimento: alta precisão, atualizações mais frequentes
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: AppConstants.gpsDistanceFilterMeters,
      );
    } else {
      // Quando parado: precisão média, economiza bateria
      return const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 50,
      );
    }
  }

  /// Para o stream de posição
  static void stopPositionStream() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  /// Verifica a precisão do GPS
  static bool isGpsAccurate(Position position) {
    return position.accuracy <= AppConstants.gpsAccuracyMeters;
  }

  /// Obtém status de qualidade do sinal GPS
  static String getGpsQualityStatus(Position position) {
    final accuracy = position.accuracy;
    if (accuracy <= 20) {
      return 'Excelente';
    } else if (accuracy <= 50) {
      return 'Bom';
    } else if (accuracy <= 100) {
      return 'Regular';
    } else {
      return 'Fraco';
    }
  }

  /// Calcula a velocidade em m/s
  static double getSpeedMps(Position position) {
    return position.speed;
  }

  /// Calcula a velocidade em km/h
  static double getSpeedKmh(Position position) {
    return position.speed * 3.6;
  }
}

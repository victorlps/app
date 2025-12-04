import 'dart:math';

class DistanceCalculator {
  /// Calcula a distância entre duas coordenadas usando a fórmula de Haversine
  /// Retorna a distância em metros
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Raio da Terra em metros

    // Converter graus para radianos
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  /// Converte graus para radianos
  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Formata a distância para exibição legível
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      double km = meters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  /// Calcula distância de alerta dinâmica baseada na velocidade
  /// desiredWarningTime em segundos
  static double calculateDynamicAlertDistance(
    double currentSpeedMps,
    int desiredWarningTime,
  ) {
    double dynamicDistance = currentSpeedMps * desiredWarningTime;
    // Limitar entre 200m e 2000m
    return dynamicDistance.clamp(200.0, 2000.0);
  }

  /// Estima tempo de chegada baseado na distância e velocidade
  /// Retorna tempo em segundos
  /// Se velocidade for muito baixa, usa velocidade média urbana (30 km/h) como fallback
  static int estimateArrivalTime(double distanceMeters, double speedMps) {
    // Se velocidade é muito baixa (< 1 m/s = 3.6 km/h), usar velocidade média urbana
    if (speedMps < 1.0) {
      // 30 km/h = 8.33 m/s (velocidade média urbana razoável)
      const fallbackSpeedMps = 8.33;
      return (distanceMeters / fallbackSpeedMps).round();
    }
    return (distanceMeters / speedMps).round();
  }

  /// Formata tempo em minutos e segundos
  static String formatTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      int minutes = seconds ~/ 60;
      int remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '${minutes}min';
      }
      return '${minutes}min ${remainingSeconds}s';
    }
  }
}

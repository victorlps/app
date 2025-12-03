enum TripState {
  idle,
  searching,
  destinationSelected,
  monitoring,
  approaching,
  arrived,
  cancelled,
}

class TripStatus {
  final TripState state;
  final double? distanceToDestination;
  final double? currentSpeed;
  final DateTime? startTime;
  final DateTime? estimatedArrival;
  final bool isGpsActive;
  final String? errorMessage;

  TripStatus({
    required this.state,
    this.distanceToDestination,
    this.currentSpeed,
    this.startTime,
    this.estimatedArrival,
    this.isGpsActive = false,
    this.errorMessage,
  });

  TripStatus copyWith({
    TripState? state,
    double? distanceToDestination,
    double? currentSpeed,
    DateTime? startTime,
    DateTime? estimatedArrival,
    bool? isGpsActive,
    String? errorMessage,
  }) {
    return TripStatus(
      state: state ?? this.state,
      distanceToDestination: distanceToDestination ?? this.distanceToDestination,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      startTime: startTime ?? this.startTime,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      isGpsActive: isGpsActive ?? this.isGpsActive,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isActive => state == TripState.monitoring || state == TripState.approaching;

  String get stateLabel {
    switch (state) {
      case TripState.idle:
        return 'Inativo';
      case TripState.searching:
        return 'Buscando destino';
      case TripState.destinationSelected:
        return 'Destino selecionado';
      case TripState.monitoring:
        return 'Monitorando...';
      case TripState.approaching:
        return 'Chegando ao destino!';
      case TripState.arrived:
        return 'Chegou!';
      case TripState.cancelled:
        return 'Cancelado';
    }
  }
}

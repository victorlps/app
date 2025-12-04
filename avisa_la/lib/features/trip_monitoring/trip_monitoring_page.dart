import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:avisa_la/core/models/destination.dart';
import 'package:avisa_la/core/services/background_service.dart';
import 'package:avisa_la/core/services/geolocation_service.dart';
import 'package:avisa_la/core/services/notification_service.dart';
import 'package:avisa_la/core/services/directions_service.dart';
import 'package:avisa_la/core/utils/distance_calculator.dart';
import 'dart:async';

class TripMonitoringPage extends StatefulWidget {
  final Destination destination;
  final double alertDistance;
  final bool useDynamicMode;
  final double alertTimeMinutes;

  const TripMonitoringPage({
    super.key,
    required this.destination,
    required this.alertDistance,
    required this.useDynamicMode,
    required this.alertTimeMinutes,
  });

  @override
  State<TripMonitoringPage> createState() => _TripMonitoringPageState();
}

class _TripMonitoringPageState extends State<TripMonitoringPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  double? _distanceToDestination;
  double? _currentSpeed;
  int? _estimatedTimeSeconds; // Tempo estimado simples (distância/velocidade)
  int? _realEstimatedTimeSeconds; // Tempo estimado real do Google Maps
  String _gpsQuality = 'Aguardando...';
  StreamSubscription<Position>? _positionStream;
  Timer? _directionsTimer;
  final Set<Marker> _markers = {};
  bool _isAppBarVisible = true;
  final ScrollController _scrollController = ScrollController();
  

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  Future<void> _startMonitoring() async {
    // start UI updates for monitoring (no local _isMonitoring flag needed)

    // Iniciar serviço em segundo plano
    await BackgroundService.startTrip(
      destination: widget.destination,
      alertDistance: widget.alertDistance,
      useDynamicMode: widget.useDynamicMode,
      alertTimeMinutes: widget.alertTimeMinutes,
    );

    // Se modo dinâmico estiver ativo, iniciar timer para atualizar tempo real
    if (widget.useDynamicMode) {
      _updateRealEstimatedTime(); // Atualizar imediatamente
      _directionsTimer = Timer.periodic(
        const Duration(seconds: 30), // Atualizar a cada 30 segundos
        (_) => _updateRealEstimatedTime(),
      );
    }

    // Iniciar stream de posição local para atualizar UI
    _positionStream = GeolocationService.getPositionStream().listen(
      (Position position) {
        setState(() {
          _currentPosition = position;
          _currentSpeed = GeolocationService.getSpeedMps(position);
          _gpsQuality = GeolocationService.getGpsQualityStatus(position);

          // Calcular distância
          _distanceToDestination = DistanceCalculator.calculateDistance(
            position.latitude,
            position.longitude,
            widget.destination.latitude,
            widget.destination.longitude,
          );

          // Estimar tempo de chegada - SEMPRE calcula, usando fallback quando necessário
          _estimatedTimeSeconds = DistanceCalculator.estimateArrivalTime(
            _distanceToDestination!,
            _currentSpeed ?? 0.0, // Usa 0 se velocidade for null, fallback será aplicado
          );

          _updateMarkers();
        });

        // Mover câmera para seguir usuário
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 16,
            ),
          ),
        );
      },
    );

    _updateMarkers();
  }

  void _updateMarkers() {
    _markers.clear();

    // Marcador de posição atual
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Você está aqui'),
        ),
      );
    }

    // Marcador de destino
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(
          widget.destination.latitude,
          widget.destination.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.destination.name),
      ),
    );
  }

  Future<void> _stopMonitoring() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Viagem?'),
        content: const Text('Tem certeza que deseja cancelar o monitoramento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cleanup();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _confirmArrival() async {
    await _cleanup();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Chegou ao Destino!'),
          content: const Text('Esperamos que tenha tido uma boa viagem!'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// Atualiza o tempo estimado real usando Google Maps Directions API
  Future<void> _updateRealEstimatedTime() async {
    if (_currentPosition == null) return;

    final timeSeconds = await DirectionsService.getEstimatedTimeToDestination(
      originLat: _currentPosition!.latitude,
      originLng: _currentPosition!.longitude,
      destLat: widget.destination.latitude,
      destLng: widget.destination.longitude,
    );

    if (timeSeconds != null && mounted) {
      setState(() {
        _realEstimatedTimeSeconds = timeSeconds;
      });
    }
  }

    Future<void> _cleanup() async {
    // stop UI monitoring updates
    _positionStream?.cancel();
    _directionsTimer?.cancel();
    await BackgroundService.stopTrip();
    await NotificationService.cancelAllNotifications();
  }

  Color _getDistanceColor() {
    if (_distanceToDestination == null) return Colors.grey;
    if (_distanceToDestination! <= widget.alertDistance) return Colors.red;
    if (_distanceToDestination! <= widget.alertDistance * 2) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _stopMonitoring();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Monitorando Viagem'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _stopMonitoring,
          ),
        ),
        body: Stack(
          children: [
            // Mapa
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.destination.latitude,
                  widget.destination.longitude,
                ),
                zoom: 14,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _updateMarkers();
              },
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
            ),

            // Card de status
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.destination.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Distância',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _distanceToDestination != null
                                    ? DistanceCalculator.formatDistance(
                                        _distanceToDestination!)
                                    : '---',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _getDistanceColor(),
                                ),
                              ),
                            ],
                          ),
                          if (_estimatedTimeSeconds != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tempo Estimado',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DistanceCalculator.formatTime(
                                      _estimatedTimeSeconds!),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.gps_fixed,
                            size: 16,
                            color: _gpsQuality == 'Excelente' ||
                                    _gpsQuality == 'Bom'
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'GPS: $_gpsQuality',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (_currentSpeed != null)
                            Text(
                              'Velocidade: ${(_currentSpeed! * 3.6).toStringAsFixed(1)} km/h',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Botões de ação
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_distanceToDestination != null &&
                      _distanceToDestination! <= widget.alertDistance)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _confirmArrival,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            '✅ Cheguei ao Destino',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _stopMonitoring,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Cancelar Viagem',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cleanup();
    _mapController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

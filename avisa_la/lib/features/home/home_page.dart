import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:avisa_la/core/models/destination.dart';
import 'package:avisa_la/core/services/geolocation_service.dart';
import 'package:avisa_la/core/services/permission_service.dart';
import 'package:avisa_la/core/utils/constants.dart';
import 'package:avisa_la/features/search/destination_search_page.dart';
import 'package:avisa_la/features/trip_monitoring/trip_monitoring_page.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Destination? _selectedDestination;
  double _alertDistance = AppConstants.defaultAlertDistance;
  bool _useDynamicMode = false;
  double _alertTimeMinutes = 5.0; // Tempo de alerta em minutos (para modo dinâmico)
  bool _isLoadingLocation = true;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    final serviceEnabled = await GeolocationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Serviço de localização desabilitado');
      setState(() => _isLoadingLocation = false);
      return;
    }

    final position = await GeolocationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // Mover câmera para posição atual
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        ),
      );
    } else {
      setState(() => _isLoadingLocation = false);
      _showError('Não foi possível obter sua localização');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _searchDestination() async {
    final destination = await Navigator.push<Destination>(
      context,
      MaterialPageRoute(
        builder: (context) => DestinationSearchPage(
          currentPosition: _currentPosition,
        ),
      ),
    );

    if (destination != null) {
      setState(() {
        _selectedDestination = destination;
        _updateMarkers();
      });

      // Mover câmera para mostrar ambos os pontos
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              _currentPosition!.latitude < destination.latitude
                  ? _currentPosition!.latitude
                  : destination.latitude,
              _currentPosition!.longitude < destination.longitude
                  ? _currentPosition!.longitude
                  : destination.longitude,
            ),
            northeast: LatLng(
              _currentPosition!.latitude > destination.latitude
                  ? _currentPosition!.latitude
                  : destination.latitude,
              _currentPosition!.longitude > destination.longitude
                  ? _currentPosition!.longitude
                  : destination.longitude,
            ),
          ),
          100,
        ),
      );
    }
  }

  void _updateMarkers() {
    _markers.clear();

    // Marcador de posição atual
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Você está aqui'),
        ),
      );
    }

    // Marcador de destino
    if (_selectedDestination != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(
            _selectedDestination!.latitude,
            _selectedDestination!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: _selectedDestination!.name),
        ),
      );
    }
  }

  Future<void> _startTrip() async {
    if (_selectedDestination == null) {
      _showError('Selecione um destino primeiro');
      return;
    }

    // Verificar permissão de localização em segundo plano
    final hasBackgroundPermission =
        await PermissionService.hasBackgroundLocationPermission();

    if (!hasBackgroundPermission) {
      final granted = await PermissionService.requestPhase2Permissions(context);
      if (!granted) {
        _showError('Permissão de localização em segundo plano é necessária');
        return;
      }
    }

    // Navegar para tela de monitoramento
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripMonitoringPage(
            destination: _selectedDestination!,
            alertDistance: _alertDistance,
            useDynamicMode: _useDynamicMode,
            alertTimeMinutes: _alertTimeMinutes,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisa Lá'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _loadCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          _currentPosition == null
              ? Center(
                  child: _isLoadingLocation
                      ? const CircularProgressIndicator()
                      : const Text('Não foi possível obter localização'),
                )
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _updateMarkers();
                  },
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),

          // Barra de busca flutuante
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _searchDestination,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDestination?.name ?? 'Para onde você vai?',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDestination != null
                              ? Colors.black
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Card de destino selecionado
          if (_selectedDestination != null)
            Positioned(
              bottom: 16,
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedDestination!.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedDestination!.address,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedDestination = null;
                                _updateMarkers();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Distância de alerta:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Slider(
                        value: _alertDistance,
                        min: 200,
                        max: 1000,
                        divisions: 8,
                        label: '${_alertDistance.round()}m',
                        onChanged: (value) {
                          setState(() => _alertDistance = value);
                        },
                      ),
                      Text(
                        'Alerta ${_alertDistance.round()}m antes do destino',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Modo Dinâmico (Tempo)'),
                        subtitle: const Text(
                          'Alertar também baseado no tempo estimado',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _useDynamicMode,
                        onChanged: (value) {
                          setState(() => _useDynamicMode = value);
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      // Slider de tempo (aparece quando modo dinâmico está ativo)
                      if (_useDynamicMode) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Tempo de alerta:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Slider(
                          value: _alertTimeMinutes,
                          min: 1,
                          max: 30,
                          divisions: 29,
                          label: '${_alertTimeMinutes.round()} min',
                          onChanged: (value) {
                            setState(() => _alertTimeMinutes = value);
                          },
                        ),
                        Text(
                          'Alerta ${_alertTimeMinutes.round()} minutos antes do destino',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _startTrip,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Iniciar Viagem',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

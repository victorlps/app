import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:avisa_la/core/models/destination.dart';
import 'package:avisa_la/core/utils/constants.dart';
import 'package:geolocator/geolocator.dart';

class DestinationSearchPage extends StatefulWidget {
  final Position? currentPosition;

  const DestinationSearchPage({super.key, this.currentPosition});

  @override
  State<DestinationSearchPage> createState() => _DestinationSearchPageState();
}

class _DestinationSearchPageState extends State<DestinationSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Destination> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() => _suggestions.clear());
      return;
    }

    if (_searchController.text.length < 3) return;

    _searchPlaces(_searchController.text);
  }

  Future<void> _searchPlaces(String query) async {
    setState(() => _isLoading = true);

    try {
      // Construir URL para Google Places Autocomplete API
      final String location = widget.currentPosition != null
          ? '${widget.currentPosition!.latitude},${widget.currentPosition!.longitude}'
          : '';

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&key=${AppConstants.googleMapsApiKey}'
        '&language=pt-BR'
        '${location.isNotEmpty ? '&location=$location&radius=50000' : ''}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;

          // Para cada predição, buscar detalhes para obter coordenadas
          List<Destination> destinations = [];

          for (var prediction in predictions.take(5)) {
            final placeId = prediction['place_id'];
            final destination = await _getPlaceDetails(placeId);
            if (destination != null) {
              destinations.add(destination);
            }
          }

          setState(() {
            _suggestions = destinations;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          _showError('Erro na busca: ${data['status']}');
        }
      } else {
        setState(() => _isLoading = false);
        _showError('Erro na conexão');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erro: $e');
    }
  }

  Future<Destination?> _getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=name,formatted_address,geometry'
        '&key=${AppConstants.googleMapsApiKey}'
        '&language=pt-BR',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'];
          final geometry = result['geometry']['location'];

          return Destination(
            name: result['name'] ?? '',
            address: result['formatted_address'] ?? '',
            latitude: geometry['lat'],
            longitude: geometry['lng'],
            placeId: placeId,
          );
        }
      }
    } catch (e) {
      print('Erro ao buscar detalhes do lugar: $e');
    }

    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _selectDestination(Destination destination) {
    Navigator.pop(context, destination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar destino...',
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _suggestions.clear());
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _suggestions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Digite o nome do lugar ou endereço'
                            : 'Nenhum resultado encontrado',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final destination = _suggestions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(destination.name),
                      subtitle: Text(
                        destination.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _selectDestination(destination),
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

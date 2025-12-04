import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
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
  final FocusNode _focusNode = FocusNode();
  List<PlacePrediction> _predictions = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Focar automaticamente no campo de busca quando a tela abre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _searchPlaces(_searchController.text);
      } else {
        setState(() {
          _predictions = [];
        });
      }
    });
  }

  Future<void> _searchPlaces(String input) async {
    if (input.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // Using new Places API (New)
      final url = Uri.parse(
        'https://places.googleapis.com/v1/places:autocomplete',
      );

      final body = {
        'input': input,
        'languageCode': 'pt-BR',
        'includedRegionCodes': ['BR'],
      };

      if (widget.currentPosition != null) {
        body['locationBias'] = {
          'circle': {
            'center': {
              'latitude': widget.currentPosition!.latitude,
              'longitude': widget.currentPosition!.longitude,
            },
            'radius': 50000.0,
          }
        };
      }

      print('🔍 Autocomplete Request URL: $url');
      print('🔍 Request Body: ${json.encode(body)}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': AppConstants.googleMapsApiKey,
          'X-Android-Package': 'com.example.avisa_la',
          'X-Android-Cert': '923C592BB5B6F767B0225CB3B75205CA5A43D0A3',
        },
        body: json.encode(body),
      );
      
      print('🔍 Response Status: ${response.statusCode}');
      print('🔍 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['suggestions'] != null && mounted) {
          setState(() {
            _predictions = (data['suggestions'] as List)
                .map((s) => PlacePrediction.fromNewApi(s))
                .toList();
          });
          print('✅ Found ${_predictions.length} predictions');
        } else {
          setState(() {
            _predictions = [];
          });
          print('⚠️ Zero results');
        }
      } else {
        final data = json.decode(response.body);
        final errorMsg = data['error']?['message'] ?? 'Erro desconhecido';
        print('❌ API Error: $errorMsg');
        _showError('Erro na busca: $errorMsg');
      }
    } catch (e) {
      _showError('Erro ao buscar lugares: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    try {
      // Using new Places API (New)
      final url = Uri.parse(
        'https://places.googleapis.com/v1/places/$placeId',
      );

      print('📍 Place Details Request URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': AppConstants.googleMapsApiKey,
          'X-Goog-FieldMask': 'id,displayName,formattedAddress,location',
          'X-Android-Package': 'com.example.avisa_la',
          'X-Android-Cert': '923C592BB5B6F767B0225CB3B75205CA5A43D0A3',
        },
      );
      
      print('📍 Response Status: ${response.statusCode}');
      print('📍 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (mounted) {
          final displayName = data['displayName'];
          final location = data['location'];

          final destination = Destination(
            name: displayName?['text'] ?? '',
            address: data['formattedAddress'] ?? '',
            latitude: location['latitude'],
            longitude: location['longitude'],
            placeId: placeId,
          );
          print('✅ Place details retrieved successfully');
          Navigator.pop(context, destination);
        }
      } else {
        final data = json.decode(response.body);
        final errorMsg = data['error']?['message'] ?? 'Erro desconhecido';
        print('❌ Place Details API Error: $errorMsg');
        _showError('Erro ao obter detalhes: $errorMsg');
      }
    } catch (e) {
      print('❌ Exception in _getPlaceDetails: $e');
      _showError('Erro ao buscar detalhes do lugar: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Destino'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Digite o endereço ou local...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _predictions = [];
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Digite para buscar um local',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_predictions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum resultado encontrado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _predictions.length,
      itemBuilder: (context, index) {
        final prediction = _predictions[index];
        return ListTile(
          leading: const Icon(Icons.location_on),
          title: Text(prediction.mainText),
          subtitle: Text(prediction.secondaryText),
          onTap: () => _getPlaceDetails(prediction.placeId),
        );
      },
    );
  }
}

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] as Map<String, dynamic>?;
    return PlacePrediction(
      placeId: json['place_id'] as String,
      description: json['description'] as String,
      mainText: structuredFormatting?['main_text'] as String? ?? json['description'] as String,
      secondaryText: structuredFormatting?['secondary_text'] as String? ?? '',
    );
  }

  // Factory para a nova Places API (New)
  factory PlacePrediction.fromNewApi(Map<String, dynamic> json) {
    final placePrediction = json['placePrediction'] as Map<String, dynamic>?;
    final text = placePrediction?['text'] as Map<String, dynamic>?;
    final structuredFormat = placePrediction?['structuredFormat'] as Map<String, dynamic>?;
    final mainText = structuredFormat?['mainText'] as Map<String, dynamic>?;
    final secondaryText = structuredFormat?['secondaryText'] as Map<String, dynamic>?;
    
    return PlacePrediction(
      placeId: placePrediction?['placeId'] as String? ?? '',
      description: text?['text'] as String? ?? '',
      mainText: mainText?['text'] as String? ?? text?['text'] as String? ?? '',
      secondaryText: secondaryText?['text'] as String? ?? '',
    );
  }
}

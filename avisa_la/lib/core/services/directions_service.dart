import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:avisa_la/core/utils/constants.dart';

class DirectionsService {
  /// Calcula o tempo estimado de chegada usando Google Maps Routes API (New)
  /// Retorna o tempo em segundos, ou null se houver erro
  static Future<int?> getEstimatedTimeToDestination({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final url = Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes');

      final body = json.encode({
        'origin': {
          'location': {
            'latLng': {
              'latitude': originLat,
              'longitude': originLng,
            }
          }
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': destLat,
              'longitude': destLng,
            }
          }
        },
        'travelMode': 'DRIVE',
        'languageCode': 'pt-BR',
      });

      print('🗺️ Routes API (New) Request');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': AppConstants.googleMapsApiKey,
          'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          // duration vem como string "1234s"
          final durationStr = route['duration'] as String;
          final durationSeconds = int.parse(durationStr.replaceAll('s', ''));
          
          print('✅ Tempo estimado (Routes API): ${durationSeconds}s (${(durationSeconds / 60).toStringAsFixed(1)} min)');
          
          return durationSeconds;
        } else {
          print('⚠️ Routes API: Nenhuma rota encontrada');
          return null;
        }
      } else {
        print('❌ Erro na Routes API: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao calcular tempo estimado: $e');
      return null;
    }
  }

  /// Calcula a distância estimada usando Google Maps Routes API (New)
  /// Retorna a distância em metros, ou null se houver erro
  static Future<double?> getEstimatedDistance({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final url = Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes');

      final body = json.encode({
        'origin': {
          'location': {
            'latLng': {
              'latitude': originLat,
              'longitude': originLng,
            }
          }
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': destLat,
              'longitude': destLng,
            }
          }
        },
        'travelMode': 'DRIVE',
        'languageCode': 'pt-BR',
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': AppConstants.googleMapsApiKey,
          'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final distanceMeters = (route['distanceMeters'] as int).toDouble();
          
          print('✅ Distância estimada: ${distanceMeters}m (${(distanceMeters / 1000).toStringAsFixed(1)} km)');
          
          return distanceMeters;
        } else {
          print('⚠️ Directions API retornou status: ${data['status']}');
          return null;
        }
      } else {
        print('❌ Erro na Directions API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao calcular distância estimada: $e');
      return null;
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:avisa_la/core/utils/constants.dart';

class DirectionsService {
  /// Faz uma requisição para a Routes API (New) do Google Maps
  /// [fieldMask] define quais campos retornar
  static Future<Map<String, dynamic>?> _makeRoutesApiRequest({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String fieldMask,
  }) async {
    try {
      final url = Uri.parse(
          'https://routes.googleapis.com/directions/v2:computeRoutes');

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
          'X-Goog-FieldMask': fieldMask,
          'X-Android-Package': AppConstants.androidPackageName,
          'X-Android-Cert': AppConstants.androidCertificateSHA1,
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          return data['routes'][0];
        } else {
          print('⚠️ Routes API: Nenhuma rota encontrada');
          return null;
        }
      } else {
        print(
            '❌ Erro na Routes API: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Erro na Routes API: $e');
      return null;
    }
  }

  /// Calcula o tempo estimado de chegada usando Google Maps Routes API (New)
  /// Retorna o tempo em segundos, ou null se houver erro
  static Future<int?> getEstimatedTimeToDestination({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    print('🗺️ Routes API (New) Request - Tempo');

    final route = await _makeRoutesApiRequest(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
      fieldMask: 'routes.duration,routes.distanceMeters',
    );

    if (route != null) {
      // duration vem como string "1234s"
      final durationStr = route['duration'] as String;
      final durationSeconds = int.parse(durationStr.replaceAll('s', ''));

      print(
          '✅ Tempo estimado (Routes API): ${durationSeconds}s (${(durationSeconds / 60).toStringAsFixed(1)} min)');

      return durationSeconds;
    }

    return null;
  }

  /// Obtém os pontos da rota (polyline) usando Google Maps Routes API (New)
  /// Retorna lista de LatLng, ou null se houver erro
  static Future<List<Map<String, double>>?> getRoutePolyline({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    print('🗺️ Routes API (New) Request - Polyline');

    final route = await _makeRoutesApiRequest(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
      fieldMask: 'routes.polyline.encodedPolyline',
    );

    if (route != null) {
      final encodedPolyline = route['polyline']['encodedPolyline'] as String;

      // Decodifica o polyline
      final points = _decodePolyline(encodedPolyline);

      print('✅ Rota obtida com ${points.length} pontos');

      return points;
    }

    return null;
  }

  /// Decodifica encoded polyline do Google Maps
  static List<Map<String, double>> _decodePolyline(String encoded) {
    List<Map<String, double>> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add({
        'latitude': lat / 1E5,
        'longitude': lng / 1E5,
      });
    }

    return points;
  }

  /// Calcula a distância estimada usando Google Maps Routes API (New)
  /// Retorna a distância em metros, ou null se houver erro
  static Future<double?> getEstimatedDistance({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    print('🗺️ Routes API (New) Request - Distância');

    final route = await _makeRoutesApiRequest(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
      fieldMask: 'routes.distanceMeters',
    );

    if (route != null) {
      final distanceMeters = (route['distanceMeters'] as int).toDouble();

      print(
          '✅ Distância estimada: ${distanceMeters}m (${(distanceMeters / 1000).toStringAsFixed(1)} km)');

      return distanceMeters;
    }

    return null;
  }
}

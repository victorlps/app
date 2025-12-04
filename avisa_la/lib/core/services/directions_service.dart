import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:avisa_la/core/utils/constants.dart';

class DirectionsService {
  /// Calcula o tempo estimado de chegada usando Google Maps Directions API
  /// Retorna o tempo em segundos, ou null se houver erro
  static Future<int?> getEstimatedTimeToDestination({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$originLat,$originLng'
        '&destination=$destLat,$destLng'
        '&mode=driving'
        '&language=pt-BR'
        '&key=${AppConstants.googleMapsApiKey}',
      );

      print('🗺️ Directions API Request: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          final durationSeconds = leg['duration']['value'] as int;
          
          print('✅ Tempo estimado: ${durationSeconds}s (${(durationSeconds / 60).toStringAsFixed(1)} min)');
          
          return durationSeconds;
        } else {
          print('⚠️ Directions API retornou status: ${data['status']}');
          return null;
        }
      } else {
        print('❌ Erro na Directions API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao calcular tempo estimado: $e');
      return null;
    }
  }

  /// Calcula a distância estimada usando Google Maps Directions API
  /// Retorna a distância em metros, ou null se houver erro
  static Future<double?> getEstimatedDistance({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$originLat,$originLng'
        '&destination=$destLat,$destLng'
        '&mode=driving'
        '&language=pt-BR'
        '&key=${AppConstants.googleMapsApiKey}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          final distanceMeters = (leg['distance']['value'] as int).toDouble();
          
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

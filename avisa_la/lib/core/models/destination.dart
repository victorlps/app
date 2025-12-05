@pragma('vm:entry-point')
class Destination {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String placeId;

  Destination({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.placeId,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      placeId: json['placeId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
    };
  }

  @override
  String toString() {
    return 'Destination(name: $name, address: $address, lat: $latitude, lng: $longitude)';
  }
}

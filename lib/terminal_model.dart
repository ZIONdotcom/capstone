import 'package:google_maps_flutter/google_maps_flutter.dart';

class Terminal {
  final int id;
  final String name;
  final double latitude; // x_coordinate in DB
  final double longitude; // y_coordinate in DB

  Terminal({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory Terminal.fromJson(Map<String, dynamic> json) {
    return Terminal(
      id: int.tryParse(json['terminal_id'].toString()) ?? 0,
      name: json['terminal_name'],
      latitude: double.tryParse(json['x_coordinate'].toString()) ??
          0.0, // Convert x_coordinate to double
      longitude: double.tryParse(json['y_coordinate'].toString()) ??
          0.0, // Convert y_coordinate to double
    );
  }
}

class RouteSuggest {
  final int franchiseID;
  final LatLng pointA;
  final LatLng pointB;
  final List<LatLng> waypoints;
  final List<LatLng> routeCoordinates;

  RouteSuggest({
    required this.franchiseID,
    required this.pointA,
    required this.pointB,
    required this.waypoints,
    required this.routeCoordinates,
  });

  factory RouteSuggest.fromJson(Map<String, dynamic> json) {
    return RouteSuggest(
      franchiseID: int.parse(json['franchise_ID']),
      pointA: LatLng(
        double.parse(json['point_A']['x']),
        double.parse(json['point_A']['y']),
      ),
      pointB: LatLng(
        double.parse(json['point_B']['x']),
        double.parse(json['point_B']['y']),
      ),
      routeCoordinates: [],
      waypoints: (json['waypoints'] as List<dynamic>).map((wp) {
        return LatLng(
          double.parse(wp['latitude']),
          double.parse(wp['longitude']),
        );
      }).toList(),
    );
  }
}

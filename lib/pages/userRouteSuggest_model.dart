import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteSuggestionUser {
  final int id;
  final String name;
  final bool isVisible;
  final int status;
  final LatLng origin;
  final LatLng destination;
  final int popularityNumber;
  final List<StepUser> steps;

  RouteSuggestionUser({
    required this.id,
    required this.name,
    required this.isVisible,
    required this.status,
    required this.origin,
    required this.destination,
    required this.popularityNumber,
    required this.steps,
  });

  factory RouteSuggestionUser.fromJson(Map<String, dynamic> json) {
    return RouteSuggestionUser(
      id: int.parse(json['route_suggestion_id']),
      name: json['route_suggestion_name'],
      isVisible: json['isVisible'],
      status: int.parse(json['status']),
      origin: LatLng(json['origin']['x_coordinate'].toDouble(),
          json['origin']['y_coordinate'].toDouble()),
// getOnCoordinates: LatLng(
//         json['get_on']['x_coordinate'].toDouble(),
//         json['get_on']['y_coordinate'].toDouble(),
//       ),

      destination: LatLng(json['destination']['x_coordinate'].toDouble(),
          json['destination']['y_coordinate'].toDouble()),
      popularityNumber: int.parse(json['popularitynumber']),
      steps: (json['steps'] as List)
          .map((step) => StepUser.fromJson(step))
          .toList(),
    );
  }
}

class StepUser {
  final int id;
  final int sequence;
  final int transportationId;
  final String transportationName;
  final LatLng getOnCoordinates;
  final LatLng getOffCoordinates;
  double travelTime;
  final double fare;
  final String instructions;
  final List<PolylinePointUser> polylinePoints;
  List<LatLng> polylineCoordinates;

  StepUser({
    required this.id,
    required this.sequence,
    required this.transportationId,
    required this.transportationName,
    required this.getOnCoordinates,
    required this.getOffCoordinates,
    required this.travelTime,
    required this.fare,
    required this.instructions,
    required this.polylinePoints,
    required this.polylineCoordinates,
  });

  factory StepUser.fromJson(Map<String, dynamic> json) {
    return StepUser(
      id: int.parse(json['step_id']),
      sequence: int.parse(json['sequence']),
      transportationId: int.parse(json['transportation_id']),
      transportationName: json['transportation_name'],
      getOnCoordinates: LatLng(
        json['get_on']['x_coordinate'].toDouble(),
        json['get_on']['y_coordinate'].toDouble(),
      ),
      getOffCoordinates: LatLng(
        json['get_off']['x_coordinate'].toDouble(),
        json['get_off']['y_coordinate'].toDouble(),
      ),
      travelTime: json['travel_time']?.toDouble() ?? 0.0,
      fare: json['fare']?.toDouble() ?? 0.0,
      instructions: json['instructions'] ?? '',
      polylinePoints: (json['polyline_points'] as List)
          .map((point) => PolylinePointUser.fromJson(point))
          .toList(),
      polylineCoordinates: [],
    );
  }
}

class LocationCoordinates {
  final int id;
  final double xCoordinate;
  final double yCoordinate;

  LocationCoordinates({
    required this.id,
    required this.xCoordinate,
    required this.yCoordinate,
  });

  factory LocationCoordinates.fromJson(Map<String, dynamic> json) {
    return LocationCoordinates(
      id: json['id'],
      xCoordinate: json['x_coordinate'].toDouble(),
      yCoordinate: json['y_coordinate'].toDouble(),
    );
  }
}

class PolylinePointUser {
  final double xCoordinate;
  final double yCoordinate;
  final int sequence;

  PolylinePointUser({
    required this.xCoordinate,
    required this.yCoordinate,
    required this.sequence,
  });

  factory PolylinePointUser.fromJson(Map<String, dynamic> json) {
    return PolylinePointUser(
      xCoordinate: json['x_coordinate'].toDouble(),
      yCoordinate: json['y_coordinate'].toDouble(),
      sequence: int.parse(json['sequence']),
    );
  }
}

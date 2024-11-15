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
  final int terminalID;
  final int transportationID;

  RouteSuggest(
      {required this.franchiseID,
      required this.pointA,
      required this.pointB,
      required this.waypoints,
      required this.routeCoordinates,
      required this.terminalID,
      required this.transportationID});

  // Override toString method to display custom information
  @override
  String toString() {
    return 'RouteSuggest(franchiseID: $franchiseID, pointA: $pointA, waypoints: $waypoints, pointB: $pointB, routeCoordinates: $routeCoordinates, terminalID: $terminalID, terminalID: $terminalID, )';
  }

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
      terminalID: int.parse(json['terminal_id']),
      transportationID: int.parse(json['transportation_id']),
    );
  }
}

class TransferOption {
  final RouteSuggest originRoute;
  final RouteSuggest destinationRoute;
  final Terminal?
      transferTerminal; // Set to null if the transfer point is an overlap instead of a terminal
  final LatLng?
      transferPoint; // For overlapping segments, if no terminal is available

  TransferOption({
    required this.originRoute,
    required this.destinationRoute,
    this.transferTerminal,
    this.transferPoint,
  });

  bool get hasTerminalTransfer => transferTerminal != null;
}

// transferpoint V2
class TransferPoint {
  final RouteSuggest fromRoute;
  final RouteSuggest toRoute;
  final LatLng transferLocation;
  final String transferType;

  TransferPoint({
    required this.fromRoute,
    required this.toRoute,
    required this.transferLocation,
    required this.transferType,
  });
}

class TerminalPath {
  final Terminal terminal;
  final List<LatLng> path; // Store the route coordinates

  TerminalPath(
      this.terminal, this.path); // Constructor to initialize both values
}

class Node {
  final String id;
  final LatLng position;
  double gScore = double.infinity; // Cost from start to this node
  double fScore = double.infinity; // Estimated cost from start to goal
  Node? cameFrom;

  Node(this.id, this.position);
}

class Edge {
  final Node source;
  final Node destination;
  int travelTime; // Real-time travel time for this edge

  Edge(this.source, this.destination, this.travelTime);
}

class PathDetail {
  final int franchiseId; // Unique identifier for the franchise (e.g., Route ID)
  final String routeName; // Name of the route
  final List<String> stops; // List of stops for the route
  final String estimatedTime; // Estimated time for the route
  final double distance; // Total distance of the route
  final double fare; // Fare for the route

  // Constructor to initialize the properties
  PathDetail({
    required this.franchiseId,
    required this.routeName,
    required this.stops,
    required this.estimatedTime,
    required this.distance,
    required this.fare,
  });

  // Factory method to create a PathDetail instance from a JSON map
  factory PathDetail.fromJson(Map<String, dynamic> json) {
    return PathDetail(
      franchiseId: json['franchiseId'],
      routeName: json['routeName'],
      stops: List<String>.from(json['stops']),
      estimatedTime: json['estimatedTime'],
      distance: json['distance'].toDouble(),
      fare: json['fare'].toDouble(),
    );
  }

  // Method to convert the PathDetail instance into a JSON map
  Map<String, dynamic> toJson() {
    return {
      'franchiseId': franchiseId,
      'routeName': routeName,
      'stops': stops,
      'estimatedTime': estimatedTime,
      'distance': distance,
      'fare': fare,
    };
  }
}

//steps fr

class TransferStep {
  String transportType;
  String fromLocationName;
  String toLocationName;
  LatLng fromLocationLatLng;
  LatLng toLocationLatLng;
  double fare;
  double travelTime; // in hours

  TransferStep({
    required this.transportType,
    required this.fromLocationName,
    required this.toLocationName,
    required this.fromLocationLatLng,
    required this.toLocationLatLng,
    required this.fare,
    required this.travelTime,
  });
}

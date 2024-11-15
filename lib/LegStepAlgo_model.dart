import 'package:google_maps_flutter/google_maps_flutter.dart';

class Leg {
  final int legID;
  final String transportationName;
  final int totalFare;
  final String timeTravelMinutes;

  Leg({
    required this.legID,
    required this.transportationName,
    required this.totalFare,
    required this.timeTravelMinutes,
  });
}

class Steps {
  final String transportationName;
  final double fare;
  final int time;
  final String getOnPoint;
  final String getOffPoint;
  final String route;

  Steps({
    required this.transportationName,
    required this.fare,
    required this.time,
    required this.getOnPoint,
    required this.getOffPoint,
    required this.route,
  });
}

class TransportationInfo {
  final String transportationName;
  final double minimumFare;
  final String pointA;
  final String pointB;

  TransportationInfo({
    required this.transportationName,
    required this.minimumFare,
    required this.pointA,
    required this.pointB,
  });

  factory TransportationInfo.fromJson(Map<String, dynamic> json) {
    return TransportationInfo(
      transportationName: json['transportation_name'],
      minimumFare: double.parse(json['regular_fare'].toString()),
      pointA: json['point_A'],
      pointB: json['point_B'],
    );
  }
}

class RouteDetail {
  final int franchiseId;
  final String transportationName;
  final double regularFare;
  final double discountedFare;
  final double perKMfare;
  final String pointA;
  final String pointB;
  final int terminalId;

  RouteDetail({
    required this.franchiseId,
    required this.transportationName,
    required this.regularFare,
    required this.discountedFare,
    required this.perKMfare,
    required this.pointA,
    required this.pointB,
    required this.terminalId,
  });

  factory RouteDetail.fromJson(Map<String, dynamic> json) {
    return RouteDetail(
      franchiseId: json['franchise_id'],
      transportationName: json['transportation_name'],
      regularFare: double.parse(json['regular_fare'].toString()),
      discountedFare: double.parse(json['discounted_fare'].toString()),
      perKMfare: double.parse(json['add_rate_KM'].toString()),
      pointA: json['point_A'],
      pointB: json['point_B'],
      terminalId: int.parse(json['terminal_id'].toString()),
    );
  }
}

class CombinedRouteData {
  final int franchiseID;
  final LatLng pointA;
  final LatLng pointB;
  final List<LatLng> waypoints;
  final List<LatLng> routeCoordinates;
  final int terminalID;
  final int transportationID;
  final String transportationName;
  final double regularFare;
  final double discountedFare;
  final double perKMfare;
  // final double traveledDistance;

  CombinedRouteData({
    required this.franchiseID,
    required this.pointA,
    required this.pointB,
    required this.waypoints,
    required this.routeCoordinates,
    required this.terminalID,
    required this.transportationID,
    required this.transportationName,
    required this.regularFare,
    required this.discountedFare,
    required this.perKMfare,
    //required this.traveledDistance,
  });
}

class PathDetail1 {
  final List<String> transportationNames;
  final double totalFare;
  final String franchisePath;
  final double totalTimeForPath;

  PathDetail1({
    required this.transportationNames,
    required this.totalFare,
    required this.franchisePath,
    required this.totalTimeForPath,
  });
}

class SegmentDetails {
  final String transportationName;
  final double traveledDistance;
  final double fare;
  final double timeTraveled;

  SegmentDetails({
    required this.transportationName,
    required this.traveledDistance,
    required this.fare,
    required this.timeTraveled,
  });
}

class TravelStep {
  final String transportationName; // Name of the transport
  final double travelTime; // Time taken for this step (in hours)
  final LatLng
      babaanLocation; // Location of the 'babaan' (end of this transport)
  final String babaanPlaceName; // Name of the 'babaan' place
  final LatLng
      sakayanLocation; // Location of the 'sakayan' (next transport start)
  final String sakayanPlaceName; // Name of the 'sakayan' place
  final String
      routeName; // The name of the transport route (Point A to Point B)
  final double fare;
  final double travelDistance; // Fare for this travel step
  final List<LatLng> routePoints;

  TravelStep({
    required this.transportationName,
    required this.travelTime,
    required this.babaanLocation,
    required this.babaanPlaceName,
    required this.sakayanLocation,
    required this.sakayanPlaceName,
    required this.routeName,
    required this.fare,
    required this.travelDistance,
    required this.routePoints,
  });
}

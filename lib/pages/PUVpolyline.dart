import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PolylineWithWaypoints extends StatefulWidget {
  @override
  _PolylineWithWaypointsState createState() => _PolylineWithWaypointsState();
}

class _PolylineWithWaypointsState extends State<PolylineWithWaypoints> {
  late GoogleMapController _mapController;
  Set<Polyline> _polylines = {};
  List<LatLng> _routeCoordinates = [];
  late LatLng _pointA;
  late LatLng _pointB;
  List<LatLng> _waypoints = [];

  @override
  void initState() {
    super.initState();
    _fetchRouteData(); // Call this method to fetch data from the database
  }

  Future<void> _fetchRouteData() async {
    final String url =
        'https://rutaco.online/routeFinderPhp/routePoints.php'; // Update this with your PHP file URL
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data.isNotEmpty) {
        for (int i = 0; i < data.length; i++) {
          final routeData = data[i];
          LatLng pointA = LatLng(
              double.parse(routeData['point_A']['x'].toString()),
              double.parse(routeData['point_A']['y'].toString()));
          LatLng pointB = LatLng(
              double.parse(routeData['point_B']['x'].toString()),
              double.parse(routeData['point_B']['y'].toString()));

          // Extract waypoints from the JSON data
          List<LatLng> waypoints = (routeData['waypoints'] as List)
              .map((wp) => LatLng(double.parse(wp['latitude'].toString()),
                  double.parse(wp['longitude'].toString())))
              .toList();

          await _drawRoute(
              pointA, pointB, waypoints, i); // Pass index as polyline ID
        }
      }
    } else {
      throw Exception('Failed to load route data');
    }
  }

  Future<void> _drawRoute(LatLng pointA, LatLng pointB, List<LatLng> waypoints,
      int routeIndex) async {
    List<LatLng> routeCoordinates =
        await _getRoutePoints(pointA, pointB, waypoints);

    // Print each coordinate in the console
    for (var coordinate in routeCoordinates) {
      print(
          "index: $routeIndex Coordinate: Latitude: ${coordinate.latitude}, Longitude: ${coordinate.longitude}");
    }

    Polyline routePolyline = Polyline(
      polylineId: PolylineId("route_$routeIndex"), // Unique ID for each route
      color: Colors.blue,
      width: 5,
      points: routeCoordinates,
    );

    setState(() {
      _polylines.add(routePolyline); // Add each polyline to the set
    });
  }

  Future<List<LatLng>> _getRoutePoints(
      LatLng start, LatLng end, List<LatLng> waypoints) async {
    String waypointsString = waypoints
        .map((point) => '${point.latitude},${point.longitude}')
        .join('|');
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&waypoints=$waypointsString&key=AIzaSyBcUDWZDnJBOX_Q5IOqDJi60RuqJy1-ZkY';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final route = data['routes'][0]['overview_polyline']['points'];
      return _decodePolyline(route);
    } else {
      throw Exception('Failed to load directions');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
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

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Polyline with Waypoints"),
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(14.8578124, 120.8064885),
          zoom: 6.0,
        ),
        polylines: _polylines,
      ),
    );
  }
}

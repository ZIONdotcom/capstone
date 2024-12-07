import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:capstone/model.dart';

// Receive the list of PolyPoints from a.dart
class MyWidget1 extends StatefulWidget {
  final List<PolyPoints> polyPointsList; // Add this to receive data
  const MyWidget1({super.key, required this.polyPointsList}); // Constructor
  @override
  State<MyWidget1> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget1> {
  final String apiKey = 'AIzaSyC88-Wkb5_LmPU5OCQwPOMDTry3RGh1J00';
  List<LatLng> polylinePoints = [];
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    // Iterate through the received list of PolyPoints
    for (var points in widget.polyPointsList) {
      _getRoute(points.origin, points.destination, points.polylinePoints);
    }
  }

  Future<void> _getRoute(
      LatLng orig, LatLng desti, List<LatLng> waypoints) async {
    String waypointsString =
        waypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|');
    final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${orig.latitude},${orig.longitude}&destination=${desti.latitude},${desti.longitude}&waypoints=$waypointsString&key=$apiKey'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final points =
          _decodePoly(data['routes'][0]['overview_polyline']['points']);
      setState(() {
        polylinePoints = points;
      });
    } else {
      throw Exception('Failed to load route');
    }
  }

  List<LatLng> _decodePoly(String poly) {
    List<LatLng> polyline = [];
    int index = 0;
    int len = poly.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = poly.codeUnitAt(index) - 63;
        index++;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = poly.codeUnitAt(index) - 63;
        index++;
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
      appBar: AppBar(title: const Text('Map with Directions')),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(14.827457, 120.892261),
          zoom: 16.0,
        ),
        polylines: {
          Polyline(
            polylineId: PolylineId('route_polyline'),
            points: polylinePoints,
            color: Colors.blue,
            width: 5,
          ),
        },
      ),
    );
  }
}

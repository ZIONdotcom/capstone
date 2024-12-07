import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late GoogleMapController _controller;
  final Set<Polyline> _polylines = {};
  final String apiKey = 'AIzaSyBcUDWZDnJBOX_Q5IOqDJi60RuqJy1-ZkY';

  @override
  void initState() {
    super.initState();
    _getRoute();
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    List<int> bytes = encoded.codeUnits;
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < bytes.length) {
      int result = 0;
      int shift = 0;
      int byte;
      do {
        byte = bytes[index] - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
        index++;
      } while (byte >= 0x20);

      int deltaLat = ((result & 0x01) != 0 ? ~(result >> 1) : (result >> 1));
      lat += deltaLat;

      result = 0;
      shift = 0;
      do {
        byte = bytes[index] - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
        index++;
      } while (byte >= 0x20);

      int deltaLng = ((result & 0x01) != 0 ? ~(result >> 1) : (result >> 1));
      lng += deltaLng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  Future<void> _getRoute() async {
    const start = LatLng(14.7538, 120.9553); // Example starting point
    const end = LatLng(14.96038166, 120.8903083); // Example ending point

    try {
      final polylineEncoded = await getRoutePolyline(start, end);
      final List<LatLng> polylinePoints = decodePolyline(polylineEncoded);

      setState(() {
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: Colors.blue,
          width: 5,
        ));
      });
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  // Future<String> getRoutePolyline(LatLng start, LatLng end) async {
  //   final url = Uri.parse(
  //     'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=AIzaSyBcUDWZDnJBOX_Q5IOqDJi60RuqJy1-ZkY',
  //   );

  //   final response = await http.get(url);
  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     if (data['routes'].isEmpty) {
  //       throw Exception('No routes found');
  //     }
  //     final polyline = data['routes'][0]['overview_polyline']['points'];
  //     return polyline;
  //   } else {
  //     throw Exception('Failed to load directions');
  //   }
  // }

  Future<String> getRoutePolyline(LatLng start, LatLng end) async {
    //       LatLng(14.762409, 120.947731),
    // LatLng(14.777073, 120.937665),
    // LatLng(14.791577, 120.932312),
    // LatLng(14.800592, 120.922940),
    // LatLng(14.828297, 120.881569),
    // LatLng(14.844308, 120.860134),
    // LatLng(14.879001, 120.864414),
    // LatLng(14.933965, 120.878478),
    // LatLng(14.945687, 120.882486),
    // LatLng(14.946343, 120.882721),
    const waypoints =
        '14.828185,120.877705|14.834249,120.864647|14.933965,120.878478'; // Example waypoints
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&waypoints=optimize:false|$waypoints&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'].isEmpty) {
        throw Exception('No routes found');
      }
      final polyline = data['routes'][0]['overview_polyline']['points'];
      return polyline;
    } else {
      throw Exception('Failed to load directions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map with Polyline')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(14.5995, 120.9842), // Initial map position
          zoom: 12,
        ),
        onMapCreated: (controller) {
          _controller = controller;
        },
        polylines: _polylines,
      ),
    );
  }
}

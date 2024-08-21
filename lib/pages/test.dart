import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class TransitMapScreen extends StatefulWidget {
  @override
  _TransitMapScreenState createState() => _TransitMapScreenState();
}

class _TransitMapScreenState extends State<TransitMapScreen> {
  GoogleMapController? _mapController;
  final String _apiKey = 'AIzaSyAnDp1NMv3WSsatCAjJL02Y_fL8a44L4NI';
  Set<Polyline> _polylines = {};
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  List<dynamic> _routes = [];
  List<dynamic> _selectedRouteSteps = [];
  String _selectedRouteInfo = '';

  Future<Map<String, dynamic>> getPublicTransitDirections(String origin, String destination, String apiKey) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=transit&key=$apiKey'
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load directions');
    }
  }

  void _getDirections() async {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter both origin and destination')));
      return;
    }

    try {
      final directions = await getPublicTransitDirections(
        _originController.text,
        _destinationController.text,
        _apiKey,
      );

      setState(() {
        _routes = directions['routes'];
        _selectedRouteSteps.clear();
        _selectedRouteInfo = '';
        _polylines.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching directions')));
    }
  }

  void _selectRoute(int index) {
    final selectedRoute = _routes[index];
    final legs = selectedRoute['legs'][0];
    final steps = legs['steps'];

    StringBuffer directionsBuffer = StringBuffer();

    for (var step in steps) {
      String travelMode = step['travel_mode'];
      String instructions = step['html_instructions'];
      directionsBuffer.write('$travelMode: $instructions\n\n');
    }

    setState(() {
      _selectedRouteSteps = steps;
      _selectedRouteInfo = directionsBuffer.toString();
      _polylines.clear();
      displayRouteOnMap(steps);
    });
  }

  void displayRouteOnMap(List<dynamic> steps) {
    List<LatLng> polylineCoordinates = [];

    for (var step in steps) {
      final startLocation = step['start_location'];
      final endLocation = step['end_location'];

      polylineCoordinates.add(LatLng(startLocation['lat'], startLocation['lng']));
      polylineCoordinates.add(LatLng(endLocation['lat'], endLocation['lng']));
    }

    setState(() {
      _polylines.add(Polyline(
        polylineId: PolylineId('transit_route'),
        points: polylineCoordinates,
        color: Colors.blue,
        width: 5,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Public Transit Directions'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _originController,
              decoration: InputDecoration(
                labelText: 'Origin',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                labelText: 'Destination',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_routes.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _routes.length,
                itemBuilder: (context, index) {
                  final route = _routes[index];
                  final legs = route['legs'][0];
                  final duration = legs['duration']['text'];
                  final distance = legs['distance']['text'];
                  return ListTile(
                    title: Text('Route ${index + 1}'),
                    subtitle: Text('Duration: $duration, Distance: $distance'),
                    onTap: () => _selectRoute(index),
                  );
                },
              ),
            ),
          if (_selectedRouteSteps.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _selectedRouteSteps.length,
                itemBuilder: (context, index) {
                  final step = _selectedRouteSteps[index];
                  String travelMode = step['travel_mode'];
                  String instructions = step['html_instructions'];
                  return ListTile(
                    title: Text('$travelMode'),
                    subtitle: Text(instructions),
                  );
                },
              ),
            ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                setState(() {
                  _mapController = controller;
                });
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(14.5995, 120.9842), // Example: Manila, Philippines
                zoom: 12,
              ),
              polylines: _polylines,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getDirections,
        child: Icon(Icons.search),
      ),
    );
  }
}

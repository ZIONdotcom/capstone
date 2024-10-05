import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:capstone/pages/travelPlan3.dart';

class Travelplanmap extends StatefulWidget {
  List<Map<String, String>> selectedLocations;

  Travelplanmap({super.key, required this.selectedLocations});

  @override
  State<Travelplanmap> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Travelplanmap> {
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  GoogleMapController? _controller;

  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(14.831582, 120.903786),
    zoom: 11.5,
  );

  final Set<Polyline> polyline = {};

  List<LatLng> points = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              onMapCreatedMarker(context);
            },
            markers: markers,
          ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            right: 16.0,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => travelPlan3()),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xff1F41BB),
                minimumSize: const Size(double.infinity, 40),
              ),
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }

  void onMapCreatedMarker(BuildContext context) {
    setState(() {
      // Adding markers on the map
      LatLng latlang;
      for (int i = 0; i < widget.selectedLocations.length; i++) {
        double latitude =
            double.parse(widget.selectedLocations[i]['latitude']!);
        double longitude =
            double.parse(widget.selectedLocations[i]['longitude']!);
        points.add(LatLng(latitude, longitude));
        latlang = LatLng(latitude, longitude);
        print('$latlang --------------------------------------------');

        markers.add(
          Marker(
            markerId: MarkerId(latlang.toString()),
            position: latlang,
            draggable: true, // Make marker draggable
            onDragEnd: (newPosition) {
              // Update the marker position when dragging ends
              setState(() {
                markers.removeWhere(
                    (m) => m.markerId == MarkerId(latlang.toString()));
                markers.add(
                  Marker(
                    markerId: MarkerId(latlang.toString()),
                    position: newPosition,
                    draggable: true, // Keep it draggable
                  ),
                );
              });
            },
          ),
        );
      }

      // Adding polyline on the map
      polyline.add(Polyline(
        polylineId: PolylineId('line'),
        points: [
          // LatLng(latitude, longitude), //start location
          // LatLng(latitude, longitude) //end location
        ],
        color: Colors.blue,
        width: 5,
      ));
    });
  }
}

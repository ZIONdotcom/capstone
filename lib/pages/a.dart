import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'b.dart';

//import model
import 'package:capstone/model.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  //method sa pag add ng data sa class-----------------------------------------------------
  // Store the list of PolyPoints
  List<PolyPoints> polyPointsList = [];

  void addToClass() {
    LatLng origin = LatLng(14.828073, 120.889548);
    LatLng destination = LatLng(14.829033, 120.890900);
    List<LatLng> polyline = [LatLng(14.828541, 120.890440)];

    final walkingStep = PolyPoints(
      id: 1,
      origin: origin,
      destination: destination,
      polylinePoints: polyline,
    );
//----------------------------------------another add (pwede namang iloop nalng para di isa isa HAHA)
    final ysa = PolyPoints(
      id: 2,
      origin: LatLng(14.826670, 120.895246),
      destination: LatLng(14.828903, 120.898030),
      polylinePoints: [
        LatLng(14.827502, 120.896252),
        LatLng(14.827874, 120.897449)
      ],
    );
    // Add these to the list
    polyPointsList = [walkingStep, ysa];
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    addToClass();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Map App"),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              addToClass();
              // Navigate to a new screen when button is pressed
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        MyWidget1(polyPointsList: polyPointsList)),
              );
            },
            child: const Text('Go to New Screen'),
          ),
          const Placeholder(), // Placeholder for Google Maps widget (you can replace this later with your actual map)
        ],
      ),
    );
  }
}

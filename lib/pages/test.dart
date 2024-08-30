import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

class test extends StatefulWidget {
  const test({super.key});

  @override
  State<test> createState() => _TravelPlan3State();
}

class _TravelPlan3State extends State<test> {
  GoogleMapController? _controller;

  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(14.831582, 120.903786),
    zoom: 11.5,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Google Map
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
            ),
          ),
          // Overlapping Container
          Positioned(
            top: 230, // Adjust this value for more or less overlap
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, -3.5), // Shadow offset upwards
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.topLeft,
                    padding:
                        const EdgeInsets.only(left: 30, top: 30, bottom: 30),
                    child: const Text(
                      'Routes',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  suggestRoute('jeep', '21', '4mins',
                      SvgPicture.asset('assets/icons/bus2.svg')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget suggestRoute(
      String transpoNames, String fare, String time, SvgPicture pic) {
    return Container(
      width: double.infinity, // Make the width match the parent
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Shadow color with opacity
            offset: const Offset(0, 4), // Offset for the shadow
            blurRadius: 8, // Blur radius for the shadow
            spreadRadius: 2, // Spread radius for the shadow
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 2, // 20% of the width
              child: Container(
                padding: const EdgeInsets.only(right: 10),
                child: pic,
              ),
            ),
            Expanded(
              flex: 9, // 80% of the width
              child: Column(
                children: [
                  //transpoName, fare, time
                  Row(
                    children: [
                      Text(
                        transpoNames,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  //route
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(
                            right: 8.0), // Space between the two texts
                        child: const Text(
                          "Fare:",
                          style: TextStyle(color: Colors.black),
                          textAlign: TextAlign.start, // Align text to the start
                        ),
                      ),
                      Text(
                        fare,
                        style: const TextStyle(color: Colors.black),
                        textAlign: TextAlign.start, // Align text to the start
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(
                            right: 8.0), // Space between the two texts
                        child: const Text(
                          "Time:",
                          style: TextStyle(color: Colors.black),
                          textAlign: TextAlign.start, // Align text to the start
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(color: Colors.black),
                        textAlign: TextAlign.start, // Align text to the start
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

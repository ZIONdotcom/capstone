import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class travelPlan4 extends StatefulWidget {
  const travelPlan4({super.key});

  @override
  State<travelPlan4> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<travelPlan4> {
  GoogleMapController? _controller;

  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(14.831582, 120.903786),
    zoom: 11.5,
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: Column(
          children: [
            SizedBox(
              height: 300,
              width: double.infinity,
              child: GoogleMap(
                initialCameraPosition: _initialCameraPosition,
                onMapCreated: (GoogleMapController controller) {
                  _controller = controller;
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft:
                      Radius.circular(20), // Adjust the radius value as needed
                  topRight: Radius.circular(20),
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
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: const Text(
                      'SM Marilao -> Bocaue -> Malolos',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  walk('Walk to highway',
                      SvgPicture.asset('assets/icons/bus2.svg')),
                  ride('transpoName', 'fare', 'time', 'route', 'geton',
                      'getoff', SvgPicture.asset('assets/icons/bus2.svg')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget walk(String text, SvgPicture pic) {
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
                child: pic,
              ),
            ),
            Expanded(
              flex: 8, // 80% of the width
              child: Container(
                color: Colors.white, // Right side color
                child: Center(
                  child: Text(
                    text,
                    style: const TextStyle(
                        color: Colors.black), // Adjust text color for contrast
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //next ride
  //transpoName, fare, time, route, geton, getoff
  Widget ride(String transpoName, String fare, String time, String route,
      String geton, String getoff, SvgPicture pic) {
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
                child: pic,
              ),
            ),
            Expanded(
              flex: 8, // 80% of the width
              child: Column(
                children: [
                  //transpoName, fare, time
                  Row(
                    children: [
                      Text(
                        transpoName,
                        style: const TextStyle(color: Colors.black),
                      ),
                      const Spacer(),
                      Text(
                        fare,
                        style: const TextStyle(
                            color:
                                Colors.black), // Adjust text color for contrast
                      ),
                      const Spacer(),
                      Text(
                        time,
                        style: const TextStyle(
                            color:
                                Colors.black), // Adjust text color for contrast
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  //route
                  Row(
                    children: [
                      Expanded(
                        flex: 4, // 20% of the space
                        child: Container(
                          padding: const EdgeInsets.only(
                              right: 8.0), // Space between the two texts
                          child: const Text(
                            "Route",
                            style: TextStyle(color: Colors.black),
                            textAlign:
                                TextAlign.start, // Align text to the start
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6, // 80% of the space
                        child: Text(
                          route,
                          style: const TextStyle(color: Colors.black),
                          textAlign: TextAlign.start, // Align text to the start
                        ),
                      ),
                    ],
                  ),

                  //get on
                  Row(
                    children: [
                      Expanded(
                        flex: 4, // 20% of the space
                        child: Container(
                          padding: const EdgeInsets.only(
                              right: 8.0), // Space between the two texts
                          child: const Text(
                            "Get on",
                            style: TextStyle(color: Colors.black),
                            textAlign:
                                TextAlign.start, // Align text to the start
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6, // 80% of the space
                        child: Text(
                          geton,
                          style: const TextStyle(color: Colors.black),
                          textAlign: TextAlign.start, // Align text to the start
                        ),
                      ),
                    ],
                  ),
                  //get off
                  Row(
                    children: [
                      Expanded(
                        flex: 4, // 20% of the space
                        child: Container(
                          padding: const EdgeInsets.only(
                              right: 8.0), // Space between the two texts
                          child: const Text(
                            "Get off",
                            style: TextStyle(color: Colors.black),
                            textAlign:
                                TextAlign.start, // Align text to the start
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6, // 80% of the space
                        child: Text(
                          getoff,
                          style: const TextStyle(color: Colors.black),
                          textAlign: TextAlign.start, // Align text to the start
                        ),
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

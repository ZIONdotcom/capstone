import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:capstone/pages/travelPlan4.dart';

class travelPlan3 extends StatefulWidget {
  const travelPlan3({super.key});

  @override
  State<travelPlan3> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<travelPlan3> {
  GoogleMapController? _controller;

  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(14.831582, 120.903786),
    zoom: 11.5,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.only(top: 40.0),
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
                borderRadius: BorderRadius.only(
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
                    padding: EdgeInsets.only(left: 30, top: 30, bottom: 30),
                    child: Text(
                      'Routes',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'SM Marilao -> Bocaue -> Malolos',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  suggestRoute('jeep', '21', '4mins',
                      SvgPicture.asset('assets/icons/bus2.svg')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget suggestRoute(
      String transpoNames, String fare, String time, SvgPicture pic) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => travelPlan4()),
        );
      },
      child: Container(
        width: double.infinity, // Make the width match the parent
        padding: EdgeInsets.all(16.0),
        margin: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // Shadow color with opacity
              offset: Offset(0, 4), // Offset for the shadow
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
                  padding: EdgeInsets.only(right: 10),
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
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),

                    SizedBox(
                      height: 10,
                    ),

                    //route
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.only(
                              right: 8.0), // Space between the two texts
                          child: Text(
                            "Fare:",
                            style: TextStyle(color: Colors.black),
                            textAlign:
                                TextAlign.start, // Align text to the start
                          ),
                        ),
                        Text(
                          fare,
                          style: TextStyle(color: Colors.black),
                          textAlign: TextAlign.start, // Align text to the start
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.only(
                              right: 8.0), // Space between the two texts
                          child: Text(
                            "Time:",
                            style: TextStyle(color: Colors.black),
                            textAlign:
                                TextAlign.start, // Align text to the start
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(color: Colors.black),
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
      ),
    );
  }
}

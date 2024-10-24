import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'searchpage.dart';
import 'package:http/http.dart' as http;

class routefinder3 extends StatefulWidget {
  @override
  final List<dynamic> legs;
  final List<dynamic> steps;
  final String origin;
  final String destination;
  final String latOrigin, longOrigin;
  final String latDestination, longDestination;

  const routefinder3({
    super.key,
    required this.latOrigin,
    required this.longOrigin,
    required this.latDestination,
    required this.longDestination,
    required this.legs,
    required this.steps,
    required this.origin,
    required this.destination,
  });

  @override
  ThirdScreenState createState() => ThirdScreenState();
}

class ThirdScreenState extends State<routefinder3> {
  final String apiKey = 'AIzaSyBcUDWZDnJBOX_Q5IOqDJi60RuqJy1-ZkY';
  //polyline v1
  final Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];

  late List<dynamic> transitType;
  late List<dynamic> legs;
  late List<dynamic> steps;
  late GoogleMapController _mapController;
  final LatLng _startLocation =
      const LatLng(14.831582, 120.903786); //  start location
  // final LatLng _destinationLocation =
  //     LatLng(34.0522, -118.2437); //  destination location

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  TextEditingController reportController = TextEditingController();

  //search page
  @override
  void initState() {
    super.initState();
    legs = widget.legs;
    steps = widget.steps;
    getRoutePolyline();
    transitType = [];
    print('Transit Type List: $transitType');
    // //polyline v1
    // // Iterate over each step to get the polyline points
    // for (var step in steps) {
    //   if (step['polyline'] != null) {
    //     String encodedPolyline = step['polyline']['points'];
    //     polylineCoordinates.addAll(decodePolyline(encodedPolyline));
    //   }
    // }
    // // Define a polyline and add it to the polylines set
    // _polylines.add(
    //   Polyline(
    //     polylineId: PolylineId("route"),
    //     color: Colors.blue,
    //     points: polylineCoordinates,
    //     width: 5, // Adjust the width as necessary
    //   ),
    // );

    print(legs);
    print(
        '----------------------------------------------------------------\n------------------------------------------------');
    _fromController.text = widget.origin;
    _toController.text = widget.destination;
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  //to searchpage.dart
  void _navigateToSearchPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  //polyline v1
  // List<LatLng> decodePolyline(String encoded) {
  //   List<LatLng> polyline = [];
  //   int index = 0, len = encoded.length;
  //   int lat = 0, lng = 0;

  //   while (index < len) {
  //     int b, shift = 0, result = 0;
  //     do {
  //       b = encoded.codeUnitAt(index++) - 63;
  //       result |= (b & 0x1F) << shift;
  //       shift += 5;
  //     } while (b >= 0x20);
  //     int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
  //     lat += dlat;

  //     shift = 0;
  //     result = 0;
  //     do {
  //       b = encoded.codeUnitAt(index++) - 63;
  //       result |= (b & 0x1F) << shift;
  //       shift += 5;
  //     } while (b >= 0x20);
  //     int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
  //     lng += dlng;

  //     polyline.add(LatLng(lat / 1E5, lng / 1E5));
  //   }
  //   return polyline;
  // }

  //polyline v2
  Future<void> getRoutePolyline() async {
    final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${widget.latOrigin},${widget.longOrigin}&destination=${widget.latDestination},${widget.longDestination} &key=$apiKey'));

    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${widget.latOrigin},${widget.longOrigin}&destination=${widget.latDestination},${widget.longDestination} &key=$apiKey";
    print(
        "${response.body}-------------------------------------------response body");
    print("$url---------------------------------------------------- url");

    print(
        "Latorigin: ${widget.latOrigin}${widget.longOrigin}------------------------------------------------------");

    if (response.statusCode == 200) {
      final decodedResponse = json.decode(response.body);
      if (decodedResponse['routes'].isNotEmpty) {
        // Extract the overview polyline
        final overviewPolyline =
            decodedResponse['routes'][0]['overview_polyline']['points'];

        // Decode the polyline
        polylineCoordinates.addAll(decodePolyline(overviewPolyline));

        setState(() {
          // Add polyline to the map
          _polylines.add(
            Polyline(
              polylineId: const PolylineId("route"),
              color: Colors.blue,
              points: polylineCoordinates,
              width: 5,
            ),
          );
        });
      }
      print(
          "$polylineCoordinates ------------------------------+++++++++++++++++++++");
    } else {
      throw Exception('Failed to load directions');
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  //next dots
  List<Widget> _generateDots(int numberOfDots, List<Color> colors) {
    List<Widget> dots = [];
    for (int i = 0; i < numberOfDots; i++) {
      dots.add(
        Container(
          height: 20.0,
          width: 20.0,
          decoration: BoxDecoration(
            color: colors[i],
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    return dots;
  }

  @override
  Widget build(BuildContext context) {
    //next dots
    int numberOfDots = 3; // Number of dots
    List<Color> colors = [
      Colors.blue,
      Colors.black,
      Colors.black,
    ]; // Colors for each dot based on the criteria

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //next from search, navigate search bar finished design
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 20, right: 5, left: 5),
                  alignment: Alignment.center,
                  height: 48.89,
                  width: 48.89,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset('assets/icons/from.svg'),
                ),
                Expanded(
                  child: GestureDetector(
                    //search
                    onTap:
                        _navigateToSearchPage, // Navigate when tapped| search
                    child: Container(
                      margin: const EdgeInsets.only(right: 20.0, top: 10),
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff1D1617).withOpacity(0.11),
                            blurRadius: 4,
                            spreadRadius: 0.0,
                          ),
                        ],
                      ),
                      child: AbsorbPointer(
                        // Prevent user from typing directly
                        child: TextFormField(
                          //navigate to search bar
                          controller: _fromController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 15),
                            hintText: 'Type here...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            //next To search, navigate search bar finished design
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 5, left: 5),
                  alignment: Alignment.center,
                  height: 48.89,
                  width: 48.89,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset('assets/icons/pin.svg'),
                ),
                Expanded(
                  child: GestureDetector(
                    //search
                    onTap:
                        _navigateToSearchPage, // Navigate when tapped | search
                    child: Container(
                      margin: const EdgeInsets.only(right: 20.0),
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff1D1617).withOpacity(0.11),
                            blurRadius: 4,
                            spreadRadius: 0.0,
                          ),
                        ],
                      ),
                      child: AbsorbPointer(
                        // Prevent user from typing directly | search
                        child: TextFormField(
                          controller: _toController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 15),
                            hintText: 'Type here...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),

            //next display map and marker - finished design
            SizedBox(
              width: double.infinity,
              height: 300,
              child: GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  // _setMarkers();
                },
                initialCameraPosition: CameraPosition(
                  target: _startLocation,
                  zoom: 11.5,
                ),
                // markers: _markers,
                polylines: _polylines,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            //next Routes , save icon - finished design
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 30.0),
                  child: const Text(
                    'Routes',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.only(left: 30),
                  alignment: Alignment.center,
                  height: 48.89,
                  width: 48.89,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset('assets/icons/save.svg'),
                ),
              ],
            ),

            // print(transitType);

            SizedBox(
              width: double
                  .infinity, // Make the container take the full width of the parent
              height: 60, // You can adjust the height as needed
              child: ListView.builder(
                scrollDirection:
                    Axis.horizontal, // Set scroll direction to horizontal
                itemCount: transitType.length, // Number of items in the list
                itemBuilder: (context, index) {
                  String type = transitType[index];

                  return Container(
                    margin: const EdgeInsets.only(left: 30),
                    alignment: Alignment.center,
                    height: 48.89, // Set the height of each item
                    width: 48.89, // Set the width of each item
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SvgPicture.asset(
                      type == 'TRANSIT'
                          ? 'assets/icons/bus2.svg'
                          : 'assets/icons/walk2.svg',
                    ),
                  );
                },
              ),
            ),

            Expanded(
              child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: steps.length + 1,
                  itemBuilder: (context, index) {
                    if (index == steps.length) {
                      // report button
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 20),
                        child: SizedBox(
                          height: 38, // Button height
                          child: ElevatedButton(
                            onPressed: () {
                              reportDialog(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                  0xffE84B4B), // Button background color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    30), // Rounded corners
                              ),
                              elevation: 5, // Adds shadow to the button
                              shadowColor:
                                  Colors.grey.withOpacity(0.5), // Shadow color
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .center, // Centers the content
                              children: [
                                SvgPicture.asset('assets/icons/Alert.svg'),
                                const SizedBox(
                                    width: 8), // Spacing between icon and text
                                const Text(
                                  'Report this route.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
//suggested steps
                    final step = steps[index];

                    // Example SVG Picture, replace with your actual SVG asset
                    SvgPicture picwalk =
                        SvgPicture.asset('assets/icons/walk2.svg');
                    SvgPicture picride =
                        SvgPicture.asset('assets/icons/bus2.svg');

                    // Assuming you have the necessary fields in each leg
                    String transpoName = step['travel_mode'] ?? 'Unknown';
                    String time = step['duration']['text'] ?? 'N/A';
                    String geton = step['html_instructions'] ?? 'N/A';
                    String instruction = step['html_instructions'] ?? 'N/A';
                    String fare = step['fare'] ?? 'N/A';
                    String getoff = step['getoff'] ?? 'N/A';
                    String route = step['route'] ?? 'N/A';
                    final num = steps.length.toString();
                    print("!!!!!!!!!!!!!!!!!!!!! $transpoName");
                    print("################################### $num");

                    if (transpoName == 'TRANSIT') {
                      transitType.add("TRANSIT");
                      return ride(transpoName, fare, time, route, geton, getoff,
                          picride);
                    } else {
                      transitType.add("WALK");
                      return walk(instruction, picwalk);
                    }
                  }),
            ),
          ],
        ),
      ),
    );
  }

  //next transportation info
  //next walk
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

  void reportDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: 350, // Set the desired width
            padding: const EdgeInsets.all(20), // Optional: Add padding
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/Alert.svg',
                      width: 30,
                      height: 30,
                      color: const Color(0xffE84B4B),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "REPORT!",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  "Is the route information inaccurate?",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 300, // Set the desired width
                  height: 40, // Set the desired height
                  child: TextFormField(
                    controller: reportController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 5, // Adjust vertical padding for more height
                        horizontal: 10,
                      ),
                      hintText: 'Tell us why...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // Space out the buttons
                  children: [
                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                    ),
                    TextButton(
                      child: const Text("Submit"),
                      onPressed: () {
                        // Add your submit logic here
                        Navigator.of(context)
                            .pop(); // Close the dialog after submission
                        //database
                        reportController.clear();
                        confirmDialog(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void confirmDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          // title: const Text("PIN LOCATION",
          //  style: TextStyle(
          //   fontSize: 13,
          //  fontWeight: FontWeight.bold
          //  ),
          //   textAlign: TextAlign.center,
          //    ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 20),
              Text(
                "Report Submitted",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
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

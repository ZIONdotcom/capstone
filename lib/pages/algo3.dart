import 'dart:convert';
import 'package:capstone/LegStepAlgo_model.dart';
import 'package:capstone/terminal_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'searchpage.dart';
import 'package:http/http.dart' as http;

class algo3 extends StatefulWidget {
  @override
  //final List<dynamic> legs;
  final List<TravelStep> steps;
  final String origin;
  final String destination;
  final String latOrigin, longOrigin;
  final String latDestination, longDestination;

  const algo3({
    super.key,
    required this.latOrigin,
    required this.longOrigin,
    required this.latDestination,
    required this.longDestination,
    //required this.legs,
    required this.steps,
    required this.origin,
    required this.destination,
  });

  @override
  ThirdScreenState createState() => ThirdScreenState();
}

class ThirdScreenState extends State<algo3> {
  final String apiKey = 'AIzaSyBcUDWZDnJBOX_Q5IOqDJi60RuqJy1-ZkY';
  late List<TravelStep> steps;
  //polyline v1

  late List<dynamic> transitType;
  // late List<dynamic> legs;

  late GoogleMapController _mapController;
  final LatLng _startLocation =
      const LatLng(14.831582, 120.903786); //  start location
  // final LatLng _destinationLocation =
  //     LatLng(34.0522, -118.2437); //  destination location

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  TextEditingController reportController = TextEditingController();

  final Set<Marker> _markers = {}; // To hold the markers
  final Set<Circle> _circles = {}; // To hold the circle markers

  // void _addMarkersAndPolylines() async {
  //   // Clear previous markers, circles, and polylines
  //   setState(() {
  //     _markers.clear();
  //     _circles.clear();
  //     _polylines.clear();
  //   });

  //   // Loop through each step and add polyline between sakayanLocation and babaanLocation
  //   for (int i = 0; i < steps.length; i++) {
  //     final step = steps[i];
  //     if (step.babaanLocation != null) {
  //       try {
  //         print('step ??? routepoints: ${step.routePoints} ');
  //         // // Fetch polyline for the current route with waypoints
  //         // final polylineEncoded = await getRoutePolyline(
  //         //   step.sakayanLocation!,
  //         //   step.babaanLocation!,
  //         //   step.routePoints ?? [], // Waypoints for the route
  //         // );

  //         // // Decode polyline
  //         // final polylinePoints = decodePolyline(polylineEncoded);

  //         // Add polyline to the map for this step
  //         final polyline = Polyline(
  //           polylineId: PolylineId('route_$i'),
  //           points: step.routePoints,
  //           color: Colors.blue,
  //           width: 5,
  //         );

  //         setState(() {
  //           _polylines.add(polyline);
  //         });

  //         // Add start and end markers for this route segment
  //         final startMarker = Marker(
  //           markerId: MarkerId('start_$i'),
  //           position: step.sakayanLocation,
  //           infoWindow: InfoWindow(title: 'Start: ${step.transportationName}'),
  //           icon:
  //               BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
  //         );

  //         final endMarker = Marker(
  //           markerId: MarkerId('end_$i'),
  //           position: step.babaanLocation,
  //           infoWindow: InfoWindow(title: 'End: ${step.transportationName}'),
  //           icon:
  //               BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
  //         );

  //         // Add circles to highlight start and end locations
  //         final startCircle = Circle(
  //           circleId: CircleId('circleStart_$i'),
  //           center: step.sakayanLocation,
  //           radius: 50.0,
  //           fillColor: Colors.blue.withOpacity(0.3),
  //           strokeColor: Colors.blue,
  //           strokeWidth: 2,
  //         );

  //         final endCircle = Circle(
  //           circleId: CircleId('circleEnd_$i'),
  //           center: step.babaanLocation,
  //           radius: 50.0,
  //           fillColor: Colors.red.withOpacity(0.3),
  //           strokeColor: Colors.red,
  //           strokeWidth: 2,
  //         );

  //         setState(() {
  //           _markers.add(startMarker);
  //           _markers.add(endMarker);
  //           _circles.add(startCircle);
  //           _circles.add(endCircle);
  //         });
  //       } catch (e) {
  //         print('Error fetching route polyline for step $i: $e');
  //       }
  //     }
  //   }
  // }

  final Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];

  void _addMarkersAndPolylines() async {
    // Clear previous markers, circles, and polylines
    setState(() {
      _markers.clear();
      _circles.clear();
      _polylines.clear();
    });

    // Loop through each step and add polyline between sakayanLocation and babaanLocation
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      if (step.babaanLocation != null) {
        try {
          print('step $i: sakayanLocation: ${step.sakayanLocation}');
          print('step $i: babaanLocation: ${step.babaanLocation}');
          print('step $i: routePoints: ${step.routePoints}');

          // Create a new list for polyline points, starting with sakayanLocation
          List<LatLng> polylinePoints = [step.sakayanLocation];

          // Filter routePoints to include only those between sakayanLocation and babaanLocation
          List<LatLng> filteredRoutePoints = [];
          if (step.routePoints != null && step.routePoints.isNotEmpty) {
            filteredRoutePoints = step.routePoints.where((point) {
              return _isPointBetweenLocations(
                  point, step.sakayanLocation, step.babaanLocation);
            }).toList();
          }

          // Only add the filtered routePoints to the polylinePoints if there are any
          if (filteredRoutePoints.isNotEmpty) {
            polylinePoints.addAll(filteredRoutePoints);
          }

          // Add babaanLocation at the end
          polylinePoints.add(step.babaanLocation);

          // Ensure no polyline is drawn if the points are just sakayanLocation and babaanLocation (i.e., no intermediate route points)
          if (polylinePoints.length > 2) {
            print('Final polyline points for step $i: $polylinePoints');

            // Create the polyline using the polylinePoints list
            final polyline = Polyline(
              polylineId: PolylineId('route_$i'),
              points:
                  polylinePoints, // This now includes sakayanLocation, filtered routePoints, and babaanLocation
              color: Colors.blue,
              width: 5,
            );

            setState(() {
              // _polylines.add(polyline);
            });
          }

          // Add start and end markers for this route segment
          final startMarker = Marker(
            markerId: MarkerId('start_$i'),
            position: step.sakayanLocation,
            infoWindow: InfoWindow(title: 'Start: ${step.transportationName}'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          );

          final endMarker = Marker(
            markerId: MarkerId('end_$i'),
            position: step.babaanLocation,
            infoWindow: InfoWindow(title: 'End: ${step.transportationName}'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          );

          // Add circles to highlight start and end locations
          final startCircle = Circle(
            circleId: CircleId('circleStart_$i'),
            center: step.sakayanLocation,
            radius: 50.0,
            fillColor: Colors.blue.withOpacity(0.3),
            strokeColor: Colors.blue,
            strokeWidth: 2,
          );

          final endCircle = Circle(
            circleId: CircleId('circleEnd_$i'),
            center: step.babaanLocation,
            radius: 50.0,
            fillColor: Colors.red.withOpacity(0.3),
            strokeColor: Colors.red,
            strokeWidth: 2,
          );

          setState(() {
            _markers.add(startMarker);
            _markers.add(endMarker);
            _circles.add(startCircle);
            _circles.add(endCircle);
          });
        } catch (e) {
          print('Error fetching route polyline for step $i: $e');
        }
      }
    }
  }

// Helper function to check if a point is between sakayanLocation and babaanLocation
  bool _isPointBetweenLocations(
      LatLng point, LatLng sakayanLocation, LatLng babaanLocation) {
    // Check if the point is between the latitudes and longitudes of sakayanLocation and babaanLocation
    bool isBetweenLat = (point.latitude >= sakayanLocation.latitude &&
            point.latitude <= babaanLocation.latitude) ||
        (point.latitude <= sakayanLocation.latitude &&
            point.latitude >= babaanLocation.latitude);

    bool isBetweenLng = (point.longitude >= sakayanLocation.longitude &&
            point.longitude <= babaanLocation.longitude) ||
        (point.longitude <= sakayanLocation.longitude &&
            point.longitude >= babaanLocation.longitude);

    return isBetweenLat && isBetweenLng;
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

  // Future<String> getRoutePolyline(
  //     LatLng start, LatLng end, List<LatLng> waypoints) async {
  //   // Create the waypoints query part
  //   String waypointsQuery = '';
  //   if (waypoints.isNotEmpty) {
  //     waypointsQuery =
  //         waypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|');
  //   }

  //   final url = Uri.parse(
  //     'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&waypoints=optimize:false|$waypointsQuery&key=$apiKey',
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

  //search page
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addMarkersAndPolylines(); // Add polylines, markers, and circles
    });

    steps = widget.steps;

    print("Steps Length: ${steps.length}");

    // getRoutePolyline();
    transitType = [];
    print('Transit Type List: $transitType');

    print(
        '----------------------------------------------------------------\n------------------------------------------------');
    _fromController.text = widget.origin;
    _toController.text = widget.destination;
  }

// Add polylines for each step
  // void _addPolylines() {
  //   for (int i = 0; i < steps.length; i++) {
  //     final step = steps[i];
  //     if (step.sakayanLocation != null && step.babaanLocation != null) {
  //       List<LatLng> polylineCoordinates = [
  //         step.sakayanLocation!,
  //         step.babaanLocation!,
  //       ];

  //       final polyline = Polyline(
  //         polylineId: PolylineId('route$i'),
  //         points: polylineCoordinates,
  //         color: Colors.blue,
  //         width: 5,
  //       );

  //       setState(() {
  //         _polylines.add(polyline);
  //       });
  //     }
  //   }
  // }

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
                markers: _markers,
                circles: _circles,
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

            // SizedBox(
            //   width: double
            //       .infinity, // Make the container take the full width of the parent
            //   height: 60, // You can adjust the height as needed
            //   child: ListView.builder(
            //     scrollDirection:
            //         Axis.horizontal, // Set scroll direction to horizontal
            //     itemCount: steps.length, // Number of items in the list
            //     itemBuilder: (context, index) {
            //       print('weeeeeeeeeeeeeee step num? ${steps.length}');
            //       String type = [
            //         'jeepney',
            //         'uv express',
            //         'tricycle',
            //         'bus',
            //         'e-jeep'
            //       ].contains(steps[index].transportationName.toLowerCase())
            //           ? 'TRANSIT'
            //           : 'WALK';
            //       // for (var step in steps) {
            //       //   if (['jeepney', 'uv express', 'tricycle', 'bus', 'e-jeep']
            //       //       .contains(step.transportationName.toLowerCase())) {
            //       //     type = 'TRANSIT';
            //       //   } else {
            //       //     type = 'WALK';
            //       //   }
            //       // }

            //       return Container(
            //         margin: const EdgeInsets.only(left: 30),
            //         alignment: Alignment.center,
            //         height: 48.89,
            //         width: 48.89,
            //         decoration: BoxDecoration(
            //           color: Colors.white,
            //           borderRadius: BorderRadius.circular(10),
            //         ),
            //         child: SvgPicture.asset(
            //           type == 'TRANSIT'
            //               ? 'assets/icons/bus2.svg'
            //               : 'assets/icons/walk2.svg',
            //         ),
            //       );
            //     },
            //   ),
            // ),

            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: steps.length + 1, // +1 for the report button
                itemBuilder: (context, index) {
                  if (index == steps.length) {
                    // Report button
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
                              borderRadius:
                                  BorderRadius.circular(30), // Rounded corners
                            ),
                            elevation: 5, // Adds shadow to the button
                            shadowColor:
                                Colors.grey.withOpacity(0.5), // Shadow color
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center, // Centers the content
                            children: [
                              SvgPicture.asset('assets/icons/Alert.svg'),
                              const SizedBox(
                                  width: 8), // Spacing between icon and text
                              const Text(
                                'Report this route.',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Suggested steps
                  final step = steps[index];

                  // SVG pictures
                  SvgPicture picwalk =
                      SvgPicture.asset('assets/icons/walk2.svg');
                  SvgPicture picride =
                      SvgPicture.asset('assets/icons/bus2.svg');

                  // Retrieve transportation data from the step
                  String transpoName = step.transportationName ?? 'Unknown';
                  String time = '${step.travelTime.toString()} min' ?? 'N/A';
                  String geton = step.sakayanPlaceName.toString() ?? 'N/A';
                  String instruction = step.sakayanPlaceName ?? 'N/A';
                  String fare = '₱${step.fare.toString()}' ?? 'N/A';
                  String getoff = step.babaanPlaceName.toString() ?? 'N/A';
                  String route = step.routeName ?? 'N/A';

                  print(
                      'transportation name: ${step.transportationName}, sakayan: ${step.sakayanLocation}, babaan: ${step.babaanLocation}');

                  // // Handle the polyline addition outside the builder if needed (for performance optimization)
                  // if (step.sakayanLocation != null &&
                  //     step.babaanLocation != null) {
                  //   List<LatLng> polylineCoordinates = [
                  //     step.sakayanLocation!, // Ensure these are not null
                  //     step.babaanLocation!
                  //   ];

                  //   // Add the polyline only once for the entire route
                  //   final polyline = Polyline(
                  //     polylineId: PolylineId('route$index'),
                  //     points: polylineCoordinates,
                  //     color: Colors.blue,
                  //     width: 5,
                  //   );

                  //   setState(() {
                  //     _polylines.add(polyline);
                  //   });
                  // }

                  // Return the proper widget based on the transportation type
                  if (['jeepney', 'uv express', 'tricycle', 'bus', 'e-jeep']
                      .contains(transpoName.toLowerCase())) {
                    return ride(
                        transpoName, fare, time, route, geton, getoff, picride);
                  } else {
                    return walk(instruction, picwalk, time);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  //next transportation info
  //next walk
  Widget walk(String text, SvgPicture pic, String time) {
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
        child: Column(
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end, // Aligns content to the right
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.black, // Adjust text color for contrast
                  ),
                ),
              ],
            ),
            Row(
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
                            color:
                                Colors.black), // Adjust text color for contrast
                      ),
                    ),
                  ),
                ),
              ],
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
                            "pick-up point: ",
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
                            "Drop off point:",
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
}

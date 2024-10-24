import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'routeFinder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:capstone/pages/routefinder3.dart';

class RouteFinder2 extends StatefulWidget {
  final String latOrigin, longOrigin;
  final String latDestination, longDestination;
  final String originName;
  final String destinationName;

  const RouteFinder2({
    super.key,
    required this.latOrigin,
    required this.longOrigin,
    required this.latDestination,
    required this.longDestination,
    required this.destinationName,
    required this.originName,
  });

  // const RouteFinder2({super.key});

  @override
  _RouteFinderState2 createState() => _RouteFinderState2();
}

class _RouteFinderState2 extends State<RouteFinder2> {
  final String apiKey = 'AIzaSyAnDp1NMv3WSsatCAjJL02Y_fL8a44L4NI';
  //swap
  bool isSwapped = false;
  final TextEditingController _controllerTo = TextEditingController();
  final TextEditingController _controllerFrom = TextEditingController();
  List<Map<String, dynamic>> selectedLegs = [];

  void _navigateToSearchPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RouteFinder()),
    );
  }

  void swapFields() {
    setState(() {
      isSwapped = !isSwapped;
    });
  }
  //end swap ----------------------------------------------------------

  //marker
  final Set<Marker> _markers = {};

  //map
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(14.831582, 120.903786), // Default initial position
    zoom: 11.5, // Default zoom level
  );

  GoogleMapController? mapController;
  List<LatLng> polylineCoordinates = [];
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    fetchRoute();
    _controllerTo.text = widget.originName;
    _controllerFrom.text = widget.destinationName;
    _setCustomMarkerIcon();
    getRoutes();
  }

  // marker icon
  BitmapDescriptor? customIcon;
  void _setCustomMarkerIcon() async {
    customIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(
            size: Size(15, 15)), // You can adjust the size if needed
        'assets/icons/dot.png');
  }
  // marker icon end

  //polyline
  Future<void> fetchRoute() async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${widget.latOrigin},${widget.longOrigin}&destination=${widget.latDestination}&key=$apiKey&alternatives=true';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final routes = jsonResponse['routes'];

        if (routes.isNotEmpty) {
          final route = routes[0]; // Use the first route
          final polyline = route['overview_polyline']['points'];

          setState(() {
            // Decode the polyline into a list of LatLng points
            polylineCoordinates = decodePolyline(polyline);

            // Clear existing markers and polylines
            _markers.clear();
            _polylines.clear();

            setState(() {
              _polylines.add(
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: polylineCoordinates,
                  color: Colors.blue,
                  width: 5,
                ),
              );
            });
            // Add polyline to the map

            // Add start and end markers
            if (polylineCoordinates.isNotEmpty) {
              final LatLng startLocation = polylineCoordinates.first;
              final LatLng endLocation = polylineCoordinates.last;

              setState(() {
                _markers.add(
                  Marker(
                    markerId: const MarkerId('start_marker'),
                    position: startLocation,
                    icon: customIcon ?? BitmapDescriptor.defaultMarker,
                    infoWindow: const InfoWindow(title: 'Start Location'),
                  ),
                );

                _markers.add(
                  Marker(
                    markerId: const MarkerId('end_marker'),
                    position: endLocation,
                    icon: customIcon ?? BitmapDescriptor.defaultMarker,
                    infoWindow: const InfoWindow(title: 'End Location'),
                  ),
                );
              });
            }
          });
        } else {
          print("No routes found.");
        }
      } else {
        print("Failed to fetch route. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error fetching route: $e");
    }
  }

  List<LatLng> decodePolyline(String polyline) {
    List<LatLng> coordinates = [];
    int index = 0;
    int len = polyline.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += deltaLat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int deltaLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += deltaLng;

      coordinates.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return coordinates;
  }

  //polyline

  //transportation suggestion transit
  // Fetch public transport routes from the API
  Future<List<Map<String, dynamic>>> fetchPublicTransportRoutes(
      String origin, String destination, String apiKey) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=transit&alternatives=true&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Print the entire API response for debugging purposes
        print("API Response: ${data.toString()}");

        if (data['status'] == 'OK') {
          List routes = data['routes'];

          // Check if routes are available
          if (routes.isEmpty) {
            print("No transit routes found.");
            return [];
          }

          List<Map<String, dynamic>> transitRoutes = [];
          for (var route in routes) {
            final overviewPolyline = route['overview_polyline']['points'];
            final legs = route['legs'];

            final routeDetails = {
              'overviewPolyline': overviewPolyline,
              'legs': legs,
            };
            transitRoutes.add(routeDetails);
          }
          return transitRoutes;
        } else {
          print('Error in API response: ${data['status']}');
          throw Exception('Failed to fetch routes: ${data['status']}');
        }
      } else {
        print(
            "Failed to connect to the Google Maps API with status code: ${response.statusCode}");
        throw Exception('Failed to connect to the Google Maps API');
      }
    } catch (e) {
      print("Error fetching public transport routes: $e");
      rethrow;
    }
  }

  List<Map<String, dynamic>> publicTransportRoutes = [];

  // Call this method to get the routes and update the UI
  // Call this method to get the routes and print the details in the terminal
  void getRoutes() async {
    try {
      publicTransportRoutes = await fetchPublicTransportRoutes(
        _controllerFrom.text, // Origin
        _controllerTo.text, // Destination
        apiKey,
      );

      for (int i = 0; i < publicTransportRoutes.length; i++) {
        final route = publicTransportRoutes[i];
        final legs = route['legs'];

        print('Route $i:');
        for (int j = 0; j < legs.length; j++) {
          final leg = legs[j];
          print('  Leg $j:');
          print('    Start Address: ${leg['start_address']}');
          print('    End Address: ${leg['end_address']}');
          print('    Duration: ${leg['duration']['text']}');
          print('    Distance: ${leg['distance']['text']}');

          for (int k = 0; k < leg['steps'].length; k++) {
            final step = leg['steps'][k];
            print('    Step $k:');
            print('      Travel Mode: ${step['travel_mode']}');
            if (step['travel_mode'] == 'TRANSIT') {
              final transitDetails = step['transit_details'];
              print(
                  '      Vehicle: ${transitDetails['line']['vehicle']['type']}');
              print('      Line Name: ${transitDetails['line']['name']}');
              print(
                  '      Departure Stop: ${transitDetails['departure_stop']['name']}');
              print(
                  '      Arrival Stop: ${transitDetails['arrival_stop']['name']}');
            } else if (step['travel_mode'] == 'WALKING') {
              print('      Walking Duration: ${step['duration']['text']}');
            }
          }
        }
      }

      setState(() {}); // Update the UI with the new routes
    } catch (e) {
      print('Error fetching routes: $e');
    }
  }

  //end transportation suggestion transit ----------------------
  //map end -----------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            //next top
            Container(
              padding: const EdgeInsets.only(bottom: 13, left: 5, right: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 3.5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      if (isSwapped)
                        const Icon(Icons.location_on,
                            size: 25, color: Color(0xff1f41bb))
                      else
                        const Icon(Icons.circle,
                            size: 17, color: Color(0xffc2d0ff)),
                      Container(
                        width: 2,
                        height: 40,
                        color: const Color(0xffc2d0ff),
                      ),
                      if (isSwapped)
                        const Icon(Icons.circle,
                            size: 17, color: Color(0xffc2d0ff))
                      else
                        const Icon(Icons.location_on,
                            size: 25, color: Color(0xff1f41bb)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        if (isSwapped)
                          fromTextFormfield(_controllerTo)
                        else
                          fromTextFormfield(_controllerFrom),
                        const SizedBox(height: 8),
                        if (isSwapped)
                          toTextFormfield(_controllerFrom)
                        else
                          toTextFormfield(_controllerTo),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_vert, size: 30),
                    onPressed: swapFields,
                  ),
                ],
              ),
            ),

            //next map
            buildMap(),

            const SizedBox(
              height: 20,
            ),

            Container(
              alignment: Alignment.topLeft,
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

            const SizedBox(
              height: 10,
            ),
            //transit
            if (_controllerFrom.text.isNotEmpty &&
                _controllerTo.text.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: publicTransportRoutes.length,
                  itemBuilder: (context, index) {
                    final route = publicTransportRoutes[index];
                    final legs = route['legs'];

                    String transportNames = '';
                    String totalDuration = '';

                    for (var leg in legs) {
                      for (var step in leg['steps']) {
                        // Check if the step is a transit step
                        if (step['travel_mode'] == 'TRANSIT') {
                          final transitDetails = step['transit_details'];
                          if (transitDetails != null &&
                              transitDetails['line'] != null) {
                            final vehicleType = transitDetails['line']
                                    ['vehicle']['type'] ??
                                'Unknown Vehicle';
                            transportNames += '$vehicleType - ';
                          } else {
                            transportNames += 'Unknown Transit - ';
                          }
                        }

                        // Check if the step is a walking step
                        if (step['travel_mode'] == 'WALKING') {
                          final duration = step['duration'] != null
                              ? step['duration']['text'] ?? 'Unknown Duration'
                              : 'Unknown Duration';
                          transportNames += 'Walk - ';
                        }
                      }

                      // Set the total duration for the leg
                      totalDuration = leg['duration'] != null
                          ? leg['duration']['text'] ?? 'Unknown Time'
                          : 'Unknown Time';
                    }

// Remove the trailing " - " from transportNames
                    if (transportNames.endsWith(' - ')) {
                      transportNames = transportNames.substring(
                          0, transportNames.length - 3);
                    }

                    print('Route $index:');
                    print('Transport Names: $transportNames');
                    print('Total Duration: $totalDuration');

                    // Customize this part based on your data structure
                    return suggestRoute(
                      transportNames,
                      '₱50.00',
                      totalDuration,
                      SvgPicture.asset('assets/icons/bus2.svg'),
                      legs,
                      legs[0]['steps'], // Pass the steps of the first leg
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  //next from textformfield
  Widget fromTextFormfield(TextEditingController control) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 3.5),
          ),
        ],
      ),
      child: TextField(
        onTap: _navigateToSearchPage,
        controller: control,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          hintText: "From..",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  //next to textformfield
  Widget toTextFormfield(TextEditingController control) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 3.5),
          ),
        ],
      ),
      child: TextField(
        onTap: _navigateToSearchPage,
        controller: control,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          hintText: "To..",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  double parseDouble(String value) {
    try {
      return double.parse(value);
    } catch (e) {
      print('Error parsing double: $e');
      // Return a default value or handle the error as needed
      return 0.0;
    }
  }

  //next map
  Widget buildMap() {
    double lat;
    double lng;

    if (widget.latOrigin == "" && widget.longOrigin == "") {
      lat = 14.831582;
      lng = 120.903786;
    } else {
      lat = parseDouble(widget.latOrigin);
      lng = parseDouble(widget.longOrigin);
    }
    return SizedBox(
      width: double.infinity,
      height: 300,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(lat, lng),
          zoom: 14,
        ),
        polylines: _polylines,
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        markers: _markers,
      ),
    );
  }

  //next routes
  //transponames, Fare, time, pic
  Widget suggestRoute(String transpoNames, String fare, String time,
      SvgPicture pic, List<dynamic> legs, List<dynamic> steps) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedLegs = List<Map<String, dynamic>>.from(legs);
        });

        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => routefinder3(
                  legs: legs,
                  steps: steps,
                  origin: _controllerTo.text,
                  destination: _controllerFrom.text)),
        );
      },
      child: Container(
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
                            textAlign:
                                TextAlign.start, // Align text to the start
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
                            textAlign:
                                TextAlign.start, // Align text to the start
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
      ),
    );
  }
}

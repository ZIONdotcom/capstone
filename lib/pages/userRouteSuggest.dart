import 'dart:convert';
import 'dart:math';
import 'package:capstone/pages/2userRouteSuggest.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:capstone/pages/travelPlan4.dart';
import 'package:capstone/pages/userRouteSuggest_model.dart';

class Userroutesuggest extends StatefulWidget {
  final String latOrigin;
  final String longOrigin;
  final String latDestination;
  final String longDestination;
  final String originName;
  final String destinationName;

  const Userroutesuggest({
    super.key,
    required this.latOrigin,
    required this.longOrigin,
    required this.latDestination,
    required this.longDestination,
    required this.destinationName,
    required this.originName,
  });

  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Userroutesuggest> {
  final TextEditingController _controllerFrom = TextEditingController();
  final TextEditingController _controllerTo = TextEditingController();
  GoogleMapController? _controller;
  late double originlat, originlong, destinationlat, destinationlong;
  late LatLng originLocation;
  late LatLng destinationLocation;
  late String originName;
  late String destinationName;
  final String apiKey = 'AIzaSyC88-Wkb5_LmPU5OCQwPOMDTry3RGh1J00';

  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(14.831582, 120.903786),
    zoom: 11.5,
  );

  //-----------------------------------------User AllRoutes
  late List<RouteSuggestionUser> routes;

  Future<List<RouteSuggestionUser>> fetchRouteSuggestions() async {
    final response = await http.get(Uri.parse(
        'https://rutaco.online/routeFinderPhp/userGeneratedRoute.php'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((json) => RouteSuggestionUser.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load route suggestions');
    }
  }

  Future<void> testRouteParsing() async {
    try {
      routes = await fetchRouteSuggestions();
      isNearby().then((_) {
        calculateTotalTravelTime();
      }).catchError((error) {
        print('Error occurred in isNearby: $error');
      });

      for (var route in routes) {
        print("Route ID: ${route.id}, Name: ${route.name}");
        for (var step in route.steps) {
          print("  Step ID: ${step.id}, Instructions: ${step.instructions}");
          for (var point in step.polylinePoints) {
            print(
                "    Polyline Point: (${point.xCoordinate}, ${point.yCoordinate})");
          }
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<bool> mayLamanBa() async {
    try {
      routes = await fetchRouteSuggestions();

      if (routes.isEmpty) {
        return false; // No routes found
      }

      for (var route in routes) {
        print("Route ID: ${route.id}, Name: ${route.name}");
        for (var step in route.steps) {
          print("  Step ID: ${step.id}, Instructions: ${step.instructions}");
          for (var point in step.polylinePoints) {
            print(
                "    Polyline Point: (${point.xCoordinate}, ${point.yCoordinate})");
          }
        }
      }
      return true; // Routes found
    } catch (e) {
      print("Error: $e");
      return false; // Error occurred, treat as no routes found
    }
  }

  //------------------------------------------------------------------------is nearby to origin and location

  late Future<List<RouteSuggestionUser>> allRoutes;
  List<RouteSuggestionUser> allPaths = [];
  List<LatLng> coords = [];

  Future<void> isNearby() async {
    List<RouteSuggestionUser> nearbyRoutes = [];
    for (var route in routes) {
      double originDistance = calculateDistances(route.origin, originLocation);
      double destinationDistance =
          calculateDistances(route.destination, destinationLocation);
      if (originDistance <= 300 && destinationDistance <= 300) {
        nearbyRoutes.add(route);
        for (var step in route.steps) {
          final List<LatLng> waypoints = step.polylinePoints
              .map((point) => LatLng(point.xCoordinate, point.yCoordinate))
              .toList();
          step.polylineCoordinates = await fetchRouteCoordinates(
              step.getOnCoordinates, step.getOffCoordinates, waypoints);
          print(
              'lengthhh: ${step.polylineCoordinates.length} and waypoint: ${waypoints}');
          print('laman nyan: ${step.polylinePoints}');
        }

        print(
            'Match: origin: ${route.origin}, ${originLocation} distance: $originDistance destination: ${route.destination}, ${destinationLocation} distance: $destinationDistance ');
      } else {
        print(
            'Not Match: origin: ${route.origin}, ${originLocation} distance: $originDistance destination: ${route.destination}, ${destinationLocation} distance: $destinationDistance ');
      }
    }
    allRoutes = Future.value(nearbyRoutes); // Assign the list to allRoutes
    allPaths.addAll(nearbyRoutes);

    print('Nearby Routes Count: ${nearbyRoutes.length}');
  }

  double calculateDistances(LatLng point1, LatLng point2) {
    //calculate distance between two LatLng points (in meters)
    // Use haversine formula to calculate distance between two LatLng points
    const double R = 6371000; // Earth radius in meters
    final dLat = radians(point2.latitude - point1.latitude);
    final dLon = radians(point2.longitude - point1.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(radians(point1.latitude)) *
            cos(radians(point2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double radians(double degrees) {
    return degrees * (pi / 180.0);
  }

  //--------------------------------------------------------Travel Time
  final Map<String, double> _cache = {};

  Future<double> getTravelTimeWithTraffic({
    required LatLng origin,
    required LatLng destination,
    required List<LatLng> waypoints,
    required String mode,
  }) async {
    // Create a unique cache key
    String waypointsStr =
        waypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|');
    String cacheKey = '${origin.latitude},${origin.longitude}-'
        '${destination.latitude},${destination.longitude}-'
        '$waypointsStr-$mode';

    print('waypoint: $waypointsStr');

    // Check if the result is already cached
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // Construct the API URL
    String url = 'https://maps.googleapis.com/maps/api/distancematrix/json?'
        'origins=${origin.latitude},${origin.longitude}&'
        'destinations=${destination.latitude},${destination.longitude}&'
        'waypoints=$waypointsStr&'
        'mode=$mode&'
        'departure_time=now&'
        'key=$apiKey';

    print('Request URL: $url');

    // Make the API request
    final response = await http.get(Uri.parse(url));
    print('API Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Check if the data contains rows and elements
      if (data.containsKey('rows') && data['rows'] is List) {
        final rows = data['rows'] as List;
        if (rows.isNotEmpty) {
          final elements = rows.first['elements'] as List;
          if (elements.isNotEmpty) {
            // Use the "duration_in_traffic" field instead of "duration"
            final durationInTraffic =
                elements.first['duration_in_traffic']?['value'];
            final duration = elements.first['duration']?['value'];

            final travelTime = durationInTraffic ??
                duration; // Fallback to regular duration if traffic data is missing
            if (travelTime != null) {
              final travelTimeInMinute =
                  travelTime / 60.0; // Convert seconds to minutes
              _cache[cacheKey] = travelTimeInMinute; // Cache the result
              return travelTimeInMinute;
            }
          }
        }
      }

      // If 'rows' or 'elements' are missing, log the full response
      print('Unexpected API response structure: ${jsonEncode(data)}');
      throw Exception('Unexpected API response structure: ${jsonEncode(data)}');
    } else {
      throw Exception(
          'API call failed with status: ${response.statusCode}, body: ${response.body}');
    }
  }

  double totalTravelTime = 0.0;

  void calculateTotalTravelTime() async {
    double newTotalTravelTime = 0.0;
    double time = 0.0;
    List<RouteSuggestionUser> allroutes = await allRoutes;

    for (var route in allroutes) {
      print("Route ID: ${route.id}, Name: ${route.name}");
      for (var step in route.steps) {
        final List<LatLng> waypoints = step.polylinePoints
            .map((point) => LatLng(point.xCoordinate, point.yCoordinate))
            .toList();
        String mode = step.transportationName.toLowerCase() == 'walking'
            ? 'walking'
            : 'driving';

        time = await getTravelTimeWithTraffic(
          origin: step.getOnCoordinates,
          destination: step.getOffCoordinates,
          waypoints: waypoints,
          mode: mode,
        );
        step.travelTime = time;

        newTotalTravelTime += time;
      }
    }

    setState(() {
      totalTravelTime = newTotalTravelTime;
    });

    print('Total Travel Time: $totalTravelTime minutes');
  }

  //-----------------------------------------------------------route coordinates on road
  Future<List<LatLng>> fetchRouteCoordinates(
      LatLng start, LatLng end, List<LatLng> waypoints) async {
    print('apiKey count: fetchRouteCoordinates');
    String waypointsString = waypoints
        .map((point) => '${point.latitude},${point.longitude}')
        .join('|');
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&waypoints=optimize:false|$waypointsString&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(data); // Log the response for debugging

      if (data['routes'].isNotEmpty) {
        final route = data['routes'][0]['overview_polyline']['points'];
        List<LatLng> decodedPoints = decodePolyline(route);

        // Ensure the start and end points are included
        if (decodedPoints.isNotEmpty &&
            (decodedPoints.first != start || decodedPoints.last != end)) {
          decodedPoints = [start, ...decodedPoints, end];
        }
        return decodedPoints;
      } else {
        throw Exception('Failed to get directions: ZERO_RESULTS');
      }
    } else {
      throw Exception('Failed to load directions');
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

  @override
  void initState() {
    super.initState();

    _controllerFrom.text = widget.originName;
    _controllerTo.text = widget.destinationName;

    originlat = double.parse(widget.latOrigin);
    originlong = double.parse(widget.longOrigin);
    destinationlat = double.parse(widget.latDestination);
    destinationlong = double.parse(widget.longDestination);

    originLocation = LatLng(
      double.parse(widget.latOrigin),
      double.parse(widget.longOrigin),
    );

    destinationLocation = LatLng(
      double.parse(widget.latDestination),
      double.parse(widget.longDestination),
    );

    // Ensure routes are fetched before calculating travel time
    Future.microtask(() async {
      await fetchRouteSuggestions();
      testRouteParsing();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: Column(
          children: [
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
                      const Icon(Icons.circle,
                          size: 17, color: Color(0xffc2d0ff)),
                      Container(
                        width: 2,
                        height: 40,
                        color: const Color(0xffc2d0ff),
                      ),
                      const Icon(Icons.location_on,
                          size: 25, color: Color(0xff1f41bb)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        fromTextFormfield(_controllerFrom),
                        const SizedBox(height: 8),
                        toTextFormfield(_controllerTo),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

                  /*
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '$destinationName -> $destinationName',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
 */
                ],
              ),
            ),
//             Expanded(
//               child: totalTravelTime == 0.0
//                   ? Center(
//                       child: CircularProgressIndicator(),
//                     )
//                   : ListView.builder(
//                       itemCount: allPaths.length,
//                       itemBuilder: (context, index) {
//                         final route = allPaths[index];
//                         double totalFare = 0.0;

//                         Map<int, StepUser> routeLookup = {
//                           for (var routeData in route.steps)
//                             routeData.id: routeData
//                         };

//                         for (var step in route.steps) {
//                           totalFare += step.fare;
//                         }
//                         List<String> transportationNamesList = [];

// // Loop through the path list
//                         for (var route in route.steps) {
//                           // Access transportationName directly from the route
//                           String transportationName =
//                               route.transportationName?.toLowerCase() ?? '';

//                           // Determine the transportation type
//                           String transpo = '';
//                           if (['jeep', 'uv', 'bus', 'e-jeep']
//                               .contains(transportationName)) {
//                             transpo = '🚍';
//                           } else if (transportationName == 'tricycle') {
//                             transpo = '🛺';
//                           } else {
//                             transpo = '🚶🏻';
//                           }

//                           // Add the transportation type to the list
//                           transportationNamesList.add(transpo);
//                         }

//                         return suggestRoute(
//                             transportationNamesList,
//                             ' ₱${totalFare.toStringAsFixed(2)}',
//                             ' ${totalTravelTime.toStringAsFixed(2)} mins',
//                             SvgPicture.asset('assets/icons/bus2.svg'),
//                             route.steps);
//                       },
//                     ),
//             ),
            Expanded(
              child: totalTravelTime == 0.0
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : FutureBuilder<List<dynamic>>(
                      future: Future(() {
                        // Calculate total time and fare for sorting
                        List<Map<String, dynamic>> sortedRoutes = [];
                        for (var route in allPaths) {
                          double totalFare = 0.0;
                          double totalTimeForPath = 0.0;

                          for (var step in route.steps) {
                            totalFare += step.fare;
                            totalTimeForPath += step.travelTime ?? 0.0;
                          }

                          sortedRoutes.add({
                            'route': route,
                            'totalFare': totalFare,
                            'totalTime': totalTimeForPath,
                          });
                        }

                        // Sort by totalTime first, then by totalFare for the same time
                        sortedRoutes.sort((a, b) {
                          if (a['totalTime'] != b['totalTime']) {
                            return a['totalTime'].compareTo(b['totalTime']);
                          } else {
                            return a['totalFare'].compareTo(b['totalFare']);
                          }
                        });

                        return sortedRoutes;
                      }),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                            ),
                          );
                        } else if (snapshot.hasData && snapshot.data != null) {
                          final sortedRoutes =
                              snapshot.data! as List<Map<String, dynamic>>;

                          return ListView.builder(
                            itemCount: sortedRoutes.length,
                            itemBuilder: (context, index) {
                              final sortedRoute = sortedRoutes[index];
                              final route = sortedRoute['route'];
                              final totalFare = sortedRoute['totalFare'];
                              final totalTimeForPath = sortedRoute['totalTime'];

                              // Convert totalTimeForPath (in minutes) to hours and minutes
                              int hours = totalTimeForPath ~/ 60; // Get hours
                              int minutes = (totalTimeForPath % 60)
                                  .round(); // Get minutes

                              // Format the time as "X hour(s) Y min(s)"
                              String formattedTime;
                              if (hours > 0) {
                                formattedTime =
                                    '$hours hour${hours != 1 ? 's' : ''} $minutes minute${minutes != 1 ? 's' : ''}';
                              } else {
                                formattedTime =
                                    '$minutes minute${minutes != 1 ? 's' : ''}';
                              }

                              // Generate transportation names list
                              List<String> transportationNamesList = [];
                              for (var step in route.steps) {
                                String transportationName =
                                    step.transportationName?.toLowerCase() ??
                                        '';
                                if (['jeep', 'uv', 'bus', 'e-jeep']
                                    .contains(transportationName)) {
                                  transportationNamesList.add('🚍');
                                } else if (transportationName == 'tricycle') {
                                  transportationNamesList.add('🛺');
                                } else {
                                  transportationNamesList.add('🚶🏻');
                                }
                              }

                              // Determine SVG icon based on sorting criteria
                              SvgPicture icon;
                              bool isSmallestFare = totalFare ==
                                  sortedRoutes
                                      .map((e) => e['totalFare'])
                                      .reduce((value, element) =>
                                          value < element ? value : element);
                              bool isSmallestTime = totalTimeForPath ==
                                  sortedRoutes
                                      .map((e) => e['totalTime'])
                                      .reduce((value, element) =>
                                          value < element ? value : element);

                              if (isSmallestFare && isSmallestTime) {
                                icon = SvgPicture.asset(
                                  'assets/icons/best.svg',
                                  width: 30,
                                  height: 25,
                                );
                              } else if (isSmallestFare && !isSmallestTime) {
                                icon = SvgPicture.asset(
                                  'assets/icons/saver2.svg',
                                  width: 30,
                                  height: 25,
                                );
                              } else if (isSmallestTime && !isSmallestFare) {
                                icon = SvgPicture.asset(
                                  'assets/icons/Fast.svg',
                                  width: 30,
                                  height: 25,
                                );
                              } else {
                                icon = SvgPicture.asset(
                                  'assets/icons/Standard.svg',
                                  width: 30,
                                  height: 25,
                                );
                              }

                              return suggestRoute(
                                transportationNamesList,
                                ' ₱${totalFare.toStringAsFixed(2)}',
                                ' $formattedTime',
                                icon,
                                route.steps,
                              );
                            },
                          );
                        } else {
                          return Center(
                            child: Text("No route found"),
                          );
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

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
        //onTap: _navigateToSearchPage,
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
        // onTap: _navigateToSearchPage,
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

  Widget suggestRoute(List<String> transpoNames, String fare, String time,
      SvgPicture pic, List<StepUser> steps) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => userRouteSuggest2(
              latOrigin: widget.latOrigin,
              longOrigin: widget.longOrigin,
              latDestination: widget.latDestination,
              longDestination: widget.longDestination,
              steps: steps,
              origin: _controllerFrom.text,
              destination: _controllerTo.text,
              traveltime: time,
            ),
          ),
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
                          transpoNames.join(' > '),
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

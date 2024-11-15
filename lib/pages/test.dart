import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'routeFinder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:capstone/pages/routefinder3.dart';
import 'package:capstone/pages/routeCreation.dart';
import 'dart:math';
import 'package:capstone/step_model.dart';
import 'package:capstone/terminal_model.dart';

class Test extends StatefulWidget {
  final String latOrigin, longOrigin;
  final String latDestination, longDestination;
  final String originName;
  final String destinationName;

  const Test({
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
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Test> {
  // Constants and initial setup variables, including Google Map API key and initial camera position.
  final String apiKey = 'AIzaSyBcUDWZDnJBOX_Q5IOqDJi60RuqJy1-ZkY';
  GoogleMapController? mapController;
  final Set<Polyline> _polylines = {};
  Set<Marker> markers = {};

  //Variables for coordinates, polylines, steps and route selections.
  List<LatLng> polylineCoordinates = [];
  List<Map<String, dynamic>> selectedLegs = [];
  List<Map<String, dynamic>> publicTransportRoutes = [];
  List<dynamic> steps = [];
  Set<Polyline> polylines = {};

  //Controllers for managing input fields for "To" and "From" locations.
  final TextEditingController _controllerTo = TextEditingController();
  final TextEditingController _controllerFrom = TextEditingController();
  bool isSwapped = false;

  //Utility methods for distance and conversion calculations.
  late double distanceMainRoad;
  late double distanceInMeter = 0.0;
  double radians(double degrees) {
    return degrees * (pi / 180.0);
  }

  double _degreeToRadian(double degree) {
    return degree * pi / 180;
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

  double calculateDistance(
      double startLat, double startLng, double endLat, double endLng) {
    const earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _degreeToRadian(endLat - startLat);
    double dLng = _degreeToRadian(endLng - startLng);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreeToRadian(startLat)) *
            cos(_degreeToRadian(endLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Radius of the Earth in kilometers
    final dLat = _degreeToRadian(lat2 - lat1);
    final dLon = _degreeToRadian(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreeToRadian(lat1)) *
            cos(_degreeToRadian(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in kilometers
  }

  //State variables for tracking user's origin, destination, and nearest road coordinates.
  late double originlat, originlong, destinationlat, destinationlong;
  late double origin, destination;
  late String roadLat, roadLng;
  late String lat, long;

  //Methods for initializing the map and setting markers.
  BitmapDescriptor? customIcon;
  void _setCustomMarkerIcon() async {
    customIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(
            size: Size(15, 15)), // You can adjust the size if needed
        'assets/icons/dot.png');
  }

  //Handles user input actions, including swapping 'To' and 'From' fields.
  void swapFields() {
    setState(() {
      isSwapped = !isSwapped;
    });
  }

  void _navigateToSearchPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RouteFinder()),
    );
  }

  //Functions for managing steps, such as walk and transportation steps.
  void walkStep(String instruction, LatLng endlocation) {
    steps.add(WalkStepModel(
      instruction: instruction,
      endlocation: endlocation,
      // Add any additional requirements if needed
    ));
  }

  void transportationStep(String transportation, double fare, String time,
      LatLng geton, LatLng getoff) {
    steps.add(TransportStepModel(
      transportation: transportation,
      fare: fare,
      time: time,
      geton: geton,
      getoff: getoff,
    ));
  }

  //Methods for fetching and displaying suggested routes.------------------------------------------------------------------------------
  double proximityThreshold = 300.0; //meter
  List<RouteSuggest> allRoutes = [];

  Future<void> loadRoutes() async {
    allRoutes = await fetchRoutesFromAPI(); // Load routes into allRoutes
    // You can now use allRoutes for other operations
  }

  Future<List<RouteSuggest>> fetchRoutesFromAPI() async {
    final response = await http
        .get(Uri.parse('https://rutaco.online/routeFinderPhp/routePoints.php'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);

      // Debugging: Print the raw data received from the database
      print("Raw data from API: $data");

      List<RouteSuggest> routeSuggestions =
          await Future.wait(data.map((route) async {
        // Parse the route data using fromJson
        RouteSuggest routeSuggest = RouteSuggest.fromJson(route);
        int franchiseID = routeSuggest
            .franchiseID; // Assuming franchiseID is parsed in fromJson
        LatLng pointA = routeSuggest.pointA;
        LatLng pointB = routeSuggest.pointB;
        List<LatLng> waypoints = routeSuggest.waypoints;
        int terminalID = routeSuggest.terminalID;
        int transportationID = routeSuggest.transportationID;

        // Debugging: Print parsed franchise ID, pointA, pointB, and waypoints
        print(
            "Franchise ID: $franchiseID, Point A: $pointA, Point B: $pointB, Waypoints: $waypoints, transporation id: $transportationID, terminal id: $terminalID ");

        // Fetch the route coordinates using Google Directions API, including waypoints
        List<LatLng> routeCoordinates =
            await fetchRouteCoordinates(pointA, pointB, waypoints);

        // Create individual polyline for this route FOR TESTING
        // Polyline polyline = Polyline(
        //   polylineId:
        //       PolylineId(franchiseID.toString()), // Unique ID for each route
        //   points: routeCoordinates,
        //   color: Colors.blue, // Customize the polyline color
        //   width: 5,
        // );
        // setState(() {
        //   _polylines.add(polyline);
        // });

        // Return RouteSuggest including waypoints
        return RouteSuggest(
          franchiseID: franchiseID,
          pointA: pointA,
          pointB: pointB,
          routeCoordinates: routeCoordinates,
          waypoints: waypoints,
          terminalID: terminalID,
          transportationID: transportationID,
        );
      }).toList());

      return routeSuggestions;
    } else {
      throw Exception('Failed to load routes');
    }
  }

  // Proximity threshold for endpoint (`point_B`) check
  // double endproximityThreshold = 300.0; // meters, for near endpoint

// Proximity threshold for route proximity check
  double routeProximityThreshold = 300.0; // meters, for along the route

  List<RouteSuggest> nearbyRoutes = [];

  Future<void> findNearbyRoutes(LatLng origin) async {
    // Fetch routes from the database
    List<RouteSuggest> routes = await fetchRoutesFromAPI();

    // Check if any route is within proximity of the user's pointA/ destination
    for (var route in routes) {
      // Calculate distance to Point A and Point B
      double distanceToPointA = calculateDistances(origin, route.pointA);
      double distanceToPointB = calculateDistances(origin, route.pointB);

      // Check the distance to each coordinate in the route || NEAR ROUTE - input Origin
      for (var point in route.routeCoordinates) {
        double distanceToRoutePoint = calculateDistances(origin, point);
        if (distanceToRoutePoint <= proximityThreshold) {
          nearbyRoutes.add(route);
        }
      }
      // Optionally log distances for debugging
      print('Route Franchise ID: ${route.franchiseID}');
      print('Distance to Point A: $distanceToPointA meters');
      print('Distance to Point B: $distanceToPointB meters');
    }
    if (nearbyRoutes.isNotEmpty) {
      // Suggest these routes to the user
      displayRoutes(nearbyRoutes);
    } else {
      // No nearby routes found
      print("No routes nearby end");
    }
  }

  List<RouteSuggest> routesEnd = [];
  //Route point b that is near or exactly the destination of the user
  Future<void> neabyRoutesEnd(LatLng destination) async {
    // Routes that end near the destination
    List<RouteSuggest> alongRouteDestination =
        []; // Routes that pass near the destination
    // Check if any route/pointb is within proximity of the destination
    for (var route in nearbyRoutes) {
      // Calculate distance to Point B
      double distanceToPointB = calculateDistances(destination, route.pointB);
      //check if destination is near the point b of terminal
      if (distanceToPointB <= proximityThreshold) {
        print(
            "Destination is near the endpoint (point_B) of route ID: ${route.franchiseID}");
        routesEnd.add(route);
        continue; // No need to check route points if near endpoint
      }
      // If destination is not near `point_B`, check if it lies along the route
      bool destinationOnRoute = false;
      for (var routePoint in route.routeCoordinates) {
        // Calculate distance to each route point
        double distanceToRoutePoint =
            calculateDistances(destination, routePoint);

        // If destination is within the route proximity threshold, add route
        if (distanceToRoutePoint <= routeProximityThreshold) {
          destinationOnRoute = true;
          print(
              "Destination lies along the route of route ID: ${route.franchiseID}");
          alongRouteDestination.add(route);
        }
      }
    }

    // Display the results
    if (routesEnd.isNotEmpty || alongRouteDestination.isNotEmpty) {
      // Display routes ending near the destination
      if (routesEnd.isNotEmpty) {
        print("Routes ending near the destination:");
      }

      // Display routes passing near the destination
      if (alongRouteDestination.isNotEmpty) {
        print("Routes passing along the destination:");
      }
    } else {
      // No nearby routes found
      print("No routes nearby");
    }
  }

// Routes with destination along the path
  List<RouteSuggest> nearEndTerminal = [];
  List<RouteSuggest> alongRoutesTerminal = [];
  Future<void> nearbyTerminalsEnd(
      LatLng destination, List<Terminal> nearestTerminals) async {
    // Fetch the routes first
    List<RouteSuggest> routes = await fetchRoutesFromAPI();

    // Check if any terminal pointB is within proximity of the destination
    for (var terminal in nearestTerminals) {
      // Filter routes by matching terminal ID
      for (var route in routes) {
        if (terminal.id == route.terminalID) {
          // Calculate the distance from the destination to the point B of the route
          double distanceToPointB =
              calculateDistances(destination, route.pointB);

          // Check if the destination is near point B
          if (distanceToPointB <= proximityThreshold) {
            print(
                "Destination is near the endpoint (point_B) of Terminal ID: ${route.terminalID}");
            nearEndTerminal.add(route);
          }

          // Now check if the destination is close to any route point (not just point B)
          bool destinationOnRouteTerminal = false;
          for (var routePoint in route.routeCoordinates) {
            double distanceToRoutePoint =
                calculateDistances(destination, routePoint);

            if (distanceToRoutePoint <= routeProximityThreshold) {
              destinationOnRouteTerminal = true;
              break;
            }
          }

          // If the destination is on the route, add it to alongRoutesTerminal
          if (destinationOnRouteTerminal) {
            print(
                "Destination lies along the route of Terminal ID: ${route.terminalID}");
            alongRoutesTerminal.add(route);
          }
        }
      }
    }

    // Display the results
    if (nearEndTerminal.isNotEmpty || alongRoutesTerminal.isNotEmpty) {
      if (alongRoutesTerminal.isNotEmpty) {
        print("Routes with destination along the route:");
        for (var route in alongRoutesTerminal) {
          print("Franchise ID: ${route.franchiseID}");
        }
      }

      if (nearEndTerminal.isNotEmpty) {
        print("Nearby terminals with point B near the destination:");
        for (var route in nearEndTerminal) {
          print(
              "Terminal ID: ${route.terminalID}, Franchise ID: ${route.franchiseID}");
        }
      }
    } else {
      print("No nearby terminals or routes found.");
    }
  }

  void displayRoutes(List<RouteSuggest> nearbyRoutes) {
    for (var route in nearbyRoutes) {
      print(
          'Nearby Route: Franchise ID: ${route.franchiseID}, Points: ${route.pointA}, ${route.pointB}');
      // You can update your UI here
    }
  }

  Future<List<Terminal>> fetchTerminals() async {
    final response = await http.get(Uri.parse(
        'https://rutaco.online/routeFinderPhp/getTerminalLocation.php'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Terminal.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load terminals');
    }
  }

  void fetchAndPrintRoutes() async {
    try {
      List<RouteSuggest> routes = await fetchRoutesFromAPI();

      // Print the fetched routes for debugging
      for (var route in routes) {
        print(
            'Franchise ID: ${route.franchiseID}, Point A: ${route.pointA}, Point B: ${route.pointB}');
      }
    } catch (e) {
      print('Error fetching routes: $e');
    }
  }

  Future<List<LatLng>> fetchRouteCoordinates(
      LatLng start, LatLng end, List<LatLng> waypoints) async {
    String waypointsString = waypoints
        .map((point) => '${point.latitude},${point.longitude}')
        .join('|');
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&waypoints=$waypointsString&key=AIzaSyBcUDWZDnJBOX_Q5IOqDJi60RuqJy1-ZkY';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(data); // Log the response for debugging

      if (data['routes'].isNotEmpty) {
        final route = data['routes'][0]['overview_polyline']['points'];
        return decodePolyline(route);
      } else {
        throw Exception('Failed to get directions: ZERO_RESULTS');
      }
    } else {
      throw Exception('Failed to load directions');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPublicTransportRoutes(
      String origin, String destination, String apiKey) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=transit&alternatives=true&key=$apiKey';

    print("Request URL: $url"); // Log the URL
    print("Origin: $origin, Destination: $destination, API Key: $apiKey");

    try {
      final response = await http.get(Uri.parse(url));
      print("Response status: ${response.statusCode}"); // Log response status

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print("API Response: ${data.toString()}");

        if (data['status'] == 'OK') {
          List routes = data['routes'];

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

  void getRoutes() async {
    try {
      print(
          'Fetching routes....................................................................................||||||||||||||||||||||||||||');
      String from = _controllerFrom.text;
      String to = _controllerTo.text;

      if (from.isEmpty || to.isEmpty) {
        print('Please enter both origin and destination.');
        return; // Exit if either is empty
      }
      print('From: $from, To: $to'); // Log the values for debugging

      if (from == 'Your Location') {
        // Fetch current location and use latitude/longitude as origin
        Position currentPosition = await getCurrentLocation();
        from = await getAddressFromLatLng(
            currentPosition.latitude, currentPosition.longitude);
        print('Using current location as origin: $from');
      }

      publicTransportRoutes = await fetchPublicTransportRoutes(
        from, // Origin
        to, // Destination
        apiKey,
      );

      print('routess !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! $from, $to');

      for (int i = 0; i < publicTransportRoutes.length; i++) {
        final route = publicTransportRoutes[i];
        final legs = route['legs'];

        if (legs == null) {
          print('No legs found for route $i');
          continue; // Skip this route if no legs are found
        }

        print('Route $i:');
        for (int j = 0; j < legs.length; j++) {
          final leg = legs[j];
          print('  Leg $j:');
          print('    Start Address: ${leg['start_address']}');
          print('    End Address: ${leg['end_address']}');
          print('    Duration: ${leg['duration']['text']}');
          print('    Distance: ${leg['distance']['text']}');

          if (leg['steps'] == null) {
            print('No steps found for leg $j');
            continue; // Skip this leg if no steps are found
          }

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

  //tranfer routes --------------------------------------------------------------------------------------------------------------------
  // Define a list to store connecting terminals

  // Helper function to fetch routes associated with a specific terminal ID
  Future<List<RouteSuggest>> routesForTerminal(int terminalId) async {
    // Filter routes by terminal ID
    List<RouteSuggest> terminalRoutes =
        allRoutes.where((route) => route.terminalID == terminalId).toList();

    return terminalRoutes;
  }

  List<TerminalPath> allConnectingPaths = []; // Store all connecting paths

  //v2
  List<TransferPoint> findTransferPoints(
      List<RouteSuggest> nearbyRoutes, List<RouteSuggest> routesEnd) {
    List<TransferPoint> transferPoints = [];

    // Early exit if there are no nearby or destination routes
    if (nearbyRoutes.isEmpty || routesEnd.isEmpty) {
      print("No nearby or destination routes to check for transfers.");
      return [];
    }

    // Iterate over each nearby route from the origin
    for (var originRoute in nearbyRoutes) {
      // Iterate over each route ending near the destination
      for (var destinationRoute in routesEnd) {
        // Check for transfer points near the coordinates of both routes
        for (var originPoint in originRoute.routeCoordinates) {
          for (var destinationPoint in destinationRoute.routeCoordinates) {
            // Calculate the distance between the two points
            double transferDistance =
                calculateDistances(originPoint, destinationPoint);

            if (transferDistance <= routeProximityThreshold) {
              // Check if this transfer point already exists in the list
              bool isDuplicate1 = false;
              for (var tp in transferPoints) {
                // Check if the transfer point with the same origin and destination already exists
                if (tp.fromRoute.franchiseID == originRoute.franchiseID &&
                    tp.toRoute.franchiseID == destinationRoute.franchiseID) {
                  isDuplicate1 = true;
                }
              }
              //Add the transfer point if it's not a duplicate
              if (!isDuplicate1) {
                print(
                    "Transfer point found between Route ${originRoute.franchiseID} and Route ${destinationRoute.franchiseID} at $originPoint and $destinationPoint");

                // transferPoints.add(TransferPoint(
                //   fromRoute: originRoute,
                //   toRoute: destinationRoute,
                //   transferLocation:
                //       destinationRoute.pointA, // Location where transfer occurs
                // ));
              }
            }
          }
        }
      }
    }

    // Log results if transfer points are identified
    if (transferPoints.isNotEmpty) {
      print("Transfer points found:");
      for (var transfer in transferPoints) {
        print(
            "Transfer from Route ${transfer.fromRoute.franchiseID} to Route ${transfer.toRoute.franchiseID} at ${transfer.transferLocation}");
      }
    } else {
      print("No transfer points found between routes.");
    }

    return transferPoints; // Return the list of transfer points
  }

  List<List<TransferPoint>> findConnectedTransferPaths(
      List<RouteSuggest> nearbyRoutes,
      List<RouteSuggest> routesEnd,
      LatLng destination) {
    List<List<TransferPoint>> connectedPaths =
        []; // Stores all possible paths to destination

    // Early exit if routes are not available
    if (nearbyRoutes.isEmpty || routesEnd.isEmpty) {
      print("No nearby or destination routes to check for transfers.");
      return [];
    }

    // Helper function for recursive path finding
    List<List<RouteSuggest>> findPath(
        RouteSuggest startRoute,
        LatLng destination,
        List<RouteSuggest> allRoutes,
        double routeProximityThreshold) {
      List<List<RouteSuggest>> paths = [];
      Queue<List<RouteSuggest>> queue = Queue();
      queue.add([startRoute]);

      while (queue.isNotEmpty) {
        List<RouteSuggest> currentPath = queue.removeFirst();
        RouteSuggest currentRoute = currentPath.last;

        // Check if any point along the current route is near the destination
        for (var routePoint in currentRoute.routeCoordinates) {
          if (calculateDistances(routePoint, destination) <=
              routeProximityThreshold) {
            // If near the destination, mark this path as complete
            paths.add(currentPath);
            print("Path found to destination at $routePoint");
            break;
          }
        }

        // If this route has not reached the destination, continue finding transfer points
        if (paths.isEmpty || paths.last != currentPath) {
          List<TransferPoint> transferPoints =
              findTransferPoints([currentRoute], allRoutes);

          for (var transfer in transferPoints) {
            // Check if this route has already been visited in the current path
            if (!currentPath.contains(transfer.toRoute)) {
              List<RouteSuggest> newPath = List.from(currentPath);
              newPath.add(transfer.toRoute);
              queue.add(newPath);
            }
          }
        }
      }

      return paths;
    }

    List<List<RouteSuggest>> allPaths = [];

    // Start pathfinding for each route in nearbyRoutes
    for (var originRoute in nearbyRoutes) {
      // Find paths from each originRoute to the destination
      List<List<RouteSuggest>> pathsFromOrigin = findPath(
          originRoute, destination, allRoutes, routeProximityThreshold);

      // Add the found paths to the allPaths list
      allPaths.addAll(pathsFromOrigin);
    }

// Now allPaths contains all routes leading from any nearby origin route to the destination
    print("All possible paths to destination: ");
    for (var path in allPaths) {
      print("Path: ${path.map((route) => route.franchiseID).join(' -> ')}");
    }

    // Log results if paths are identified
    if (connectedPaths.isNotEmpty) {
      print("Connected paths leading to destination found:");
      for (var path in connectedPaths) {
        print("Path:");
        for (var transfer in path) {
          print(
              "Transfer from Route ${transfer.fromRoute.franchiseID} to Route ${transfer.toRoute.franchiseID} at ${transfer.transferLocation}");
        }
      }
    } else {
      print("No connected paths to destination found.");
    }

    return connectedPaths;
  }

//end transfer routes----------------------------------------------------------------------------------------------------------------

  //Methods for fetching location data, such as nearest terminal, road, and public transport routes.
  // Global variable to store nearest terminals

  Future<List<Terminal>> getNearestTerminals(LatLng location) async {
    // Fetch all available terminals
    List<Terminal> terminals = await fetchTerminals();
    List<Terminal> nearestTerminals = [];

    // Clear the global list to avoid duplicate entries from previous calls
    //nearestTerminals.clear();

    LatLng origin = LatLng(location.latitude, location.longitude);

    for (Terminal terminal in terminals) {
      LatLng terminalLocation = LatLng(terminal.latitude, terminal.longitude);
      double distance = calculateDistances(origin, terminalLocation);

      print(
          'Threshold: $distance , Distance: $distance , Terminal: ${terminal.latitude}, ${terminal.longitude}, Location: $origin');

      // Check if terminal is within the minimum distance threshold
      if (proximityThreshold > distance) {
        nearestTerminals.add(terminal);
        print('Nearest Terminal: ${terminal.name}');
      }
    }

    // Check if any terminals were found within the threshold
    if (nearestTerminals.isNotEmpty) {
      print('Nearest terminals found and stored in global variable.');
    } else {
      print('No terminals found within proximity threshold.');
    }

    // Return the list of nearest terminals
    return nearestTerminals;
  }

  Future<void> getNearestRoad(double latitude, double longitude) async {
    final String url =
        'https://roads.googleapis.com/v1/snapToRoads?path=$latitude,$longitude&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Handle the response data
      if (data['snappedPoints'].isNotEmpty) {
        var nearestRoad = data['snappedPoints'][0];
        roadLat = nearestRoad['location']['latitude'].toString();
        roadLng = nearestRoad['location']['longitude'].toString();
        print('Nearest Road: ${nearestRoad['location']}');

        // Now calculate the distance once the roadLat and roadLng are available
        if (lat.isNotEmpty && long.isNotEmpty) {
          double distanceMainRoad = haversineDistance(
            double.parse(lat),
            double.parse(long),
            double.parse(roadLat),
            double.parse(roadLng),
          );
          distanceInMeter = distanceMainRoad * 1000;

          print(
              'haaaaaaaaaaaaaaaaaaaaaaaaaaa----------------------------- $roadLat , $roadLng');
          print('Distance to nearest main road: $distanceMainRoad');
          print(
              'Distance to nearest main road: ${distanceInMeter.toStringAsFixed(2)} meters');
        } else {
          print(
              'Error: Unable to calculate distance, lat/long values are missing.');
        }
      } else {
        print('No roads found nearby.');
      }
    } else {
      print('Failed to get nearest road: ${response.statusCode}');
    }
  }

  Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      // Get the list of placemarks from the coordinates
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      // Get the first placemark (usually the most accurate)
      Placemark place = placemarks[0];

      // Return a more structured format similar to Google Maps
      // Example: "Place Name, Locality, City, Country"
      return "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
    } catch (e) {
      print(e);
      return "Address not found"; // Return null if there's an error
    }
  }

  Future<void> checkNearest() async {
    Position userLocation = await getCurrentLocation();

    // Get nearest road
    await getNearestRoad(originlat, originlong);
    print('srfgswrgwr $originlat , $originlong');

    // // Find nearby public terminals
    // await findNearbyTerminals(userLocation.latitude, userLocation.longitude);
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location service are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permission is denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  //Methods for adding steps to the route.
  late bool tricycle = false;
  Future<void> addStep() async {
    if (distanceInMeter < 200 ||
        (distanceInMeter >= 200 && tricycle == false)) {
      // walk == true
      LatLng endwalk = LatLng(double.parse(roadLat), double.parse(roadLng));
      String endwalkAddress = await getAddressFromLatLng(
          double.parse(roadLat), double.parse(roadLng));
      walkStep('Walk to $endwalkAddress', endwalk);

      for (var s in steps) {
        print('${s}eyyyyyyyyyyyyy');
      }

      print(
          'end walk------------------ $endwalk and $endwalkAddress ------------=====================');
    } else if (distanceInMeter >= 200 && tricycle == true) {
      //walk = false
      print('noooooooooooooooooooooooo');
    }
  }

  //Additional route fetching and decoding methods.

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
                // _markers.add(
                //   Marker(
                //     markerId: const MarkerId('start_marker'),
                //     position: startLocation,
                //     icon: customIcon ?? BitmapDescriptor.defaultMarker,
                //     infoWindow: const InfoWindow(title: 'Start Location'),
                //   ),
                // );

                // _markers.add(
                //   Marker(
                //     markerId: const MarkerId('end_marker'),
                //     position: endLocation,
                //     icon: customIcon ?? BitmapDescriptor.defaultMarker,
                //     infoWindow: const InfoWindow(title: 'End Location'),
                //   ),
                // );
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

  List<LatLng> decodePolylines(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int shift = 0, result = 0;
      int b;
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

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  //Helper functions, such as parseDouble or any additional utility functions.
  double parseDouble(String value) {
    try {
      return double.parse(value);
    } catch (e) {
      print('Error parsing double: $e');
      // Return a default value or handle the error as needed
      return 0.0;
    }
  }

  late LatLng originLocation;
  late LatLng destinationLocation;

  // In initState
  initData() async {
    // Step 1: Find Nearby Routes
    await findNearbyRoutes(originLocation);
    if (nearbyRoutes.isNotEmpty) {
      List<RouteSuggest> routesTerminal = await fetchRoutesFromAPI();
      neabyRoutesEnd(destinationLocation);
// Find and store transfer points
      List<TransferPoint> transferPoints =
          findTransferPoints(nearbyRoutes, routesTerminal);

      // Correct call:
      findConnectedTransferPaths(
          nearbyRoutes, routesTerminal, destinationLocation);
    } else {
      print("No nearby routes found after initialization.");
    }

    // Step 2: Get Nearest Terminals after routes
    final nearestTerminals = await getNearestTerminals(originLocation);
    if (nearestTerminals.isNotEmpty) {
      nearbyTerminalsEnd(destinationLocation, nearestTerminals);
      // Optionally: findConnectingTerminals(destinationLocation, nearestTerminals);
    } else {
      print("No nearby terminals found after initialization.");
    }
  }

  // INITSTATE
  @override
  void initState() {
    super.initState();
    _controllerTo.text = widget.originName;
    _controllerFrom.text = widget.destinationName;

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

    loadRoutes();

    // Fetch routes and terminals
    fetchAndPrintRoutes(); //debugging
    fetchRoute();

    // // Fetch nearby routes and terminals, then find transfer options
    // Future.wait([
    //   findNearbyRoutes(originLocation).then((_) {
    //     if (nearbyRoutes.isNotEmpty) {
    //       neabyRoutesEnd(destinationLocation);
    //       findTransferOptionsFromPointB(originLocation, allRoutes);
    //     } else {
    //       print("No nearby routes found after initialization.");
    //     }
    //   }),
    //   getNearestTerminals(originLocation).then((nearestTerminals) {
    //     if (nearestTerminals.isNotEmpty) {
    //       nearbyTerminalsEnd(destinationLocation, nearestTerminals);
    //       //findConnectingTerminals(destinationLocation, nearestTerminals);
    //     } else {
    //       print("No nearby terminals found after initialization.");
    //     }
    //   }),
    // ]);
    setState(() {});

    initData();

    //TESt - ongoing
    //testFetchRouteCoordinates();

    //TESt
    checkNearest().then((_) {
      addStep();
    });
    //gps
    getCurrentLocation().then(
      (value) {
        lat = '${value.latitude}';
        long = '${value.longitude}';
        setState(() {
          print('Latitude: $lat, Longtitude: $long');
          markers.add(Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(value.latitude, value.longitude),
            infoWindow: const InfoWindow(title: 'Current Location'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ));
        });
        // liveLocation();
      },
    );

    _setCustomMarkerIcon();
    getRoutes();
  }

  //Widget builder methods for the main app layout and text fields.
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

//List of suggested route
            if (_controllerFrom.text.isNotEmpty &&
                _controllerTo.text.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: publicTransportRoutes.length +
                      1, // Add 1 for suggestion button

                  itemBuilder: (context, index) {
                    if (index == publicTransportRoutes.length) {
                      // suggest button
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 30),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(
                                    0, 3), // Changes position of shadow
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize:
                                MainAxisSize.min, // Adjusts size to content
                            children: [
                              const Text(
                                'Do you want to suggest alternative route?',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(
                                  height: 5), // Spacing between text and button
                              SizedBox(
                                width: 232, // Full-width button
                                height: 35, // Set the height
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const RouteCreation()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(
                                        0xff1f41bb), // Button background color
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          30), // Rounded corners
                                    ),
                                  ),
                                  child: const Text(
                                    'Suggest alternative route to earn points',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Handle route items
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
              )
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
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        polylines: _polylines,
        //polylines: _polylines,
        //markers: markers,
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
          if (markers.isNotEmpty) {
            mapController
                ?.animateCamera(CameraUpdate.newLatLng(markers.first.position));
          }
        },
      ),
    );
  }

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
                  latOrigin: widget.latOrigin,
                  longOrigin: widget.latOrigin,
                  latDestination: widget.latDestination,
                  longDestination: widget.longDestination,
                  // legs: legs,
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
                    // Row(
                    //   children: [
                    //     Container(
                    //       padding: const EdgeInsets.only(
                    //           right: 8.0), // Space between the two texts
                    //       child: const Text(
                    //         "Fare:",
                    //         style: TextStyle(color: Colors.black),
                    //         textAlign:
                    //             TextAlign.start, // Align text to the start
                    //       ),
                    //     ),
                    //     Text(
                    //       fare,
                    //       style: const TextStyle(color: Colors.black),
                    //       textAlign: TextAlign.start, // Align text to the start
                    //     ),
                    //   ],
                    // ),
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

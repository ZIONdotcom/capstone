import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'routeFinder.dart';
import 'package:capstone/pages/routefinder3.dart';
import 'package:capstone/pages/routeCreation.dart';
import 'dart:math';
import 'package:capstone/step_model.dart';
import 'package:capstone/terminal_model.dart';
import 'package:capstone/LegStepAlgo_model.dart';

class RouteFinderAlgo extends StatefulWidget {
  final String latOrigin;
  final String longOrigin;
  final String latDestination;
  final String longDestination;
  final String originName;
  final String destinationName;

  const RouteFinderAlgo({
    super.key,
    required this.latOrigin,
    required this.longOrigin,
    required this.latDestination,
    required this.longDestination,
    required this.destinationName,
    required this.originName,
  });

  @override
  _RouteScreenState createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteFinderAlgo> {
  final TextEditingController _controllerFrom = TextEditingController();
  final TextEditingController _controllerTo = TextEditingController();
  final List<Map<String, dynamic>> publicTransportRoutes = [];
  List<Map<String, dynamic>> selectedLegs = [];
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  final String apiKey = 'AIzaSyBcUDWZDnJBOX_Q5IOqDJi60RuqJy1-ZkY';
  late double originlat, originlong, destinationlat, destinationlong;
  late LatLng originLocation;
  late LatLng destinationLocation;
  late String lat, long;
  double proximityThreshold = 300.0; //meter
  List<RouteSuggest> allRoutes = [];
  List<RouteSuggest> routesEnd = [];
  double routeProximityThreshold = 300.0;
  Queue<List<RouteSuggest>> queue = Queue();
  List<List<RouteSuggest>> allPaths = [];

  //  final response = await http.post(
  //     Uri.parse('https://rutaco.online/routeFinderPhp/routeDetailsFetch.php'),

  List<CombinedRouteData> combineRouteData(List<RouteSuggest> routeSuggestList,
      List<RouteDetail> routeDetailList, double distance) {
    List<CombinedRouteData> combinedData = [];

    // Create a map for fast lookup of RouteDetail by franchiseID
    Map<int, RouteDetail> routeDetailMap = {
      for (var routeDetail in routeDetailList)
        routeDetail.franchiseId: routeDetail
    };

    // Combine data based on franchiseID
    for (var routeSuggest in routeSuggestList) {
      // Find the corresponding RouteDetail using franchiseID
      RouteDetail? routeDetail = routeDetailMap[routeSuggest.franchiseID];

      // if (routeDetail != null) {
      //   // Create CombinedRouteData by merging RouteSuggest and RouteDetail
      //   combinedData.add(CombinedRouteData(
      //     franchiseID: routeSuggest.franchiseID,
      //     pointA: routeSuggest.pointA,
      //     pointB: routeSuggest.pointB,
      //     waypoints: routeSuggest.waypoints,
      //     routeCoordinates: routeSuggest.routeCoordinates,
      //     terminalID: routeSuggest.terminalID,
      //     transportationID: routeSuggest.transportationID,
      //     transportationName: routeDetail.transportationName,
      //     regularFare: routeDetail.regularFare,
      //     discountedFare: routeDetail.discountedFare,
      //     perKMfare: routeDetail.perKMfare,

      //   ));
      // }
    }

    return combinedData;
  }

  //fetch route detail --------------------------------------------------------

// Define the method that processes and groups PathDetails
  List<List<Map<int, PathDetail>>> groupPathDetailsByFranchiseId(
      List<PathDetail> pathDetails) {
    // Initialize allPaths
    List<List<Map<int, PathDetail>>> allPaths = [];

    // Group the PathDetails by franchiseId
    var groupedPaths = <int, List<PathDetail>>{};

    for (var pathDetail in pathDetails) {
      if (groupedPaths.containsKey(pathDetail.franchiseId)) {
        groupedPaths[pathDetail.franchiseId]!.add(pathDetail);
      } else {
        groupedPaths[pathDetail.franchiseId] = [pathDetail];
      }
    }

    // Convert the grouped paths to the desired structure
    groupedPaths.forEach((franchiseId, paths) {
      List<Map<int, PathDetail>> pathMapList = paths.map((path) {
        return {franchiseId: path};
      }).toList();
      allPaths.add(pathMapList);
    });

    return allPaths;
  }

  Future<List<RouteDetail>> fetchRouteDetails(List<int> franchiseIDs) async {
    final response = await http.post(
      Uri.parse('https://rutaco.online/routeFinderPhp/routeDetailsFetch.php'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'franchise_ids': franchiseIDs}),
    );
    // Debug: Print the raw response body
    print("Response body route: ${response.body}");

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);

      setState(() {
        _routeDetails = data.map((item) => RouteDetail.fromJson(item)).toList();
        _isLoading = false;
      });

      // Parse data into RouteDetail objects
      return data.map((item) => RouteDetail.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load route details');
    }
  }

  List<RouteDetail> _routeDetails = [];
  bool _isLoading = true;

  Future<void> fetchRouteDetailsFromAPI() async {
    try {
      // Get the franchise IDs
      List<int> franchiseIDs = allPaths
          .expand((pathList) => pathList.map((route) => route.franchiseID))
          .toSet()
          .toList();

      print('franchise id all paths: $franchiseIDs');

      // Await the response from fetchRouteDetails
      List<RouteDetail> details = await fetchRouteDetails(franchiseIDs);

      // Print each RouteDetail for debugging
      for (var detail in details) {
        print(
            "Franchise ID: ${detail.franchiseId} | Transportation Name: ${detail.transportationName} | Regular Fare: ${detail.regularFare} | Discounted Fare: ${detail.discountedFare} | Point A: ${detail.pointA} | Point B: ${detail.pointB} | Terminal ID: ${detail.terminalId}");
      }
    } catch (e) {
      print("Error fetching route details: $e");
    }
  }

  //end fetch route detail ----------------------------------

  //RouteSuggestion--------------------------------------------------------------------------------------------------------------------

  Future<void> loadRoutes() async {
    allRoutes = await fetchRoutesFromAPI(); // Load routes into allRoutes
    // You can now use allRoutes for other operations
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

  //---------------polyline
  final Set<Polyline> _polylines = {};

  Future<void> _fetchAndDisplayRoutes() async {
    List<RouteSuggest> routeSuggestions = await fetchRoutesFromAPI();

    for (var routeSuggest in routeSuggestions) {
      _addPolyline(
        routeSuggest.franchiseID.toString(),
        routeSuggest.routeCoordinates,
      );
    }
  }

  void _addPolyline(String id, List<LatLng> coordinates) {
    final polyline = Polyline(
      polylineId: PolylineId(id),
      color: Colors.blue, // Customize color for each route if needed
      width: 5,
      points: coordinates,
    );

    setState(() {
      _polylines.add(polyline);
    });
  }

  //-------------------------------

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

  void displayRoutes(List<RouteSuggest> nearbyRoutes) {
    for (var route in nearbyRoutes) {
      print(
          'Nearby Route: Franchise ID: ${route.franchiseID}, Points: ${route.pointA}, ${route.pointB}');
      // You can update your UI here
    }
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

  //transfer routes--------------------------------------------------------------------------------------------------------------

  // List<TransferPoint> findTransferPoints(
  //     List<RouteSuggest> nearbyRoutes, List<RouteSuggest> routesEnd) {
  //   List<TransferPoint> transferPoints = [];

  //   // Early exit if there are no nearby or destination routes
  //   if (nearbyRoutes.isEmpty || routesEnd.isEmpty) {
  //     print("No nearby or destination routes to check for transfers.");
  //     return [];
  //   }

  //   // Iterate over each nearby route from the origin
  //   for (var originRoute in nearbyRoutes) {
  //     // Iterate over each route ending near the destination
  //     for (var destinationRoute in routesEnd) {
  //       // Check for transfer points near the coordinates of both routes
  //       for (var originPoint in originRoute.routeCoordinates) {
  //         for (var destinationPoint in destinationRoute.routeCoordinates) {
  //           // Calculate the distance between the two points
  //           double transferDistance =
  //               calculateDistances(originPoint, destinationPoint);

  //           if (transferDistance <= routeProximityThreshold) {
  //             // Check if this transfer point already exists in the list
  //             bool isDuplicate1 = false;
  //             for (var tp in transferPoints) {
  //               // Check if the transfer point with the same origin and destination already exists
  //               if (tp.fromRoute.franchiseID == originRoute.franchiseID &&
  //                   tp.toRoute.franchiseID == destinationRoute.franchiseID) {
  //                 isDuplicate1 = true;
  //               }
  //             }
  //             //Add the transfer point if it's not a duplicate
  //             if (!isDuplicate1) {
  //               print(
  //                   "Transfer point found between Route ${originRoute.franchiseID} and Route ${destinationRoute.franchiseID} at $originPoint and $destinationPoint");

  //               transferPoints.add(TransferPoint(
  //                 fromRoute: originRoute,
  //                 toRoute: destinationRoute,
  //                 transferLocation:
  //                     destinationPoint, // Location where transfer occurs
  //               ));
  //             }
  //           }
  //         }
  //       }
  //     }
  //   }

  //   // Log results if transfer points are identified
  //   if (transferPoints.isNotEmpty) {
  //     print("Transfer points found:");
  //     for (var transfer in transferPoints) {
  //       print(
  //           "Transfer from Route ${transfer.fromRoute.franchiseID} to Route ${transfer.toRoute.franchiseID} at ${transfer.transferLocation}");
  //     }
  //   } else {
  //     print("No transfer points found between routes.");
  //   }

  //   return transferPoints; // Return the list of transfer points
  // }

  Future<List<List<TransferPoint>>> findConnectedTransferPaths(
      List<RouteSuggest> nearbyRoutes,
      List<RouteSuggest> routesEnd,
      LatLng destination) async {
    List<List<TransferPoint>> connectedPaths = [];
    if (nearbyRoutes.isEmpty || routesEnd.isEmpty) {
      print("No nearby or destination routes to check for transfers.");
      return [];
    }
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
        double distanceTraveled = 0.0;
        for (int i = 0; i < currentRoute.routeCoordinates.length; i++) {
          var routePoint = currentRoute.routeCoordinates[i];

          if (i > 0) {
            distanceTraveled += calculateDistances(
                currentRoute.routeCoordinates[i - 1], routePoint);
          }
          if (distanceTraveled >= 500) {
            if (calculateDistances(routePoint, destination) <=
                routeProximityThreshold) {
              // If near the destination, mark this path as complete
              paths.add(currentPath);
              print("Path found to destination at $routePoint");
              return paths; // Stop once destination is found
            }
          }
        }
      }
      return paths;
    }

    for (var originRoute in nearbyRoutes) {
      List<List<RouteSuggest>> pathsFromOrigin = findPath(
          originRoute, destination, routesEnd, routeProximityThreshold);
      allPaths.addAll(pathsFromOrigin);
    }
    print("All possible paths to destination: ");
    for (var path in allPaths) {
      print("Path: ${path.map((route) => route.franchiseID).join(' -> ')}");

      print("All possible paths to destination:");
      for (var route in path) {
        print("Path: ${path.map((route) => route.franchiseID).join(' -> ')}");
        print("franchiseIDDD: ${route.franchiseID}");
      }
    }
    if (allPaths.isNotEmpty) {
      for (var pathIndex = 0; pathIndex < allPaths.length; pathIndex++) {
        print("Path ${pathIndex + 1}:");

        List<RouteSuggest> path = allPaths[pathIndex];
        for (var routeIndex = 0; routeIndex < path.length; routeIndex++) {
          RouteSuggest route = path[routeIndex];
          print(
              "Routess: ${routeIndex + 1}: Franchise ID: ${route.franchiseID} Route Coordinates: ${route.routeCoordinates}");
          print("  ");
          print("  ");
        }
      }
    }
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

//transfer routes--------------------------------------------------------------------------------------------------------------

  initData() async {
    // Step 1: Find Nearby Routes
    await findNearbyRoutes(originLocation);
    if (nearbyRoutes.isNotEmpty) {
      List<RouteSuggest> routesTerminal = await fetchRoutesFromAPI();
      neabyRoutesEnd(destinationLocation);
// Find and store transfer points
      // List<TransferPoint> transferPoints =
      //     findTransferPoints(nearbyRoutes, routesTerminal);
      // Correct call:
      findConnectedTransferPaths(
          nearbyRoutes, routesTerminal, destinationLocation);
      if (allPaths.isNotEmpty) {
        fetchRouteDetailsFromAPI();
      } else {
        print('it was empty');
      }
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

    initData();
    _fetchAndDisplayRoutes();

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
  }

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
            const SizedBox(height: 16),
            buildMap(),
            const SizedBox(height: 20),
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
            const SizedBox(height: 10),
            if (_controllerFrom.text.isNotEmpty &&
                _controllerTo.text.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: allPaths.length + 1,
                  itemBuilder: (context, index) {
                    if (index == allPaths.length) {
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
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
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
                              const SizedBox(height: 5),
                              SizedBox(
                                width: 232,
                                height: 35,
                                child: ElevatedButton(
                                  onPressed: navigateToRouteCreation,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff1f41bb),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
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
                    return null;
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

//UI-----------------------------------------------------------------------------------------------------------

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

  double parseDouble(String value) {
    try {
      return double.parse(value);
    } catch (e) {
      print('Error parsing double: $e');
      // Return a default value or handle the error as needed
      return 0.0;
    }
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
      SvgPicture pic, List<dynamic> steps) {
    return InkWell(
      onTap: () {
        setState(() {
          // selectedLegs = List<Map<String, dynamic>>.from(legs);
        });

        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //       builder: (context) => routefinder3(
        //           latOrigin: widget.latOrigin,
        //           longOrigin: widget.latOrigin,
        //           latDestination: widget.latDestination,
        //           longDestination: widget.longDestination,
        //           steps: steps,
        //           origin: _controllerTo.text,
        //           destination: _controllerFrom.text)),
        // );
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

  void navigateToRouteCreation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Route Creation'),
          content: const Text('This is the route creation page.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  List<dynamic> steps = [];
  //steps data
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
}

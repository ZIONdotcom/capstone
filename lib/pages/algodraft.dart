import 'dart:collection';
import 'dart:convert';

import 'package:capstone/pages/algo3.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:capstone/step_model.dart';
import 'package:capstone/terminal_model.dart';
import 'package:capstone/LegStepAlgo_model.dart';

class RouteFinderAlgodraft extends StatefulWidget {
  final String latOrigin;
  final String longOrigin;
  final String latDestination;
  final String longDestination;
  final String originName;
  final String destinationName;

  const RouteFinderAlgodraft({
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

class _RouteScreenState extends State<RouteFinderAlgodraft> {
  final TextEditingController _controllerFrom = TextEditingController();
  final TextEditingController _controllerTo = TextEditingController();
  final List<Map<String, dynamic>> publicTransportRoutes = [];
  List<Map<String, dynamic>> selectedLegs = [];
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  final String apiKey = '';
  late double originlat, originlong, destinationlat, destinationlong;
  late LatLng originLocation;
  late LatLng destinationLocation;
  late String lat, long;
  double proximityThreshold = 300.0; //meter
  List<RouteSuggest> allRoutes = [];
  List<RouteSuggest> routesEnd = [];
  List<RouteDetail> routeDetails = [];
  double routeProximityThreshold = 300.0;
  Queue<List<RouteSuggest>> queue = Queue();
  List<List<RouteSuggest>> allPaths = [];
  Set<String> seenPaths = {}; // To track unique paths

  List<PathDetail1> pathDetailsList1 = [];

  //  final response = await http.post(
  //     Uri.parse('https://rutaco.online/routeFinderPhp/routeDetailsFetch.php'),

  //Displaying the data to ui---------------------
  Future<List<CombinedRouteData>> combineRouteData(
      List<RouteSuggest> routeSuggestList,
      List<RouteDetail> routeDetailList) async {
    List<CombinedRouteData> combinedData = [];
    // Map<int, String> locationNames = await fetchRouteLocations();

    // Create a map for fast lookup of RouteDetail by franchiseID
    Map<int, RouteDetail> routeDetailMap = {
      for (var routeDetail in routeDetailList)
        routeDetail.franchiseId: routeDetail
    };

    // Combine data based on franchiseID
    for (var routeSuggest in routeSuggestList) {
      // Find the corresponding RouteDetail using franchiseID
      RouteDetail? routeDetail = routeDetailMap[routeSuggest.franchiseID];

      if (routeDetail != null) {
        // String? pointAName = locationNames[routeSuggest.pointA] ?? 'Unknown';
        // String? pointBName = locationNames[routeSuggest.pointB] ?? 'Unknown';
        // Create CombinedRouteData by merging RouteSuggest and RouteDetail
        combinedData.add(CombinedRouteData(
          franchiseID: routeSuggest.franchiseID,
          pointA: routeSuggest.pointA,
          pointB: routeSuggest.pointB,
          waypoints: routeSuggest.waypoints,
          routeCoordinates: routeSuggest.routeCoordinates,
          terminalID: routeSuggest.terminalID,
          transportationID: routeSuggest.transportationID,
          transportationName: routeDetail.transportationName,
          regularFare: routeDetail.regularFare,
          discountedFare: routeDetail.discountedFare,
          perKMfare: routeDetail.perKMfare,
          // distance: distance,
        ));
      }
    }

    return combinedData;
  }

//-------------------------------------------

  List<PathDetail> pathDetails = [];

  //remove duplicate allPaths---------------
  List<List<RouteSuggest>> removeDuplicates(List<List<RouteSuggest>> allPaths) {
    Set<String> seen = {};
    List<List<RouteSuggest>> uniquePaths = [];

    for (var path in allPaths) {
      String pathString =
          path.map((route) => route.franchiseID.toString()).join(',');
      if (!seen.contains(pathString)) {
        uniquePaths.add(path);
        seen.add(pathString);
      }
    }
    return uniquePaths;
  }

  Future<void> fetchData() async {
    // Fetch your paths here (simulated with a dummy list)

    // Once data is fetched, remove duplicates
    setState(() {
      uniqueAllPaths = removeDuplicates(allPaths);
    });
  }

  List<List<RouteSuggest>> uniqueAllPaths = [];

  //end remove duplicate allpaths --------------

  //-----------------------------------------Path details
  Future<List<PathDetail>> createPathDetails(
      List<RouteDetail> routeDetails) async {
    // Convert RouteDetail objects into PathDetail objects
    for (var route in routeDetails) {
      //fare------------------
      // Method to calculate the fare based on distance
      // double calculateFare(double distance) {
      //   // If distance is within the first 4 km, return the regular fare
      //   if (distance <= 4) {
      //     return route.regularFare;
      //   } else {
      //     // Calculate extra distance beyond 4 km
      //     double extraDistance = distance - 4;
      //     // Total fare = regular fare + additional cost for extra distance
      //     return route.regularFare + (route.perKMfare * extraDistance);
      //   }
      // }

      PathDetail pathDetail = PathDetail(
        franchiseId: route.franchiseId,
        routeName: route.transportationName,
        stops: [
          route.pointA,
          route.pointB
        ], // Example, you can modify according to your needs
        estimatedTime: '30 mins', // Set this dynamically based on your logic
        distance: 10.5, // Set the distance dynamically based on your logic
        fare: route.regularFare, // Use the appropriate fare
      );
      pathDetails.add(pathDetail);
    }

    return pathDetails;
  }

  Future<void> fetchRouteDetailsAndCreatePathDetails() async {
    try {
      List<int> franchiseIDs = allPaths
          .expand((pathList) => pathList.map((route) => route.franchiseID))
          .toSet()
          .toList();
      // Fetch the route details

      // Create PathDetail objects from RouteDetail objects
      pathDetails = await createPathDetails(routeDetails);

      print('path details: ${pathDetails.length}');

      // Print PathDetails for debugging
      for (var path in pathDetails) {
        // print(
        //     "Path Detail - Franchise ID: ${path.franchiseId}, Route Name: ${path.routeName}, Estimated Time: ${path.estimatedTime}, Distance: ${path.distance}, Fare: ${path.fare}");
      }
    } catch (e) {
      print("Error creating PathDetails: $e");
    }
  }

  // end Path Details----------------------------

  //fetch route detail --------------------------------------------------------
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
        // _routeDetails = data.map((item) => RouteDetail.fromJson(item)).toList();
        _isLoading = false;
      });

      // Parse data into RouteDetail objects
      return data.map((item) => RouteDetail.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load route details');
    }
  }

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
        // print(
        //     "Franchise ID: ${detail.franchiseId} | Transportation Name: ${detail.transportationName} | Regular Fare: ${detail.regularFare} | Discounted Fare: ${detail.discountedFare} | Point A: ${detail.pointA} | Point B: ${detail.pointB} | Terminal ID: ${detail.terminalId}");
      }
    } catch (e) {
      print("Error fetching route details: $e");
    }
  }

  //end fetch route detail ----------------------------------

  //RouteSuggestion--------------------------------------------------------------------------------------------------------------------

  Future<void> loadRoutes() async {
    allRoutes = await fetchRoutesFromAPI(); // Load routes into allRoutes
    List<int> fID = [];

    for (var routes in allRoutes) {
      fID.add(routes.franchiseID);
    }

    routeDetails = await fetchRouteDetails(fID);
  }

  // Future<List<LatLng>> fetchRouteCoordinates(
  //     LatLng start, LatLng end, List<LatLng> waypoints) async {
  //   String waypointsString = waypoints
  //       .map((point) => '${point.latitude},${point.longitude}')
  //       .join('|');
  //   final String url =
  //       'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&waypoints=optimize:false|$waypointsString&key=$apiKey';

  //   final response = await http.get(Uri.parse(url));
  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     print(data); // Log the response for debugging

  //     if (data['routes'].isNotEmpty) {
  //       final route = data['routes'][0]['overview_polyline']['points'];
  //       return decodePolyline(route);
  //     } else {
  //       throw Exception('Failed to get directions: ZERO_RESULTS');
  //     }
  //   } else {
  //     throw Exception('Failed to load directions');
  //   }
  // }

  Future<List<LatLng>> fetchRouteCoordinates(
      LatLng start, LatLng end, List<LatLng> waypoints) async {
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
        // print(
        //     "Franchise ID: $franchiseID, Point A: $pointA, Point B: $pointB, Waypoints: $waypoints, transporation id: $transportationID, terminal id: $terminalID ");

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

  List<LatLng> yey = [];
  final Set<Polyline> _polylines = {};

  Future<void> testPolyline() async {
    List<RouteSuggest> route = await fetchRoutesFromAPI();
    for (var ey in route) {
      if (ey.franchiseID == 6) {
        print('try try try ${ey.franchiseID}');
        Polyline polyline = Polyline(
          polylineId:
              PolylineId(ey.franchiseID.toString()), // Unique ID for each route
          points: ey.routeCoordinates,
          color: Colors.blue, // Customize the polyline color
          width: 5,
        );
        setState(() {
          _polylines.add(polyline);
        });
      }

      if (ey.franchiseID == 4) {
        print('try try try ${ey.franchiseID}');
        Polyline polyline = Polyline(
          polylineId:
              PolylineId(ey.franchiseID.toString()), // Unique ID for each route
          points: ey.routeCoordinates,
          color: Colors.red, // Customize the polyline color
          width: 2,
        );
        setState(() {
          _polylines.add(polyline);
        });
      }
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

      // print(
      //   'Threshold: $distance , Distance: $distance , Terminal: ${terminal.latitude}, ${terminal.longitude}, Location: $origin');

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
            // print(
            //     "Destination is near the endpoint (point_B) of Terminal ID: ${route.terminalID}");
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
            // print(
            //     "Destination lies along the route of Terminal ID: ${route.terminalID}");
            alongRoutesTerminal.add(route);
          }
        }
      }
    }

    // Display the results
    if (nearEndTerminal.isNotEmpty || alongRoutesTerminal.isNotEmpty) {
      if (alongRoutesTerminal.isNotEmpty) {
        // print("Routes with destination along the route:");
        for (var route in alongRoutesTerminal) {
          //  print("Franchise ID: ${route.franchiseID}");
        }
      }

      if (nearEndTerminal.isNotEmpty) {
        // print("Nearby terminals with point B near the destination:");
        for (var route in nearEndTerminal) {
          // print(
          //     "Terminal ID: ${route.terminalID}, Franchise ID: ${route.franchiseID}");
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
        // print(
        //     "Destination is near the endpoint (point_B) of route ID: ${route.franchiseID}");
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
          // print(
          //     "Destination lies along the route of route ID: ${route.franchiseID}");
          alongRouteDestination.add(route);
        }
      }
    }

    // Display the results
    if (routesEnd.isNotEmpty || alongRouteDestination.isNotEmpty) {
      // Display routes ending near the destination
      if (routesEnd.isNotEmpty) {
        //  print("Routes ending near the destination:");
      }

      // Display routes passing near the destination
      if (alongRouteDestination.isNotEmpty) {
        //  print("Routes passing along the destination:");
      }
    } else {
      // No nearby routes found
      //print("No routes nearby");
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
      // print('Route Franchise ID: ${route.franchiseID}');
      // print('Distance to Point A: $distanceToPointA meters');
      // print('Distance to Point B: $distanceToPointB meters');
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
      // print(
      //     'Nearby Route: Franchise ID: ${route.franchiseID}, Points: ${route.pointA}, ${route.pointB}');
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
  //                 setState(() {
  //                   isDuplicate1 = true;
  //                 });
  //               } else {
  //                 setState(() {
  //                   isDuplicate1 = false;
  //                 });
  //               }
  //             }
  //             // Add the transfer point if it's not a duplicate
  //             if (!isDuplicate1) {
  //               // Determine if this is a "baba" or "sakay" point
  //               String transferType =
  //                   "walk"; // Default to walk if it's not a transfer point

  //               // Logic to determine if it's "sakay" or "baba" based on route direction
  //               if (originRoute.routeCoordinates.indexOf(originPoint) ==
  //                   originRoute.routeCoordinates.length - 1) {
  //                 transferType = "baba"; // Last point in origin route (baba)
  //               } else if (destinationRoute.routeCoordinates
  //                       .indexOf(destinationPoint) ==
  //                   0) {
  //                 transferType =
  //                     "sakay"; // First point in destination route (sakay)
  //               }

  //               // Add the transfer point to the list
  //               transferPoints.add(TransferPoint(
  //                 fromRoute: originRoute,
  //                 toRoute: destinationRoute,
  //                 transferLocation:
  //                     destinationPoint, // Location where transfer occurs
  //                 transferType: transferType, // "baba", "sakay", or "walk"
  //               ));
  //               print(
  //                   "Transfer point found between Route ${originRoute.franchiseID} and Route ${destinationRoute.franchiseID} at $originPoint and $destinationPoint with type: $transferType");
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
  //           "Transfer from Route ${transfer.fromRoute.franchiseID} to Route ${transfer.toRoute.franchiseID} at ${transfer.transferLocation} with type: ${transfer.transferType}");
  //     }
  //   } else {
  //     print("No transfer points found between routes.");
  //   }

  //   return transferPoints; // Return the list of transfer points
  // }

// Function to check if two routes meet (overlap or share a segment)
  bool checkForMeetingSegment(
      RouteSuggest originRoute, RouteSuggest destinationRoute) {
    // This checks if there are overlapping coordinates or segments between the two routes
    for (var originCoord in originRoute.routeCoordinates) {
      for (var destCoord in destinationRoute.routeCoordinates) {
        if (isWithinThreshold(originCoord, destCoord)) {
          return true; // The routes are meeting (overlapping at this coordinate)
        }
      }
    }
    return false; // No meeting segment found
  }

// Function to find the meeting point of two routes
  LatLng findMeetingPoint(
      RouteSuggest originRoute, RouteSuggest destinationRoute) {
    // Logic to find the meeting point (e.g., last common coordinate in the overlap)
    for (var originCoord in originRoute.routeCoordinates) {
      for (var destCoord in destinationRoute.routeCoordinates) {
        if (isWithinThreshold(originCoord, destCoord)) {
          return originCoord; // The coordinate where routes meet
        }
      }
    }
    return const LatLng(0.0, 0.0); // Default (error case)
  }

  LatLng findMeetingPointWithOrigin(RouteSuggest route, LatLng userOrigin) {
    // Logic to find the meeting point (e.g., the first coordinate within a threshold from the origin)
    for (var routeCoord in route.routeCoordinates) {
      if (isWithinThreshold(routeCoord, userOrigin)) {
        return routeCoord; // The coordinate where the route meets the origin
      }
    }
    return userOrigin; // If no meeting point is found, default to origin
  }

  LatLng findClosestPointIfNear(
      List<LatLng> route1Coords, List<LatLng> route2Coords, double threshold) {
    LatLng closestPoint = const LatLng(0.0, 0.0);
    double minDistance = double.infinity;

    for (var coord1 in route1Coords) {
      for (var coord2 in route2Coords) {
        double distance = calculateDistances(coord1, coord2);
        if (distance < threshold && distance < minDistance) {
          minDistance = distance;
          closestPoint = coord1;
        }
      }
    }

    return minDistance < threshold
        ? closestPoint
        : const LatLng(0.0,
            0.0); // Return valid point if within threshold, otherwise (0,0)
  }

  LatLng findClosestPointToOrigin(
      List<LatLng> routeCoords, LatLng originLocation, double threshold) {
    LatLng closestPoint = LatLng(0.0, 0.0); // Default value
    double minDistance = double.infinity; // Start with a very large distance

    // Loop through all route coordinates
    for (var coord in routeCoords) {
      double distance =
          calculateDistances(coord, originLocation); // Calculate distance

      // Log the distance to help with debugging
      // print("Checking coordinate: ${coord.latitude}, ${coord.longitude}");
      //print("Distance from origin: $distance");

      // If distance is smaller than the threshold and smaller than the current minDistance
      if (distance < threshold && distance < minDistance) {
        minDistance = distance; // Update the closest point
        closestPoint = LatLng(coord.latitude, coord.longitude);
        // print(
        //     "New closest point: ${coord.latitude}, ${coord.longitude} at distance: $distance");
      }
    }

    // Log result
    if (minDistance < threshold) {
      // print(
      //     "Closest point found: ${closestPoint.latitude}, ${closestPoint.longitude}");
      return closestPoint;
    } else {
      // print("No valid point found within the threshold of $threshold meters.");
      return LatLng(0.0, 0.0);
    }
  }

// Helper function to determine if two coordinates are within a threshold of proximity
  bool isWithinThreshold(LatLng coord1, LatLng coord2) {
    // Threshold to check if two coordinates are close enough to be considered overlapping
    double threshold = 0.0001;
    return (coord1.latitude - coord2.latitude).abs() < threshold &&
        (coord1.longitude - coord2.longitude).abs() < threshold;
  }

  List<TransferPoint> findTransferPoints(
      List<RouteSuggest> nearbyRoutes, List<RouteSuggest> routesEnd) {
    List<TransferPoint> transferPoints = [];
    Set<String> addedRoutePairs = {}; // To track unique route pairs

    if (nearbyRoutes.isEmpty || routesEnd.isEmpty) {
      print("No nearby or destination routes to check for transfers.");
      return [];
    }

    // Iterate over each origin route
    for (var originRoute in nearbyRoutes) {
      // Iterate over each destination route
      for (var destinationRoute in routesEnd) {
        String routePairKey =
            '${originRoute.franchiseID}-${destinationRoute.franchiseID}';

        print("checking apir key:$routePairKey ");

        if (!addedRoutePairs.contains(routePairKey)) {
          addedRoutePairs.add(routePairKey);

          bool areRoutesMeeting =
              checkForMeetingSegment(originRoute, destinationRoute);

          bool areNearRoutes = false;

          for (var originPoint in originRoute.routeCoordinates) {
            for (var destinationPoint in destinationRoute.routeCoordinates) {
              double routeDistance =
                  calculateDistances(originPoint, destinationPoint);
              if (routeDistance <= proximityThreshold) {
                areNearRoutes = true;
              }
            }
          }

          if (areRoutesMeeting && areNearRoutes) {
            var meetingPoint = findMeetingPoint(originRoute, destinationRoute);

            TransferPoint newTransferPoint = TransferPoint(
              fromRoute: originRoute,
              toRoute: destinationRoute,
              transferLocation: meetingPoint,
              transferType: "sakay", // Adjust transfer type
            );

            transferPoints.add(newTransferPoint);
            print(
                "Transfer point found between Route ${originRoute.franchiseID} and Route ${destinationRoute.franchiseID} at meeting point: $meetingPoint");
          } else if (areNearRoutes && !areRoutesMeeting) {
            var meetingPoint = findMeetingPoint(originRoute, destinationRoute);

            LatLng closestPoint = findClosestPointIfNear(
                originRoute.routeCoordinates,
                destinationRoute.routeCoordinates,
                proximityThreshold);

            //  var meetingPoint = findMeetingPoint(originRoute, destinationRoute);
            // Add walk step if routes don't directly meet
            var walkTransferPoint = TransferPoint(
              fromRoute: originRoute,
              toRoute: destinationRoute,
              transferLocation: closestPoint, // Indicating walking step
              transferType: "walk",
            );
            transferPoints.add(walkTransferPoint);
            print(
                "2 Transfer point found between Route ${originRoute.franchiseID} and Route ${destinationRoute.franchiseID} at meeting point: $meetingPoint");
            // print(
            //     "Walk added between Route ${originRoute.franchiseID} and Route ${destinationRoute.franchiseID}");
          }
        }
      }
    }

    for (var transferPoint in transferPoints) {
      print(
          "All transfer points found: From Route: ${transferPoint.fromRoute.franchiseID}, To Route: ${transferPoint.toRoute.franchiseID}, Location: ${transferPoint.transferLocation}, Type: ${transferPoint.transferType}");
    }

    return transferPoints;
  }

  Future<List<List<TransferPoint>>> findConnectedTransferPaths(
      List<RouteSuggest> nearbyRoutes,
      List<RouteSuggest> routesEnd,
      LatLng destination) async {
    List<List<TransferPoint>> connectedPaths = [];
    Set<String> seenPaths = {}; // Track all considered paths
    Set<int> seenRoutes = {}; // Track all considered routes

    if (nearbyRoutes.isEmpty || routesEnd.isEmpty) {
      print("No nearby or destination routes to check for transfers.");
      return [];
    }
/*
    List<List<RouteSuggest>> findPath(
        RouteSuggest startRoute, // nearby routes
        LatLng destination,
        List<RouteSuggest> allRoutes, //lahat ng route from api
        double routeProximityThreshold) {
      List<List<RouteSuggest>> paths = [];
      Queue<List<RouteSuggest>> queue = Queue();
      queue.add([startRoute]);

      while (queue.isNotEmpty) {
        List<RouteSuggest> currentPath = queue.removeFirst();
        RouteSuggest currentRoute = currentPath.last;

        for (int i = 0; i < currentRoute.routeCoordinates.length; i++) {
          var routePoint = currentRoute.routeCoordinates[i];

          // Check if destination is close enough
          if (calculateDistances(routePoint, destination) <=
              routeProximityThreshold) {
            paths.add(currentPath);
            print("Path found to destination at $routePoint");
            return paths;
          }
        }

        List<TransferPoint> transferPoints =
            findTransferPoints([currentRoute], allRoutes);
        Map<int, CombinedRouteData> routeLookup = {
          for (var routeData in combinedRoutes) routeData.franchiseID: routeData
        };

        for (var transfer in transferPoints) {
          if (!currentPath.contains(transfer.toRoute) &&
              !seenRoutes.contains(transfer.toRoute.franchiseID)) {
            var routeData = routeLookup[transfer.toRoute.franchiseID];
            if (routeData != null) {
              // Add to the path and queue
              List<RouteSuggest> newPath = List.from(currentPath);
              newPath.add(transfer.toRoute);
              queue.add(newPath);
              seenRoutes.add(transfer
                  .toRoute.franchiseID); // Mark this route as considered
            }
          }
        }
      }
      print("Paths without filtering: $paths ");
      return paths;
    }
*/
    List<List<RouteSuggest>> findPath(
        RouteSuggest startRoute, // nearby routes
        LatLng destination,
        List<RouteSuggest> allRoutes, // all routes from API
        double routeProximityThreshold) {
      List<List<RouteSuggest>> paths = [];
      Queue<List<RouteSuggest>> queue = Queue();
      Set<int> seenRoutes = Set(); // To keep track of explored routes
      queue.add([startRoute]);

      while (queue.isNotEmpty) {
        List<RouteSuggest> currentPath = queue.removeFirst();
        RouteSuggest currentRoute = currentPath.last;

        // Check if any route point is close enough to the destination
        for (int i = 0; i < currentRoute.routeCoordinates.length; i++) {
          var routePoint = currentRoute.routeCoordinates[i];

          if (calculateDistances(routePoint, destination) <=
              routeProximityThreshold) {
            paths.add(currentPath); // Path to destination found
            print("Path found to destination at $routePoint");
            continue; // Continue finding other paths
          }
        }

        // Find possible transfer points from current route
        List<TransferPoint> transferPoints =
            findTransferPoints([currentRoute], allRoutes);
        Map<int, CombinedRouteData> routeLookup = {
          for (var routeData in combinedRoutes) routeData.franchiseID: routeData
        };

        // Add each transfer route to the path queue for further exploration
        for (var transfer in transferPoints) {
          if (!currentPath.contains(transfer.toRoute) &&
              !seenRoutes.contains(transfer.toRoute.franchiseID)) {
            var routeData = routeLookup[transfer.toRoute.franchiseID];
            if (routeData != null) {
              // Add the transfer route to the current path and add to the queue for further exploration
              List<RouteSuggest> newPath = List.from(currentPath);
              newPath.add(transfer.toRoute);
              queue.add(newPath);
              seenRoutes
                  .add(transfer.toRoute.franchiseID); // Mark as considered
            }
          }
        }
      }

      print("Paths without filtering: $paths");
      for (var path in paths) {
        // Create a list of franchise IDs for the current path
        List<String> franchiseIDs =
            path.map((route) => route.franchiseID.toString()).toList();

        // Join the franchise IDs with " -> " and print the result
        print('pathssssssssssssssssssssssss: ${franchiseIDs.join(" -> ")}');
      }

      return paths;
    }

    for (var originRoute in nearbyRoutes) {
      seenRoutes.clear(); // Clear seen routes for each new origin route
      List<List<RouteSuggest>> pathsFromOrigin = findPath(
          originRoute, destination, routesEnd, routeProximityThreshold);

      LatLng sakayanLocationInitial;
      LatLng babaanLocationInitial;

      LatLng userDestination = LatLng(
        double.parse(widget.latDestination),
        double.parse(widget.longDestination),
      );

//adding of condition if traveled idstance is less 300, remove that step.
      for (var path in pathsFromOrigin) {
        for (int i = 0; i < path.length - 1; i++) {
          var nextRoute = path[i + 1];
          RouteSuggest route = path[i];

          if (i == 0) {
            // First route: Set babaanLocation to where it meets the next route
            if (nextRoute != null) {
              LatLng meetingPoint = findMeetingPoint(route, nextRoute);
              if (meetingPoint.latitude == 0.0 &&
                  meetingPoint.longitude == 0.0) {
                // Routes are nearby but not crossing
                // Set babaanLocation to the end of the current route where it gets close to the next route
                babaanLocationInitial = findClosestPointIfNear(
                    route.routeCoordinates,
                    nextRoute.routeCoordinates,
                    proximityThreshold);
              } else {
                // Routes are crossing, use the intersection point
                babaanLocationInitial = meetingPoint;
              }
            } else {
              babaanLocationInitial =
                  userDestination; // If no next route, set to user destination
            }

            // Set sakayanLocation to where the current route meets the origin
            sakayanLocationInitial =
                findMeetingPointWithOrigin(route, originLocation);
          } else if (nextRoute != null) {
            // Intermediate routes: Check for nearby but non-crossing routes
            RouteSuggest previousRoute = path[i - 1];
            LatLng meetingPoint = findMeetingPoint(previousRoute, route);

            if (meetingPoint.latitude == 0.0 && meetingPoint.longitude == 0.0) {
              // Routes are nearby but not crossing
              // Set sakayanLocation as the first coordinate of the current route where it gets close to the previous route
              sakayanLocationInitial = findClosestPointIfNear(
                  route.routeCoordinates,
                  previousRoute.routeCoordinates,
                  proximityThreshold);

              // Set babaanLocation as the end of the current route where it gets close to the next route
              babaanLocationInitial = findClosestPointIfNear(
                  route.routeCoordinates,
                  nextRoute.routeCoordinates,
                  proximityThreshold);
            } else {
              // Routes are crossing, use the intersection point
              sakayanLocationInitial = meetingPoint;
              //babaanLocationInitial = meetingPoint;
              babaanLocationInitial = findClosestPointIfNear(
                  route.routeCoordinates,
                  nextRoute.routeCoordinates,
                  proximityThreshold);
            }
          } else {
            // Last route: sakayanLocation is the point it meets the previous route
            RouteSuggest previousRoute = path[i - 1];
            LatLng meetingPoint = findMeetingPoint(previousRoute, route);

            if (meetingPoint.latitude == 0.0 && meetingPoint.longitude == 0.0) {
              // Routes are nearby but not crossing
              sakayanLocationInitial = findClosestPointIfNear(
                  route.routeCoordinates,
                  previousRoute.routeCoordinates,
                  proximityThreshold);
            } else {
              // Routes are crossing, use the intersection point
              sakayanLocationInitial = meetingPoint;
            }

            babaanLocationInitial =
                userDestination; // Set babaan for last route as the destination
          }

          double distanceBetweenSakayanAndBabaan =
              calculateDistances(sakayanLocationInitial, babaanLocationInitial);
          print(
              'distance sakayan at babaan = $distanceBetweenSakayanAndBabaan id franchise: ${route.franchiseID}');

          // If the distance between sakayan and babaan is less than 100 meters, skip adding this step
          if (distanceBetweenSakayanAndBabaan < 300) {
            print("path removed below 300: ${path[i]}");
            path.removeAt(i); // Remove the current route step from the path
            i--; // Adjust index after removal to avoid skipping the next element
          }
        }
      }

/*
      for (var pathFromOrigin in pathsFromOrigin) {
        // Check for gaps between consecutive routes in the path and insert walking step if needed
        List<RouteSuggest> pathWithWalk = [];

        double walkProximityThreshold = 0.0001;
        for (int i = 0; i < pathFromOrigin.length - 1; i++) {
          pathWithWalk.add(pathFromOrigin[i]);

          //----
          var currentRoute = pathFromOrigin[i];
          var nextRoute = pathFromOrigin[i + 1];

          LatLng pointA = findClosestPointIfNear(currentRoute.routeCoordinates,
              nextRoute.routeCoordinates, proximityThreshold);

          print("Wnalking route from $pointA checking......");

          // If pointA is a valid point (not LatLng(0.0, 0.0)), create a walking route
          if (pointA.latitude != 0.0 && pointA.longitude != 0.0) {
            // Now, find the closest point on the next route to the current route's last point
            LatLng pointB = findClosestPointIfNear(nextRoute.routeCoordinates,
                currentRoute.routeCoordinates, proximityThreshold);

            print("after Walking route from $pointA to $pointB");

            // If pointB is valid, create a walking route between pointA and pointB
            if (pointB.latitude != 0.0 && pointB.longitude != 0.0) {
              RouteSuggest walkingRoute = RouteSuggest(
                pointA: pointA,
                pointB: pointB,
                waypoints: [pointA, pointB],
                terminalID: -1, // Special ID for walking step
                transportationID: 6, // ID for walking transport type
                routeCoordinates: [pointA, pointB],
                franchiseID: -1, // Special ID for walking step
              );

              print("end Walking route from $pointA to $pointB");

              // Add walking step to the path
              pathWithWalk.add(walkingRoute);
            }
          }

          // // Check if there's a gap between consecutive routes
          // double distanceBetweenRoutes = calculateDistances(
          //     pathFromOrigin[i].routeCoordinates.last,
          //     pathFromOrigin[i + 1].routeCoordinates.first);

          // if (distanceBetweenRoutes > walkProximityThreshold) {
          //   // Create walking step between the two routes
          //   RouteSuggest walkingRoute = RouteSuggest(
          //     pointA: pathFromOrigin[i].routeCoordinates.last,
          //     pointB: pathFromOrigin[i + 1].routeCoordinates.first,
          //     waypoints: [
          //       pathFromOrigin[i].routeCoordinates.last,
          //       pathFromOrigin[i + 1].routeCoordinates.first
          //     ],
          //     terminalID: -1, // Special ID to mark as a walking segment
          //     transportationID: 6,
          //     routeCoordinates: [
          //       pathFromOrigin[i].routeCoordinates.last,
          //       pathFromOrigin[i + 1].routeCoordinates.first
          //     ],
          //     franchiseID: -1, // Special ID to mark as a walking segment
          //   );

          //   print(
          //       "walk pointA: ${pathFromOrigin[i].routeCoordinates.last}, walk pointb: ${pathFromOrigin[i + 1].routeCoordinates.first}");

          //   // Add walking segment between routes
          //   pathWithWalk.add(walkingRoute);
          // }
        }

        // Add the last route in the path
        pathWithWalk.add(pathFromOrigin.last);

        String pathStringWalk = pathWithWalk
            .map((route) => route.franchiseID.toString())
            .join(' -> ');

        String pathString = pathFromOrigin
            .map((route) => route.franchiseID.toString())
            .join(' -> ');

        if (!seenPaths.contains(pathString)) {
          // allPaths.add(pathFromOrigin);
          allPaths.add(pathWithWalk);
          seenPaths.add(pathString);
          print("Added new unique path: $pathString");
          print("with walk: $pathStringWalk");
        } else {
          print("Duplicate path ignored: $pathString");
        }
      }

*/

// Adding walking routes to paths
      for (var pathFromOrigin in pathsFromOrigin) {
        // Check for gaps between consecutive routes in the path and insert walking step if needed
        List<RouteSuggest> pathWithWalk = [];

        LatLng invalid = LatLng(0.0, 0.0);

        // Iterate through the path for debugging purposes
        for (var route in pathFromOrigin) {
          String pathStringWalk = pathWithWalk
              .map((route) => route.franchiseID.toString())
              .join(' -> ');
          print("very start all franchise IDs in path: $pathStringWalk");
        }

        if (pathFromOrigin.length == 1) {
          var currentRoute = pathFromOrigin[0];

          // Check if there is a need for a walking route at the beginning
          LatLng nearestMeet = findClosestPointToOrigin(
              currentRoute.routeCoordinates,
              originLocation,
              proximityThreshold);

          double distance = calculateDistances(nearestMeet, originLocation);
          print('Origin distance $distance route: ${currentRoute.franchiseID}');

          if (nearestMeet != invalid && distance > 0.0001) {
            RouteSuggest walkingRoute = RouteSuggest(
              pointA: originLocation,
              pointB: nearestMeet,
              waypoints: [originLocation, nearestMeet],
              terminalID: -1, // Special ID for walking step
              transportationID: 6, // ID for walking transport type
              routeCoordinates: [originLocation, nearestMeet],
              franchiseID: -1, // Special ID for walking step
            );

            pathWithWalk.add(walkingRoute);
          }

          // Add the only route (no walking needed)
          pathWithWalk.add(currentRoute);

          // Check if there is a need for a walking route at the destination
          LatLng nearestMeetDestination = findClosestPointToOrigin(
              currentRoute.routeCoordinates,
              destinationLocation,
              proximityThreshold);

          double distDest =
              calculateDistances(nearestMeetDestination, destinationLocation);

          print(
              'Destination distance $distDest route: ${currentRoute.franchiseID}');

          if (nearestMeetDestination != invalid && distDest > 0.0001) {
            RouteSuggest walkingRouteDest = RouteSuggest(
              pointA: nearestMeetDestination,
              pointB: destinationLocation,
              waypoints: [nearestMeetDestination, destinationLocation],
              terminalID: -1, // Special ID for walking step
              transportationID: 6, // ID for walking transport type
              routeCoordinates: [nearestMeetDestination, destinationLocation],
              franchiseID: -1, // Special ID for walking step
            );

            pathWithWalk.add(walkingRouteDest);
          }
        } else {
          // Add walking step at the start if needed
          var firstRoute = pathFromOrigin[0];
          LatLng nearestStart = findClosestPointToOrigin(
              firstRoute.routeCoordinates, originLocation, proximityThreshold);

          double startDistance =
              calculateDistances(nearestStart, originLocation);

          if (nearestStart != invalid && startDistance > 0.0001) {
            RouteSuggest walkingRouteStart = RouteSuggest(
              pointA: originLocation,
              pointB: nearestStart,
              waypoints: [originLocation, nearestStart],
              terminalID: -1, // Special ID for walking step
              transportationID: 6, // ID for walking transport type
              routeCoordinates: [originLocation, nearestStart],
              franchiseID: -1, // Special ID for walking step
            );
            pathWithWalk.add(walkingRouteStart);
          }

          // Iterate through the rest of the routes and check for walking gaps
          double walkProximityThreshold = 0.0001;
          for (int i = 0; i < pathFromOrigin.length - 1; i++) {
            var currentRoute = pathFromOrigin[i];
            var nextRoute = pathFromOrigin[i + 1];
            LatLng pointA = LatLng(0.0, 0.0);
            LatLng pointB = LatLng(0.0, 0.0);

            pathWithWalk.add(pathFromOrigin[i]);

            pointA = findClosestPointIfNear(currentRoute.routeCoordinates,
                nextRoute.routeCoordinates, proximityThreshold);
            pointB = findClosestPointIfNear(nextRoute.routeCoordinates,
                currentRoute.routeCoordinates, proximityThreshold);

            double distanceBetweenRoutes = calculateDistances(pointA, pointB);

            if (distanceBetweenRoutes <= proximityThreshold &&
                distanceBetweenRoutes > walkProximityThreshold) {
              // Check if walking route is needed between routes
              if (pointA.latitude != 0.0 && pointA.longitude != 0.0) {
                if (pointB.latitude != 0.0 && pointB.longitude != 0.0) {
                  RouteSuggest walkingRoute = RouteSuggest(
                    pointA: pointA,
                    pointB: pointB,
                    waypoints: [pointA, pointB],
                    terminalID: -1, // Special ID for walking step
                    transportationID: 6, // ID for walking transport type
                    routeCoordinates: [pointA, pointB],
                    franchiseID: -1, // Special ID for walking step
                  );
                  pathWithWalk.add(walkingRoute);
                }
              }
            }
          }

          // Add the last route in the path
          pathWithWalk.add(pathFromOrigin.last);

          // Add walking step at the end if needed
          var lastRoute = pathFromOrigin.last;
          LatLng nearestEnd = findClosestPointToOrigin(
              lastRoute.routeCoordinates,
              destinationLocation,
              proximityThreshold);

          double endDistance =
              calculateDistances(nearestEnd, destinationLocation);

          if (nearestEnd != invalid && endDistance > 0.0001) {
            RouteSuggest walkingRouteEnd = RouteSuggest(
              pointA: nearestEnd,
              pointB: destinationLocation,
              waypoints: [nearestEnd, destinationLocation],
              terminalID: -1,
              transportationID: 6,
              routeCoordinates: [nearestEnd, destinationLocation],
              franchiseID: -1,
            );

            pathWithWalk.add(walkingRouteEnd);
          }
        }

        // Check if this path is already in the seen paths set to prevent duplication
        String pathStringWalk = pathWithWalk
            .map((route) => route.franchiseID.toString())
            .join(' -> ');

        String pathString = pathFromOrigin
            .map((route) => route.franchiseID.toString())
            .join(' -> ');

        if (!seenPaths.contains(pathString)) {
          // Add new unique path to the allPaths list
          allPaths.add(pathWithWalk);
          seenPaths.add(pathString);
          print("Added new unique path: $pathString");
          print("With walk: $pathStringWalk");
        } else {
          print("Duplicate path ignored: $pathString");
        }
      }
    }

    // Additional code to process the paths
    fetchRouteDetailsAndCreatePathDetails();
    return connectedPaths;
  }

  double getAverageSpeed(String transportationName) {
    switch (transportationName.toLowerCase()) {
      case 'walk':
        return 5.0; // 5 km/h
      case 'jeep':
        return 20.0; // 20 km/h
      case 'e-jeep':
        return 15.0; // 15 km/h
      case 'bus':
        return 25.0; // 25 km/h
      case 'uv express':
        return 30.0; // 30 km/h
      case 'tricycle':
        return 15.0; // 15 km/h
      default:
        return 15.0; // Default speed if the type is unknown
    }
  }

  //--------------traveled distance
  // Separate function to calculate distances for each path
  Future<List<Map<String, dynamic>>> calculatePathDistances(
      List<List<TransferPoint>> paths) async {
    List<Map<String, dynamic>> pathsWithDistances = [];

    for (var path in paths) {
      double totalDistance = 0.0;

      // Calculate the total distance for each TransferPoint within the path
      for (var transfer in path) {
        RouteSuggest route = transfer.fromRoute;
        for (int i = 1; i < route.routeCoordinates.length; i++) {
          totalDistance += calculateDistances(
              route.routeCoordinates[i - 1], route.routeCoordinates[i]);
        }
      }

      pathsWithDistances.add({"path": path, "distance": totalDistance});
    }

    return pathsWithDistances;
  }

  Future<List<List<TravelStep>>> populateTravelSteps(
      List<List<RouteSuggest>> allPaths,
      Map<int, CombinedRouteData> routeLookup,
      LatLng userDestination) async {
    List<List<TravelStep>> travelStepsByPath = [];
    // List<RouteDetail> routeDetails

    for (var path in allPaths) {
      List<TravelStep> travelStepsForPath = [];

      List<String> transportationNames = [];
      // Create a map for fast lookup of RouteDetail by franchiseID
      Map<int, RouteDetail> routeDetailMap = {
        for (var routeDetail in routeDetails)
          routeDetail.franchiseId: routeDetail
      };

      // Loop through each route in the path
      for (int i = 0; i < path.length; i++) {
        RouteSuggest route = path[i];
        RouteDetail? detail = routeDetailMap[
            route.franchiseID]; // Retrieve RouteDetail based on franchiseID
        var routeData = routeLookup[route.franchiseID];

        bool walk = false;

        // Check for walking route (franchiseID or transportationID -1 indicates a walking step)
        if (route.franchiseID == -1 || route.transportationID == 6) {
          walk = true;

          double totalDistance = 0;
          double totalTimeForPath = 0;

          double distanceTraveled = 0.0;
          distanceTraveled += calculateDistances(route.pointA, route.pointB);
          totalDistance += distanceTraveled;
          double totalDistanceInKm = totalDistance / 1000;

          print(
              'walkkkk coord 1: ${route.routeCoordinates.first} 2: ${route.routeCoordinates.last}');

          double averageSpeed = 5.0; // 5 km/h average walking speed
          double timeForRoute = totalDistanceInKm / averageSpeed * 60;
          totalTimeForPath += timeForRoute;

          // Add walking as a transportation name
          transportationNames.add('Walk');

          Future<String> sakayanName =
              getSakayanName(route.routeCoordinates.last);
          Future<String> babaanName =
              getSakayanName(route.routeCoordinates.first);

          // Wait for both Future values
          String sakayan = await sakayanName;
          String babaan = await babaanName;

          //  List<LatLng> routeCoordinates =
          //   await fetchRouteCoordinates(babaanName, pointB, waypoints);

          // Create TravelStep for walking route
          TravelStep travelStep = TravelStep(
            FranchiseID: -1,
            transportationName: 'Walk',
            travelTime: totalTimeForPath, //minutes
            babaanLocation: route.routeCoordinates
                .last, // Walking doesn't have specific places, adjust as needed
            babaanPlaceName: 'to $babaan',
            sakayanLocation:
                route.routeCoordinates.first, // Walking start point
            sakayanPlaceName: 'walk to $sakayan',
            routeName: ['Walking Segment'],
            fare: 0, // No fare for walking
            travelDistance: totalDistanceInKm.floorToDouble(), //meter
            routePoints: route.routeCoordinates,
          );

          travelStepsForPath.add(travelStep);
        } else if (routeData != null) {
          /*
          if (i == 0) {
            // First route: Set sakayanLocation to the point it meets the origin
            sakayanLocation = findMeetingPointWithOrigin(route, originLocation);
          } else if (nextRoute != null) {
            // Intermediate routes: Check for nearby but non-crossing routes
            LatLng meetingPoint = findMeetingPoint(route, nextRoute);

            if (meetingPoint.latitude == 0.0 && meetingPoint.longitude == 0.0) {
              // Routes are nearby but not crossing, find the closest points
              babaanLocation = findClosestPointIfNear(route.routeCoordinates,
                  nextRoute.routeCoordinates, proximityThreshold);
              sakayanLocation = nextRoute.routeCoordinates.isNotEmpty
                  ? findClosestPointIfNear(nextRoute.routeCoordinates,
                      route.routeCoordinates, proximityThreshold)
                  : LatLng(0.0, 0.0);
            } else {
              // Routes are crossing, use the intersection point
              babaanLocation = meetingPoint;
              sakayanLocation = nextRoute.routeCoordinates.isNotEmpty
                  ? nextRoute.routeCoordinates.first
                  : LatLng(0.0, 0.0);
            }
          } else {
            // Last route: sakayanLocation is the point it meets the previous route
            RouteSuggest previousRoute = path[i - 1];
            LatLng meetingPoint = findMeetingPoint(previousRoute, route);

            if (meetingPoint.latitude == 0.0 && meetingPoint.longitude == 0.0) {
              // Routes are nearby but not crossing, find the closest points
              sakayanLocation = findClosestPointIfNear(route.routeCoordinates,
                  previousRoute.routeCoordinates, proximityThreshold);
            } else {
              // Routes are crossing, use the intersection point
              sakayanLocation = meetingPoint;
            }

            babaanLocation =
                userDestination; // Set babaan for last route as the destination
          }
          */

          LatLng babaanLocation;
          LatLng sakayanLocation;

          RouteSuggest? nextRoute = (i < path.length - 1) ? path[i + 1] : null;

          if (route.franchiseID == -1) {
            // Walking route: Set babaanLocation and sakayanLocation
            babaanLocation =
                route.routeCoordinates.first; // Starting point of walking
            sakayanLocation =
                route.routeCoordinates.last; // Ending point of walking

            print(
                "------------walk sakayan: $sakayanLocation babaan: $babaanLocation");
          } else {
            walk = false;
            if (i == 0) {
              // First route: Set babaanLocation to where it meets the next route
              if (nextRoute != null) {
                LatLng meetingPoint = findMeetingPoint(route, nextRoute);
                if (meetingPoint.latitude == 0.0 &&
                    meetingPoint.longitude == 0.0) {
                  // Routes are nearby but not crossing
                  // Set babaanLocation to the end of the current route where it gets close to the next route
                  babaanLocation = findClosestPointIfNear(
                      route.routeCoordinates,
                      nextRoute.routeCoordinates,
                      proximityThreshold);
                } else {
                  // Routes are crossing, use the intersection point
                  babaanLocation = meetingPoint;
                }
              } else {
                babaanLocation =
                    userDestination; // If no next route, set to user destination
              }

              // Set sakayanLocation to where the current route meets the origin
              sakayanLocation =
                  findMeetingPointWithOrigin(route, originLocation);
            } else if (nextRoute != null) {
              // Intermediate routes: Check for nearby but non-crossing routes
              RouteSuggest previousRoute = path[i - 1];
              LatLng meetingPoint = findMeetingPoint(previousRoute, route);

              if (meetingPoint.latitude == 0.0 &&
                  meetingPoint.longitude == 0.0) {
                // Routes are nearby but not crossing
                // Set sakayanLocation as the first coordinate of the current route where it gets close to the previous route
                sakayanLocation = findClosestPointIfNear(route.routeCoordinates,
                    previousRoute.routeCoordinates, proximityThreshold);

                // Set babaanLocation as the end of the current route where it gets close to the next route
                babaanLocation = findClosestPointIfNear(route.routeCoordinates,
                    nextRoute.routeCoordinates, proximityThreshold);
              } else {
                // Routes are crossing, use the intersection point
                sakayanLocation = meetingPoint;
                babaanLocation = findClosestPointIfNear(route.routeCoordinates,
                    nextRoute.routeCoordinates, proximityThreshold);
              }
            } else {
              // Last route: sakayanLocation is the point it meets the previous route
              RouteSuggest previousRoute = path[i - 1];
              LatLng meetingPoint = findMeetingPoint(previousRoute, route);

              if (meetingPoint.latitude == 0.0 &&
                  meetingPoint.longitude == 0.0) {
                // Routes are nearby but not crossing
                sakayanLocation = findClosestPointIfNear(route.routeCoordinates,
                    previousRoute.routeCoordinates, proximityThreshold);
              } else {
                // Routes are crossing, use the intersection point
                sakayanLocation = meetingPoint;
              }

              babaanLocation =
                  userDestination; // Set babaan for last route as the destination
            }
          }

          //----------------------------------fare, distance traveled, time travel,
          double totalFare = 0;
          double totalDistance = 0;
          double totalTimeForPath = 0;
          totalFare += routeData.regularFare;

          // Calculate distance traveled for this route
          double distanceTraveled = 0.0;

          distanceTraveled +=
              calculateDistances(sakayanLocation, babaanLocation);
          totalDistance += distanceTraveled;
          double totalDistanceInKm = totalDistance / 1000; //km

          // Calculate time for this route
          double averageSpeed = getAverageSpeed(routeData.transportationName);
          double timeForRoute = averageSpeed != null
              ? (totalDistanceInKm / averageSpeed) * 60
              : (totalDistanceInKm / 15) *
                  60; // default speed if averageSpeed is null

          totalTimeForPath += timeForRoute;

          double calculateFare(double distance) {
            // If distance is within the first 4 km, return the regular fare
            if (distance <= 4) {
              return routeData.regularFare;
            } else {
              // Calculate extra distance beyond 4 km
              double extraDistance = distance - 4;
              // Total fare = regular fare + additional cost for extra distance
              return routeData.regularFare +
                  (routeData.perKMfare * extraDistance);
            }
          }

          double RouteFare = calculateFare(totalDistanceInKm).floorToDouble();

          //-----------------------------------------------------------
          if (!transportationNames.contains(routeData.transportationName)) {
            transportationNames.add(routeData.transportationName);
          }

          // // Construct route name
          List<String> routeName = ['${detail?.pointA} ⇌ ${detail?.pointB}'];

          Future<String> sakayanName = getSakayanName(sakayanLocation);
          Future<String> babaanName = getSakayanName(babaanLocation);

          // Wait for both Future values
          String sakayan = await sakayanName;
          String babaan = await babaanName;

          // List<LatLng> routeCoordinates = await fetchRouteCoordinates(
          //     babaanLocation, sakayanLocation, route.waypoints);

          // Create the TravelStep
          TravelStep travelStep = TravelStep(
            FranchiseID: route.franchiseID,
            transportationName: routeData.transportationName,
            travelTime: totalTimeForPath.floorToDouble(),
            babaanLocation: babaanLocation,
            babaanPlaceName: babaan,
            sakayanLocation: sakayanLocation,
            sakayanPlaceName: sakayan,
            routeName: routeName,
            fare: RouteFare,
            travelDistance: totalDistanceInKm.floorToDouble(),
            routePoints: route.routeCoordinates,
            //route.waypoints,
          );

          travelStepsForPath.add(travelStep);
        }
      }

      travelStepsByPath
          .add(travelStepsForPath); // Add each path's steps to the main list
    }

    return travelStepsByPath;
  }

  Future<String> getSakayanName(LatLng location) async {
    // Wait for the results of all futures
    var establishment =
        await getNearestEstablishmentWithinRadius(location, 200);
    var address = await getAddressFromLatLng(location);
    var landmarks = await getNearbyLandmarks(location);

    // Determine the SakayanName based on availability
    String sakayanName = '';

    // If the establishment is not null, use it; otherwise, use the address
    if (establishment != null && establishment.isNotEmpty) {
      sakayanName = establishment['name'] ??
          'Unknown Establishment'; // Replace 'name' with the actual key

      print('establishemnt Nameeee: $sakayanName');
    } else if (address!.isNotEmpty) {
      sakayanName = address; // Use the address if establishment is null
      //print('address Nameeee: $sakayanName');
    } else if (landmarks != null && landmarks.isNotEmpty) {
      sakayanName = landmarks.join(
          ', '); // Use landmarks if both establishment and address are null
      //print('landmarks Nameeee: $sakayanName');
    } else {
      sakayanName = 'No Location Available';
    }

    return sakayanName;
  }

  Future<String?> getAddressFromLatLng(LatLng latLng) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'] != null && data['results'].isNotEmpty) {
        // Get the first address result
        String address = data['results'][0]['formatted_address'];
        return address;
      } else {
        return null;
      }
    } else {
      throw Exception('Failed to fetch address');
    }
  }

  bool meronLandmark = false;
  Future<List<String>?> getNearbyLandmarks(LatLng latLng) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${latLng.latitude},${latLng.longitude}&radius=500&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<String> landmarks = [];
      if (data['results'] != null && data['results'].isNotEmpty) {
        for (var result in data['results']) {
          String name = result['name'];
          landmarks.add(name);
        }
        meronLandmark = true;
        return landmarks;
      } else {
        meronLandmark = false;
        return null;
      }
    } else {
      meronLandmark = false;
      return null;
    }
  }

  bool meronEstablishment = false;

  Future<Map<String, dynamic>?> getNearestEstablishmentWithinRadius(
      LatLng latLng, int radius) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${latLng.latitude},${latLng.longitude}&radius=$radius&type=establishment&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['results'] != null && data['results'].isNotEmpty) {
        final nearest =
            data['results'][0]; // First result is the nearest within the radius

        // List of all possible establishment types
        List<String> knownEstablishmentTypes = [
          'accounting',
          'airport',
          'amusement_park',
          'aquarium',
          'art_gallery',
          'atm',
          'bakery',
          'bank',
          'bar',
          'beauty_salon',
          'bicycle_store',
          'book_store',
          'bowling_alley',
          'bus_station',
          'cafe',
          'campground',
          'car_dealer',
          'car_rental',
          'car_repair',
          'car_wash',
          'casino',
          'cemetery',
          'church',
          'city_hall',
          'clothing_store',
          'convenience_store',
          'courthouse',
          'dentist',
          'department_store',
          'doctor',
          'drugstore',
          'electrician',
          'electronics_store',
          'embassy',
          'fire_station',
          'florist',
          'funeral_home',
          'furniture_store',
          'gas_station',
          'gym',
          'hair_care',
          'hardware_store',
          'hindu_temple',
          'home_goods_store',
          'hospital',
          'insurance_agency',
          'jewelry_store',
          'laundry',
          'lawyer',
          'library',
          'light_rail_station',
          'liquor_store',
          'local_government_office',
          'locksmith',
          'lodging',
          'meal_delivery',
          'meal_takeaway',
          'mosque',
          'movie_rental',
          'movie_theater',
          'moving_company',
          'museum',
          'night_club',
          'painter',
          'park',
          'parking',
          'pet_store',
          'pharmacy',
          'physiotherapist',
          'plumber',
          'police',
          'post_office',
          'primary_school',
          'real_estate_agency',
          'restaurant',
          'roofing_contractor',
          'rv_park',
          'school',
          'secondary_school',
          'shoe_store',
          'shopping_mall',
          'spa',
          'stadium',
          'storage',
          'store',
          'subway_station',
          'supermarket',
          'synagogue',
          'taxi_stand',
          'tourist_attraction',
          'train_station',
          'transit_station',
          'travel_agency',
          'university',
          'veterinary_care',
          'zoo'
        ];

        // Check if the establishment's type is in the known list
        if ((nearest['types'] as List)
            .any((type) => knownEstablishmentTypes.contains(type))) {
          // Collect establishment details
          return {
            'name': nearest['name'],
            'address': nearest['vicinity'],
            'type': (nearest['types'] as List).join(", "),
            'location': LatLng(
              nearest['geometry']['location']['lat'],
              nearest['geometry']['location']['lng'],
            ),
          };
        } else {
          print('Establishment is of an unknown type: ${nearest['types']}');
          return null; // Return null for unknown types
        }
      } else {
        print('No nearby establishments found within the specified radius');
        return null;
      }
    } else {
      print('Failed to fetch nearby establishments');
      return null;
    }
  }

//transfer routes--------------------------------------------------------------------------------------------------------------
  bool isNavigating = false;
  @override
  void dispose() {
    isNavigating = true;
    super.dispose();
  }

  List<CombinedRouteData> combinedRoutes = [];
  initData() async {
    // Step 1: Find Nearby Routes
    await findNearbyRoutes(originLocation);
    if (nearbyRoutes.isNotEmpty) {
      List<RouteSuggest> routesTerminal = await fetchRoutesFromAPI();
      neabyRoutesEnd(destinationLocation);
      testPolyline();
// Find and store transfer points
      List<TransferPoint> transferPoints =
          findTransferPoints(nearbyRoutes, routesTerminal);
      combinedRoutes = await combineRouteData(allRoutes, routeDetails);

      findConnectedTransferPaths(
          nearbyRoutes, routesTerminal, destinationLocation);
      if (allPaths.isNotEmpty) {
        fetchRouteDetailsFromAPI();
        fetchRouteDetailsAndCreatePathDetails();
        uniqueAllPaths = removeDuplicates(allPaths);
        fetchData();

        print(
            'may laman ba and combineRoutes? ${combinedRoutes.length}, eh ang allRoutes? ${allRoutes.length}, eh ang routeDetails? ${routeDetails.length}');
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

    if (!isNavigating) {
      loadRoutes();

      initData();

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
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
            ));
          });
          // liveLocation();
        },
      );
    }

    // _fetchAndDisplayRoutes();

    //gps
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
                child: combinedRoutes.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(),
                      ) // Show loading indicator if no routes are found yet
                    : allPaths.isEmpty
                        ? const Center(
                            child: Text("No route found"),
                          ) // Display "No route found" message if there are no paths
                        : FutureBuilder<List<List<TravelStep>>>(
                            future: populateTravelSteps(
                                allPaths,
                                {
                                  for (var route in combinedRoutes)
                                    route.franchiseID: route
                                },
                                destinationLocation),

//  List<List<TravelStep>> stepsByPath =
//               //                         populateTravelSteps(
//               //                             allPaths,
//               //                             combinedRoutesstep,
//               //                             destinationLocation);

                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                ); // Show loading indicator while waiting for data
                              } else if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Error: ${snapshot.error}',
                                  ), // Display error message if an error occurs
                                );
                              } else if (snapshot.hasData &&
                                  snapshot.data != null) {
                                List<List<TravelStep>> stepsByPath =
                                    snapshot.data!;

                                return ListView.builder(
                                  itemCount: allPaths.length,
                                  itemBuilder: (context, index) {
                                    // Initialize routeLookup inside itemBuilder
                                    Map<int, CombinedRouteData> routeLookup = {
                                      for (var routeData in combinedRoutes)
                                        routeData.franchiseID: routeData,
                                    };

                                    List<RouteSuggest> path = allPaths[index];
                                    List<TravelStep> paths = stepsByPath[index];

                                    double totalFare = 0.0;
                                    double totalTimeForPath = 0.0;

                                    for (var step in paths) {
                                      totalFare += step.fare.floor();
                                      totalTimeForPath +=
                                          step.travelTime!.floor();
                                    }

                                    List<String> transportationNamesList =
                                        path.map((route) {
                                      var routeData =
                                          routeLookup[route.franchiseID];
                                      return routeData != null
                                          ? routeData.transportationName
                                          : 'Walk';
                                    }).toList();

                                    return suggestRoute(
                                      transportationNamesList,
                                      ' ₱${totalFare.toString()}', // Use the calculated total fare
                                      ' ${totalTimeForPath.toString()} mins', // Use the calculated total time
                                      SvgPicture.asset('assets/icons/bus2.svg'),
                                      paths,
                                    );
                                  },
                                );
                              } else {
                                return const Center(
                                  child: Text("No route found"),
                                ); // Display message if no data is returned
                              }
                            },
                          ),
              ),

            // Expanded(
            //     child: combinedRoutes.isEmpty
            //         ? Center(
            //             child:
            //                 CircularProgressIndicator()) // Show loading indicator if no routes are found yet
            //         : allPaths.isEmpty
            //             ? Center(
            //                 child: Text(
            //                     "No route found")) // Display "No route found" message if there are no paths
            //             : ListView.builder(
            //                 itemCount: allPaths.length,
            //                 itemBuilder: (context, index) {
            //                   // Initialize routeLookup inside itemBuilder
            //                   Map<int, CombinedRouteData> routeLookup = {
            //                     for (var routeData in combinedRoutes)
            //                       routeData.franchiseID: routeData
            //                   };

            //                   // Declare variables for total fare, travel time, and combined transportation names

            //                   List<String> transportationNames = [];
            //                   List<RouteSuggest> path = allPaths[index];

            //                   Set<int> processedFranchiseIDs = {};

            //                   if (index < allPaths.length) {
            //                     Map<int, CombinedRouteData>
            //                         combinedRoutesstep = {
            //                       for (var route in combinedRoutes)
            //                         route.franchiseID: route
            //                     };

            //                     List<List<TravelStep>> stepsByPath =
            //                         populateTravelSteps(
            //                             allPaths,
            //                             combinedRoutesstep,
            //                             destinationLocation);

            //                     double totalFare = 0.0;
            //                     double totalTimeForPath = 0.0;
            //                     List<TravelStep> paths = stepsByPath[index];
            //                     for (var step in paths) {
            //                       totalFare += step.fare.floor();
            //                       totalTimeForPath += step.travelTime.floor();
            //                     }

            //                     List<String> transportationNamesList =
            //                         path.map((route) {
            //                       var routeData =
            //                           routeLookup[route.franchiseID];
            //                       return routeData != null
            //                           ? routeData.transportationName
            //                           : 'Walk';
            //                     }).toList();

            //                     return suggestRoute(
            //                       transportationNamesList,
            //                       ' ₱${totalFare.toString()}', // Use the calculated total fare
            //                       ' ${totalTimeForPath.toString()} mins', // Use the calculated total time
            //                       //totalDistanceString, // Use the calculated total distance
            //                       SvgPicture.asset('assets/icons/bus2.svg'),
            //                       stepsByPath[index],
            //                     );
            //                   } else {
            //                     // Return an empty state or a message if no path is found
            //                     return Center(child: Text('No route found.'));
            //                   }
            //                 },
            //               ))
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
  // setState(() {
  //         // selectedLegs = List<Map<String, dynamic>>.from(legs);
  //       });

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

  // Widget suggestRoute(String transpoNames, String fare, String time,
  //     SvgPicture pic, List<dynamic> steps) {
  //   return InkWell(
  //     onTap: () {
  //       setState(() {
  //         // Handle route selection logic
  //       });

  //       // Navigate to another screen if needed, passing the steps or additional data
  //     },
  //     child: Container(
  //       width: double.infinity,
  //       padding: const EdgeInsets.all(16.0),
  //       margin: const EdgeInsets.all(8.0),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(10),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withOpacity(0.2),
  //             offset: const Offset(0, 4),
  //             blurRadius: 8,
  //             spreadRadius: 2,
  //           ),
  //         ],
  //       ),
  //       child: IntrinsicHeight(
  //         child: Row(
  //           children: [
  //             Expanded(
  //               flex: 2,
  //               child: Container(
  //                 padding: const EdgeInsets.only(right: 10),
  //                 child: pic, // Icon/Image for transportation
  //               ),
  //             ),
  //             Expanded(
  //               flex: 9,
  //               child: Column(
  //                 children: [
  //                   // Transportation Name
  //                   Row(
  //                     children: [
  //                       Text(
  //                         transpoNames,
  //                         style: const TextStyle(color: Colors.black),
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 10),
  //                   // Fare
  //                   Row(
  //                     children: [
  //                       const Text(
  //                         "Fare:",
  //                         style: TextStyle(color: Colors.black),
  //                       ),
  //                       Text(fare, style: const TextStyle(color: Colors.black)),
  //                     ],
  //                   ),
  //                   // Time (you can calculate or pass estimated time here)
  //                   Row(
  //                     children: [
  //                       const Text(
  //                         "Time:",
  //                         style: TextStyle(color: Colors.black),
  //                       ),
  //                       Text(time, style: const TextStyle(color: Colors.black)),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget suggestRoute(List<String> transpoNames, String fare, String time,
      SvgPicture pic, List<TravelStep> steps) {
    return InkWell(
      onTap: () {
        setState(() {
          print("Steps Lengthsssss: ${steps.length}");
          for (var step in steps) {
            print("Step Laman: ${step.transportationName}");
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => algo3(
                latOrigin: widget.latOrigin,
                longOrigin: widget.longOrigin,
                latDestination: widget.latDestination,
                longDestination: widget.longDestination,
                steps: steps,
                origin: _controllerFrom.text,
                destination: _controllerTo.text,
              ),
            ),
          );
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.only(right: 10),
                  child: Wrap(
                    spacing: 10, // Spacing between icons
                    children: transpoNames
                        .map((name) => getTransportIcon(name))
                        .toList(), // Map the list to icons
                  ),
                ),
              ),
              Expanded(
                flex: 9,
                child: Column(
                  children: [
                    // Transportation Name(s)
                    Row(
                      children: [
                        Text(
                          transpoNames
                              .join(' > '), // Display names separated by " > "
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Fare
                    Row(
                      children: [
                        const Text(
                          "Fare:",
                          style: TextStyle(color: Colors.black),
                        ),
                        Text(fare, style: const TextStyle(color: Colors.black)),
                      ],
                    ),
                    // Time
                    Row(
                      children: [
                        const Text(
                          "Time:",
                          style: TextStyle(color: Colors.black),
                        ),
                        Text(time, style: const TextStyle(color: Colors.black)),
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

// Method to get transport icon based on transportation name
  Widget getTransportIcon(String transportationName) {
    // Convert transportationName to lowercase for case-insensitive comparison
    String normalizedName = transportationName.toLowerCase();

    switch (normalizedName) {
      case 'jeepney':
        return SvgPicture.asset(
          'assets/icons/jeep_icon.svg',
          width: 24, // Specify size here
          height: 24,
        ); // Replace with actual path
      case 'uv express':
        return SvgPicture.asset(
          'assets/icons/taxi.svg',
          width: 24, // Specify size here
          height: 24,
        ); // Replace with actual path
      case 'bus':
        return SvgPicture.asset(
          'assets/icons/bus2.svg',
          width: 24, // Specify size here
          height: 24,
        ); // Replace with actual path
      // Add other cases for different transport types
      default:
        return const Icon(
          Icons.directions_bus,
          color: Colors.grey,
          size: 24, // Default size for icon
        );
    }
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

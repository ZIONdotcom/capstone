import 'dart:async';

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
  testState createState() => testState();
}

class testState extends State<Test> {
  //map
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(14.831582, 120.903786), // Default initial position
    zoom: 11.5, // Default zoom level
  );

  //add step to the list
  List<dynamic> steps = [];
  //if there is a tricycle
  late bool tricycle;
  //late bool isWalk;

  // call the API and fetch terminals
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

//calculate distance
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

  double _degreeToRadian(double degree) {
    return degree * pi / 180;
  }

//nearest terminal
  Future<Terminal> getNearestTerminal(LatLng location) async {
    List<Terminal> terminals = await fetchTerminals();

    Terminal? nearestTerminal;
    double minDistance = double.infinity;

    for (Terminal terminal in terminals) {
      double distance = calculateDistance(
        location.latitude,
        location.longitude,
        terminal.latitude,
        terminal.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestTerminal = terminal;
      }
    }

    if (nearestTerminal != null) {
      return nearestTerminal;
    } else {
      throw Exception('No terminals found.');
    }
  }

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

  //distance walk math
  late double distanceMainRoad;
  late double distanceInMeter = 0.0;
  double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Radius of the Earth in kilometers
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in kilometers
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  //roads
  late String roadLat;
  late String roadLng;
  // Function to get nearest road using Google Maps Roads API
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

  late double originlat;
  late double originlong;
  late double destinationlat;
  late double destinationlong;
  late double origin;
  late double destination;
// Main function to check nearest road and terminals
  Future<void> checkNearest() async {
    Position userLocation = await getCurrentLocation();

    originlat = double.parse(widget.latOrigin);
    originlong = double.parse(widget.longOrigin);
    destinationlat = double.parse(widget.latDestination);
    destinationlong = double.parse(widget.longDestination);

    // Get nearest road
    await getNearestRoad(originlat, originlong);
    print('srfgswrgwr $originlat , $originlong');

    // // Find nearby public terminals
    // await findNearbyTerminals(userLocation.latitude, userLocation.longitude);
  }

  //gps
  late String lat;
  late String long;
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

  GoogleMapController? mapController;
  List<LatLng> polylineCoordinates = [];
  final Set<Polyline> _polylines = {};

  //late String lat_origin, long_origin, lat_destination, long_destination;
  final String apiKey = 'AIzaSyBcUDWZDnJBOX_Q5IOqDJi60RuqJy1-ZkY';
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
  //final Set<Marker> _markers = {};
  Set<Marker> markers = {};

  //gps livelocation ------------- if want ng custom marker
  // void liveLocation() {
  //   LocationSettings locationSettings = const LocationSettings(
  //     accuracy: LocationAccuracy.high,
  //     distanceFilter: 100,
  //   );

  //   Geolocator.getPositionStream(locationSettings: locationSettings)
  //       .listen((Position position) {
  //     lat = position.latitude.toString();
  //     long = position.longitude.toString();

  //     setState(() {
  //       print('Latitude: $lat, Longtitude: $long ====== Location Updates');
  //       markers.clear();
  //       markers.add(Marker(
  //         markerId: MarkerId('current_location'),
  //         position: LatLng(position.latitude, position.longitude),
  //         infoWindow: InfoWindow(title: 'Current Location'),
  //         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
  //       ));
  //       mapController?.animateCamera(CameraUpdate.newLatLng(
  //           LatLng(position.latitude, position.longitude)));
  //     });
  //   });
  // }
  // add step list
  Future<void> addStep() async {
    if (distanceInMeter < 200 ||
        (distanceInMeter >= 200 && tricycle == false)) {
      // walk == true
      LatLng endwalk = LatLng(double.parse(roadLat), double.parse(roadLng));
      String endwalkAddress = await getAddressFromLatLng(
          double.parse(roadLat), double.parse(roadLng));
      walkStep('Walk to $endwalkAddress', endwalk);

      for (var s in steps) {
        print('${s}eyyyyyyyyyyyyy'); // This will now print meaningful details
      }

      print(
          'end walk------------------ $endwalk and $endwalkAddress ------------=====================');
    } else if (distanceInMeter >= 200 && tricycle == true) {
      //walk = false
      print('noooooooooooooooooooooooo');
    }
  }

  //route suggestion----------------------------------------------------------------------------

  // Fetch routes and associated terminal locations from your PHP API
  Future<List<RouteSuggest>> fetchRoutesFromAPI() async {
    final response = await http.get(
        Uri.parse('https://rutaco.online/routeFinderPhp/getRoutePUV2.php'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);

      List<RouteSuggest> routeSuggestions =
          await Future.wait(data.map((route) async {
        int franchiseID = int.parse(route['franchise_ID']);
        LatLng pointA = LatLng(
          double.parse(route['point_A_x']),
          double.parse(route['point_A_y']),
        );
        LatLng pointB = LatLng(
          double.parse(route['point_B_x']),
          double.parse(route['point_B_y']),
        );

        // Fetch the route coordinates using Google Directions API
        List<LatLng> routeCoordinates =
            await fetchRouteCoordinates(pointA, pointB);

        return RouteSuggest(
          franchiseID: franchiseID,
          pointA: pointA,
          pointB: pointB,
          routeCoordinates: routeCoordinates,
        );
      }).toList());

      return routeSuggestions;
    } else {
      throw Exception('Failed to load routes');
    }
  }

//Test
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

  Future<void> findNearbyRoutes(LatLng userLocation) async {
    // Fetch routes from the database
    List<RouteSuggest> routes = await fetchRoutesFromAPI();

    // Define proximity threshold (e.g., 100 meters)
    const double proximityThreshold = 100.0;

    List<RouteSuggest> nearbyRoutes = [];

    // Check if any route is within proximity of the user's location
    for (var route in routes) {
      // Calculate distance to Point A and Point B
      double distanceToPointA = calculateDistances(userLocation, route.pointA);
      double distanceToPointB = calculateDistances(userLocation, route.pointB);

      // Print route coordinates for debugging
      print(
          'Route Franchise ID:------------------------------------------------------------------------------------------------------------------------------------------------------------- ${route.franchiseID} , Route Coordinates:');
      for (var point in route.routeCoordinates) {
        print('Latitude: ${point.latitude}, Longitude: ${point.longitude}');
      }

      print('Coordinates: ${route.routeCoordinates.length.toString()}');

      // Check the distance to each coordinate in the route
      for (var point in route.routeCoordinates) {
        double distanceToRoutePoint = calculateDistances(userLocation, point);
        if (distanceToRoutePoint <= proximityThreshold) {
          nearbyRoutes.add(route);
          break; // No need to check other points if we already found a nearby route
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
      print("No routes nearby");
    }
  }

  void displayRoutes(List<RouteSuggest> nearbyRoutes) {
    for (var route in nearbyRoutes) {
      print(
          'Nearby Route: Franchise ID: ${route.franchiseID}, Points: ${route.pointA}, ${route.pointB}');
      // You can update your UI here
    }
  }

//calculate distance between two LatLng points (in meters)
  double calculateDistances(LatLng point1, LatLng point2) {
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

//convert degrees to radians
  double radians(double degree) => degree * pi / 180;

//Coordinates adding , creation
  Future<List<LatLng>> fetchRouteCoordinates(
      LatLng pointA, LatLng pointB) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${pointA.latitude},${pointA.longitude}&destination=${pointB.latitude},${pointB.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        String encodedPolyline =
            data['routes'][0]['overview_polyline']['points'];
        return decodePolylines(encodedPolyline);
      } else {
        throw Exception('Failed to get directions');
      }
    } else {
      throw Exception('Failed to load data from API');
    }
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

  //TEST
  Future<void> testFetchRouteCoordinates() async {
    // Sample points for testing (Guiguinto, Malolos) - ongoing
    LatLng pointA = LatLng(14.794754, 120.876076); // Guiguinto
    LatLng pointB = LatLng(14.82812, 120.884323); // Malolos

    try {
      // Fetch the route coordinates between pointA and pointB
      List<LatLng> routeCoordinates =
          await fetchRouteCoordinates(pointA, pointB);

      // Log the coordinates
      if (routeCoordinates.isNotEmpty) {
        print("Route coordinates between Point A and Point B:");
        for (LatLng coord in routeCoordinates) {
          print('Lat::: ${coord.latitude}, Lng: ${coord.longitude}');
        }
      } else {
        print("No coordinates found for the route.");
      }
    } catch (e) {
      print("Error fetching route coordinates: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _controllerTo.text = widget.originName;
    _controllerFrom.text = widget.destinationName;

    print(
        'TEST ---------------------------mmjksfkdbjgbker     jksbjfbsr -----------------------origin: ${widget.latOrigin}, ${widget.longOrigin}long: ${widget.latDestination}, ${widget.longDestination}');
    LatLng sample = const LatLng(14.827017, 120.883796);

    //test latlng sample should be palitan ng origin latlng

    //TEST ZONE
    //routes from db
    fetchAndPrintRoutes();

    //test latlng sample should be palitan ng origin latlng
    // function to get the nearest terminal
    getNearestTerminal(sample).then((nearestTerminal) {
      print('Nearest Terminal: ${nearestTerminal.name}');
      print('Terminal ID: ${nearestTerminal.id}');
      print('Latitude: ${nearestTerminal.latitude}');
      print('Longitude: ${nearestTerminal.longitude}');
    }).catchError((error) {
      print('Error finding nearest terminal: $error');
    });
    // Call the function to fetch terminals and print the results
    fetchTerminals().then((terminals) {
      for (Terminal terminal in terminals) {
        print(
            'Terminal ID: ${terminal.id}, Name: ${terminal.name}, Latitude: ${terminal.latitude}, Longitude: ${terminal.longitude}');
      }
    }).catchError((error) {
      print('Error fetching terminals: $error');
    });
    print('ewan ko kung gagana ${getNearestTerminal(sample)}');

    //nearby routes passing - ongoing
    findNearbyRoutes(sample);

    //TESt - ongoing
    testFetchRouteCoordinates();

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

    fetchRoute();

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

  //polyline

  //transportation suggestion transit
  // Fetch public transport routes from the API
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

  List<Map<String, dynamic>> publicTransportRoutes = [];

  //latlng to human readable address
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

  // Call this method to get the routes and update the UI
  // Call this method to get the routes and print the details in the terminal
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
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
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
                  latOrigin: widget.latOrigin,
                  longOrigin: widget.latOrigin,
                  latDestination: widget.latDestination,
                  longDestination: widget.longDestination,
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

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:capstone/LegStepAlgo_model.dart';
import 'package:capstone/pages/routeFinder.dart';
import 'package:capstone/terminal_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'searchpage.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class algo3draft extends StatefulWidget {
  @override
  //final List<dynamic> legs;
  final List<TravelStep> steps;
  final String origin;
  final String destination;
  final String latOrigin, longOrigin;
  final String latDestination, longDestination;
  final String TimeTotal;

  const algo3draft({
    super.key,
    required this.latOrigin,
    required this.longOrigin,
    required this.latDestination,
    required this.longDestination,
    //required this.legs,
    required this.steps,
    required this.origin,
    required this.destination,
    required this.TimeTotal,
  });

  @override
  ThirdScreenState createState() => ThirdScreenState();
}

class ThirdScreenState extends State<algo3draft> {
  final String apiKey = 'AIzaSyC88-Wkb5_LmPU5OCQwPOMDTry3RGh1J00';
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

  final Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
/*
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

          print(
              'may laman ba ang route points? ${step.routePoints.length} ano ang laman? ${step.routePoints}');

          //v3

          if (step.routePoints != null && step.routePoints.isNotEmpty) {
            // Identify the indices of sakayanLocation and babaanLocation in routePoints
            int startIndex = step.routePoints.indexWhere((point) =>
                point.latitude == step.sakayanLocation.latitude &&
                point.longitude == step.sakayanLocation.longitude);
            int endIndex = step.routePoints.indexWhere((point) =>
                point.latitude == step.babaanLocation.latitude &&
                point.longitude == step.babaanLocation.longitude);

            // Ensure valid indices are found
            if (startIndex != -1 && endIndex != -1 && startIndex < endIndex) {
              // Add only the routePoints between sakayanLocation and babaanLocation
              final filteredRoutePoints =
                  step.routePoints.sublist(startIndex + 1, endIndex);
              polylinePoints.addAll(filteredRoutePoints);
            }
          }

          // Filter routePoints to include only those between sakayanLocation and babaanLocation
          // if (step.routePoints != null && step.routePoints.isNotEmpty) {
          //   final filteredRoutePoints = step.routePoints.where((point) {
          //     return _isPointBetweenLocations(
          //         point, step.sakayanLocation, step.babaanLocation);
          //   }).toList();
          //   polylinePoints.addAll(filteredRoutePoints);
          // }

          // List<LatLng> filteredRoutePoints = [];
          // if (step.routePoints != null && step.routePoints.isNotEmpty) {
          //   filteredRoutePoints = step.routePoints.where((point) {
          //     return _isPointBetweenLocations(
          //         point, step.sakayanLocation, step.babaanLocation);
          //   }).toList();
          // }

          // // Only add the filtered routePoints to the polylinePoints if there are any
          // if (filteredRoutePoints.isNotEmpty) {
          //   polylinePoints.addAll(filteredRoutePoints);
          // }

          // Add babaanLocation at the end
          polylinePoints.add(step.babaanLocation);

          // Ensure no polyline is drawn if the points are just sakayanLocation and babaanLocation (i.e., no intermediate route points)
          if (polylinePoints.length > 1) {
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
              _polylines.add(polyline);
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
*/

  late List<LatLng> coords = [];

  List<LatLng> filteredRoutePoints = [];
  void _addMarkersAndPolylines() async {
    if (isDisposed) return;
    // Clear previous markers, circles, and polylines
    setState(() {
      _markers.clear();
      _circles.clear();
      _polylines.clear();
    });

    // Loop through each step and add polyline between sakayanLocation and babaanLocation
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];

      try {
        print('step fid ${step.routeName}');
        print('step $i: sakayanLocation: ${step.sakayanLocation}');
        print('step $i: babaanLocation: ${step.babaanLocation}');
        print('step $i: routePoints: ${step.routePoints}');

        // Create a new list for polyline points, starting with sakayanLocation
        List<LatLng> polylinePoints = [step.sakayanLocation];

        // Filter the route points to include only those between sakayanLocation and babaanLocation
        // filteredRoutePoints = _filterRoutePoints(step.routePoints, step.sakayanLocation, step.babaanLocation);
        if (step.FranchiseID == -1) {
          step.routePoints = await getRoadCoordinates(
              step.sakayanLocation, step.babaanLocation);
        } else {
          coords = _filterRoutePoints(
            step.routePoints,
            step.sakayanLocation,
            step.babaanLocation,
          );
          // timeTravel();
          step.routePoints = _filterRoutePoints(
            step.routePoints,
            step.sakayanLocation,
            step.babaanLocation,
          );
        }

        polylinePoints.addAll(step.routePoints);

        // Add babaanLocation at the end
        polylinePoints.add(step.babaanLocation);

        // Ensure no polyline is drawn if the points are just sakayanLocation and babaanLocation (i.e., no intermediate route points)
        if (polylinePoints.length > 1) {
          print('Final polyline points for step $i: $polylinePoints');

          // Create the polyline using the polylinePoints list
          final polyline = Polyline(
            polylineId: PolylineId('route_$i'),
            points:
                polylinePoints, // This now includes sakayanLocation, filtered routePoints, and babaanLocation
            color: Colors.blue,
            width: 5,
          );
          if (isDisposed) return;

          setState(() {
            _polylines.add(polyline);
          });
        }

        for (var point in polylinePoints) {
          if (point.latitude.isNaN || point.longitude.isNaN) {
            print("Invalid point detected: $point");
          }
        }
        // Add start and end markers for this route segment
        final startMarker = Marker(
          markerId: MarkerId('start_$i'),
          position: step.sakayanLocation,
          infoWindow: InfoWindow(title: 'Start: ${step.transportationName}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );

        final endMarker = Marker(
          markerId: MarkerId('end_$i'),
          position: step.babaanLocation,
          infoWindow: InfoWindow(title: 'End: ${step.transportationName}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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
        if (isDisposed) return;

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

  Future<List<LatLng>> getRoadCoordinates(
      LatLng origin, LatLng destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final polyline = route['overview_polyline']['points'];

        // Decode the polyline into a list of LatLng points
        return _decodePolyline(polyline);
      }
    }

    return [];
  }

  // List<LatLng> _filterRoutePoints(
  //     List<LatLng> routePoints, LatLng sakayanLocation, LatLng babaanLocation) {
  //   // Find the index of sakayanLocation and babaanLocation in the routePoints list
  //   int startIndex = _findClosestSegment(routePoints, sakayanLocation);
  //   int endIndex = _findClosestSegment(routePoints, babaanLocation);

  //   // Check if both indices are valid
  //   if (startIndex == -1 || endIndex == -1) {
  //     print("One of the points couldn't be found.");
  //     return [];
  //   }

  //   // Return the sublist of routePoints between sakayanLocation and babaanLocation
  //   if (startIndex < endIndex) {
  //     return routePoints.sublist(startIndex, endIndex + 1);
  //   } else {
  //     return routePoints.sublist(endIndex, startIndex + 1);
  //   }
  // }

  List<LatLng> _filterRoutePoints(
      List<LatLng> routePoints, LatLng sakayanLocation, LatLng babaanLocation) {
    // Find the closest segments to sakayanLocation and babaanLocation in the route
    int startIndex = _findClosestSegment(routePoints, sakayanLocation);
    int endIndex = _findClosestSegment(routePoints, babaanLocation);

    // If either sakayanLocation or babaanLocation is not found, return an empty list
    if (startIndex == -1 || endIndex == -1) {
      print("One of the points couldn't be found.");
      return [];
    }

    // Initialize the result list
    List<LatLng> filteredPoints = [];

    // Add points from startIndex to endIndex, in the correct direction
    if (startIndex < endIndex) {
      // Collect points between the start and end index, including the start and end points
      for (int i = startIndex; i <= endIndex; i++) {
        filteredPoints.add(routePoints[i]);
      }
    } else {
      // If sakayanLocation is after babaanLocation, collect points in reverse order
      for (int i = startIndex; i >= endIndex; i--) {
        filteredPoints.add(routePoints[i]);
      }
    }

    return filteredPoints;
  }

  int _findClosestSegment(List<LatLng> routePoints, LatLng location) {
    double minDistance =
        double.infinity; // Start with an infinitely large distance
    int closestIndex = -1;

    for (int i = 0; i < routePoints.length; i++) {
      double distance = _calculateDistance(routePoints[i], location);

      // If this point is closer than the previous closest, update the closest index
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex; // Return the index of the closest point
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double R = 6371; // Earth radius in km
    double lat1 = point1.latitude * pi / 180;
    double lon1 = point1.longitude * pi / 180;
    double lat2 = point2.latitude * pi / 180;
    double lon2 = point2.longitude * pi / 180;

    double dlat = lat2 - lat1;
    double dlon = lon2 - lon1;

    double a = sin(dlat / 2) * sin(dlat / 2) +
        cos(lat1) * cos(lat2) * sin(dlon / 2) * sin(dlon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Return distance in kilometers
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

//---GPS
  bool _isMapCreated = false;
  bool position = false;
  late StreamSubscription<Position> positionStream;
  LatLng previousLocation = LatLng(0, 0); // Initialize with a default location
  Map<String, List<LatLng>> polylineCache = {};
  bool _isWalkingStepAdded = false;
  bool _isMarkerDone = false;
  bool _isRemoveStepDone = false;
  bool start = false;

  void _trackUserLocation() {
    if (_isMapCreated) {
      position = true;
      positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      ).listen((Position position) {
        if (start == false) {
          trackLocationAndCalculate();
          print('2runnnnggg?');
          start = true;
        }

        print('plus api calssssss');

        _updateUserLocation(LatLng(position.latitude, position.longitude));
      });
    }
  }

  late List<LatLng> newPoints = [];
  bool isnewPoint = false;
//  d totalTravelTimestart = 0;
  late Future<double> totalTravelTimestart;
  bool isRemainingTime = false;
  //late double predefinedTravelTime;

  void _updateUserLocation(LatLng userLocation) {
    if (isDisposed) return;
    setState(() {
      print('2plus api calssssss');

      //----------------------------------------Create a marker for the user's location
      final userMarker = Marker(
        markerId: const MarkerId('user_location'),
        position: userLocation,
        infoWindow: const InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );

      _markers.add(userMarker);
      //-----------------------------------------------------

      //------------------------------------- Identify the current step nearest to the user
      int nearestStepIndex = _findNearestStep(userLocation);
      print('nearest step index: $nearestStepIndex');
      //-----------------------------------------------------

      if (nearestStepIndex != -2) {
        List<LatLng> updatedPolylinePoints = [];
        updatedPolylinePoints.add(userLocation); // Start from user's location

        // Get the nearest step
        final step = steps[nearestStepIndex];

        // Find the nearest coordinate on the step's route
        LatLng? nearestRoutePoint;
        double minDistance = double.infinity;
        int nearestRoutePointIndex = -1;

        if (step.routePoints.isNotEmpty) {
          for (int i = 0; i < step.routePoints.length; i++) {
            final routePoint = step.routePoints[i];
            double distance = Geolocator.distanceBetween(
              userLocation.latitude,
              userLocation.longitude,
              routePoint.latitude,
              routePoint.longitude,
            );

            if (distance < minDistance) {
              minDistance = distance;
              nearestRoutePoint = routePoint;
              nearestRoutePointIndex = i;
            }
          }
        }

        //---------------------------- If a nearest route point is found, connect from there
        if (nearestRoutePoint != null) {
          //--------------------------------- add marker at meeting point
          if (!_isMarkerDone) {
            final connectedMarker = Marker(
              markerId: const MarkerId('connected_point'),
              position: nearestRoutePoint,
              infoWindow: const InfoWindow(title: 'Connected Point'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
            );
            if (isDisposed) return;

            setState(() {
              _markers.add(connectedMarker); // Add the marker to the map
            });

            _isMarkerDone = true;
          }

          //=-----------------------------------

          // Check if the current location polyline is already cached
          String polylineKey =
              '${userLocation.latitude},${userLocation.longitude}:${nearestRoutePoint.latitude},${nearestRoutePoint.longitude}';
          if (polylineCache.containsKey(polylineKey)) {
            updatedPolylinePoints.addAll(polylineCache[polylineKey]!);
          } else {
            print(' 3plus api calssssss');
            //---------------- Fetch the snapped polyline to the nearest route point
            _getSnappedPolyline(userLocation, nearestRoutePoint)
                .then((snappedPolyline) async {
              // Cache the polyline for later use
              polylineCache[polylineKey] = snappedPolyline;
              updatedPolylinePoints.addAll(snappedPolyline);

              // Add remaining points in the current step starting from the nearest route point index
              if (nearestRoutePointIndex != -1) {
                for (int i = nearestRoutePointIndex;
                    i < step.routePoints.length;
                    i++) {
                  updatedPolylinePoints.add(step.routePoints[i]);
                }
              }

              // Add points from subsequent steps
              for (int i = nearestStepIndex + 1; i < steps.length; i++) {
                final nextStep = steps[i];
                //ignore newly added step
                if (nextStep.FranchiseID == -3) {
                  continue;
                }
                if (nextStep.routePoints.isNotEmpty) {
                  updatedPolylinePoints.addAll(nextStep.routePoints);
                }
              }

              if (isnewPoint == false) {
                newPoints.addAll(updatedPolylinePoints);

                // trackRemainingTimeWithWaypoints(updatedPolylinePoints,
                //     destinationLocation, predefinedTravelTime);
                print('are you running?222');
                if (isDisposed) return;
                setState(() {
                  isremaining = true;
                });

                isnewPoint = true;
              }

              if (!_isRemoveStepDone) {
                // Add points from subsequent steps
                List<int> excludedSteps = _getExcludedSteps(nearestStepIndex);

                // String excludedStepsStr = excludedSteps.map((index) {
                //   if (index >= 0 && index < steps.length) {
                //     String franchiseId = steps[index].routeName ??
                //         'Unknown'; // Replace with actual field name
                //     return '${index + 1} -> $franchiseId';
                //   }
                //   return '';
                // }).join(' -> ');

                removeExcludedSteps(nearestStepIndex);

                // // Print the excluded steps in the console
                // print('Excluded Steps: $excludedStepsStr');
                _isRemoveStepDone = true;
              }
              List<int> yey = [];
              for (var step in steps) {
                yey.add(step.FranchiseID);
              }
              print('steps yeeee: $yey');

              if (!_isWalkingStepAdded) {
                addWalkingStepAtBeginning(userLocation, nearestRoutePoint,
                    'Walk towards the first Point');
                _isWalkingStepAdded =
                    true; // Set flag to true after adding walking step
              }

              //-------------------------------------- TRAVEL TIME
//              calculateTravelTimeFromCurrentLocation(userLocation, steps);

              //---------------------------------------

              // Now that we have the updated polyline, remove markers that are not part of it
              Set<String> validMarkerIds = {}; // Set of valid marker IDs

              // Check each route point in the updated polyline
              for (var point in updatedPolylinePoints) {
                for (var marker in _markers) {
                  if (Geolocator.distanceBetween(
                        marker.position.latitude,
                        marker.position.longitude,
                        point.latitude,
                        point.longitude,
                      ) <
                      10) {
                    // You can adjust the distance threshold if necessary
                    validMarkerIds.add(marker.markerId.value);
                  }
                }
              }

              // Remove markers that are no longer part of the polyline
              _markers.removeWhere(
                  (marker) => !validMarkerIds.contains(marker.markerId.value));
              if (isDisposed) return;

              //-----------------------current step
              if (steps.isNotEmpty && steps[0].FranchiseID == -3) {
                // If the user is within range of the walking step, treat it as the current step
                if (isDisposed) return;
                setState(() {
                  currentStepIndex = 0;
                });
              } else {
                // Otherwise, find the nearest step (existing logic)
                int nearestStepIndex = _findNearestStep(userLocation);
                setState(() {
                  currentStepIndex = nearestStepIndex;
                });
              }

              //----------------------------------

              // Create the updated polyline
              final updatedPolyline = Polyline(
                polylineId: const PolylineId('updated_route'),
                points: updatedPolylinePoints,
                color: Colors.blue,
                width: 5,
              );
              if (isDisposed) return;

              // Update state
              setState(() {
                _polylines.clear(); // Clear old polylines
                _polylines.add(updatedPolyline); // Add the updated polyline
              });
            });
          }
        } else {
          userLocationDialog(context);
        }

        // Move the camera to the user's current location
        _mapController.animateCamera(CameraUpdate.newLatLng(userLocation));
      }
    });
  }

//TRAVEL TIME DRAFT----------------------------------------------------------------------------------
  //final Geolocator _geolocator = Geolocator();
  Position? currentPosition;
  double? totalDistance = 0;
  double? totalTimeInSeconds = 0;
  double? velocity;
  DateTime? lastUpdateTime;
  Timer? positionTimer;

// Variables to track movement time and last update time
  double? movementTimeInSeconds = 0; // Tracks actual moving time
  DateTime? lastMovementTime; // Tracks the last time the user was moving

// Default velocity (m/s) for when the user is not moving
  double defaultVelocity =
      20.0; // Can be adjusted based on walking, driving, etc.

// Method to track the location and calculate velocity and distance
  void trackLocationAndCalculate() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Calculate the distance from the current position to the destination
    double remainingDistance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      destinationLocation.latitude,
      destinationLocation.longitude,
    );

    // Calculate the velocity (m/s) - only if we have movement time
    if (movementTimeInSeconds != 0) {
      velocity = remainingDistance / movementTimeInSeconds!; // m/s
    }

    // If the velocity is still not calculated (user isn't moving), use the default velocity
    if (velocity == null || velocity == 0) {
      velocity = defaultVelocity; // Use default velocity when stationary
    }

    // Calculate the estimated time left to reach the destination
    double timeRemaining = remainingDistance / velocity!; // time in seconds

    // Convert time remaining into hours, minutes, and seconds
    int hours = (timeRemaining / 3600).floor();
    int minutes = ((timeRemaining % 3600) / 60).floor();
    int seconds = (timeRemaining % 60).floor();
    if (isDisposed) return;

    // Update the total distance and time
    setState(() {
      totalDistance = remainingDistance;
      totalTimeInSeconds = timeRemaining;
    });

    // Debugging: print current position, remaining distance, and time left
    print(
        "Current Position: Lat: ${position.latitude}, Lon: ${position.longitude}");
    print("Remaining Distance: ${remainingDistance.toStringAsFixed(2)} meters");
    print("Time Left: ${hours}h ${minutes}m ${seconds}s");
    print("Velocity: ${velocity?.toStringAsFixed(2)} m/s");

    // If the user has not reached the destination, keep updating the time
    if (remainingDistance > 0) {
      positionTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
        trackLocationAndCalculate(); // Keep tracking until destination is reached
      });
    } else {
      // Once the user has reached the destination, stop tracking
      positionTimer?.cancel();
    }
  }

  // Helper method to format the total time into hours, minutes, and seconds
  String formatDuration(double totalTimeInSeconds) {
    int hours = (totalTimeInSeconds / 3600).floor();
    int minutes = ((totalTimeInSeconds % 3600) / 60).floor();
    int seconds = (totalTimeInSeconds % 60).floor();
    return "${hours}h ${minutes}m ${seconds}s";
  }

  // Debugging method to print out the relevant details during the trip
  void _printDebuggingInfo(Position position, double remainingDistance) {
    print('--- Debug Info ---');
    print(
        'Current Position: Lat: ${position.latitude}, Lon: ${position.longitude} Remaining Distance: ${remainingDistance.toStringAsFixed(2)} meters Total Time: ${formatDuration(totalTimeInSeconds!)} Velocity: ${velocity?.toStringAsFixed(2)} m/s');

    print(
        'Current Position: Lat: ${position.latitude}, Lon: ${position.longitude}');
    print('Remaining Distance: ${remainingDistance.toStringAsFixed(2)} meters');
    print('Total Time: ${formatDuration(totalTimeInSeconds!)}');
    print('Velocity: ${velocity?.toStringAsFixed(2)} m/s');
    print('-------------------');
  }

  //---------------------------------------------------------------------------------------

  //----------------------------------TRAVEL TIME
  //remainingTimeNotifier.value = predefinedTravelTime;
  bool isremaining = false;

  ValueNotifier<double> remainingTimeNotifier = ValueNotifier<double>(0.0);
  ValueNotifier<double> remainingDistanceNotifier = ValueNotifier<double>(0.0);

// Function to calculate the total distance based on waypoints and destination
  // Function to calculate the total distance based on waypoints and destination
  double calculateTotalDistance(
      Position position, List<LatLng> waypoints, LatLng destination) {
    double totalDistance = 0.0;
    LatLng lastWaypoint = LatLng(position.latitude, position.longitude);

    // Iterate through the waypoints and calculate the distance from current position to the next waypoint
    for (LatLng waypoint in waypoints) {
      totalDistance += Geolocator.distanceBetween(
        lastWaypoint.latitude,
        lastWaypoint.longitude,
        waypoint.latitude,
        waypoint.longitude,
      );
      lastWaypoint = waypoint;
    }

    // Add distance to the destination (in meters)
    totalDistance += Geolocator.distanceBetween(
      lastWaypoint.latitude,
      lastWaypoint.longitude,
      destination.latitude,
      destination.longitude,
    );

    return totalDistance / 1000; // Convert meters to kilometers
  }

  Future<void> trackRemainingTimeWithWaypoints(
    List<LatLng> waypoints,
    LatLng destination,
    double predefinedRemainingTime,
  ) async {
    Position? previousPosition;
    DateTime? previousTime;
    double totalDistance = 0.0;
    double distanceCovered = 0.0;
    double lastKnownVelocity = 10.0; // Default initial velocity (km/h)
    const double normalSpeed = 16.67; // km/h (60 km/h)

    print('Tracking remaining time...');

    // Assuming predefined time is used until movement is detected
    double remainingTime = predefinedRemainingTime;
    position = true;
    // Initialize the position stream to listen to position updates
    positionStream = Geolocator.getPositionStream().listen((Position position) {
      if (previousPosition != null && previousTime != null) {
        // Calculate distance traveled since last position update (in meters)
        final distanceTraveled = Geolocator.distanceBetween(
          previousPosition!.latitude,
          previousPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        // Update distance covered (in meters)
        distanceCovered += distanceTraveled;

        // Calculate the remaining distance using waypoints and destination (in kilometers)
        double remainingDistance =
            calculateTotalDistance(position, waypoints, destination);

        // If the distance traveled is greater than 0, calculate the velocity and remaining time
        if (distanceTraveled > 0) {
          final timeElapsed =
              DateTime.now().difference(previousTime!).inSeconds;
          final velocity =
              distanceTraveled / timeElapsed; // velocity in meters per second

          // Convert velocity to kilometers per hour
          double velocityKmH = velocity * 3.6;

          if (velocityKmH > 0 && velocityKmH < 30) {
            // Ensure realistic velocity
            lastKnownVelocity = velocityKmH;
            remainingTime = remainingDistance / lastKnownVelocity;

            // Update the ValueNotifier for remaining time
            remainingTimeNotifier.value = remainingTime;

            print('Remaining time: ${remainingTime.toStringAsFixed(2)} mins');
          }
        }

        // Update the ValueNotifier for remaining distance
        remainingDistanceNotifier.value = remainingDistance;
      } else {
        // Store the initial position and time
        previousPosition = position;
        previousTime = DateTime.now(); // Set initial time
      }

      // Update the previous position after each calculation
      previousPosition = position;
      previousTime = DateTime.now(); // Update the time
    });
  }

/*
  double calculateTotalDistance(
      Position currentPosition, List<LatLng> waypoints, LatLng destination) {
    double totalDistance = 0;
    LatLng currentPoint =
        LatLng(currentPosition.latitude, currentPosition.longitude);

    for (var waypoint in waypoints) {
      totalDistance += Geolocator.distanceBetween(
        currentPoint.latitude,
        currentPoint.longitude,
        waypoint.latitude,
        waypoint.longitude,
      );
      currentPoint = waypoint;
    }

    totalDistance += Geolocator.distanceBetween(
      currentPoint.latitude,
      currentPoint.longitude,
      destination.latitude,
      destination.longitude,
    );

    return totalDistance;
  }
*/
  void removePassedWaypoints(Position currentPosition, List<LatLng> waypoints) {
    while (waypoints.isNotEmpty) {
      final nextWaypoint = waypoints.first;
      final distanceToWaypoint = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        nextWaypoint.latitude,
        nextWaypoint.longitude,
      );

      if (distanceToWaypoint < 20) {
        waypoints.removeAt(0);
      } else {
        break;
      }
    }
  }

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

// Helper function to convert LatLng to Position
  Position convertLatLngToPosition(LatLng latLng) {
    return Position(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      altitude: 0.0,
      speed: 0.0,
      heading: 0.0,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  //----------------------------------

  Future<List<LatLng>> _getSnappedPolyline(
      LatLng origin, LatLng destination) async {
    if (isDisposed) return [];
    // Check if polyline already cached before making the API call
    String cacheKey =
        '${origin.latitude},${origin.longitude}:${destination.latitude},${destination.longitude}';
    if (polylineCache.containsKey(cacheKey)) {
      return polylineCache[cacheKey]!;
    }

    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=walking&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final polyline = route['overview_polyline']['points'];

        // Decode the polyline string into a list of LatLng points
        List<LatLng> decodedPolyline = _decodePolyline(polyline);

        // Cache the result
        polylineCache[cacheKey] = decodedPolyline;

        return decodedPolyline;
      }
    }

    return [];
  }

  void addWalkingStepAtBeginning(
      LatLng userLocation, LatLng? babaanLocation, String sakayanPlaceName) {
    if (isDisposed) return;
    // Create a new walking step
    final walkingStep = TravelStep(
      FranchiseID: -3,
      transportationName: 'Walking', // Transportation type
      travelTime: 0.2, // Approximate walking time in hours
      babaanLocation: babaanLocation ??
          LatLng(0.0, 0.0), // Starting point is user's current location
      babaanPlaceName: 'Current Location', // Description of the starting point
      sakayanLocation: userLocation, // Destination for this walking step
      sakayanPlaceName: sakayanPlaceName, // Destination place name
      routeName: [
        'Walk to $sakayanPlaceName'
      ], // Description of the walking route
      fare: 0.0, // Walking doesn't have a fare
      travelDistance: Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        babaanLocation!.latitude,
        babaanLocation.longitude,
      ), // Calculate distance between points
      routePoints: [userLocation, babaanLocation], // Define route points
    );
    if (isDisposed) return;
    // Prepend the walking step to the steps list
    setState(() {
      steps.insert(0, walkingStep);
    });
  }

/*
  void _updateUserLocation(LatLng userLocation) {
    setState(() {
      // Create a marker for the user's location
      final userMarker = Marker(
        markerId: MarkerId('user_location'),
        position: userLocation,
        infoWindow: InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );

      // Add or update the user location marker
      _markers.add(userMarker);

      // Identify the current step nearest to the user
      int nearestStepIndex = _findNearestStep(userLocation);

      if (nearestStepIndex != -2) {
        List<LatLng> updatedPolylinePoints = [];
        updatedPolylinePoints.add(userLocation); // Start from user's location

        // Get the nearest step
        final step = steps[nearestStepIndex];

        // Find the nearest coordinate on the step's route
        LatLng? nearestRoutePoint;
        double minDistance = double.infinity;
        int nearestRoutePointIndex = -1;

        if (step.routePoints != null && step.routePoints.isNotEmpty) {
          for (int i = 0; i < step.routePoints.length; i++) {
            final routePoint = step.routePoints[i];
            double distance = Geolocator.distanceBetween(
              userLocation.latitude,
              userLocation.longitude,
              routePoint.latitude,
              routePoint.longitude,
            );

            if (distance < minDistance) {
              minDistance = distance;
              nearestRoutePoint = routePoint;
              nearestRoutePointIndex = i;
            }
          }
        }

        // If a nearest route point is found, connect from there
        if (nearestRoutePoint != null) {
          updatedPolylinePoints.add(nearestRoutePoint);

          // Add remaining points in the current step starting from the nearest route point index
          if (nearestRoutePointIndex != -1) {
            for (int i = nearestRoutePointIndex;
                i < step.routePoints.length;
                i++) {
              updatedPolylinePoints.add(step.routePoints[i]);
            }
          }

          // Add points from subsequent steps
          for (int i = nearestStepIndex + 1; i < steps.length; i++) {
            final nextStep = steps[i];
            if (nextStep.routePoints != null &&
                nextStep.routePoints.isNotEmpty) {
              updatedPolylinePoints.addAll(nextStep.routePoints);
            }
          }
        }

        // Create the updated polyline
        final updatedPolyline = Polyline(
          polylineId: PolylineId('updated_route'),
          points: updatedPolylinePoints,
          color: Colors.blue,
          width: 5,
        );

        // Update state
        setState(() {
          _polylines.clear(); // Clear old polylines
          _polylines.add(updatedPolyline); // Add the updated polyline
        });
      } else {
        userLocationDialog(context);
      }

      // Move the camera to the user's current location
      _mapController.animateCamera(CameraUpdate.newLatLng(userLocation));
    });
  }
*/
/*
  Future<List<LatLng>> _getSnappedPolyline(
      LatLng origin, LatLng destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=walking&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final polyline = route['overview_polyline']['points'];

        // Decode the polyline string into a list of LatLng points
        return _decodePolyline(polyline);
      }
    }

    return [];
  }
*/

  List<LatLng> _decodePolyline(String encoded) {
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
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  int _findNearestStep(LatLng userLocation) {
    double minDistance = double.infinity;
    int nearestStepIndex = -2;
    LatLng pointFinal = LatLng(0, 0);

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];

      // Skip the step with FranchiseID -3 (the newly created walking step)
      if (step.FranchiseID == -3) {
        continue; // Skip this step
      }

      if (step.routePoints.isNotEmpty) {
        for (LatLng point in step.routePoints) {
          double distance = Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            point.latitude,
            point.longitude,
          );
          if (distance < minDistance) {
            minDistance = distance;
            pointFinal = point;

            double pointTobaban =
                calculateDistances(pointFinal, step.babaanLocation);
            if (pointTobaban >= 200) {
              nearestStepIndex = i;
            } else {
              nearestStepIndex = i + 1;
            }
          }
        }
      }
    }

    print(
        'Final nearest step index: $nearestStepIndex distance: $minDistance userlocation: $userLocation point: $pointFinal');

    return minDistance <= 300 ? nearestStepIndex : -2; // 50 meters threshold
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

  List<int> _getExcludedSteps(int nearestStepIndex) {
    // If nearestStepIndex is invalid, exclude all steps
    if (nearestStepIndex < 0 || nearestStepIndex >= steps.length) {
      return List<int>.generate(steps.length, (index) => index);
    }

    // Add all steps before the nearest step (exclusive)
    List<int> excludedSteps =
        List<int>.generate(nearestStepIndex, (index) => index);

    return excludedSteps;
  }

  void removeExcludedSteps(int nearestStepIndex) {
    // Get the excluded step indices
    List<int> excludedStepsIndices = _getExcludedSteps(nearestStepIndex);

    // Retain steps that are not in the exclusion list
    steps = steps
        .asMap()
        .entries
        .where((entry) {
          int index = entry.key;
          return !excludedStepsIndices.contains(index);
        })
        .map((entry) => entry.value)
        .toList();
  }

/*
  //updates the user location
  void _trackUserLocation() {
    if (_isMapCreated) {
      Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high, // High accuracy for location updates
        ),
      ).listen((Position position) {
        //updates the user location
        _updateUserLocation(
          LatLng(position.latitude,
              position.longitude), // Pass updated coordinates
        );
      });
    }
  }

  void _updateUserLocation(LatLng userLocation) {
    setState(() {
      // Create a marker for the user's location
      final userMarker = Marker(
        markerId: MarkerId('user_location'),
        position: userLocation,
        infoWindow: InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );

      // Add or update the user location marker
      _markers.add(userMarker);

       // Identify the current step nearest to the user
    int nearestStepIndex = _findNearestStep(userLocation);


      // Check if the user is close to the route points
      for (int i = 0; i < steps.length; i++) {
        final step = steps[i];

        if (step.routePoints != null && step.routePoints.isNotEmpty) {
          // Check if the user is near the current step's polyline
          bool isOnRoute = step.routePoints.any((point) {
            return _isPointNear(userLocation, point, 50.0); // Within 50 meters
          });

          if (isOnRoute) {
            // Add the user location to the polyline points
            List<LatLng> updatedPolylinePoints = [
              ...step.routePoints,
              userLocation
            ];

            // Create a new polyline
            final polyline = Polyline(
              polylineId: PolylineId('route_$i'),
              points: updatedPolylinePoints,
              color: Colors.blue,
              width: 5,
            );

            // Remove the old polyline and add the updated one
            _polylines.removeWhere((p) => p.polylineId.value == 'route_$i');
            _polylines.add(polyline);
          }
        }
      }

      // Move the camera to the user's current location
      _mapController.animateCamera(CameraUpdate.newLatLng(userLocation));
    });
  }

int _findNearestStep(LatLng userLocation) {
  double minDistance = double.infinity;
  int nearestStepIndex = -2;

  for (int i = 0; i < steps.length; i++) {
    final step = steps[i];
    if (step.routePoints != null && step.routePoints.isNotEmpty) {
      for (LatLng point in step.routePoints) {
        double distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          point.latitude,
          point.longitude,
        );
        if (distance < minDistance) {
          minDistance = distance;
          nearestStepIndex = i;
        }
      }
    }
  }

  return minDistance <= 50.0 ? nearestStepIndex : -2; // 50 meters threshold
}

*/

  bool _isPointNear(LatLng userLocation, LatLng routePoint, double threshold) {
    final double distance = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      routePoint.latitude,
      routePoint.longitude,
    );
    return distance <= threshold; // True if within the threshold distance
  }

//--

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
  //double predefinedTravelTime = 0;
  // Future<void> timeTravel() async {
  //   predefinedTravelTime = await getTravelTimeWithTraffic(
  //       origin: originLocation,
  //       destination: destinationLocation,
  //       waypoints: coords,
  //       mode: 'driving');
  // }

  bool isNavigating = false;
  LatLng destinationLocation = const LatLng(0, 0);
  LatLng originLocation = const LatLng(0, 0);

  //search page
  @override
  void initState() {
    super.initState();
    isNavigating = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isNavigating) {
        _addMarkersAndPolylines();
      }

      // Add polylines, markers, and circles

      /*
      for (int i = 0; i < steps.length; i++) {
        final step = steps[i];
        List<LatLng> polylinePoints = [];
        polylinePoints.addAll(step.routePoints);

        // Create the polyline using the polylinePoints list
        final polyline = Polyline(
          polylineId: PolylineId('route_$i'),
          points:
              polylinePoints, // This now includes sakayanLocation, filtered routePoints, and babaanLocation
          color: Colors.blue,
          width: 5,
        );

        setState(() {
          _polylines.add(polyline);
        });
      }
      */
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

    destinationLocation = LatLng(
      double.parse(widget.latDestination),
      double.parse(widget.longDestination),
    );
    originLocation = LatLng(
      double.parse(widget.latOrigin),
      double.parse(widget.longOrigin),
    );
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

  bool isDisposed = false;
  @override
  void dispose() {
    // _fromController.dispose();
    // _toController.dispose();
    isDisposed = true;
    if (position == true) {
      positionStream.cancel();
    }

    isNavigating = true;
    _isMapCreated = false;
    print('disposed');
    super.dispose();
  }

  //to searchpage.dart
  void _navigateToSearchPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  int currentStepIndex = -7;
  bool _isButtonVisible = true;
  @override
  Widget build(BuildContext context) {
    String timetotal = widget.TimeTotal;
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
            /*
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
           */
            const SizedBox(
              height: 10,
            ),

            Stack(
              children: [
                // Google Map widget
                SizedBox(
                  width: double.infinity,
                  height: 400,
                  child: GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      _isMapCreated = true;
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
                if (!isremaining)
                  Positioned(
                      top: 20, // Adjust the position as needed
                      left: 20,
                      child: Column(
                        children: [
                          // ValueListenableBuilder<double>(
                          //   valueListenable: remainingTimeNotifier,
                          //   builder: (context, timetotal, child) {

                          Container(
                            height: 35,
                            width: 234,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Color(0xFFc2d0ff), // Border color
                                width: 1.0, // Border width
                              ),
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xff1D1617).withOpacity(0.11),
                                  blurRadius: 4,
                                  spreadRadius: 0.2,
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                foregroundColor: Color(0xff1F41BB),
                              ),
                              child: Text(
                                'Travel Time: $timetotal mins',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                          //   },
                          // ),
                          if (isremaining)
                            ValueListenableBuilder<double>(
                              valueListenable: remainingDistanceNotifier,
                              builder: (context, remainingDistance, child) {
                                return Container(
                                  height: 35,
                                  width: 234,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Color(0xFFc2d0ff), // Border color
                                      width: 1.0, // Border width
                                    ),
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xff1D1617)
                                            .withOpacity(0.11),
                                        blurRadius: 4,
                                        spreadRadius: 0.2,
                                      ),
                                    ],
                                  ),
                                  child: TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      foregroundColor: Color(0xff1F41BB),
                                    ),
                                    child: Text(
                                      'Remaining Distance:  ${remainingDistance.toStringAsFixed(2)} km',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      )),
              ],
            ),

            // //next display map and marker - finished design
            // SizedBox(
            //   width: double.infinity,
            //   height: 300,
            //   child: GoogleMap(
            //     onMapCreated: (GoogleMapController controller) {
            //       _mapController = controller;
            //       _isMapCreated = true;
            //       // _setMarkers();
            //     },
            //     initialCameraPosition: CameraPosition(
            //       target: _startLocation,
            //       zoom: 11.5,
            //     ),
            //     markers: _markers,
            //     circles: _circles,
            //     polylines: _polylines,
            //   ),
            // ),

            const SizedBox(
              height: 20,
            ),

            //next Routes , save icon - finished design
            Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Pushes the text to the start and the icons to the end
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
                Row(
                  children: [
                    // Declare a boolean variable to control button visibility

                    SizedBox(
                      height: 29,
                      child: _isButtonVisible
                          ? ElevatedButton(
                              onPressed: () {
                                // Your button click logic
                                if (!isNavigating) {
                                  _trackUserLocation();
                                  print('ano baa?');
                                  setState(() {
                                    _isButtonVisible =
                                        false; // Hide the button after it's clicked
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 255,
                                    255, 255), // Button background color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      30), // Rounded corners
                                ),
                                elevation: 5, // Adds shadow to the button
                                shadowColor:
                                    const Color.fromARGB(255, 243, 100, 100)
                                        .withOpacity(0.5), // Shadow color
                                padding: EdgeInsets
                                    .zero, // Remove padding inside the button
                              ),
                              child: const Text('Start'),
                            )
                          : Container(), // If the button is not visible, display an empty container
                    ),

                    const SizedBox(width: 10),
                    // Container(
                    //   margin: const EdgeInsets.only(left: 30),
                    //   alignment: Alignment.center,
                    //   width: 30,
                    //   height: 30,
                    //   decoration: BoxDecoration(
                    //     color: Colors.white,
                    //     borderRadius: BorderRadius.circular(10),
                    //   ),
                    //   child: SvgPicture.asset(
                    //     'assets/icons/save.svg',
                    //     height: 25, // Define a height for the SVG
                    //     width: 25, // Define a width for the SVG
                    //     color: Colors.red,
                    //   ),
                    // ),
                    // SizedBox(
                    //   width: 25,
                    //   height: 25,
                    //   child: ElevatedButton(
                    //     onPressed: () {
                    //       reportDialog(context);
                    //     },
                    //     // style: ElevatedButton.styleFrom(
                    //     //   backgroundColor: const Color.fromARGB(
                    //     //       255, 255, 255, 255), // Button background color
                    //     //   shape: RoundedRectangleBorder(
                    //     //     borderRadius:
                    //     //         BorderRadius.circular(30), // Rounded corners
                    //     //   ),
                    //     //   elevation: 5, // Adds shadow to the button
                    //     //   shadowColor: const Color.fromARGB(255, 243, 100, 100)
                    //     //       .withOpacity(0.5), // Shadow color
                    //     //   padding: EdgeInsets
                    //     //       .zero, // Remove padding inside the button
                    //     // ),
                    //     child: SvgPicture.asset(
                    //       'assets/icons/save.svg',
                    //       height: 25, // Define a height for the SVG
                    //       width: 25, // Define a width for the SVG
                    //       color: Colors.red,
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(width: 10), // Spacing between the two icons
                    SizedBox(
                      width: 25,
                      height: 29,
                      child: ElevatedButton(
                        onPressed: () {
                          reportDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                              255, 255, 255, 255), // Button background color
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(30), // Rounded corners
                          ),
                          elevation: 5, // Adds shadow to the button
                          shadowColor: const Color.fromARGB(255, 243, 100, 100)
                              .withOpacity(0.5), // Shadow color
                          padding: EdgeInsets
                              .zero, // Remove padding inside the button
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/Alert.svg',
                          height: 30, // Define a height for the SVG
                          width: 25, // Define a width for the SVG
                          color: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
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

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: steps.length, // +1 for the report button
                itemBuilder: (context, index) {
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
                  String route1 = step.routeName[0] ?? 'N/A';
                  String? route2 =
                      (step.routeName.length > 1) ? step.routeName[1] : 'N/A';

                  print(
                      'transportation name: ${step.transportationName}, sakayan: ${step.sakayanLocation}, babaan: ${step.babaanLocation}');

                  // Determine if the current step is being followed
                  bool isCurrentStep = index == currentStepIndex;

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
                  Color bgColor = isCurrentStep
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.white;
                  Color textColor = isCurrentStep
                      ? Colors.white
                      : Colors.black; // White for current step, black otherwise

                  print('isCurrent Step:$isCurrentStep');

                  // Return the proper widget based on the transportation type
                  if (['jeep', 'uv', 'tricycle', 'bus', 'e-jeep']
                      .contains(transpoName.toLowerCase())) {
                    return sampleRide(transpoName, fare, route1, geton, getoff,
                        picride, bgColor, textColor, route2);
                  } else {
                    return walk(instruction, picwalk, bgColor, textColor);
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
  Widget walk(String text, SvgPicture pic, Color bgColor, Color textColor) {
    return Container(
      width: double.infinity, // Make the width match the parent
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: bgColor,
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
            // Row(
            //   mainAxisAlignment:
            //       MainAxisAlignment.end, // Aligns content to the right
            //   children: [
            //     Text(
            //      // time,
            //       style: TextStyle(
            //         color: textColor, // Adjust text color for contrast
            //       ),
            //     ),
            //   ],
            // ),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(
                        0xff1F41BB), // blue background for the icon section
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.directions_walk, // walking person icon
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Expanded(
                  flex: 8, // 80% of the width
                  child: Container(
                    //color: bgColor, // Right side color
                    child: Center(
                      child: Text(
                        'Walk $text',
                        style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight
                                .w500), // Adjust text color for contrast
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
  Widget ride(String transpoName, String fare, String route, String geton,
      String getoff, SvgPicture pic, bgColor, Color textColor, String? route2) {
    return Container(
      width: double.infinity, // Make the width match the parent
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: bgColor,
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
              flex: 1, // 20% of the width
              child: Container(
                child: pic,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 8, // 80% of the width
              child: Column(
                children: [
                  //transpoName, fare, time
                  Row(
                    children: [
                      Text(
                        '$transpoName Route: ',
                        style: TextStyle(color: textColor),
                      ),
                      const Spacer(),
                      Expanded(
                        flex: 6, // 80% of the space
                        child: Text(
                          route,
                          style: TextStyle(color: textColor),
                          textAlign: TextAlign.start, // Align text to the start
                        ),
                      ),
                      Expanded(
                        flex: 6, // 80% of the space
                        child: Text(
                          '⇌',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.start, // Align text to the start
                        ),
                      ),
                      Expanded(
                        flex: 6, // 80% of the space
                        child: Text(
                          '$route2',
                          style: TextStyle(color: textColor),
                          textAlign: TextAlign.start, // Align text to the start
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  // Text(
                  //       fare,
                  //       style: TextStyle(
                  //           color: textColor), // Adjust text color for contrast
                  //     ),
                  //     const Spacer(),
                  //     // Text(
                  //     //   time,
                  //     //   style: TextStyle(
                  //     //       color: textColor), // Adjust text color for contrast
                  //     // ),

                  const SizedBox(
                    height: 15,
                  ),
/*
                  //route
                  Row(
                    children: [
                      Expanded(
                        flex: 4, // 20% of the space
                        child: Container(
                          padding: const EdgeInsets.only(
                              right: 8.0), // Space between the two texts
                          child: Text(
                            "Route",
                            style: TextStyle(color: textColor),
                            textAlign:
                                TextAlign.start, // Align text to the start
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6, // 80% of the space
                        child: Text(
                          route,
                          style: TextStyle(color: textColor),
                          textAlign: TextAlign.start, // Align text to the start
                        ),
                      ),
                    ],
                  ),
*/
                  //get on
                  Row(
                    children: [
                      Expanded(
                        flex: 4, // 20% of the space
                        child: Container(
                          padding: const EdgeInsets.only(
                              right: 8.0), // Space between the two texts
                          child: Text(
                            "pick-up point: ",
                            style: TextStyle(color: textColor),
                            textAlign:
                                TextAlign.start, // Align text to the start
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6, // 80% of the space
                        child: Text(
                          geton,
                          style: TextStyle(color: textColor),
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
                          child: Text(
                            "Drop off point:",
                            style: TextStyle(color: textColor),
                            textAlign:
                                TextAlign.start, // Align text to the start
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6, // 80% of the space
                        child: Text(
                          getoff,
                          style: TextStyle(color: textColor),
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

  Widget sampleRide(
    String transpoName,
    String fare,
    String route,
    String geton,
    String getoff,
    SvgPicture pic,
    bgColor,
    Color textColor,
    String? route2,
  ) {
    return Center(
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon Section
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Color(0xff1F41BB),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                Icons.directions_bus,
                color: Colors.white,
                size: 30,
              ),
            ),
            SizedBox(width: 16.0),

            // Information Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '$transpoName Route',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          route,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '⇌ ',
                        style: TextStyle(fontSize: 15),
                      ),
                      Expanded(
                        child: Text(
                          route2 ?? 'N/A',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Sakayan Point',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    geton,
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Babaan Point',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    getoff,
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sampleWalk(
      String text, SvgPicture pic, Color bgColor, Color textColor) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, // white background
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue, // blue background for the icon section
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.directions_walk, // walking person icon
                color: Colors.white,
              ),
            ),
            SizedBox(width: 10), // Space between the icon and the text
            Text(
              'towards $text',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold, // bold text
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

  void userLocationDialog(BuildContext context) {
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
                      "You're far from the Route!",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  "Do you want to change your origin as your current location?",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // Space out the buttons
                  children: [
                    TextButton(
                      child: const Text("No"),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                    ),
                    TextButton(
                      child: const Text("Yes"),
                      onPressed: () {
                        // Add your submit logic here
                        Navigator.of(context)
                            .pop(); // Close the dialog after submission
                        //database

                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RouteFinder(),
                            ));
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
}

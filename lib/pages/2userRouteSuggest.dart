import 'dart:async';
import 'dart:convert';
import 'dart:math';
//import 'package:geolocator_platform_interface/src/models/position.dart' as geo;
//import 'package:googleapis/datamigration/v1.dart' as gapi;
import 'package:capstone/pages/routeFinder.dart';
import 'package:http/http.dart' as http;

import 'package:capstone/pages/userRouteSuggest_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class userRouteSuggest2 extends StatefulWidget {
  //final List<dynamic> legs;
  final List<StepUser> steps;
  final String origin;
  final String destination;
  final String latOrigin, longOrigin;
  final String latDestination, longDestination;

  const userRouteSuggest2({
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
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<userRouteSuggest2> {
  late GoogleMapController _controller;
  late List<StepUser> steps;
  late LatLng destinationLocation;
  final String apiKey = 'AIzaSyC88-Wkb5_LmPU5OCQwPOMDTry3RGh1J00';

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  bool _isMapCreated = false;

  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(14.831582, 120.903786),
    zoom: 11.5,
  );

  //-------------------------------------------------------------add marker and polyline
  final Set<Marker> _markers = {}; // To hold the markers
  final Set<Circle> _circles = {}; // To hold the circle markers
  final Set<Polyline> _polylines = {};

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
      try {
        // Create a new list for polyline points, starting with sakayanLocation
        List<LatLng> polylinePoints = [step.getOnCoordinates];

        // Filter the route points to include only those between sakayanLocation and babaanLocation
        // filteredRoutePoints = _filterRoutePoints(step.routePoints, step.sakayanLocation, step.babaanLocation);

        // step.routePoints = _filterRoutePoints(
        //   step.routePoints,
        //   step.sakayanLocation,
        //   step.babaanLocation,
        // );
        // final List<LatLng> waypoints = step.polylinePoints
        //     .map((point) => LatLng(point.xCoordinate, point.yCoordinate))
        //     .toList();

        polylinePoints.addAll(step.polylineCoordinates);

        // Add babaanLocation at the end
        polylinePoints.add(step.getOffCoordinates);

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

        for (var point in polylinePoints) {
          if (point.latitude.isNaN || point.longitude.isNaN) {
            print("Invalid point detected: $point");
          }
        }
        // Add start and end markers for this route segment
        final startMarker = Marker(
          markerId: MarkerId('start_$i'),
          position: step.getOnCoordinates,
          infoWindow: InfoWindow(title: 'Start: ${step.transportationName}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );

        final endMarker = Marker(
          markerId: MarkerId('end_$i'),
          position: step.getOffCoordinates,
          infoWindow: InfoWindow(title: 'End: ${step.transportationName}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );

        // Add circles to highlight start and end locations
        final startCircle = Circle(
          circleId: CircleId('circleStart_$i'),
          center: step.getOnCoordinates,
          radius: 50.0,
          fillColor: Colors.blue.withOpacity(0.3),
          strokeColor: Colors.blue,
          strokeWidth: 2,
        );

        final endCircle = Circle(
          circleId: CircleId('circleEnd_$i'),
          center: step.getOffCoordinates,
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

  //------------------------------------------------------start user
  late StreamSubscription<geo.Position> positionStream;

  void _trackUserLocation() {
    if (_isMapCreated) {
      positionStream = geo.Geolocator.getPositionStream(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.bestForNavigation,
        ),
      ).listen((geo.Position position) {
        //if (distanceTraveled >= 5) {
        // Trigger update if user moves more than 20 meters

        // if (position.accuracy <= 10) {
        print('plus api calssssss');
        // Only update if the accuracy is good enough (e.g., within 10 meters)
        //  print('Accuracy is good: ${position.accuracy}');
        _updateUserLocation(LatLng(position.latitude, position.longitude));
        // previousLocation = LatLng(
        //     position.latitude, position.longitude); // Update previous location
        // } else {
        //   print('Accuracy too low: ${position.accuracy}');
        //} // Update previous location
        //  }
      });
    }
  }

  Map<String, List<LatLng>> polylineCache = {};
  bool isDisposed = false;
  bool _isMarkerDone = false;
  bool isnewPoint = false;
  late List<LatLng> newPoints = [];
  bool _isRemoveStepDone = false;
  bool _isWalkingStepAdded = false;
  int currentStepIndex = -7;

  Future<void> _updateUserLocation(LatLng userLocation) async {
    if (isDisposed) return;

    int nearestStepIndex = _findNearestStep(
        userLocation); //await findNearestStepOnRoad(userLocation);
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

      // int nearestStepIndex = _findNearestStep(userLocation);

      print(
          'haaaaaaaaaaaaa tama ba yung nearest step? $nearestStepIndex --- Location: $userLocation');
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

        if (step.polylineCoordinates.isNotEmpty) {
          for (int i = 0; i < step.polylineCoordinates.length; i++) {
            final routePoint = step.polylineCoordinates[i];
            double distance = geo.Geolocator.distanceBetween(
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
                    i < step.polylineCoordinates.length;
                    i++) {
                  updatedPolylinePoints.add(step.polylineCoordinates[i]);
                }
              }

              // Add points from subsequent steps
              for (int i = nearestStepIndex + 1; i < steps.length; i++) {
                final nextStep = steps[i];
                //ignore newly added step
                if (nextStep.id == -3) {
                  continue;
                }
                if (nextStep.polylineCoordinates.isNotEmpty) {
                  updatedPolylinePoints.addAll(nextStep.polylineCoordinates);
                }
              }

              // if (isnewPoint == false) {
              //   newPoints.addAll(updatedPolylinePoints);
              //   double predefinedTravelTime = await getTravelTimeWithTraffic(
              //       origin: userLocation,
              //       destination: destinationLocation,
              //       waypoints: updatedPolylinePoints,
              //       mode: 'driving');

              //   trackRemainingTimeWithWaypoints(updatedPolylinePoints,
              //       destinationLocation, predefinedTravelTime);
              //   print('are you running?222');
              //   if (isDisposed) return;
              //   setState(() {
              //     isremaining = true;
              //   });

              //   isnewPoint = true;
              // }

              if (!_isRemoveStepDone) {
                // Add points from subsequent steps
                List<int> excludedSteps = _getExcludedSteps(nearestStepIndex);
                print('tama ba yung nearest step? $nearestStepIndex');

                String excludedStepsStr = excludedSteps.map((index) {
                  if (index >= 0 && index < steps.length) {
                    // String franchiseId = steps[index].routeName ??
                    //     'Unknown'; // Replace with actual field name
                    // return '${index + 1} -> $franchiseId';
                  }
                  return '';
                }).join(' -> ');

                removeExcludedSteps(nearestStepIndex);

                // Print the excluded steps in the console
                print('Excluded Steps: $excludedStepsStr');
                _isRemoveStepDone = true;
              }

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
                  if (geo.Geolocator.distanceBetween(
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
              if (steps.isNotEmpty && steps[0].id == -3) {
                // If the user is within range of the walking step, treat it as the current step
                setState(() {
                  currentStepIndex = 0;
                });
              } else {
                // Otherwise, find the nearest step (existing logic)
                //int nearestStepIndex = _findNearestStep(userLocation);
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
        _controller.animateCamera(CameraUpdate.newLatLng(userLocation));
      }
    });
  }

  //--------------------------------------------------------------
  int _findNearestStep(LatLng userLocation) {
    double minDistance = double.infinity;
    int nearestStepIndex = -2;
    LatLng pointFinal = LatLng(0, 0);

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];

      // Skip the step with FranchiseID -3 (the newly created walking step)
      if (step.id == -3) {
        continue; // Skip this step
      }

      if (step.polylineCoordinates.isNotEmpty) {
        for (LatLng point in step.polylineCoordinates) {
          double distance = geo.Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            point.latitude,
            point.longitude,
          );
          if (distance < minDistance) {
            minDistance = distance;
            pointFinal = point;

            double pointTobaban =
                calculateDistances(pointFinal, step.getOffCoordinates);
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

  //--------------------------------------------------------------

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

  void addWalkingStepAtBeginning(
      LatLng userLocation, LatLng? babaanLocation, String sakayanPlaceName) {
    if (isDisposed) return;
    // Create a new walking step

    final walkingStep = StepUser(
        id: -3,
        sequence: 0,
        transportationId: 6,
        transportationName: 'walking',
        getOnCoordinates: userLocation,
        getOffCoordinates: babaanLocation ?? LatLng(0.0, 0.0),
        travelTime: 0,
        fare: 0,
        instructions: 'Walk to the next point',
        polylinePoints: [
          PolylinePointUser(
              xCoordinate: userLocation.latitude,
              yCoordinate: userLocation.longitude,
              sequence: 1),
          PolylinePointUser(
              xCoordinate: babaanLocation!.latitude,
              yCoordinate: babaanLocation!.longitude,
              sequence: 2),
        ],
        polylineCoordinates: [
          userLocation,
          babaanLocation
        ]);
    if (isDisposed) return;
    // Prepend the walking step to the steps list
    setState(() {
      steps.insert(0, walkingStep);
    });
  }

  //----------------------------------------------------------------

  @override
  void dispose() {
    positionStream?.cancel();
    isDisposed = true;
    super.dispose();
  }

  bool isNavigating = false;

  @override
  void initState() {
    super.initState();

    steps = widget.steps;

    print("Steps Length: ${steps.length}");

    _fromController.text = widget.origin;
    _toController.text = widget.destination;

    destinationLocation = LatLng(
      double.parse(widget.latOrigin),
      double.parse(widget.longDestination),
    );
    isNavigating = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isNavigating) {
        _addMarkersAndPolylines();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    // onTap:
                    //     _navigateToSearchPage, // Navigate when tapped| search
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
                    // onTap:
                    //     _navigateToSearchPage, // Navigate when tapped | search
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
            SizedBox(
              height: 300,
              width: double.infinity,
              child: GoogleMap(
                initialCameraPosition: _initialCameraPosition,
                onMapCreated: (GoogleMapController controller) {
                  _controller = controller;
                  _isMapCreated = true;
                },
                markers: _markers,
                circles: _circles,
                polylines: _polylines,
              ),
            ),
            Expanded(
              // Ensure remaining height is bounded
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, -3.5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          alignment: Alignment.topLeft,
                          padding: const EdgeInsets.only(
                              left: 30, top: 30, bottom: 30),
                          child: const Text(
                            'Routes',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Row(
                          children: [
                            SizedBox(
                              // width: 25,
                              height: 29,

                              child: ElevatedButton(
                                onPressed: () {
                                  // reportDialog(context);
                                  // setState(() {
                                  if (!isNavigating) {
                                    _trackUserLocation();
                                    print('ano baa?');
                                  }

                                  //  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255,
                                      255, 255, 255), // Button background color
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
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              margin: const EdgeInsets.only(left: 30),
                              alignment: Alignment.center,
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SvgPicture.asset(
                                'assets/icons/save.svg',
                                height: 25, // Define a height for the SVG
                                width: 25, // Define a width for the SVG
                                color: Colors.red,
                              ),
                            ),
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
                            const SizedBox(
                                width: 10), // Spacing between the two icons
                            SizedBox(
                              width: 25,
                              height: 29,
                              child: ElevatedButton(
                                onPressed: () {
                                  reportDialog(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255,
                                      255, 255, 255), // Button background color
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

                    // Container(
                    //   padding: const EdgeInsets.only(bottom: 10),
                    //   child: const Text(
                    //     'SM Marilao -> Bocaue -> Malolos',
                    //     style: TextStyle(
                    //         fontSize: 14, fontWeight: FontWeight.w500),
                    //   ),
                    // ),
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
                          String transpoName =
                              step.transportationName ?? 'Unknown';
                          String time =
                              '${step.travelTime.toString()} min' ?? 'N/A';
                          //  String geton = step.instructions.toString() ?? 'N/A';
                          String instruction = step.instructions ?? 'N/A';
                          String fare = '₱${step.fare.toString()}' ?? 'N/A';
                          // String getoff =
                          //     step.babaanPlaceName.toString() ?? 'N/A';
                          // String route = step.routeName ?? 'N/A';

                          print(
                              'transportation name: ${step.transportationName}');

                          // Determine if the current step is being followed
                          //bool isCurrentStep = index == currentStepIndex;
                          bool isCurrentStep = true;

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
                              : Colors
                                  .black; // White for current step, black otherwise

                          print('isCurrent Step:$isCurrentStep');

                          // Return the proper widget based on the transportation type
                          if (['jeep', 'uv', 'tricycle', 'bus', 'e-jeep']
                              .contains(transpoName.toLowerCase())) {
                            return ride(transpoName, fare, time, instruction,
                                picride, bgColor, textColor);
                          } else {
                            return walk(
                                instruction, picwalk, time, bgColor, textColor);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget walk(String text, SvgPicture pic, String time, Color bgColor,
      Color textColor) {
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
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end, // Aligns content to the right
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: textColor, // Adjust text color for contrast
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
                    //color: bgColor, // Right side color
                    child: Center(
                      child: Text(
                        text,
                        style: TextStyle(
                            color: textColor), // Adjust text color for contrast
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
  Widget ride(String transpoName, String fare, String time, String instruction,
      SvgPicture pic, bgColor, Color textColor) {
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
                        style: TextStyle(color: textColor),
                      ),
                      const Spacer(),
                      Text(
                        fare,
                        style: TextStyle(
                            color: textColor), // Adjust text color for contrast
                      ),
                      const Spacer(),
                      Text(
                        time,
                        style: TextStyle(
                            color: textColor), // Adjust text color for contrast
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
                          child: Text(
                            "Instruction",
                            style: TextStyle(color: textColor),
                            textAlign:
                                TextAlign.start, // Align text to the start
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6, // 80% of the space
                        child: Text(
                          instruction,
                          style: TextStyle(color: textColor),
                          textAlign: TextAlign.start, // Align text to the start
                        ),
                      ),
                    ],
                  ),
/*
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
                      // Expanded(
                      //   flex: 6, // 80% of the space
                      //   child: Text(
                      //     geton,
                      //     style: TextStyle(color: textColor),
                      //     textAlign: TextAlign.start, // Align text to the start
                      //   ),
                      // ),
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
                      // Expanded(
                      //   flex: 6, // 80% of the space
                      //   child: Text(
                      //     getoff,
                      //     style: TextStyle(color: textColor),
                      //     textAlign: TextAlign.start, // Align text to the start
                      //   ),
                      // ),
                    ],
                  ),
                */
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

  TextEditingController reportController = TextEditingController();
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

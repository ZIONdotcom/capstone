import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; // Add geocoding package
import 'package:capstone/pages/travelPlan3.dart';
import 'package:capstone/pages/test.dart';
import 'package:capstone/pages/routeFinderAlgo.dart';
import 'package:capstone/pages/userroutesuggest.dart';
import 'package:google_maps_webservice/places.dart' as google_places;
import 'package:google_maps_webservice/places.dart';
import 'package:google_maps_webservice/places.dart'
    as gms; // Add alias 'gms' for Google Maps Webservice
import 'package:geocoding/geocoding.dart'; // Geocoding package without alias

class Travelplanmap extends StatefulWidget {
  final String latOrigin;
  final String longOrigin;
  final String latDestination;
  final String longDestination;
  final String originName;
  final String destinationName;

  const Travelplanmap({
    super.key,
    required this.latOrigin,
    required this.longOrigin,
    required this.latDestination,
    required this.longDestination,
    required this.destinationName,
    required this.originName,
  });

  @override
  State<Travelplanmap> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Travelplanmap> {
  final apiKey = 'AIzaSyC88-Wkb5_LmPU5OCQwPOMDTry3RGh1J00';
  Set<Marker> markers = {};
  GoogleMapController? _controller;
  bool isEditingOrigin = false;
  bool isEditingDestination = false;

  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(14.831582, 120.903786),
    zoom: 11.5,
  );
  late LatLng updatedOrigin;
  late LatLng updatedDestination;
  String updatedOriginName = '';
  String updatedDestinationName = '';

  @override
  void initState() {
    super.initState();
    updatedOrigin = LatLng(
      double.parse(widget.latOrigin),
      double.parse(widget.longOrigin),
    );
    updatedDestination = LatLng(
      double.parse(widget.latDestination),
      double.parse(widget.longDestination),
    );
    _addMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Check Origin and Destination',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color.fromARGB(255, 3, 36, 63),
            //letterSpacing: 1.5,
          ),
          softWrap: true,
        ), // This is where the title is set
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
            markers: markers,
            onTap: (LatLng position) {
              if (isEditingOrigin) {
                _updateMarkerPosition(position, 'origin');
              } else if (isEditingDestination) {
                _updateMarkerPosition(position, 'destination');
              }
            },
          ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            right: 16.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row widget to align buttons to the right
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end, // Align buttons to the right
                  children: [
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isEditingOrigin = true;
                              isEditingDestination = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor:
                                const Color.fromARGB(255, 0, 28, 127),
                            backgroundColor:
                                const Color.fromARGB(221, 107, 139, 255),
                            minimumSize:
                                const Size(150, 40), // Set smaller width
                          ),
                          child: const Text('Edit Origin'),
                        ),
                        SizedBox(width: 8.0), // Space between the buttons
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isEditingDestination = true;
                              isEditingOrigin = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor:
                                const Color.fromARGB(255, 0, 28, 127),
                            backgroundColor:
                                const Color.fromARGB(221, 107, 139, 255),
                            minimumSize:
                                const Size(150, 40), // Set smaller width
                          ),
                          child: const Text('Edit Destination'),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8.0),
                ElevatedButton(
                  onPressed: () async {
                    if (isEditingDestination && isEditingOrigin) {
                      // Get the names for origin and destination
                      updatedOriginName = await _getPlaceName(
                        double.parse(widget.latOrigin),
                        double.parse(widget.longOrigin),
                      );
                      updatedDestinationName = await _getPlaceName(
                        double.parse(widget.latDestination),
                        double.parse(widget.longDestination),
                      );
                    } else if (isEditingDestination && !isEditingOrigin) {
                      updatedDestinationName = await _getPlaceName(
                        double.parse(widget.latDestination),
                        double.parse(widget.longDestination),
                      );
                      updatedOriginName = widget.originName;
                    } else if (!isEditingDestination && isEditingOrigin) {
                      updatedOriginName = await _getPlaceName(
                        double.parse(widget.latOrigin),
                        double.parse(widget.longOrigin),
                      );
                      updatedDestinationName = widget.destinationName;
                    } else {
                      updatedOriginName = widget.originName;
                      updatedDestinationName = widget.destinationName;
                    }

                    // Show the report dialog
                    reportDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xff1F41BB),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addMarkers() {
    markers.add(
      Marker(
        markerId: MarkerId('origin'),
        position: updatedOrigin,
        draggable: true,
        onDragEnd: (LatLng newPosition) {
          _updateMarkerPosition(newPosition, 'origin');
        },
      ),
    );
    markers.add(
      Marker(
        markerId: MarkerId('destination'),
        position: updatedDestination,
        draggable: true,
        onDragEnd: (LatLng newPosition) {
          _updateMarkerPosition(newPosition, 'destination');
        },
      ),
    );
  }

  // Method to update the position of the markers
  void _updateMarkerPosition(LatLng newPosition, String markerType) async {
    setState(() {
      if (markerType == 'origin') {
        updatedOrigin = newPosition;
        markers.removeWhere((marker) => marker.markerId == MarkerId('origin'));
        markers.add(
          Marker(
            markerId: MarkerId('origin'),
            position: updatedOrigin,
            draggable: true,
          ),
        );
      } else if (markerType == 'destination') {
        updatedDestination = newPosition;
        markers.removeWhere(
            (marker) => marker.markerId == MarkerId('destination'));
        markers.add(
          Marker(
            markerId: MarkerId('destination'),
            position: updatedDestination,
            draggable: true,
          ),
        );
      }
    });

    // After the position is updated, get place names
    updatedOriginName =
        await _getPlaceName(updatedOrigin.latitude, updatedOrigin.longitude);
    updatedDestinationName = await _getPlaceName(
        updatedDestination.latitude, updatedDestination.longitude);
  }

  // Fetch place name for given coordinates
  Future<String> _getPlaceName(double latitude, double longitude) async {
    try {
      // Fetching placemarks based on the coordinates
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        // Constructing the full address by combining multiple fields
        String fullAddress = '';
        fullAddress +=
            placemarks[0].name ?? ''; // Name of the place (SM City Marilao)
        fullAddress += placemarks[0].thoroughfare != null
            ? ', ${placemarks[0].thoroughfare}'
            : ''; // Street address
        fullAddress += placemarks[0].locality != null
            ? ', ${placemarks[0].locality}'
            : ''; // Locality (Marilao)
        fullAddress += placemarks[0].administrativeArea != null
            ? ', ${placemarks[0].administrativeArea}'
            : ''; // State or province (Bulacan)
        fullAddress += placemarks[0].country != null
            ? ', ${placemarks[0].country}'
            : ''; // Country (Philippines)

        return fullAddress; // Return the complete address
      }
    } catch (e) {
      print("Error getting place name: $e");
    }
    return "Unknown location"; // Return a default message if an error occurs
  }

  void reportDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 8),
                    Text(
                      "Choose a route Suggesting option:",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Column(
                  children: [
                    TextButton(
                      child: const Text("Google Transit"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Test(
                              latOrigin: updatedOrigin.latitude.toString(),
                              longOrigin: updatedOrigin.longitude.toString(),
                              latDestination:
                                  updatedDestination.latitude.toString(),
                              longDestination:
                                  updatedDestination.longitude.toString(),
                              destinationName: updatedDestinationName,
                              originName: updatedOriginName,
                            ),
                          ),
                        );
                      },
                    ),
                    TextButton(
                      child: const Text("Application Suggestion"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RouteFinderAlgo(
                              latOrigin: updatedOrigin.latitude.toString(),
                              longOrigin: updatedOrigin.longitude.toString(),
                              latDestination:
                                  updatedDestination.latitude.toString(),
                              longDestination:
                                  updatedDestination.longitude.toString(),
                              destinationName: updatedDestinationName,
                              originName: updatedOriginName,
                            ),
                          ),
                        );
                      },
                    ),
                    TextButton(
                      child: const Text("User Route Suggest"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Userroutesuggest(
                              latOrigin: updatedOrigin.latitude.toString(),
                              longOrigin: updatedOrigin.longitude.toString(),
                              latDestination:
                                  updatedDestination.latitude.toString(),
                              longDestination:
                                  updatedDestination.longitude.toString(),
                              destinationName: updatedDestinationName,
                              originName: updatedOriginName,
                            ),
                          ),
                        );
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

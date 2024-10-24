import 'package:capstone/pages/routeFinder2.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:uuid/uuid.dart';

class test extends StatefulWidget {
  const test({super.key});

  @override
  _RouteFinderState createState() => _RouteFinderState();
}

class _RouteFinderState extends State<test> {
  //navigate to 2nd screen and pass
  var uuid = const Uuid();

  TextEditingController fromController = TextEditingController();
  TextEditingController toController = TextEditingController();
  bool isSwapped = false;

  FocusNode fromFocusNode = FocusNode();
  FocusNode toFocusNode = FocusNode();
  List<String> locationSuggestions = [];
  final apiKey = 'AIzaSyAnDp1NMv3WSsatCAjJL02Y_fL8a44L4NI';
  late String lat, long;
  late String lat_origin, long_origin, lat_destination, long_destination;

  void fetchRouteAndNavigate() {
    if (lat_origin.isNotEmpty &&
        long_origin.isNotEmpty &&
        lat_destination.isNotEmpty &&
        long_destination.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => RouteFinder2(
                  latOrigin: lat_origin,
                  longOrigin: long_origin,
                  latDestination: lat_destination,
                  longDestination: long_destination,
                  destinationName: fromController.text,
                  originName: toController.text,
                )),
      );

      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => RouteStepsPrinter(
      //         latOrigin: lat_origin,
      //         longOrigin: long_origin,
      //         latDestination: lat_destination,
      //         longDestination: long_destination,
      //         destinationName: fromController.text,
      //         originName: toController.text),
      //   ),
      // );
    }
  }

  //end

  void swapFields() {
    setState(() {
      String tempText = fromController.text;
      fromController.text = toController.text;
      toController.text = tempText;
      isSwapped = !isSwapped;
    });
  }

  @override
  void initState() {
    super.initState();

    fromFocusNode.addListener(() {
      setState(() {});
    });
    toFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    fromFocusNode.dispose();
    toFocusNode.dispose();
    super.dispose();
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location service disabled');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location Permissions are denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> fetchSuggestions(String text) async {
    if (text.isEmpty) {
      setState(() {
        locationSuggestions = [];
      });
      return;
    }
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$text&key=$apiKey&components=country:ph';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> predictions =
          json.decode(response.body)['predictions'];
      setState(() {
        locationSuggestions =
            predictions.map((p) => p['description'] as String).toList();
      });
    } else {
      setState(() {
        locationSuggestions = ['Failed to fetch suggestions'];
      });
    }
  }

  Future<void> fetchLatLong(String placeDescription) async {
    // URL-encode the placeDescription to handle special characters
    final encodedDescription = Uri.encodeComponent(placeDescription);
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedDescription&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        //print("Request URL: $url");
        //print("API Response: $jsonResponse");

        final List<dynamic> results = jsonResponse['results'];
        if (results.isNotEmpty) {
          final location = results[0]['geometry']['location'];
          setState(() {
            lat = location['lat'].toString();
            long = location['lng'].toString();

            if (toFocusNode.hasFocus) {
              lat_destination = lat;
              long_destination = long;
            } else if (fromFocusNode.hasFocus) {
              lat_origin = lat;
              long_origin = long;
            }
            //navigate to 2nd screen christine
            if (lat_origin.isNotEmpty &&
                long_origin.isNotEmpty &&
                lat_destination.isNotEmpty &&
                long_destination.isNotEmpty) {
              fetchRouteAndNavigate();
            }
          });
          print("Lat: $lat, Long: $long");
        } else {
          print("No results found for the given place description.");
        }
      } else {
        print(
            "Failed to fetch latitude and longitude. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error fetching latitude and longitude: $e");
    }
  }

  Future<void> fetchPlaceDetails(String placeId) async {
    final String placeDetailsUrl =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

    try {
      // Fetch place details
      final response = await http.get(Uri.parse(placeDetailsUrl));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final Map<String, dynamic> location =
            jsonResponse['result']['geometry']['location'];

        setState(() {
          lat = location['lat'].toString();
          long = location['lng'].toString();

          if (toFocusNode.hasFocus) {
            lat_destination = lat;
            long_destination = long;
          } else if (fromFocusNode.hasFocus) {
            lat_origin = lat;
            long_origin = long;
          }

          print("Lat: $lat, Long: $long");

          if (lat_origin.isNotEmpty &&
              long_origin.isNotEmpty &&
              lat_destination.isNotEmpty &&
              long_destination.isNotEmpty) {
            fetchRouteAndNavigate();
          }
        });
      } else {
        print(
            "Failed to fetch place details. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching place details: $e");
    }
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
                          buildTextField('To...', fromController, toFocusNode)
                        else
                          buildTextField(
                              'From..', fromController, fromFocusNode),
                        const SizedBox(height: 8),
                        if (isSwapped)
                          buildTextField('From..', toController, fromFocusNode)
                        else
                          buildTextField('To...', toController, toFocusNode),
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
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                _getCurrentLocation().then((value) {
                  lat = '${value.latitude}';
                  long = '${value.longitude}';
                  String locationText = "Your Location";
                  setState(() {
                    if (fromFocusNode.hasFocus) {
                      fromController.text = locationText;
                      lat_origin = lat;
                      long_origin = long;
                    } else if (toFocusNode.hasFocus) {
                      toController.text = locationText;
                      lat_destination = lat;
                      long_destination = long;
                    }
                  });
                  print("Lat: $lat, Long: $long");
                });
              },
              child: Container(
                padding: const EdgeInsets.only(
                    top: 14, bottom: 14, left: 10, right: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.my_location, size: 24, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Your location',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () {
                //dito yung map
              },
              child: Container(
                padding: const EdgeInsets.only(
                    top: 14, bottom: 14, left: 10, right: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.pin_drop, size: 24, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Pin locaction on the map',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(0),
                itemCount: locationSuggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(locationSuggestions[index]),
                    onTap: () {
                      String selectedLocation = locationSuggestions[index];
                      if (fromFocusNode.hasFocus) {
                        fromController.text = selectedLocation;
                      } else if (toFocusNode.hasFocus) {
                        toController.text = selectedLocation;
                      }
                      setState(() {
                        locationSuggestions.clear();
                      });
                      fetchLatLong(selectedLocation);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(
      String hintText, TextEditingController controller, FocusNode focusNode) {
    return Column(
      children: [
        Container(
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
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide.none,
              ),
              suffixIcon: focusNode.hasFocus && controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          controller.clear();
                          locationSuggestions.clear();
                        });
                      })
                  : null,
            ),
            onChanged: (text) {
              fetchSuggestions(text);
            },
          ),
        ),
      ],
    );
  }
}

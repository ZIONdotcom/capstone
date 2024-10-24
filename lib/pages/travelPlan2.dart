import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class travelPlan2 extends StatefulWidget {
  const travelPlan2({super.key});

  @override
  State<travelPlan2> createState() => _TravelPlan2State();
}

class _TravelPlan2State extends State<travelPlan2> {
  final apiKey = 'AIzaSyBcUDWZDnJBOX_Q5IOqDJi60RuqJy1-ZkY';

  late String lat, long;
  TextEditingController controller = TextEditingController();

  List<String> locationSuggestions = [];

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
    final encodedDescription = Uri.encodeComponent(placeDescription);
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedDescription&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> results = jsonResponse['results'];
        if (results.isNotEmpty) {
          final location = results[0]['geometry']['location'];
          String lat = location['lat'].toString();
          String long = location['lng'].toString();

          // Return to the previous screen with the selected location data
          Navigator.pop(context, {
            'location': placeDescription,
            'latitude': lat,
            'longitude': long,
          });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding:
            const EdgeInsets.only(top: 40.0, left: 10, right: 10, bottom: 10),
        child: Column(
          children: [
            Container(
              alignment: Alignment.topLeft,
              margin: const EdgeInsets.only(top: 20, bottom: 10, left: 20),
              child: const Text(
                'Search destination',
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                onChanged:
                    fetchSuggestions, // Fetch suggestions as the user types
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  hintText: 'type here',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: locationSuggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(locationSuggestions[index]),
                    onTap: () {
                      String selectedLocation = locationSuggestions[index];
                      controller.text = selectedLocation;
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
}

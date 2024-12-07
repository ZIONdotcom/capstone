import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  final String apiKey = 'AIzaSyC88-Wkb5_LmPU5OCQwPOMDTry3RGh1J00';
  final FocusNode  focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.requestFocus(); 
  }


  Future<void> _getSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String requestUrl =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&components=country:ph&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(requestUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _suggestions = data['predictions'].map<Map<String, dynamic>>((prediction) {
              return {
                'description': prediction['description'],
                'placeId': prediction['place_id'],
              };
            }).toList();
          });
        } else {
          setState(() {
            _suggestions = [];
          });
        }
      }
    } catch (e) {
      print("Error fetching suggestions: $e");
      setState(() {
        _suggestions = [];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<LatLng?> _getCoordinatesFromPlaceId(String placeId) async {
    final String detailsUrl =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(detailsUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      print("Error fetching coordinates: $e");
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 40.0, left: 10, right: 10, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20.0, top: 10),
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
              child: TextFormField(
                focusNode: focusNode,
                controller: _controller,
                onChanged: (value) {
                  _getSuggestions(value);
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  hintText: 'Type here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (_isLoading) const Center(child: CircularProgressIndicator()), // Loading indicator
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_suggestions[index]['description']),
                    onTap: () async {
                      LatLng? selectedLocation = await _getCoordinatesFromPlaceId(_suggestions[index]['placeId']);
                      if (selectedLocation != null) {
                        Navigator.pop(context, {
                          'latLng': selectedLocation,
                          'name': _suggestions[index]['description'],
                        });
                      }
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

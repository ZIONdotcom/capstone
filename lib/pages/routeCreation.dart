import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class Routecreation extends StatefulWidget {
  const Routecreation({super.key});

  @override
  State<Routecreation> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Routecreation> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(14.831582, 120.903786), // Set the initial position of the map
    zoom: 11.5, // Set the zoom level
  );

  bool walkClicked = false;
  bool doneClicked = false;
  bool rideClicked = false;
  bool _mapClicked = false;
  String? selectedMode;

  List<String> modes = ['Jeep', 'Tricycle', 'Bus', 'Walk'];
  List<Widget> walkWidgets = [];
  List<Widget> rideWidgets = [];
  List<Widget> doneWidgets =[];

  GoogleMapController? _controller;
  Marker? _selectedMarker;
  String _locationName = "";
  TextEditingController _locationController = TextEditingController();
  TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
     _addressController.dispose();
    super.dispose();
  }
  
  String _address = '';
  String _establishmentName = '';


Future<void> _onMapTap(LatLng position) async {
  List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
  
  if (placemarks.isNotEmpty) {
    Placemark placemark = placemarks[0];
    String name = placemark.name ?? "";
    String address = "${placemark.street ?? ""}, ${placemark.locality ?? ""}, ${placemark.administrativeArea ?? ""}, ${placemark.country ?? ""}";

    setState(() {
      _selectedMarker = Marker(
        markerId: MarkerId('selected-location'),
        position: position,
        infoWindow: InfoWindow(title: name),
      );
      _mapClicked = true;
      _locationController.text = name;
      _addressController.text = address;
      _address = address;

      // Fetch establishment name
      _fetchPlaceDetails(position);
    });
  }
}

Future<void> _fetchPlaceDetails(LatLng position) async {
  const apiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
  final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${position.latitude},${position.longitude}&radius=500'
      '&keyword=church|coffee shop|mall|establishment'
      '&key=$apiKey';

  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final results = data['results'] as List<dynamic>;
    if (results.isNotEmpty) {
      final establishment = results[0];
      final name = establishment['name'];
      setState(() {
        _establishmentName = name;
      });
    } else {
      setState(() {
        _establishmentName = 'No nearby establishment found';
      });
    }
  } else {
    throw Exception('Failed to load place details');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: Padding(
        padding: const EdgeInsets.only(left: 10, right: 0, top: 10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
             
              Row(
                children: [
                  Container(
                    margin: EdgeInsets.all(5),
                    alignment: Alignment.center,
                    child: SvgPicture.asset('assets/icons/from.svg'),
                    height: 48.89,
                    width: 48.89,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: 30.0),
                      height: 37,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xff1D1617).withOpacity(0.11),
                            blurRadius: 4,
                            spreadRadius: 0.0,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          hintText: 'From...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

             if(_mapClicked)
             Column(
              children: [
                  Container(
                    padding: EdgeInsets.only(left: 20.0),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _address,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.only(left: 20.0),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'establishment name',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

              ],
             ),
          
              SizedBox(height: 10),

              Divider(
                thickness: 2.0,
                color: Colors.grey,
              ),

              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.only(left: 20.0),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pin a starting point',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 20),

              buildMap(),
              
              SizedBox(height: 20),

              if (_mapClicked)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.only(left: 20.0),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'What is this location called?',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                      SizedBox(height: 10),
                    Container(
                      margin: EdgeInsets.only(right: 20.0, left: 20.0),
                      height: 37,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xff1D1617).withOpacity(0.11),
                            blurRadius: 4,
                            spreadRadius: 0.0,
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          hintText: 'Type here...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.only(left: 20.0),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'What is the next step?',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: 20, right: 5, top: 10, bottom: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                // walkWidgets.add(buildWalk());
                                rideClicked = false; 
                                walkClicked = true;
                               
                              });
                             
                            },
                            child: Text('Walk'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Color(0xff1F41BB),
                              minimumSize: Size(131, 26),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 5, right: 5, top: 10, bottom: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                walkClicked = false;
                                // rideWidgets.add(buildWalk());
                                rideClicked = true;
                              });
                            },
                            child: Text('Ride'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Color(0xff1F41BB),
                              minimumSize: Size(131, 26),
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  ],
                ),
            
              if (rideClicked) buildRide(),
              if (walkClicked) buildWalk(),
                ...walkWidgets, 
              ...rideWidgets,
              ...doneWidgets,
 
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  AppBar appBar() {
    return AppBar(
      title: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 10),
        child: const Text(
          'Create and suggest route',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0.0,
    );
  }

   Widget buildMap() {
    return SizedBox(
      height: 400,
      child: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        onMapCreated: (controller) => _controller = controller,
        markers: _selectedMarker != null ? {_selectedMarker!} : {},
        onTap: _onMapTap,
      ),
    );
  }

    Widget buildRide(){
      return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  
                Container(
                  padding: EdgeInsets.only(left: 20.0),
                  child: Text(
                    'Choose Transportation Mode',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  width: 363,
                  height: 64,
                  margin: EdgeInsets.only(right: 20.0, left: 20.0),
                  
                  child: DropdownButton<String>(
                    value: selectedMode,
                    hint: Text('Select Mode'),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedMode = newValue;
                      });
                    },
                    items: modes.map((String mode) {
                      return DropdownMenuItem<String>(
                        value: mode,
                        child: Text(mode),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.only(left: 20.0),
                  child: Text(
                    'Estimated Fare:',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 10),

                Container(
            margin: EdgeInsets.only(right: 20.0, left: 20.0),
            height: 37,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Color(0xff1D1617).withOpacity(0.11),
                  blurRadius: 4,
                  spreadRadius: 0.0,
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                hintText: 'Type here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.only(left: 20.0),
                  child: Text(
                    'Route',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row (
                children: [
                  Container(
                    margin: EdgeInsets.all(10),
                    height: 33,
                    width: 149,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xff1D1617).withOpacity(0.11),
                          blurRadius: 4,
                          spreadRadius: 0.0,
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        hintText: 'Type here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Container(
                  margin: EdgeInsets.all(5),
                  alignment: Alignment.center,
                  child: SvgPicture.asset('assets/icons/arrow.svg'),
                  height: 48.89,
                  width: 48.89,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                  Container(
                    margin: EdgeInsets.all(10),
                    height: 33,
                    width: 149,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xff1D1617).withOpacity(0.11),
                          blurRadius: 4,
                          spreadRadius: 0.0,
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        hintText: 'Type here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                
                ],
                ),
                SizedBox(height: 10),

                Container(
                  padding: EdgeInsets.only(left: 20.0),
                  child: Text(
                    'Where to stop:',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                SizedBox(height: 10),
                Container(
            margin: EdgeInsets.only(right: 20.0, left: 20.0),
            height: 37,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Color(0xff1D1617).withOpacity(0.11),
                  blurRadius: 4,
                  spreadRadius: 0.0,
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                hintText: 'Type here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

                SizedBox(height: 10),

                Container(
                  padding: EdgeInsets.only(left: 20.0),
                  child: Text(
                    'What is the next step?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            
                Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: 20, top: 10, bottom: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                              
                               walkWidgets.add(buildWalk());
                              });
                            },
                            child: Text('Walk'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Color(0xff1F41BB),
                              minimumSize: Size(120, 26),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 5, top: 10, bottom: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                
                                rideWidgets.add(buildRide());
                              });
                            },
                            child: Text('Ride'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Color(0xff1F41BB),
                              minimumSize: Size(120, 26),
                            ),
                          ),
                        ),

                        Container(
                          margin: EdgeInsets.only(left: 5, top: 10, bottom: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                              doneWidgets.add(buildDone());
                              });
                            },
                            child: Text('Done'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Color(0xff1F41BB),
                              minimumSize: Size(120, 26),
                            ),
                          ),
                        ),
                      ],
                    ),
              
            ],
          );              
    }

    Widget buildWalk(){
      return Column(
        children: [
          Container(
            padding: EdgeInsets.only(left: 20.0),
            alignment: Alignment.centerLeft,
            child: Text(
              'Walk to:',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
            SizedBox(height: 10),
                Container(
            margin: EdgeInsets.only(right: 20.0, left: 20.0),
            height: 37,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Color(0xff1D1617).withOpacity(0.11),
                  blurRadius: 4,
                  spreadRadius: 0.0,
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                hintText: 'Type here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.only(left: 20.0),
            alignment: Alignment.centerLeft,
            child: Text(
              'What is the next step?',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
                    
            Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(left: 20, top: 10, bottom: 10),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      
                      walkWidgets.add(buildWalk());
                    });
                  },
                  child: Text('Walk'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xff1F41BB),
                    minimumSize: Size(120, 26),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 5, top: 10, bottom: 10),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      rideWidgets.add(buildRide());
                    });
                  },
                  child: Text('Ride'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xff1F41BB),
                    minimumSize: Size(120, 26),
                  ),
                ),
              ),

              Container(
                margin: EdgeInsets.only(left: 5, top: 10, bottom: 10),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                    doneWidgets.add(buildDone());
                    });
                  },
                  child: Text('Done'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xff1F41BB),
                    minimumSize: Size(120, 26),
                  ),
                ),
              ),
            ],
          ),
    
        ],
      );
    }

    Widget buildDone(){
      return Column(
        children: [
           Container(
              padding: EdgeInsets.only(left: 20.0),
              child: Text(
                'Pin the end location:',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          buildMap(),

           Container(
            padding: EdgeInsets.only(left: 20.0),
            child: Text(
              'Whatis the location called?',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 30.0),
            height: 37,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Color(0xff1D1617).withOpacity(0.11),
                  blurRadius: 4,
                  spreadRadius: 0.0,
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                hintText: 'Type here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

         Container(
            margin: EdgeInsets.only(left: 5, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  
                });
              },
              child: Text('Submit & Save'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xff1F41BB),
                minimumSize: Size(227, 26),
              ),
            ),
          ),

        ],
      );

    }
}

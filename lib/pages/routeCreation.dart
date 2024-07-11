import 'dart:collection';
import 'dart:ffi';
import 'dart:js_interop';

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

  Map<String,HashSet>steps = HashMap();
  

  GoogleMapController? _controller;
  Marker? _selectedMarker;
  final String _locationName = "";
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _walkToController = TextEditingController();
  final TextEditingController _estiFareController = TextEditingController();
  final TextEditingController _stoplocationController = TextEditingController();
  final TextEditingController _endLocController = TextEditingController();
  final TextEditingController _endLocNameController = TextEditingController();
   final TextEditingController _toRouteController = TextEditingController();
    final TextEditingController _fromRouteController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
     _addressController.dispose();
    super.dispose();
  }
  
  String _address = '';
  String _establishmentName = '';
  int _stepNumber= 0;


  //Hashsets that will gather data
  final locationDetails = HashSet();
  final walkDetails = HashSet<String>();
  final rideDetails = HashSet<String>();

  //method to use in storing data
  void insertLocationDetails(String address, String latLang, String _name){
    locationDetails.addAll({address,latLang,_name});
    String step = 'Step' + '$_stepNumber';
    insertDataintoMap(step, locationDetails);
  } 
  void insertWalkDetails(String walkTo){
    walkDetails.addAll({'Walk',walkTo});
    String step = 'Step' + '$_stepNumber'; 
    insertDataintoMap(step, walkDetails);
  }
   insertRideDetails(String transpoMode,String fare, String fromRoute, String toRoute,String stopLoc){
    rideDetails.addAll({'Ride',transpoMode,fare,fromRoute,toRoute,stopLoc});
    String step = 'Step' + '$_stepNumber'; 
    insertDataintoMap(step, rideDetails);
  }
  void insertDataintoMap(String step,HashSet details){
    steps.addAll({step: details});

  }


Future<void> _onMapTap(LatLng position) async {
  List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
  
  if (placemarks.isNotEmpty) {
    Placemark placemark = placemarks[0];
    String name = placemark.name ?? "";
    String address = "${placemark.street ?? ""}, ${placemark.locality ?? ""}, ${placemark.administrativeArea ?? ""}, ${placemark.country ?? ""}";

    setState(() {
      _selectedMarker = Marker(
        markerId: const MarkerId('selected-location'),
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
                    margin: const EdgeInsets.all(5),
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
                    child: Container(
                      margin: const EdgeInsets.only(right: 30.0),
                      height: 37,
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
                      child: TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
                    padding: const EdgeInsets.only(left: 20.0),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _address,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.only(left: 20.0),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'establishment name',
                      style: TextStyle(
                        color: Color.fromARGB(255, 66, 66, 66),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

              ],
             ),
          
              const SizedBox(height: 10),

              const Divider(
                thickness: 2.0,
                color: Colors.grey,
              ),

              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.only(left: 20.0),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Pin a starting point',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              buildMap(),
              
              const SizedBox(height: 20),

              if (_mapClicked)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 20.0),
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'What is this location called?',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                      const SizedBox(height: 10),
                    Container(
                      margin: const EdgeInsets.only(right: 20.0, left: 20.0),
                      height: 37,
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
                      child: TextField(
                        controller: _locationNameController,
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
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.only(left: 20.0),
                      alignment: Alignment.centerLeft,
                      child: const Text(
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
                          margin: const EdgeInsets.only(left: 20, right: 5, top: 10, bottom: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                // walkWidgets.add(buildWalk());
                                rideClicked = false; 
                                walkClicked = true;
                               
                              });
                             
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xff1F41BB),
                              minimumSize: const Size(131, 26),
                            ),
                            child: const Text('Walk'),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 5, right: 5, top: 10, bottom: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                walkClicked = false;
                                // rideWidgets.add(buildWalk());
                                rideClicked = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xff1F41BB),
                              minimumSize: const Size(131, 26),
                            ),
                            child: const Text('Ride'),
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
      title: const Padding(
        padding: EdgeInsets.only(left: 16.0, top: 10),
        child: Text(
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
                  padding: const EdgeInsets.only(left: 20.0),
                  child: const Text(
                    'Choose Transportation Mode',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 363,
                  height: 64,
                  margin: const EdgeInsets.only(right: 20.0, left: 20.0),
                  
                  child: DropdownButton<String>(
                    value: selectedMode,
                    hint: const Text('Select Mode'),
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
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: const Text(
                    'Estimated Fare:',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Container(
            margin: const EdgeInsets.only(right: 20.0, left: 20.0),
            height: 37,
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
            child: TextField(
              controller: _estiFareController,
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
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: const Text(
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
                    margin: const EdgeInsets.all(10),
                    height: 33,
                    width: 149,
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
                    child: TextField(
                      controller: _fromRouteController,
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
                  Container(
                  margin: const EdgeInsets.all(5),
                  alignment: Alignment.center,
                  height: 48.89,
                  width: 48.89,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset('assets/icons/arrow.svg'),
                ),

                  Container(
                    margin: const EdgeInsets.all(10),
                    height: 33,
                    width: 149,
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
                    child: TextField(
                      controller: _toRouteController,
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
                
                ],
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: const Text(
                    'Where to stop:',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Container(
            margin: const EdgeInsets.only(right: 20.0, left: 20.0),
            height: 37,
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
            child: TextField(
              controller: _stoplocationController,
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

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: const Text(
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
                          margin: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                              insertRideDetails(selectedMode!, _estiFareController.text, _fromRouteController.text, _toRouteController.text, _stoplocationController.text);
                               walkWidgets.add(buildWalk());
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xff1F41BB),
                              minimumSize: const Size(120, 26),
                            ),
                            child: const Text('Walk'),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 5, top: 10, bottom: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                insertRideDetails(selectedMode!, _estiFareController.text, _fromRouteController.text, _toRouteController.text, _stoplocationController.text);
                                rideWidgets.add(buildRide());
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xff1F41BB),
                              minimumSize: const Size(120, 26),
                            ),
                            child: const Text('Ride'),
                          ),
                        ),

                        Container(
                          margin: const EdgeInsets.only(left: 5, top: 10, bottom: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                              doneWidgets.add(buildDone());
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xff1F41BB),
                              minimumSize: const Size(120, 26),
                            ),
                            child: const Text('Done'),
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
            padding: const EdgeInsets.only(left: 20.0),
            alignment: Alignment.centerLeft,
            child: const Text(
              'Walk to:',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
            const SizedBox(height: 10),
                Container(
            margin: const EdgeInsets.only(right: 20.0, left: 20.0),
            height: 37,
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
            child: TextField(
              controller: _walkToController,
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
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(left: 20.0),
            alignment: Alignment.centerLeft,
            child: const Text(
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
                margin: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      
                      walkWidgets.add(buildWalk());
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xff1F41BB),
                    minimumSize: const Size(120, 26),
                  ),
                  child: const Text('Walk'),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 5, top: 10, bottom: 10),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      rideWidgets.add(buildRide());
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xff1F41BB),
                    minimumSize: const Size(120, 26),
                  ),
                  child: const Text('Ride'),
                ),
              ),

              Container(
                margin: const EdgeInsets.only(left: 5, top: 10, bottom: 10),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                    doneWidgets.add(buildDone());
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xff1F41BB),
                    minimumSize: const Size(120, 26),
                  ),
                  child: const Text('Done'),
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
              padding: const EdgeInsets.only(left: 20.0),
              child: const Text(
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
            padding: const EdgeInsets.only(left: 20.0),
            child: const Text(
              'What is the location called?',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 30.0),
            height: 37,
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
            child: TextField(
              controller: _endLocNameController,
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

         Container(
            margin: const EdgeInsets.only(left: 5, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: () {
                var _location = _locationController.text;
                var _locationAddress = _address;
                var _locationName = _locationNameController.text;
                var  _walkTo = _walkToController.text;
                var _estiFare = _estiFareController.text;
                var _stopLocation = _stoplocationController.text;
                var _endLocation = _endLocController.text;
                var _endLocationName = _endLocNameController.text;
                var _toRoute = _toRouteController.text;
                var _fromRoute = _fromRouteController.text;

              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xff1F41BB),
                minimumSize: const Size(227, 26),
              ),
              child: const Text('Submit & Save'),
            ),
          ),

        ],
      );

    }
}

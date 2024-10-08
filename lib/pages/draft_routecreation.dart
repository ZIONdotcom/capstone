// ignore: file_names
import 'dart:collection';
import 'package:eosdart/eosdart.dart' as eos;
import 'dart:ffi' hide Size;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_maps_webservice/places.dart' as places;



class DraftRoutecreation extends StatefulWidget {
  const DraftRoutecreation({super.key});

  @override
  State<DraftRoutecreation> createState() => _MyWidgetState();
}


/*class WalkStep{
  TextEditingController _walkToController;

  WalkStep() : _walkToController = TextEditingController();
}
class RideStep{
  String? _selectedMode;
  TextEditingController _estiFareController;
  TextEditingController _toRouteController;
  TextEditingController _fromRouteController;
  TextEditingController _stopLocationController;

  RideStep(): _selectedMode = null,
   _estiFareController = TextEditingController(),
   _toRouteController = TextEditingController(),
   _fromRouteController = TextEditingController(),
   _stopLocationController = TextEditingController();
}*/


class _MyWidgetState extends State<DraftRoutecreation> {
 CameraPosition _initialCameraPosition = const CameraPosition(
  target: LatLng(14.831582, 120.903786), // Default initial position
  zoom: 11.5, // Default zoom level
);

CameraPosition _initialCameraPosition2 = const CameraPosition(
  target: LatLng(14.831582, 120.903786), // Default initial position for second map
  zoom: 11.5, // Default zoom level for second map
);



bool _isFirstSearch = true; // Track if it's the first search

  bool walkClicked = false;
  bool doneClicked = false;
  bool rideClicked = false;
  bool _mapClicked = false;
  bool _map2Clicked = false; 
  //String? selectedMode;

  
  List<TextEditingController> walkControllers = [];
  List<TextEditingController> rideControllers = [];
  List<TextEditingController> fareControllers = [];
  List<TextEditingController> fromRouteControllers = [];
  List<TextEditingController> toRouteControllers = [];
  List<TextEditingController> stopLocationControllers = [];
  List<String> selectedModes = [];



  List<Map<String, dynamic>> routeSteps = [];
  int stepNumber = 1;

  //List<String> modes = ['Jeep', 'Tricycle', 'Bus', 'E-jeep'];
  List<Widget> widgets = [];
  
  List<Widget> doneWidgets =[];

  final apiKey = 'AIzaSyAnDp1NMv3WSsatCAjJL02Y_fL8a44L4NI'; // Replace with your actual API key
  late final GoogleMapsPlaces _places;

  //var _location, _locationAddress,_locationname,_walkTo,_estiFare,_stopLocation,_endLocation,_endLocationName,_toRoute,_fromRoute;

  /*final TextEditingController _walkToController = TextEditingController();
  final TextEditingController _estiFareController = TextEditingController();
  final TextEditingController _fromRouteController = TextEditingController();
  final TextEditingController _toRouteController = TextEditingController();
  final TextEditingController _stoplocationController = TextEditingController();*/
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _endLocNameController = TextEditingController();

  
 // Function to add a new walk widget
  void addWalkWidget() {
    setState(() {
      walkControllers.add(TextEditingController());
      widgets.add(buildWalk(walkControllers.last));
    });
  }
   // Function to add a new ride widget
  void addRideWidget() {
    setState(() {
      rideControllers.add(TextEditingController());
      fareControllers.add(TextEditingController());
      fromRouteControllers.add(TextEditingController());
      toRouteControllers.add(TextEditingController());
      stopLocationControllers.add(TextEditingController());
      selectedModes.add('');

      widgets.add(buildRide(
        rideControllers.last,
        fareControllers.last,
        fromRouteControllers.last,
        toRouteControllers.last,
        stopLocationControllers.last,
        selectedModes.length - 1, // Index for selected mode
      ));
    });
  }


  @override
  void initState() {
    super.initState();
    _places = GoogleMapsPlaces(apiKey: apiKey); // Initialize _places with the API key
    //update data real time
    /*_locationController.addListener(_updateText);
    _addressController.addListener(_updateText);
    _locationNameController.addListener(_updateText);
    _walkToController.addListener(_updateText);
    _estiFareController.addListener(_updateText);
    _stoplocationController.addListener(_updateText);
    _endLocController.addListener(_updateText);
    _endLocNameController.addListener(_updateText);
    _toRouteController.addListener(_updateText);
    _fromRouteController.addListener(_updateText);*/
  }
  

  //Map<int,HashSet>steps = HashMap();
  GoogleMapController? _controller2;
   GoogleMapController? _controller;
  Marker? _selectedMarker;
  //Marker? _selectedMarker2; 
  Set<Marker> _markers2 = {};
  //final String _locationName = "";
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _searchController = TextEditingController(); // Controller for the search bar
  bool _showSearchBar = false; // New state for showing/hiding the search bar
  String _address = '';
  String _endAddress = '';
  String _establishmentName = '';
  bool submitClicked = false;
 /* final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _walkToController = TextEditingController();
  final TextEditingController _estiFareController = TextEditingController();
  final TextEditingController _stoplocationController = TextEditingController();
  final TextEditingController _endLocController = TextEditingController();
  final TextEditingController _endLocNameController = TextEditingController();
   final TextEditingController _toRouteController = TextEditingController();
    final TextEditingController _fromRouteController = TextEditingController();*/

  @override
  void dispose() {
    print('dis[pse]');
    _locationController.dispose();
    _addressController.dispose();
    _searchController.dispose();
    /*_walkToController.dispose();
    _estiFareController.dispose();
    _fromRouteController.dispose();
    _toRouteController.dispose();
    _stoplocationController.dispose();*/
    _locationNameController.dispose();
    _endLocNameController.dispose();
    super.dispose();
  }
  void clearAll() {
  // Clear all the text controllers in the lists
  for (var controller in walkControllers) {controller.clear();}
  for (var controller in rideControllers) {controller.clear();}
  for (var controller in fareControllers) {controller.clear();}
  for (var controller in fromRouteControllers) {controller.clear();}
  for (var controller in toRouteControllers) {controller.clear();}
  for (var controller in stopLocationControllers) {controller.clear();}

  // Clear individual text controllers
  _locationNameController.clear();
  _endLocNameController.clear();

  // Reset any other relevant variables or states
  setState(() {
    walkClicked = false;
    doneClicked = false;
    rideClicked = false;
    _mapClicked = false;
    _map2Clicked = false; // Reset the second map click state

    selectedModes.clear();
    routeSteps.clear();
    stepNumber = 1;

    widgets.clear();
    doneWidgets.clear();
  });
}
  //final int _stepNumber= 0;

  //Hashsets that will gather data
  //final locationDetails = HashSet<dynamic>();

 // final rideDetails = HashSet<dynamic>();

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

Future<void> _onMap2Tap(LatLng position) async {
  List<Placemark> placemarks2 = await placemarkFromCoordinates(position.latitude, position.longitude);

  if (placemarks2.isNotEmpty) {
    Placemark placemark2 = placemarks2[0];
    String name2 = placemark2.name ?? "";
    String address2 = "${placemark2.street ?? ""}, ${placemark2.locality ?? ""}, ${placemark2.administrativeArea ?? ""}, ${placemark2.country ?? ""}";

    setState(() {  
        // _selectedMarker2 = Marker(
        //   markerId: const MarkerId('selected-location-2'),
        //   position: position,
        //   infoWindow: InfoWindow(title: name2),
        //   visible: true
        // );

        _markers2.clear();
        _markers2.add(Marker(markerId: MarkerId('map2'), position: position));
      
      _map2Clicked = true;
      _endLocNameController.text = name2;
      _endAddress = address2;

    });

    // Fetch establishment name
    _fetchPlaceDetails2(position);
  }
}


 Future<void> _fetchPlaceDetails(LatLng position) async {
  // Create an instance of the Location class from google_maps_webservice
  final location = places.Location(
    lat: position.latitude,
    lng: position.longitude,
  );

  // Fetch nearby places using the nearbySearch method
  final response = await _places.searchNearbyWithRadius(
    location,
    500, // Radius in meters
    type: 'establishment',
    keyword: 'church|coffee shop|mall|establishment',
  );

  // Check the response and update state
  if (response.status == 'OK' && response.results.isNotEmpty) {
    final establishment = response.results.first;
    final name = establishment.name;
    setState(() {
      _establishmentName = name;
    });
  } else {
    setState(() {
      _establishmentName = 'No nearby establishment found';
    });
  }
}


Future<void> _fetchPlaceDetails2(LatLng position) async {
  final location = places.Location(
    lat: position.latitude,
    lng: position.longitude,
  );

  final response = await _places.searchNearbyWithRadius(
    location,
    500, // Radius in meters
    type: 'establishment',
    keyword: 'church|coffee shop|mall|establishment',
  );

  if (response.status == 'OK' && response.results.isNotEmpty) {
    final establishment = response.results.first;
    final name = establishment.name;
    setState(() {
      _establishmentName = name;
    });
  } else {
    setState(() {
      _establishmentName = 'No nearby establishment found';
    });
  }
}

void _searchPlaces(String query) async {
  final response = await _places.searchByText(query);

  if (response.status == 'OK' && response.results.isNotEmpty) {
    final place = response.results.first;
    final location = LatLng(place.geometry?.location.lat ?? 0.0, place.geometry?.location.lng ?? 0.0);

    setState(() {
      _selectedMarker = Marker(
        markerId: const MarkerId('search-location'),
        position: location,
        infoWindow: InfoWindow(title: place.name),
      );

      if (_isFirstSearch) {
        // Update the initial camera position
        _initialCameraPosition = CameraPosition(
          target: location,
          zoom: 15.0, // Adjust zoom level as needed
        );
        _isFirstSearch = false;
        // Move the camera to the new initial position
        _controller?.moveCamera(CameraUpdate.newCameraPosition(_initialCameraPosition));
      } else {
        // Animate the camera to the searched location
        _controller?.animateCamera(CameraUpdate.newLatLng(location));
      }

      _searchController.clear();
      _showSearchBar = false; // Hide the search bar after selecting a location
       _locationController.text = place.formattedAddress ?? ''; // Show the selected address in the TextField
        _address = place.formattedAddress ?? ''; // Update the _address with the selected address

        // Fetch establishment name for the searched location
        _fetchPlaceDetails(location);
    });

     // Update the address and establishment name
      setState(() {
        _mapClicked = true; // Show address and establishment name
        _address = place.formattedAddress ?? ''; // Update _address with the new location's address
        _searchController.clear(); // Clear the search bar
        _showSearchBar = false; // Hide the search bar
      });

  } else {
    // Handle no results found
    setState(() {
      _searchController.clear();
      _showSearchBar = false;
    });
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
                      onTap: () {
                        setState(() {
                          _showSearchBar = true; 
                          submitClicked = false;
                        });
                      },
                      onSubmitted: (query) {
                        _searchPlaces(query);
                        submitClicked = true;
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        hintText: 'Search for places...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: _showSearchBar
                            ? IconButton(
                                icon: const Icon(Icons.cancel),
                                onPressed: () {
                                  setState(() {
                                    _showSearchBar = false;
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                      
                    ),
                  ),
                ),
              ],
            ),          
             if(_mapClicked || submitClicked )
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
  //  buildMap2(),

//buildDone(),
              
  //             const SizedBox(height: 20),
              
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
                      child: TextFormField(
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
                        validator: (value){
                            if(value!.isEmpty){
                              return "Fill out this field";
                            }else{
                              return null;
                            }
                        },
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
                              if(_locationNameController.text.isNotEmpty){
                                setState(() {
                               addWalkWidget();
                              });
                              }
                              else{
                                ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                content: Text('Please fill out all fields.'),
                                duration: Duration(seconds: 1),
                                  ),
                                );
                               }                                   
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
                               if(_locationNameController.text.isNotEmpty){
                                setState(() {
                                // walkWidgets.add(buildWalk());
                                addRideWidget();
                               
                              });
                              }
                              else{
                                ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                content: Text('Please fill out all fields.'),
                                duration: Duration(seconds: 2),
                                  ),
                                );
                               }     
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
            
              //if (rideClicked) buildRide(),
              //if (walkClicked) buildWalk(),
                ...widgets, 
              //...rideWidgets,
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

//display map
   Widget buildMap() {
  return SizedBox(
    width: double.infinity,
    height: 200,
    child: GoogleMap(
      initialCameraPosition: _initialCameraPosition,
      onMapCreated: (controller) {
        _controller = controller;
      },
      onTap: _onMapTap,
      markers: _selectedMarker != null ? {_selectedMarker!} : {},
    ),
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
         
          //second map here
           buildMap2(),
          
              if (_mapClicked)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
            child: TextFormField(
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
              validator: (value){
                            if(value!.isEmpty){
                              return "Fill out this field";
                            }
                            else{
                              return null;
                            }
                          }
            ),
          ),

         Container(
            margin: const EdgeInsets.only(left: 5, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: () {
                if(_endLocNameController.text.isNotEmpty){
                      //dito na ata yung saving sa database, di ko sure
                      print(_address);
                      print(_locationNameController.text);
                      print('Route Steps: $routeSteps');

                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                    return AlertDialog(
                      title:const Text('Route Suggestion Submitted'),
                      content: const Text('Your route suggestion has been submitted and will be reviewed by the admin. Thank you'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('OK'),
                          onPressed: () {
                            clearAll();
                            Navigator.of(context).pop(); // Close the dialog
                            // Optionally, navigate or perform any other action upon closing the dialog
                          },
                        ),
                      ],
                    );
                  },
                );
                  }
               else{
                      ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                     content: Text('Please fill out the missing field.'),
                     duration: Duration(seconds: 2),
                       ),
                      );
                  }  
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
                    ),
                  
                  ],
                );

    }
      //method to use in storing data
 

//displaymap2
Widget buildMap2() {
  return SizedBox(
    width: double.infinity,
    height: 200,
    child: GoogleMap(
      initialCameraPosition: _initialCameraPosition2,
      onMapCreated: (controller) {
        _controller2 = controller;
      },
      onTap: _onMap2Tap,
      markers: _markers2,
      //markers: _selectedMarker2 != null ? {_selectedMarker2!} : {},
    ),
  );
}

 
    Widget buildRide(TextEditingController rideController,
    TextEditingController fareController,
    TextEditingController fromRouteController,
    TextEditingController toRouteController,
    TextEditingController stopLocationController,
    int modeIndex){
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
                    value: selectedModes[modeIndex].isEmpty ? null : selectedModes[modeIndex],
                    hint: const Text('Select Mode'),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedModes[modeIndex] = newValue ?? '';
                      });
                    },
                    items:  ['Jeep', 'Tricycle', 'Bus', 'E-jeep']
                      .map((String mode) => DropdownMenuItem<String>(
                      value: mode,
                      child: Text(mode),
                    )).toList(),
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
            child: TextFormField(
              controller: fareController,
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
              validator: (value){
                            if(value!.isEmpty){
                              return "Fill out this field";
                            }else{
                              return null;
                            }
              }
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
                    child: TextFormField(
                      controller: fromRouteController,
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
                       validator: (value){
                            if(value!.isEmpty){
                              return "Fill out this field";
                            }else{
                              return null;
                            }
                          }
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
                    child: TextFormField(
                      controller: toRouteController,
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
                      validator: (value){
                            if(value!.isEmpty){
                              return "Fill out this field";
                            }else{
                              return null;
                            }
                          }
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
            child: TextFormField(
              controller: stopLocationController,
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
              validator: (value){
                            if(value!.isEmpty){
                              return "Fill out this field";
                            }else{
                              return null;
                            }
                          }
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
                                   if (fareController.text.isNotEmpty &&
                                  fromRouteController.text.isNotEmpty &&
                                  toRouteController.text.isNotEmpty &&
                                  stopLocationController.text.isNotEmpty &&
                                  selectedModes.isNotEmpty) {
                                  insertRideStep(selectedModes, fareController.text, fromRouteController.text, toRouteController.text, stopLocationController.text);
                                  //_estiFareController.clear();
                                  //_fromRouteController.clear();
                                  //_toRouteController.clear();
                                  //_stoplocationController.clear();
                                  setState(() {
                                    addWalkWidget();
                                    //selectedMode = '';
                                  });
                               }
                               else{
                                ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                content: Text('Please fill out all fields.'),
                                duration: Duration(seconds: 2), // Adjust the duration as needed
                                  ),
                                );

                               }
                              //insertRideDetails(selectedMode!, _estiFareController.text, _fromRouteController.text, _toRouteController.text, _stoplocationController.text);
                               
                              
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
                               if (fareController.text.isNotEmpty &&
                                  fromRouteController.text.isNotEmpty &&
                                  toRouteController.text.isNotEmpty &&
                                  stopLocationController.text.isNotEmpty &&
                                  selectedModes.isNotEmpty) {
                                  insertRideStep(selectedModes, fareController.text, fromRouteController.text, toRouteController.text, stopLocationController.text);
                                 /* _estiFareController.clear();
                                  _fromRouteController.clear();
                                  _toRouteController.clear();
                                  _stoplocationController.clear();*/
                                  setState(() {
                                    addRideWidget();
                                  });
                               }
                               else{
                                ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                content: Text('Please fill out all fields.'),
                                duration: Duration(seconds: 2),
                                  ),
                                );
                               }
                              
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
                              if (fareController.text.isNotEmpty &&
                                  fromRouteController.text.isNotEmpty &&
                                  toRouteController.text.isNotEmpty &&
                                  stopLocationController.text.isNotEmpty &&
                                  selectedModes.isNotEmpty) {
                                  insertRideStep(selectedModes, fareController.text, fromRouteController.text, toRouteController.text, stopLocationController.text);
                                  /*_estiFareController.clear();
                                  _fromRouteController.clear();
                                  _toRouteController.clear();
                                  _stoplocationController.clear();*/
                                  setState(() {
                                  doneWidgets.add(buildDone());
                                  });
                               }
                               else{
                                ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                content: Text('Please fill out all fields.'),
                                duration: Duration(seconds: 2),
                                  ),
                                );
                               }                              
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

    Widget buildWalk(TextEditingController controller){
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
            child: TextFormField(
              controller: controller,
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
              validator: (value){
                            if(value!.isEmpty){
                              return "Fill out this field";
                            }else{
                              return null;
                            }
                          }
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
                    if (controller.text.isNotEmpty) {
                      insertWalkStep(controller.text);
                      //_walkToController.clear();
                      addWalkWidget();
                    }
                    else{
                                ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                content: Text('Please fill out all fields.'),
                                duration: Duration(seconds: 2), // Adjust the duration as needed
                                  ),
                                );

                               }
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
                    if (controller.text.isNotEmpty) {
                      insertWalkStep(controller.text);
                      //_walkToController.clear();
                      setState(() {
                      addRideWidget();
                    });
                    }
                    else{
                                ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                content: Text('Please fill out all fields.'),
                                duration: Duration(seconds: 2), // Adjust the duration as needed
                                  ),
                                );

                               }
                    
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
                    if (controller.text.isNotEmpty) {
                      insertWalkStep(controller.text);
                      //_walkToController.clear();
                      setState(() {
                    doneWidgets.add(buildDone());
                    });
                    }
                    else{
                                ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                content: Text('Please fill out all fields.'),
                                duration: Duration(seconds: 2), // Adjust the duration as needed
                                  ),
                                );

                               }
                    
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

  void insertWalkStep(String walkTo) {
    Map<String, dynamic> walkStep = {
      'stepNumber': stepNumber,
      'type': 'Walk',
      'details': {'walkTo': walkTo},
    };
    routeSteps.add(walkStep);
    setState(() {
      stepNumber++;
    });
  }
  void insertRideStep(List<String> mode, String fare, String fromRoute, String toRoute, String stopLocation) {
    Map<String, dynamic> rideStep = {
      'stepNumber': stepNumber,
      'type': 'Ride',
      'details': {
        'mode': mode,
        'fare': fare,
        'fromRoute': fromRoute,
        'toRoute': toRoute,
        'stopLocation': stopLocation,
      },
    };
    routeSteps.add(rideStep);
    setState(() {
      stepNumber++;
    });
    
  }


  /*void insertLocationDetails(String address, String latLang, String name){
    locationDetails.addAll({address,latLang,name});
    int step =_stepNumber;
    insertDataintoMap(step, locationDetails);
  } 
  void insertWalkDetails(String walkTo){
    walkDetails.addAll({'Walk',walkTo});
     int step =_stepNumber; 
    insertDataintoMap(step, walkDetails);
  }
   insertRideDetails(String transpoMode,String fare, String fromRoute, String toRoute,String stopLoc){
    rideDetails.addAll({'Ride',transpoMode,fare,fromRoute,toRoute,stopLoc});
     int step =_stepNumber; 
    insertDataintoMap(step, rideDetails);
  }
  insertDataintoMap(int step,HashSet details){
    steps.addAll({step: details});

  }*/
  //update text
 /* void _updateText(){
    setState(() {
      _location = _locationController.text;
      _locationAddress = _address;
      _locationname = _locationNameController.text;
      _walkTo = _walkToController.text;
      _estiFare = _estiFareController.text;
      _stopLocation = _stoplocationController.text;
      _endLocation = _endLocController.text;
      _endLocationName = _endLocNameController.text;
      _toRoute = _toRouteController.text;
      _fromRoute = _fromRouteController.text;


    });

    void _addNewWalk(String goTo){
      setState(() {
        final walkDetails = HashSet<dynamic>();
        walkDetails.addAll({'Walk',goTo});
        steps.add(walkDetails);
        
      });
    }
  }*/
}



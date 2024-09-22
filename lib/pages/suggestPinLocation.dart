import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class SuggestPinLocation extends StatefulWidget {
  const SuggestPinLocation({super.key});

  @override
  SuggestPinLocationState createState() => SuggestPinLocationState();
}

class SuggestPinLocationState extends State<SuggestPinLocation> {
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(14.831582, 120.903786),
    zoom: 11.5,
  );

  late GoogleMapController _googleMapController;
  Marker? _pinnedMarker;
  String? _address;
  String? selectedMode;
  TextEditingController _establishmentController = TextEditingController();
  TextEditingController _fareController = TextEditingController();
  TextEditingController _fromRouteController = TextEditingController();
  TextEditingController _toRouteController = TextEditingController();

  bool _showEstablishment = true;
  bool _showOptions = false; // To control visibility of widgets


  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      _showDialog(context);
    });
  }
  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Pin Missing Establishment/Terminal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) {
              _googleMapController = controller;
            },
            markers: _pinnedMarker != null ? {_pinnedMarker!} : {},
            onTap: _addMarker,
          ),
          if (_showOptions)
            Positioned(
              top: 0,
              left: 0.0,
              right: 0.0,
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6.0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.center,
                      child: const Text(
                        'Is this an establishment or terminal?',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showEstablishment = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: _showEstablishment ? Color.fromARGB(255, 121, 141, 211) : const Color(0xff1F41BB),
                            minimumSize: const Size(120, 26),
                          ),
                          child: const Text(
                            'Establishment',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showEstablishment = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: !_showEstablishment ? Color.fromARGB(255, 121, 141, 211) : const Color(0xff1F41BB),
                            minimumSize: const Size(120, 26),
                          ),
                          child: const Text(
                            'Terminal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (_showOptions)
            DraggableScrollableSheet(
              initialChildSize: 0.25, // Initial size of the bottom sheet when it's collapsed
              minChildSize: 0.25, // Minimum size of the bottom sheet when dragged down
              maxChildSize: 0.6, // Maximum size of the bottom sheet when fully expanded
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _showEstablishment ? buildEstablishment() : buildTerminal(),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        onPressed: () => _googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(_initialCameraPosition),
        ),
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }

    Widget buildTerminal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 13.0),
          child: const Text(
            'Choose transportation vehicle',
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
            items: ['Jeep', 'Tricycle', 'Bus', 'E-jeep']
                .map((String mode) => DropdownMenuItem<String>(
                      value: mode,
                      child: Text(mode),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.only(left: 13.0),
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
            controller: _fareController,
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
            validator: (value) {
              if (value!.isEmpty) {
                return "Fill out this field";
              } else {
                return null;
              }
            },
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.only(left: 13.0),
          child: const Text(
            'Route',
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
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
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Fill out this field";
                  } else {
                    return null;
                  }
                },
              ),
            ),
            Container(
              alignment: Alignment.center,
              height: 40,
              width: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset('assets/icons/arrow.svg'),
            ),
            Container(
              margin: const EdgeInsets.all(5),
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
        Container(
          padding: const EdgeInsets.only(left: 13.0),
          child: const Text(
            'Picture of Terminal',
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
         const SizedBox(height: 5),
          OutlinedButton(
            onPressed: () {
              // di ko pa alam dito
            },
            style: OutlinedButton.styleFrom(
              
              side: const BorderSide(color: Color.fromARGB(255, 171, 209, 255)),
              foregroundColor: const Color.fromARGB(255, 171, 209, 255), 
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              minimumSize: const Size(80,30),
            ),
            child: const Text('Select File'),
          ),

         ElevatedButton(
            onPressed: () {
              if (_fareController.text.isNotEmpty &&
                _fromRouteController.text.isNotEmpty &&
                _toRouteController.text.isNotEmpty &&
                selectedMode != ''){
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
                  content: Text('Please fill out all fields.'),
                  duration: Duration(seconds: 2), // Adjust the duration as needed
                  ),
                );
              }               
            
            },
            style: ElevatedButton.styleFrom(
              alignment: Alignment.center,
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xff1F41BB),
              minimumSize: const Size(120, 26),
            ),
            child: const Text('Submit'),
          ),
          
      ],
    );
  }
  Widget buildEstablishment() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(left: 20.0),
          alignment: Alignment.centerLeft,
          child: const Text(
            'What is this establishment called?',
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
            controller: _establishmentController,
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
            validator: (value) {
              if (value!.isEmpty) {
                return "Fill out this field";
              } else {
                return null;
              }
            },
          ),
        ),
        const SizedBox( height: 5),
        Container(
         padding: const EdgeInsets.only(left: 16.0),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Picture of Establishment',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
         const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.only(left: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () {
                  // di ko pa alam dito
                },
                style: OutlinedButton.styleFrom(
                  
                  side: const BorderSide(color: Color.fromARGB(255, 171, 209, 255)),
                  foregroundColor: const Color.fromARGB(255, 171, 209, 255), 
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  minimumSize: const Size(80,30),
                ),
                child: const Text('Select File'),
              ),
            ),
          ),
        ElevatedButton(
          onPressed: () {
            if (_establishmentController.text.isNotEmpty){
                  //submit popup
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
          child: const Text('Submit'),
        ),
      ],
    );
  }

void clearAll(){
  _establishmentController.clear();
  _fareController.clear();
  _fromRouteController.clear();
  _toRouteController.clear();

}
  void _addMarker(LatLng position) async {
    setState(() {
      _pinnedMarker = Marker(
        markerId: const MarkerId('Pinned'),
        infoWindow: const InfoWindow(title: 'Pinned Location'),
        icon: BitmapDescriptor.defaultMarker,
        position: position,
      );
      _showOptions = true;
    });

    await _getAddress(position);
  }

  Future<void> _getAddress(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _address = '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
        });
      }
    } catch (e) {
      print('Failed to get address: $e');
    }
  }
  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("PIN THE ORIGIN",
           style: TextStyle(
            fontSize: 13,
           fontWeight: FontWeight.bold
           ),
            textAlign: TextAlign.center,
             ),
          content: const Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Icon(
                Icons.add_location_alt_outlined,
                size: 100,
                color: Color.fromARGB(255, 151, 175, 255),
              ),
              SizedBox(height: 20),
              Text("Let's start creating your route!",
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
    // TransitionBuilder:  (context, animation, secondaryAnimation, child){
    //   return FadeTransition(
    //     opacity: animation,
    //     child: child,
    //   );
    // },
    // transitionDuration
}
}

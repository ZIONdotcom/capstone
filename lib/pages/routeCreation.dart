import 'dart:convert';
import 'dart:core';
import 'package:capstone/pages/mapForPolylines.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; //use to convert coordinates to address
import 'searchPage.dart';

// import 'polyline_decoder.dart';
import 'polylineDecoder.dart';

class RouteCreation extends StatefulWidget {
  const RouteCreation({super.key});

  @override
  State<RouteCreation> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<RouteCreation>
    with SingleTickerProviderStateMixin {
  GoogleMapController? mapController;
  Marker? originMarker;
  Marker? temporaryMarker;
  Polyline? temporaryPolyline;
  String? origin_address;
  late LatLng origin_coordinates;
  String selectedLocation = 'Search Location';

  final String apiKey = 'AIzaSyC88-Wkb5_LmPU5OCQwPOMDTry3RGh1J00'; 
  final Polylinedecoder _polylineDecoder = Polylinedecoder('AIzaSyC88-Wkb5_LmPU5OCQwPOMDTry3RGh1J00');

  final PageController pageController = PageController();
  final ScrollController scrollController = ScrollController();
  final LatLng _initialCameraPosition = const LatLng(14.831582, 120.903786);
  final GlobalKey<FormState> _walkFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _rideFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _page1FormKey = GlobalKey<FormState>();

  // late LatLng currentPinnedLocation;
  bool mapClicked = false;

  final Map<int, List<dynamic>> stepsCpntainer = {};
  List<LatLng> pinnedLocations = []; //coordinates
  Map <int, List<LatLng>> step_polyline = {};
  final Set<Polyline> _polylines = {};
  final List<PolylineId> polyline_IDs = [];
  final Set<Marker> _markers = {};
  final Set<Marker> _originMarker = {};
  int stepNumber = 0;

  PolylineId _updatecurrentPolylineId = PolylineId('NoId');
  final List<String> existingPagesTracker = [];
  String currentPage = 'origin';


  void setNewPolyId(PolylineId id){
    setState(() {
      _updatecurrentPolylineId = id;
      print('setnew id');
    });
  }
  void _fetchPolylineForExisting(LatLng pointA, LatLng pointB, Polyline nextPolyline,PolylineId polylineID) async{
    final polylinePoints = await _polylineDecoder.getRoutePolyline(
    [pointA,pointB]);
    setState(() {
      try{
        Polyline newNPolyline = Polyline(
          polylineId: polylineID,
          points: polylinePoints,
          color: Colors.blue,
          width: 5,
        );
        _polylines.remove(nextPolyline);
        _polylines.add(newNPolyline);
        print('successful updating next polyline');
      } catch (e) {
        print('error updating next polyline');
      }
    });
  }

 void _fetchPolyline() async {
  List<LatLng> polylinePoints;
  PolylineId? previousPolylineid;
  if(currentPageTracker == 0){
    //if nasa origin
    polylinePoints = await _polylineDecoder.getRoutePolyline(
    [pinnedLocations[currentPageTracker],
    pinnedLocations[currentPageTracker+1]]
   
  );
  }
  else{
    polylinePoints = await _polylineDecoder.getRoutePolyline(
    [pinnedLocations[currentPageTracker - 1],
    pinnedLocations[currentPageTracker]]
  );
  previousPolylineid  = PolylineId('polyline${currentPageTracker-1}');
  }
  //Fetch the polyline points between the specified pinned locations
  
  print(polylinePoints);
  step_polyline[currentPageTracker] = polylinePoints;

  PolylineId polylineID = PolylineId('polyline$currentPageTracker');
  setNewPolyId(PolylineId('polyline$currentPageTracker'));
  int nextIndex = currentPageTracker+1;
  PolylineId nextPolylineid = PolylineId('polyline$nextIndex');
    try {
      //Find the existing polyline, if any, by filtering on polylineId
      Polyline? existingPolyline;
      Polyline? nextExistingpolyline;
      Polyline? previousPolyine;
      for (var polyline in _polylines) {
        if (polyline.polylineId == polylineID) {
          existingPolyline = polyline;
          print('existing polyline is visible');
        }
        if (polyline.polylineId == nextPolylineid) {
          nextExistingpolyline = polyline;
        }
        if(previousPolylineid !=  null && polyline.polylineId == previousPolylineid){
          previousPolyine = polyline;
        }
      }
      setState(() {
         
         print("assign: $_updatecurrentPolylineId");
      if (existingPolyline != null) {
        //If the polyline exists, remove it from the set
        _polylines.remove(existingPolyline);
        print('Updated existing polyline');
      } 
      else {
        // new polyline
        print('Adding new polyline');
        polyline_IDs.add(polylineID);
      }
      // if (previousPolyine != null) {
      //   //If the polyline exists, remove it from the set
      //   _polylines.remove(previousPolyine);
      //   print('Updated existing polyline');
      // } 

      //Create a new polyline with the updated points
      Polyline newPolyline = Polyline(
        polylineId: polylineID,
        points: polylinePoints,
        color: Colors.blue,
        width: 5,
      );
      DataManager().insert_decodedPolyline_ToDM([newPolyline.points.first, newPolyline.points.last]);
      DataManager().insert_AllDecodedPolyline_ToDM(polylinePoints);
      getMidpoint(polylinePoints);
      

      //Add the updated or new polyline
      _polylines.add(newPolyline);
      print('polyline added');
       if(nextExistingpolyline != null){
        nextExistingpolyline.points.first = newPolyline.points.last;
        _fetchPolylineForExisting(nextExistingpolyline.points.first,nextExistingpolyline.points.last,nextExistingpolyline,nextPolylineid);
        // if(previousPolyine != null){
        //   _fetchPolylineForExisting(previousPolyine.points.first, newPolyline.points.first,previousPolyine,previousPolylineid!);
        // }
      }
      });
    } catch (e) {
      print('Error updating or adding polyline: $e');
    }
}
bool notChanged = false;
void getMidpoint(List<LatLng> midpoints){
  double computeMiddle = midpoints.length / 2;
  int middle = computeMiddle.toInt();
  LatLng middlepoint = midpoints[middle];
  notChanged = true;
  DataManager().insert_midpoint(currentPageTracker, [middlepoint], notChanged);
  
}

void updatePolylineFromChange(List<LatLng> midpoints) async {
  // Assuming _polylineDecoder.getRoutePolyline(midpoints) returns the updated points
  final updatePolylinePoints = await _polylineDecoder.getRoutePolyline(midpoints);
  print('update poly: $midpoints');
  print('update Polyline From Change: $_updatecurrentPolylineId');

  // Use forEach to iterate over the list of polylines and find the polyline to update
  _polylines.forEach((poly) {
    if (poly.polylineId == _updatecurrentPolylineId) {
      // Found the polyline to update
      setState(() {
        // Create a new Polyline with the updated midpoints
        Polyline updatedPolyline = Polyline(
          polylineId: _updatecurrentPolylineId!,  // Use the same PolylineId
          points: midpoints,  // Updated points (midpoints)
          color: Colors.blue,  // Set the color as needed
          width: 5,  // Set the width as needed
        );

        // Remove the old polyline and add the updated one
        _polylines.remove(poly);
        _polylines.add(updatedPolyline);
      });
    }
  });
}

  void changeWidget_for_changedButton(String nextButton){
    print('pages: $pages');
    int indexForNext = currentPageTracker + 1;
    MarkerId markerID = MarkerId('step$indexForNext');
    setState(() {
      if (nextButton == 'walk') {
        pages[indexForNext] = WalkWidget(
            key: UniqueKey(), onNewPage: _newPage, formKey: _walkFormKey);
        currentPages[indexForNext] = 'walk';
        print('change to walk');
      } else if (nextButton == 'ride') {
        pages[currentPageTracker + 1] = RideWidget(
            key: UniqueKey(), onNewPage: _newPage, formKey: _rideFormKey);
        currentPages[currentPageTracker + 1] = 'ride';
        print('change to ride');
      } else if (nextButton == 'done') {}
      for (Marker _marker in _markers) {
        if (_marker.markerId == markerID) {
          //creates a copy of the marker
          String snippet = _marker.infoWindow.snippet!;
          Marker updatedMarker = _marker.copyWith(
            infoWindowParam: InfoWindow(
                title: 'Step $indexForNext: ${currentPages[indexForNext]}',
                snippet: snippet),
          );
          _markers.remove(_marker);
          _markers.add(updatedMarker);
          break;
        }
      }
    });
  }

  List<Widget> pages = [];
  List<Widget> question_pages = [
    const WalkQuestionWidget(),
    const RideQuestionWidget()
  ];
  List<String> currentPages = ['origin'];
  int questionPageTracker = 0;
  int currentPageTracker = 0;
  bool questionIsVisible = false;
  List<double> sheetSizes = [0.46, 0.25, 0.46];
  String? temporary_LocationName;

  // String getTermporary_LocationName(){
  //   print('in method: $temporary_LocationName');
  //   return temporary_LocationName!;
  // }
  // final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Method to trigger form validation
  // void validateForm() {
  //   if (_formKey.currentState?.validate() ?? false) {
  //     print("Form is valid");
  //   } else {
  //     print("Form is invalid");
  //   }
  // }
  void size_Checker(){
    if(currentPages.length -1   == _markers.length){
        questionIsVisible = true;
        setState(() {
          sheetSizes[0] = 0.26;
          sheetSizes[2] = 0.26;
          sheetSizes[1] = 0.25;
        });
      }else{
        questionIsVisible = false;
        // print( 'sheet size: $sheetSizes[0],$sheetSizes[1],$sheetSizes[2] ');
        setState(() {

          
          if(currentPage == 'walk'){
            sheetSizes[1] = 0.40;
            sheetSizes[0] = 0.50;
            
            sheetSizes[2] = 0.50;
          }
          else if(currentPage == 'ride'){
            sheetSizes[1] = 0.40;
            sheetSizes[0] = 0.50;
            sheetSizes[2] = 0.50;
            // print('ride size');
          }
          else if( currentPage == 'origin'){
            sheetSizes[1] = 0.30;
            sheetSizes[0] = 0.40;
            sheetSizes[2] = 0.45;
          }
      });
      // print('not question');
    }
  }
  // void pageChecker() {
  //   if(currentPageTracker < currentPages.length){
  //     if(currentPages[currentPageTracker] == 'walk'){
  //       page = WalkWidget(onNewPage: _newPage);
  //       print('--- walk');
  //     }
  //     else if(currentPages[currentPageTracker] == 'ride'){
  //       page = RideWidget(onNewPage: _newPage);
  //     }
  //     else{
  //     page = Page1(onNewPage: _newPage);
  //     print('--- origin');
  //   }
  //   }

  //   print('Page checker');
  //   print(currentPages[currentPageTracker]);
  // }

  // late Widget page;
  void _newPage(String pagename) {
    setState(() {
      currentPage = pagename;
      currentPages.add(pagename);
      currentPageTracker++;
      DataManager().updateCountTracker(currentPageTracker);
      print('new page: $currentPageTracker - $currentPage');

      if (pagename == 'walk') {
        questionPageTracker = 0;
        // page = WalkWidget(onNewPage: _newPage);
        pages.add(WalkWidget(
            key: UniqueKey(), onNewPage: _newPage, formKey: _walkFormKey));
      } else if (pagename == 'ride') {
        questionPageTracker = 1;
        pages.add(RideWidget(
            key: UniqueKey(), onNewPage: _newPage, formKey: _rideFormKey));
        // page = RideWidget(onNewPage: _newPage);
      } else if (pagename == 'done') {
      } else if (pagename == 'origin') {
        pages.add(Page1(
            key: UniqueKey(), onNewPage: _newPage, formKey: _page1FormKey));
        // page = Page1(onNewPage: _newPage);
      }
      //for icons in question widget to be not
      size_Checker();

      // print('question is visible: $questionIsVisible');
    });

    print("Pages - - $pages");
    // print(sheetSizes);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DialogPopUp()._show_StartDialog(context);
    });
    // currentPages.add('origin');
    pages.add(Page1(onNewPage: _newPage, formKey: _page1FormKey));
  }

  //Function to get the place name using Places API
  // Future<void> _getPlaceName(LatLng position) async {
  //   final url =
  //       'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${position.latitude},${position.longitude}&radius=50&key=$apiKey';

  //   final response = await http.get(Uri.parse(url));

  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     if (data['results'] != null && data['results'].isNotEmpty) {
  //       final placeName = data['results'][0]['name'];
  //       setState(() {
  //        DataManager().
  //       });
  //     } else {
  //       setState(() {
  //         // _locationNameController.text = "No place found";
  //       });
  //     }
  //   } else {
  //     setState(() {
  //       print("Error fetching place name");
  //     });
  //   }
  // }

//GET ADDRESS OF PINNED LOCATION
  Future<String> _getAddress(LatLng position) async {
    try {
      String address = 'No address found';
      String placeName = 'Unknown Place';
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String name = placemark.name ?? '';
        String locality = placemark.locality ?? '';
        String administrativeArea = placemark.administrativeArea ?? '';
        address = '$name, $locality, $administrativeArea';
      }

      final url =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${position.latitude},${position.longitude}&radius=50&type=establishment&key=$apiKey';

      final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'] != null && data['results'].isNotEmpty) {
        placeName = data['results'][1]['name']; //Get the second nearby place
        print('place name: $placeName $address');
        DataManager().set_temporary_LocationName(placeName);
       
        print('temporary location: $temporary_LocationName');
      }
    }
    return address;
  } catch (e) {
    return 'Error retrieving location data: ${e.toString()}';
  }
}

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  //for map pins
  void _addPin(LatLng pinnedLocation) async {
    String address = await _getAddress(pinnedLocation);
    setState(() {
      String currentPage = currentPages[currentPageTracker];
      Marker? existingMarker;
      MarkerId? markerID;
      if (currentPageTracker == 0) {
        markerID = const MarkerId('origin');
      } else {
        markerID = MarkerId('step$currentPageTracker');
      }
      for (Marker _marker in _markers) {
        if (_marker.markerId == markerID) {
          existingMarker = _marker;
        }
      }
      if (existingMarker != null) {
        _markers.remove(existingMarker);
        pinnedLocations[currentPageTracker] = pinnedLocation;
        print('Marker removed and is going to be updated');
      } else {
        pinnedLocations.add(pinnedLocation);
        print('Add new marker');
      }
      Marker newMarker = Marker(
          markerId: markerID,
          position: pinnedLocation,
          infoWindow: InfoWindow(
              title: currentPageTracker == 0
                  ? "Origin"
                  : "Step $currentPageTracker: $currentPage",
              snippet: address));
      _markers.add(newMarker);
      DataManager().insertStepLocationData(currentPageTracker, currentPage,
          [address, pinnedLocation.latitude, pinnedLocation.longitude]);
      print('location details added to Data Manager');
      if (pinnedLocations.length > 1) {
        print('try to fetch polyliine...');
        _fetchPolyline();

        print('polyliine fetched');
      } else {
        print('polyliine not fetched');
      }
      size_Checker();
      print("add pin question is visible: $questionIsVisible");
    });
  }

  //animate camera to last pinned location
  void _focusOnLastPinnedLocation() async {
    if (pinnedLocations.isNotEmpty && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(pinnedLocations.last, 17.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Create a route',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                SizedBox(
                  height: mapClicked ? 500 : double.infinity,
                  width: double.infinity,
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _initialCameraPosition,
                      zoom: 13.5,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    onTap: (LatLng pinnedLocation) {
                      _addPin(pinnedLocation);
                      mapClicked = true;
                    },
                  ),
                ),
                Container(
            margin: const EdgeInsets.only(top: 2, left: 5, right: 5),
            padding: const EdgeInsets.only(top: 10, bottom: 3, left: 5),
            height: 37,
            width: double.infinity,
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
            child: Row(
              children: [
                const Icon(Icons.search, size: 20),
                Expanded(
                  child: TextFormField(
                    onTap: () async {
                      final newInitialPosition = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchPage(),
                        ),
                      );

                    //Update the map's camera position if a location was selected
                    if (newInitialPosition != null) {
                      mapController!.animateCamera(
                        CameraUpdate.newLatLng(newInitialPosition['latLng']),
                      );
                      setState(() {
                        selectedLocation = newInitialPosition['name'];
                      });
                    }
                  },
                  readOnly: true, //Make TextFormField non-editable
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      hintText: selectedLocation,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if(_polylines.isNotEmpty && questionIsVisible == false)
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 65),
            // padding: const EdgeInsets.only(top: 5,bottom: 5),
            height: 35,
            width: 234,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFc2d0ff), 
                width: 1.0, 
              ),
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff1D1617).withOpacity(0.11),
                  blurRadius: 4,
                  spreadRadius: 0.2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                
                Flexible(
                  child: TextButton(
                    onPressed: () {
                      _showMapPolylines(context);
                      print('pressed floating');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero, 
                      foregroundColor: const Color(0xff1F41BB),
                    ),
                    child: const Text(
                      'Incorrect line? Click here to edit',
                      style: TextStyle(
                        fontSize: 13,
                        overflow: TextOverflow.ellipsis, 
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (mapClicked)
        DraggableScrollableSheet(
        initialChildSize: sheetSizes[0],
        minChildSize: sheetSizes[1],
        maxChildSize: sheetSizes[2],
        builder: (context, scrollController) {
          final screenHeight = MediaQuery.of(context).size.height;
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom; 
          return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20.0),
        topRight: Radius.circular(20.0),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10.0,
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 5.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (questionIsVisible == false)
                    Row(
                      children: [
                        if (currentPageTracker >= 1)
                          IconButton(
                            onPressed: () async {
                              setState(() {
                                if (currentPageTracker == 0) {
                                    currentPage = 'origin'; 
                                  }
                                  currentPageTracker--;
                                   DataManager().updateCountTracker(currentPageTracker);
                                // if(currentPages[currentPageTracker]== 'walk' && (_walkFormKey.currentState?.validate() ?? false)){
                                //   
                                //   DataManager().updateCountTracker(currentPageTracker);
                                //   print("Form is valid");
                                // }
                                // else if(currentPages[currentPageTracker]== 'ride' && (_rideFormKey.currentState?.validate() ?? false)){
                                //   currentPageTracker--;
                                //   DataManager().updateCountTracker(currentPageTracker);
                                //   print("Form is valid");
                                // }
                                // else {
                                //   print("Form is invalid");
                                // }
                                
                              });
                            },
                            icon: const Icon(Icons.arrow_back, size: 24),
                          ),
                        const Spacer(),
                        if (currentPages.length >= 2 && currentPageTracker < currentPages.length - 1)
                          IconButton(
                            onPressed: () async {
                              setState(() {
                                print('in icons -------------');
                                if(currentPages[currentPageTracker+1] != DataManager().get_nextButton()){
                                  print('need to change');
                                  String page  =currentPages[currentPageTracker+1];
                                  String next = DataManager().get_nextButton()!;
                                  print("in current page: $page - from Data Manager: $next");
                                  changeWidget_for_changedButton(next);
                                }
                                if (currentPages[currentPageTracker]== 'origin' &&(_page1FormKey.currentState?.validate() ?? false)) {
                                    currentPage = 'origin';
                                      currentPageTracker++;
                                      DataManager().updateCountTracker(currentPageTracker);
                                    print("Page 1 is valid");
                                  }
                                else if(currentPages[currentPageTracker]== 'walk' && (_walkFormKey.currentState?.validate() ?? false)){
                                  currentPageTracker++;
                                  DataManager().updateCountTracker(currentPageTracker);
                                  print("Form is valid");
                                }
                                else if(currentPages[currentPageTracker]== 'ride' && (_rideFormKey.currentState?.validate() ?? false)){
                                  currentPageTracker++;
                                  DataManager().updateCountTracker(currentPageTracker);
                                  print("Form is valid");
                                }
                                else {
                                  print("Form is invalid");
                                }
                                
                              });
                            },
                            icon: const Icon(Icons.arrow_forward, size: 24),
                          ),
                      ],
                    ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 50,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      //Adjust the height dynamically based on screen and keyboard
                      height: questionIsVisible ? 80 : screenHeight - keyboardHeight - 350, // Adjust for screen and keyboard
                      child: pages.length > 1 && pages.length - 1 == _markers.length
                          ? question_pages[questionPageTracker]
                          : pages[currentPageTracker],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
          );
        },
      ),
      
                Positioned(
                  top: 45,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: _focusOnLastPinnedLocation,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.location_searching_rounded),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //para se fetching ng decoded polyline then assign it again
  Set<Polyline> polylinesInStep = {};
  Set<Polyline> _convertListToPolyline(){
    if(step_polyline.isNotEmpty){
      List<LatLng>? inStepPolylines = step_polyline[currentPageTracker];
      for(int i = 0; inStepPolylines!.length - 1 > i; i++){
        Polyline polyline = Polyline(
          polylineId: PolylineId('polyline$i'),
          points: [inStepPolylines[i],inStepPolylines[i+1]],
          color: Colors.blue,
          width: 5
        );
        polylinesInStep.add(polyline);
      }
      print(polylinesInStep);
    }
    return polylinesInStep;
  }

  // for editing polyines
  void _showMapPolylines(BuildContext context){
    // print("show map polylines");
    showDialog(
      context: context, 
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20.0),
        insetAnimationCurve: Curves.fastEaseInToSlowEaseOut,
        insetAnimationDuration: const Duration(milliseconds: 300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 450,
          child: MapForPolylines(
            polyline: _convertListToPolyline(),
          ),
        ),
      ));
  }
  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "PIN LOCATION",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.route_outlined,
                size: 100,
                color: Color.fromARGB(255, 151, 175, 255),
              ),
              SizedBox(height: 20),
              Text(
                "Pin the location you want to suggest!",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                // print(data[1]['username']);
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}

class WalkQuestionWidget extends StatefulWidget {
  const WalkQuestionWidget({super.key});

  @override
  State<WalkQuestionWidget> createState() => _WalkQuestionWidgetState();
}

class _WalkQuestionWidgetState extends State<WalkQuestionWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 50, left: 15.0, right: 15.0),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: const Text(
              'Pin your walk destination',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class RideQuestionWidget extends StatefulWidget {
  const RideQuestionWidget({super.key});

  @override
  State<RideQuestionWidget> createState() => _RideQuestionWidgetState();
}

class _RideQuestionWidgetState extends State<RideQuestionWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 50, left: 15.0, right: 15.0),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: const Text(
              'Pin your drop-off location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class Page1 extends StatefulWidget {
  final Function(String) onNewPage;
  final GlobalKey<FormState> formKey;
  // final Function(String) onPlaceNameUpdated;
  const Page1({super.key, required this.onNewPage, required this.formKey});
  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> {
  final _MyWidgetState mainwidget = _MyWidgetState();
  int pagesLength = 0;
  int currentPageCount = 0;
  // StoresheetSizes storesheetSizes = StoresheetSizes();
  final ScrollController _scrollController = ScrollController();
  TextEditingController textOriginController = TextEditingController();
  TextEditingController landmarkController = TextEditingController();
  bool hasNextStep = false;
  String nextButton = '';
  String? temporary_locationName;
  int currentPageTracker = 0;
  bool textOriginIsNotEmpty = false;
  // _Page1State(this._scrollController);

  @override
  void initState() {
    super.initState();
    print('now in page 1');
    temporary_locationName = DataManager().get_temporary_LocationName();
    if (temporary_locationName != null) {
      setState(() {
        textOriginController.text = temporary_locationName!;
        textOriginIsNotEmpty = true;
      });
    }

    //to identify if the textOrigin is empty or not
    textOriginController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          textOriginIsNotEmpty = textOriginController.text.isNotEmpty;
          //print(textOriginIsNotEmpty.toString());
        });
      });
    });

    var valuesInMap = DataManager().get_accessOnValuesInMap();
    if(valuesInMap.length == 2 && valuesInMap[1].length == 5){
      textOriginController.text = valuesInMap[1][3];
      landmarkController.text = valuesInMap[1][4];
      if(DataManager().get_nextButton() != null){
        nextButton = DataManager().get_nextButton()!;
        hasNextStep = true;
      } else {
        hasNextStep = false;
      }
      textOriginController.addListener(saveChangesToDataManager);
      landmarkController.addListener(saveChangesToDataManager);
      // textOriginController.addListener(retrieveChangesFromDM);
    }

    // if(DataManager().get_ExistingStepDetails() != null){
    //   List<dynamic> originDetails = DataManager().get_ExistingStepDetails()!;
    //   //exameple: [locatiion_name,landmark]
    //   setState(() {
    //       landmarkController.text = originDetails[1];
    //       textOriginController.text = originDetails[0];

    //   });
    // }
    // if(DataManager().getStepsMap().length > 1){
    //   List<dynamic> stepDetails = DataManager().getValueInStepsMap();
    //   // example:  [origin, [RVHR+F5H,Guiguinto, Central Luzon, 14.828484319502026, 120.89096836745739], [fre, ss]]
    //   print('Page 1 - getStepsMap: $stepDetails');
    //   if(stepDetails.length == 3){
    //     setState(() {
    //       landmarkController.text = stepDetails[2][1];
    //       textOriginController.text = stepDetails[2][0];
    //       nextButton = DataManager().getStepsMap()[DataManager().getCurrentPageTracker() +1]![0];
    //       print('next Button: $nextButton');
    //       hasNextStep = true;

    //     });
    //     textOriginController.addListener((){
    //       DataManager().getValueInStepsMap()[2][0] = textOriginController.text;
    //     });
    //     landmarkController.addListener((){
    //       DataManager().getValueInStepsMap()[2][1] = landmarkController.text;
    //     });

    //     //get the next step for the button

    //   }
    // }

    //  if(mainwidget.getTermporary_LocationName() != ''){
    // print('tempo location is not empty');
    //   textOriginController.text = mainwidget.getTermporary_LocationName();
    // }
  }

  // void change_locationName_By_MapClick(String newlocation){
  //   setState(() {
  //     textOriginController.text = newlocation;
  //     print("Change loc name: ${textOriginController.text}");
  //   });
  // }
  void saveChangesToDataManager(){
    DataManager().getStepsInformation()[1][3] = textOriginController.text;
    DataManager().getStepsInformation()[1][4] = landmarkController.text;

  }

  // NOT YET IMPLEMENTED!!
  void updateLocationName_basedOnTap(String locationname) {
    setState(() {
      textOriginController.text = locationname;
    });
  }

  void addToDataManager() {
    // DataManager().addOriginInformation(textOriginController.text,landmarkController.text);
    DataManager().insert_LocationNameLandmark(textOriginController.text,landmarkController.text);
    
  }

  void clearAll() {
    landmarkController.clear();
    textOriginController.clear();
  }

  void onClick_check(String buttonname) {
    if (widget.formKey.currentState?.validate() ?? false) {
      addToDataManager();
      widget.onNewPage(buttonname);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: const Text(
                        'What is this location called?',
                        style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0,right: 15.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: Form(
                      key: widget.formKey,
                      child: TextFormField(
                        controller: textOriginController,
                        maxLength: 50,
                        maxLines: 1,
                        minLines: 1,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 15),
                          hintText: 'Type here...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(255, 255, 255, 255),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(255, 76, 174, 255),
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the location name';
                          }
                          return null;  // You can add more validations as needed
                          },
                          style: const TextStyle(fontSize: 14),
                      ),
                      ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only( top:8.0, bottom: 8.0, left: 15),
                      child: Text(
                        'Landmark:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ),
                  const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left:15.0, right: 15.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: TextFormField(
                      controller: landmarkController,
                      maxLength: 50,
                      maxLines: 1,
                      minLines: 1,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10),
                        hintText: 'Optional',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 255, 255, 255),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 76, 174, 255),
                            width: 2,
                          ),
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),            
                  ),
                ),
                        const SizedBox(height: 10),
                    
                    //  if(textOriginIsNotEmpty)
                    Column(
                      children: [hasNextStep
                        ? Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.only(left: 20.0),
                              alignment: Alignment.centerLeft,
                              child: const Text(
                                'Next Step:',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(left: 10, right: 5),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    if (nextButton == 'walk') {
                                      nextButton = 'ride';
                                    }
                                    // else if(nextButton == 'ride'){
                                    //   nextButton = 'done';
                                    // }
                                    else if (nextButton == 'ride') {
                                      nextButton = 'walk';
                                    }
                                    DataManager().updateNextButton(nextButton);
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor:
                                      const Color.fromARGB(255, 99, 131, 249),
                                  minimumSize: const Size(131, 26),
                                ),
                                child: Text(nextButton),
                              ),
                            ),
                            const Row(
                              children: [
                                Text(
                                  '(',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 22,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Tap to change',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w100,
                                      ),
                                    ),
                                    Text(
                                      'step',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w100,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 5),
                                Text(
                                  ')',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 22,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            )
                          ],
                        )
                      : Column(
                          children: [
                            if (textOriginIsNotEmpty)
                              Container(
                                padding: const EdgeInsets.only(left: 20.0),
                                alignment: Alignment.centerLeft,
                                child: const Text(
                                  'What is the first step?',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (textOriginIsNotEmpty)
                              Row(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(
                                        left: 20,
                                        right: 5,
                                        top: 10,
                                        bottom: 10),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        onClick_check('walk');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor:
                                            const Color(0xff1F41BB),
                                        minimumSize: const Size(131, 26),
                                      ),
                                      child: const Text('Walk'),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(
                                        left: 20,
                                        right: 5,
                                        top: 10,
                                        bottom: 10),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        onClick_check('ride');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor:
                                            const Color(0xff1F41BB),
                                        minimumSize: const Size(131, 26),
                                      ),
                                      child: const Text('Ride'),
                                    ),
                                  )
                                ],
                              )
                          ],
                        ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class WalkWidget extends StatefulWidget {
  final Function(String) onNewPage;
  final GlobalKey<FormState> formKey;
  const WalkWidget({super.key, required this.onNewPage, required this.formKey});

  @override
  _WalkWidgetState createState() => _WalkWidgetState();
}

class _WalkWidgetState extends State<WalkWidget> {
  final _MyWidgetState mainwidget = _MyWidgetState();
  late int pagesLength;
  late int currentPageCount;
  final ScrollController scrollController = ScrollController();
  // List <TextEditingController> locationName_controllers =[];
  // List <TextEditingController> landmarkName_controllers =[];
  // List <TextEditingController> instructions_controllers =[];
  Map<int, List<TextEditingController>> controllers = {};
  TextEditingController locationName_controller = TextEditingController();
  TextEditingController landmarkName_controller = TextEditingController();
  TextEditingController instructions_controller = TextEditingController();
  bool allIsNotEmpty = false;
  // bool instructionsIsNotEmpty = false;
  bool numberIsEqual = true;
  String nextButton = '';
  String? temporary_locationName;
  bool hasNextStep = false;

  // void addNewController(){
  //   TextEditingController locationName_controller = TextEditingController();
  //   TextEditingController landmarkName_controller = TextEditingController();
  //   TextEditingController instructions_controller = TextEditingController();
  //   locationName_controllers.add(locationName_controller);
  //   landmarkName_controllers.add(landmarkName_controller);
  //   instructions_controllers.add(instructions_controller);
  // }

  @override
  void initState() {
    super.initState();
    temporary_locationName = DataManager().get_temporary_LocationName();
    if (temporary_locationName != null) {
      setState(() {
        locationName_controller.text = temporary_locationName!;
        allIsNotEmpty = true;
      });
    }
    locationName_controller.addListener(notEmptyChecker);
    instructions_controller.addListener(notEmptyChecker);

    var valuesInMap = DataManager().get_accessOnValuesInMap();
    if(valuesInMap.length == 3){
      locationName_controller.text = valuesInMap[1][3];
      landmarkName_controller.text = valuesInMap[1][4];
      instructions_controller.text = valuesInMap[2][0];
      if(DataManager().get_nextButton() != null){
        nextButton = DataManager().get_nextButton()!;
        hasNextStep = true;
      } else {
        hasNextStep = false;
      }
      locationName_controller.addListener(saveChangesToDataManager);
      landmarkName_controller.addListener(saveChangesToDataManager);
      instructions_controller.addListener(saveChangesToDataManager);
    }
    //  int currentTracker = DataManager().getCurrentPageTracker();
    //  if(controllers.containsKey(currentTracker)){
    //   print('existing texteditor');
    //  }
    //  else{
    //   controllers[currentTracker] = [TextEditingController(),TextEditingController(),TextEditingController()];
    //   print('new texteditor');
    //  }
    // //  controllers[currentTracker]![0].addListener(notEmptyChecker);
    // //  controllers[currentTracker]![1].addListener(notEmptyChecker);
    //  locationName_controller = controllers[currentTracker]![0];
    //  landmarkName_controller = controllers[currentTracker]![1];
    //  instructions_controller = controllers[currentTracker]![2];

    //  locationName_controller!.addListener(notEmptyChecker);
    //  instructions_controller!.addListener(notEmptyChecker);
    //  var stepDetails = DataManager().getStepsInformation();
    //  if(stepDetails.length == 3){
    //   print('step Details is not empty');
    //   setState(() {
    //     locationName_controller.text = stepDetails[2][0];
    //     landmarkName_controller.text = stepDetails[2][1];
    //     instructions_controller.text = stepDetails[2][2];
    //   });
    //  }
    //  else{
    //   print('Step details is empty');
    //  }
  }
  void saveChangesToDataManager(){
    DataManager().getStepsInformation()[1][3] = locationName_controller.text;
    DataManager().getStepsInformation()[1][4] = landmarkName_controller.text;
    DataManager().getStepsInformation()[2][0] = instructions_controller.text;

  }

  void notEmptyChecker() {
    setState(() {
      allIsNotEmpty = locationName_controller.text.isNotEmpty &&
          instructions_controller.text.isNotEmpty;
      // if(DataManager().getStepsMap().containsKey(DataManager().getCurrentPageTracker()) &&allIsNotEmpty){
      // }
    });
  }

  @override
  void dispose() {
    locationName_controller.dispose();
    instructions_controller.dispose();
    landmarkName_controller.dispose();
    super.dispose();
  }

  // void clearAll(){
  //   locationName_controller.clear();
  //   instructions_controller.clear();
  //   landmarkName_controller.clear();
  // }
  void insertToDataManager(){
    DataManager().insert_LocationNameLandmark(locationName_controller.text,landmarkName_controller.text);
    DataManager().insertStepData([instructions_controller.text]);
  }
  // void updateState(bool numberisequal){

  //     numberIsEqual = numberisequal;

  // }
  void onClick_check(String buttonname) {
    if (widget.formKey.currentState?.validate() ?? false) {
      insertToDataManager();
      widget.onNewPage(buttonname);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
          child: Form(
            key: widget.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location Name:',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  height: 47,
                  child: TextFormField(
                    controller: locationName_controller,
                    maxLength: 50,
                    maxLines: 1,
                    minLines: 1,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 15),
                      hintText: 'Type here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 255, 255, 255),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 76, 174, 255),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the location name';
                      }
                      return null;  // You can add more validations as needed
                      },
                      style: const TextStyle(fontSize: 12),
                  ),
                ),
                const Text(
                  'Landmark:',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  height: 47,
                  child: TextFormField(
                    controller: landmarkName_controller,
                    maxLength: 50,
                    maxLines: 1,
                    minLines: 1,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      hintText: 'Optional',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 255, 255, 255),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 76, 174, 255),
                          width: 2,
                        ),
                      ),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),            
                ),
                const Text(
                  'Instructions:',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                TextFormField(
                  controller: instructions_controller,
                  maxLength: 100,
                  maxLines: 2,
                  minLines: 1,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                    vertical: 5, horizontal: 15),
                    hintText: 'Type here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 255, 255, 255),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 76, 174, 255),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter instructions';
                    }
                    return null; // You can add more validations as needed
                  },
                style: const TextStyle(fontSize: 12),
                ),
                Column(
                  children: [hasNextStep
                  ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 20.0),
                      alignment: Alignment.centerLeft,
                      child: const Text(
                       'Next Step:',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 10, right: 5),
                      child: ElevatedButton(
                      onPressed: (){
                        setState(() {
                          if(nextButton == 'walk'){
                            nextButton = 'ride';
                           }
                           else if(nextButton == 'ride'){
                            nextButton = 'done';
                           }
                            else if(nextButton == 'done'){
                            nextButton = 'walk';
                           }
                           DataManager().updateNextButton(nextButton);
                        });
                        },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color.fromARGB(255, 99, 131, 249),
                            minimumSize: const Size(131, 26), 
                            ),
                          child: Text(nextButton),
                          ),
                        ),
                        const Row(
                          children: [
                              Text(
                              '(',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            SizedBox(width: 5),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Tap to change',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w100,
                                  ),
                                ),
                                Text(
                                  'step',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w100,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 5),
                            Text(
                              ')',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        )
                                
                      ],
                   )
                  : Column(
                    children: [
                      if (allIsNotEmpty)
                      Container(
                        padding: const EdgeInsets.only(left: 6.0),
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
                      if (allIsNotEmpty)
                      Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(
                              right: 5),
                            child: ElevatedButton(
                              onPressed: () {
                                onClick_check('walk');
                                
                                // clearAll();
                                
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xff1F41BB),
                                minimumSize: const Size(100, 26),
                              ),
                              child: const Text('Walk'),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(
                                left: 5, right: 5),
                            child: ElevatedButton(
                              onPressed: () {
                                onClick_check('ride');
                                // clearAll();
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xff1F41BB),
                                minimumSize: const Size(100, 26),
                              ),
                              child: const Text('Ride'),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(
                                left: 5, right: 5),
                            child: ElevatedButton(
                              onPressed: () {
                                insertToDataManager();
                                DialogPopUp()._showDoneDialog(context);
                                // clearAll();
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xff1F41BB),
                                minimumSize: const Size(100, 26),
                              ),
                              child: const Text('Done'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),             
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RideWidget extends StatefulWidget {
  final Function(String) onNewPage;
  final GlobalKey<FormState> formKey;
  const RideWidget({super.key, required this.onNewPage, required this.formKey});

  @override
  State<RideWidget> createState() => _RideWidgetState();
}

class _RideWidgetState extends State<RideWidget> {
  final _MyWidgetState mainwidget = _MyWidgetState();
  final ScrollController scrollController = ScrollController();
  TextEditingController landmarkName_controller = TextEditingController();
  TextEditingController locationName_controller = TextEditingController();
  TextEditingController instructions_controller = TextEditingController();
  TextEditingController fare_controller = TextEditingController();
  bool allIsNotEmpty = false;
  bool instructionsIsNotEmpty = false;
  List<bool> buttonClicked = [true, true, true, true, true];
  String nextButton = '';
  String? temporary_locationName;
  bool hasNextStep = false;
  String? selectedVehicle;
  // final GlobalKey<FormState> rideFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    temporary_locationName = DataManager().get_temporary_LocationName();
    if (temporary_locationName != null) {
      setState(() {
        locationName_controller.text = temporary_locationName!;
        allIsNotEmpty = true;
      });
    }
    locationName_controller.addListener(notEmptyChecker);
    instructions_controller.addListener(notEmptyChecker);
    fare_controller.addListener(notEmptyChecker);

    var valuesInMap = DataManager().get_accessOnValuesInMap();
    if(valuesInMap.length == 3){
      locationName_controller.text = valuesInMap[1][3];
      landmarkName_controller.text = valuesInMap[1][4];
      instructions_controller.text = valuesInMap[2][0];
      if(valuesInMap[2].length == 3){
        fare_controller.text = valuesInMap[2][1];
        selectedVehicle = valuesInMap[2][2];
      }

      regenerateButton();
      print('To widget: $valuesInMap');
      // switch(valuesInMap[2][4]){
      //   case 'Bus':
      //     index = 0; break;
      //   case 'E-jeep':
      //     index = 1; break;
      //   case 'Jeep':
      //     index = 2; break;
      //   case 'Tricycle':
      //     index = 3; break;
      //   case 'UV':
      //     index = 4; break;
      // }
      // for(int i = 0; i<buttonClicked.length; i++){
      //   if(i != index){
      //     buttonClicked[i] = false;
      //   }
      // }
      if (DataManager().get_nextButton() != null) {
        nextButton = DataManager().get_nextButton()!;
        hasNextStep = true;
        print('Button: has next step is true');
      } else {
        hasNextStep = false;
        print('Button: has next step is false');
      }
      locationName_controller.addListener(saveChangesToDataManager);
      landmarkName_controller.addListener(saveChangesToDataManager);
      instructions_controller.addListener(saveChangesToDataManager);
      // instructions_controller.addListener(saveChangesToDataManager);
      if(DataManager().getStepsInformation()[2].length == 3 && selectedVehicle != (DataManager().getStepsInformation()[2][2]) ){
        print('Selected vehicle is not equal to data manager');
        saveChangesToDataManager();
      }
    }

    // if(DataManager().get_ExistingStepDetails() != null){
    //   List<dynamic> originDetails = DataManager().get_ExistingStepDetails()!;
    //   //exameple: [locatiion_name,landmark, instructions,selectedItem]
    //   setState(() {
    //     locationName_controller.text = originDetails[0];
    //     landmarkName_controller.text = originDetails[1];
    //     instructions_controller.text = originDetails[2];
    //     // selectedItem = originDetails[3];

    //     //for displaying the existing next step
    //     if(DataManager().get_nextButton() != null){
    //       nextButton = DataManager().get_nextButton()!;
    //       hasNextStep = true;
    //     }
    //     else{
    //       hasNextStep = false;
    //     }
    //     locationName_controller.addListener((){
    //       DataManager().get_accessOnValuesInMap()[2][0] = locationName_controller.text;
    //     });
    //     landmarkName_controller.addListener((){
    //       DataManager().get_accessOnValuesInMap()[2][1] = locationName_controller.text;
    //     });
    //     instructions_controller.addListener((){
    //       DataManager().get_accessOnValuesInMap()[2][2] = instructions_controller.text;
    //     });
    //     // if(originDetails[3] != selectedItem && selectedItem !=null){
    //     //   originDetails[3] = selectedItem;
    //     // }
    //   });

    // }

    // if(DataManager().stepChecker() == true){
    //   List<dynamic> stepDetails = DataManager().getStepsInformation();
    //   print('fetch ride successful');
    //  print(stepDetails);
    //  if(stepDetails.length == 3){
    //   setState(() {

    //    locationName_controller.text = stepDetails[2][0];
    //    landmarkName_controller.text = stepDetails[2][1];
    //    instructions_controller.text = stepDetails[2][2];
    //    selectedItem = stepDetails[2][3];
    //     nextButton = DataManager().getStepsMap()[DataManager().getCurrentPageTracker() +1]![0];
    //     hasNextStep = true;
    //  });
    //  locationName_controller.addListener((){
    //     setState(() {
    //       DataManager().get_accessOnValuesInMap()[2][0] = locationName_controller.text;
    //     });
    //   });
    //   landmarkName_controller.addListener((){
    //     setState(() {
    //       DataManager().get_accessOnValuesInMap()[2][1] = locationName_controller.text;
    //     });
    //   });
    //   instructions_controller.addListener((){
    //     setState(() {
    //       DataManager().get_accessOnValuesInMap()[2][2] = instructions_controller.text;
    //     });
    //   });
    //   selectedItem =  DataManager().getStepsInformation()[2][3];
    //  }

    // }
  }

  void regenerateButton() {
    int index = 0;
    setState(() {
      switch (selectedVehicle) {
        case 'Bus':
          index = 0;
          break;
        case 'E-jeep':
          index = 1;
          break;
        case 'Jeep':
          index = 2;
          break;
        case 'Tricycle':
          index = 3;
          break;
        case 'UV':
          index = 4;
          break;
      }
      for (int i = 0; i < buttonClicked.length; i++) {
        if (i != index) {
          buttonClicked[i] = false;
        }
      }
    });
  }
  void saveChangesToDataManager(){
    DataManager().getStepsInformation()[1][3] = locationName_controller.text;
    DataManager().getStepsInformation()[1][4] = landmarkName_controller.text;
    DataManager().getStepsInformation()[2][0] = instructions_controller.text;
    DataManager().getStepsInformation()[2][1] = fare_controller.text;
    DataManager().getStepsInformation()[2][2] = selectedVehicle;
    
  }
  void updateButtonInDataManager(){
    if(DataManager().getStepsInformation().length == 3 && DataManager().getStepsInformation()[2].length == 3){
      DataManager().getStepsInformation()[2][2] = selectedVehicle;
    }
  }

  void notEmptyChecker() {
    setState(() {
      allIsNotEmpty = allIsNotEmptyChecker();
    });
  }

  bool allIsNotEmptyChecker() {
    bool _buttonClicked = false;
    int _true = 0;
    for(int x = 0;x < buttonClicked.length; x++){
      if(buttonClicked[x] == true){
       _true++;
      }
    }
    if(true == 1){_buttonClicked = true;}
    print('_buttonClicked: $buttonClicked');
    return locationName_controller.text.isNotEmpty && 
    instructions_controller.text.isNotEmpty && 
    fare_controller.text.isNotEmpty && buttonClicked == true;
    // need pa code dito para sa selection
  }
  void insertToDataManager(){
    DataManager().insert_LocationNameLandmark(locationName_controller.text,landmarkName_controller.text);
    DataManager().insertStepData([instructions_controller.text,fare_controller.text,selectedVehicle]);
  }

  void onClick_check(String buttonname) {
    if (widget.formKey.currentState?.validate() ?? false) {
      insertToDataManager();
      widget.onNewPage(buttonname);
    }
  }

  @override
  void dispose() {
    locationName_controller.dispose();
    landmarkName_controller.dispose();
    instructions_controller.dispose();
    fare_controller.dispose();
    selectedVehicle = '';
    super.dispose();
  }

  void toggleButtonClicked(int index) {
    for (int i = 0; i < buttonClicked.length; i++) {
      if (index == i) {
        buttonClicked[i] = true;
        updateButtonInDataManager();
      } else {
        buttonClicked[i] = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: scrollController,
        child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 15.0,right: 15.0),
                    child: Text(
                      'Mode of Transportation:',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [ 
                        Container(
                          margin: const EdgeInsets.only(
                            right: 5, bottom: 5),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedVehicle = 'Bus';
                                toggleButtonClicked(0);
                              });
                              
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: buttonClicked[0]?const Color(0xff1F41BB):const Color.fromARGB(255, 122, 143, 221),
                              minimumSize: const Size(20, 25),
                            ),
                            child: const Text('Bus',style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                            right: 5, bottom: 5),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedVehicle = 'E-jeep';
                                toggleButtonClicked(1);
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: buttonClicked[1]?const Color(0xff1F41BB):const Color.fromARGB(255, 122, 143, 221),
                              minimumSize: const Size(20, 25),
                            ),
                            child: const Text('E-jeep',style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                            right: 5, bottom: 5),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedVehicle = 'Jeep';
                                toggleButtonClicked(2);
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: buttonClicked[2]?const Color(0xff1F41BB):const Color.fromARGB(255, 122, 143, 221),
                              minimumSize: const Size(20, 25),
                            ),
                            child: const Text('Jeep',style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                            right: 5, bottom: 5),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedVehicle = 'Tricycle';
                                toggleButtonClicked(3);
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: buttonClicked[3]?const Color(0xff1F41BB):const Color.fromARGB(255, 122, 143, 221),
                              minimumSize: const Size(20, 25),
                            ),
                            child: const Text('Tricycle',style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                            right: 5, bottom: 5),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedVehicle = 'UV';
                                toggleButtonClicked(4);
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: buttonClicked[4]?const Color(0xff1F41BB):const Color.fromARGB(255, 122, 143, 221),
                              minimumSize: const Size(20, 25),
                            ),
                            child: const Text('UV',style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15.0,right: 15.0),
                    child: Form(
                      key: widget.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimated Fare:',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: TextFormField(
                              controller: fare_controller,
                              keyboardType: TextInputType.number,  // Set keyboard type for numeric input
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,  // Only allow digits
                              ],
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                hintText: 'Type here...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 76, 174, 255),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the esimated fare';
                                }
                                return null;  // You can add more validations as needed
                              },
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Location Name:',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: double.infinity,
                            height: 47,
                            child: TextFormField(
                              controller: locationName_controller,
                              maxLength: 50,
                              maxLines: 1,
                              minLines: 1,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 15),
                                hintText: 'Type here...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 76, 174, 255),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the location name';
                                }
                                return null;  
                              },
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const Text(
                            'Landmark:',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: double.infinity,
                            height: 47,
                            child: TextFormField(
                              controller: landmarkName_controller,
                              maxLength: 50,
                              maxLines: 1,
                              minLines: 1,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 10),
                                hintText: 'Optional',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 76, 174, 255),
                                    width: 2,
                                  ),
                                ),
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                            
                          ),
                          const Text(
                            'Instructions:',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          TextFormField(
                            controller: instructions_controller,
                            maxLength: 100,
                            maxLines: 2,
                            minLines: 1,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 10),
                              hintText: 'Type here...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 76, 174, 255),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter instructions';
                                }
                                return null;  // You can add more validations as needed
                              },
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    children: [hasNextStep
                    ? Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 20.0),
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'Next Step:',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 10, right: 5),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  if (nextButton == 'walk') {
                                    nextButton = 'ride';
                                  } else if (nextButton == 'ride') {
                                    nextButton = 'done';
                                  } else if (nextButton == 'done') {
                                    nextButton = 'walk';
                                  }
                                  DataManager().updateNextButton(nextButton);
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    const Color.fromARGB(255, 99, 131, 249),
                                minimumSize: const Size(131, 26),
                              ),
                              child: Text(nextButton),
                            ),
                          ),
                          const Row(
                            children: [
                              Text(
                                '(',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              SizedBox(width: 5),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Tap to change',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w100,
                                    ),
                                  ),
                                  Text(
                                    'step',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w100,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 5),
                              Text(
                                ')',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          )
                        ],
                      )
                    : Column(
                        children: [
                          // if (allIsNotEmpty)
                          Container(
                            // margin: const EdgeInsets.only(top: 10.0),
                            padding: const EdgeInsets.only(left: 16.0),
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
                          // if (allIsNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 15.0),
                            child: Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(
                                right: 5),
                              child: ElevatedButton(
                                onPressed: () {
                                  onClick_check('walk');
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color(0xff1F41BB),
                                  minimumSize: const Size(100, 26),
                                ),
                                child: const Text('Walk'),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(
                                  left: 5, right: 5),
                              child: ElevatedButton(
                                onPressed: () {
                                  onClick_check('ride');
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color(0xff1F41BB),
                                  minimumSize: const Size(100, 26),
                                ),
                                child: const Text('Ride'),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(
                                  left: 5, right: 5),
                              child: ElevatedButton(
                                onPressed: () {
                                  insertToDataManager();
                                  DialogPopUp()._showDoneDialog(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color(0xff1F41BB),
                                  minimumSize: const Size(100, 26),
                                ),
                                child: const Text('Done'),
                            ),
                                                    ),
                                                  ],
                                                ),
                          ),
                        ],
                      ),
              ],
            )
          ],
        ),
      ),
    );
  }
  // TextEditingController descriptionController = TextEditingController();
  //  final ScrollController scrollController = ScrollController();
  // bool descriptionTextIsNotEmpty = false;
  // List<String> vehicles = ['tricycle', 'jeep', 'e-jeep', 'bus'];
  // List<String> busCorporations = ['German Espiritu', 'Victory Liner', 'P2P'];
  // List<String> jeepRoutes = [
  //   'Bocaue',
  //   'Lolomboy',
  //   'Balagtas',
  //   'Plaridel',
  //   'Marilao',
  //   'Guiguinto',
  //   'Meycauayan'
  // ];
  // List<String> busRoutes = [
  //   'Balagtas',
  //   'Bulakan',
  //   'Balagtas',
  //   'Plaridel',
  //   'Monumento'
  // ];
  // List<bool> checkboxBusTracker = [];
  // List<bool> checkboxJeepRoutesTracker = [];
  // List<bool> checkboxBusRoutesTracker = [];

  // //int listNumber = 0;

  // String? selectedValue;
  // @override
  // void initState() {
  //   super.initState();
  //   // Initialize the TextEditingController
  //   descriptionController.addListener(() {
  //     WidgetsBinding.instance.addPersistentFrameCallback((_) {
  //       setState(() {
  //         descriptionTextIsNotEmpty = descriptionController.text.isNotEmpty;
  //       });
  //     });
  //   });
  //   _generateJeepRoutesTracker();
  //   _generateBusCorpTracker();
  //   _generateBusRoutesTracker();
  // }

  // void _generateJeepRoutesTracker() {
  //   for (int i = 0; i < jeepRoutes.length; i++) {
  //     checkboxJeepRoutesTracker.add(false);
  //   }
  // }

  // void _generateBusCorpTracker() {
  //   for (int i = 0; i < busCorporations.length; i++) {
  //     checkboxBusTracker.add(false);
  //   }
  // }

  // void _generateBusRoutesTracker() {
  //   for (int i = 0; i < busRoutes.length; i++) {
  //     checkboxBusRoutesTracker.add(false);
  //   }
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: SingleChildScrollView(
  //       controller: scrollController,
  //       child: Padding(
  //         padding: const EdgeInsets.all(5.0),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Container(
  //               alignment: Alignment.center,
  //               margin: const EdgeInsets.only(top: 10),
  //               child: Container(
  //                 width: 60,
  //                 height: 6,
  //                 decoration: BoxDecoration(
  //                   color: Colors.grey,
  //                   borderRadius: BorderRadius.circular(3),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 10),
  //             Row(
  //               children: [
  //                 IconButton(
  //                   icon: const Icon(Icons.arrow_back),
  //                   onPressed: () {
  //                     //widget.onPop();
  //                     //widget.onSubmit(descriptionController.text);
  //                     Navigator.pop(context);
  //                   },
  //                 ),
  //                 const Text(
  //                   'Ride',
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             Container(
  //               alignment: Alignment.center,
  //               padding: const EdgeInsets.symmetric(vertical: 5.0),
  //               child: const Text(
  //                 'Pin your ride destination',
  //                 style: TextStyle(
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //                 textAlign: TextAlign.center,
  //               ),
  //             ),
  //             const SizedBox(height: 12),
  //             // const Padding(
  //             //   padding: EdgeInsets.only(left: 15.0),
  //             //   child:  Text('Description:',
  //             //   style: TextStyle(
  //             //     color: Colors.black,
  //             //     fontSize: 12,
  //             //     fontWeight: FontWeight.w600,
  //             //   ),),
  //             // ),
  //             // const SizedBox(height: 10),
  //             // Padding(
  //             //   padding: const EdgeInsets.only(left: 10.0, right: 10.0),
  //             //   child: TextFormField(
  //             //     controller: descriptionController,
  //             //     maxLength: 100,
  //             //     maxLines: 2,
  //             //     minLines: 1,
  //             //     decoration: InputDecoration(
  //             //       filled: true,
  //             //       fillColor: Colors.white,
  //             //       contentPadding:
  //             //           const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
  //             //       hintText: 'Type here...',
  //             //       border: OutlineInputBorder(
  //             //         borderRadius: BorderRadius.circular(5),
  //             //         borderSide: const BorderSide(
  //             //           color: Color.fromARGB(255, 255, 255, 255),
  //             //           width: 1.5,
  //             //         ),
  //             //       ),
  //             //       focusedBorder: OutlineInputBorder(
  //             //         borderRadius: BorderRadius.circular(5),
  //             //         borderSide: const BorderSide(
  //             //           color: Color.fromARGB(255, 76, 174, 255),
  //             //           width: 2,
  //             //         ),
  //             //       ),
  //             //     ),
  //             //   ),
  //             // ),
  //             const Padding(
  //               padding: EdgeInsets.only(left: 15.0),
  //               child: Text(
  //                 'Mode of Transportation:',
  //                 style: TextStyle(
  //                   color: Colors.black,
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //             ),
  //             Container(
  //               padding: const EdgeInsets.only(left: 20, right: 160),
  //               alignment: Alignment.centerLeft,
  //               child: DropdownButtonFormField<String>(
  //                 value: selectedValue,
  //                 hint: const Text('Select mode',style: TextStyle(fontSize: 13)),
  //                 // isExpanded: true,
  //                 items: vehicles.map((String item) {
  //                   return DropdownMenuItem<String>(
  //                     value: item,
  //                     child: Text(item,style: const TextStyle(fontSize: 13)));
  //                 }).toList(),
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     selectedValue = newValue;
  //                   });
  //                 },
  //                 // underline: Container(
  //                 //   height: 2,
  //                 //   color: Colors.blue,
  //                 // ),
  //               ),
  //             ),
  //             const SizedBox(height: 12),
  //             if(selectedValue == 'bus')
  //             Column(
  //               children: [
  //                 Container(
  //                   padding: const EdgeInsets.only(left: 16.0),
  //                   alignment: Alignment.centerLeft,
  //                   child: const Text(
  //                     'Bus Name: ',
  //                     style: TextStyle(
  //                       color: Colors.black,
  //                       fontSize: 12,
  //                       fontWeight: FontWeight.w600,
  //                     ),
  //                   ),
  //                 ),
  //                 Wrap(
  //                 spacing: 8.0,
  //                 runSpacing: 0.0,
  //                 children: List.generate(busCorporations.length, (index) {
  //                   return SizedBox(
  //                     width: MediaQuery.of(context).size.width / 2 - 16,
  //                     child: Row(
  //                       children: [
  //                         Checkbox(
  //                           value: checkboxBusTracker[index],
  //                           onChanged: (bool? value) {
  //                             setState(() {
  //                               checkboxBusTracker[index] = value ?? false;
  //                             });
  //                           },
  //                         ),
  //                         Text(
  //                           busCorporations[index],
  //                           style: const TextStyle(fontSize: 12),
  //                         ),
  //                       ],
  //                     ),
  //                   );
  //                 }),
  //               ),
  //               Container(
  //                   padding: const EdgeInsets.only(left: 16.0),
  //                   alignment: Alignment.centerLeft,
  //                   child: const Text(
  //                     'Bus Route: ',
  //                     style: TextStyle(
  //                       color: Colors.black,
  //                       fontSize: 12,
  //                       fontWeight: FontWeight.w600,
  //                     ),
  //                   ),
  //                 ),
  //               Wrap(
  //               spacing: 8.0,
  //               runSpacing: 0.0,
  //               children: List.generate(busRoutes.length, (index) {
  //                 return SizedBox(
  //                   width: MediaQuery.of(context).size.width / 2 - 16,
  //                   child: Row(
  //                     children: [
  //                       Checkbox(
  //                         value: checkboxBusRoutesTracker[index],
  //                         onChanged: (bool? value) {
  //                           setState(() {
  //                             checkboxBusRoutesTracker[index] = value ?? false;
  //                           });
  //                         },
  //                       ),
  //                       Text(
  //                         busRoutes[index],
  //                         style: const TextStyle(fontSize: 12),
  //                       ),
  //                     ],
  //                   ),
  //                 );
  //               }),
  //             )

  //               ],
  //             ),
  //             if(descriptionTextIsNotEmpty)
  //             Column(
  //               children: [
  //                 Container(
  //                   padding: const EdgeInsets.only(left: 16.0),
  //                   alignment: Alignment.centerLeft,
  //                   child: const Text(
  //                     'What is the next step?',
  //                     style: TextStyle(
  //                       color: Colors.black,
  //                       fontSize: 12,
  //                       fontWeight: FontWeight.w600,
  //                     ),
  //                   ),
  //                 ),
  //                 Row(
  //                   children: [
  //                     Container(
  //                         margin: const EdgeInsets.only(
  //                             left: 15, right: 5, top: 10, bottom: 10),
  //                         child: ElevatedButton(
  //                           onPressed: () {
  //                             widget.onNewPage('walk');
  //                           },
  //                           style: ElevatedButton.styleFrom(
  //                             foregroundColor: Colors.white,
  //                             backgroundColor: const Color(0xff1F41BB),
  //                             minimumSize: const Size(100, 26),
  //                           ),
  //                           child: const Text('Walk'),
  //                         ),
  //                       ),
  //                       Container(
  //                         margin: const EdgeInsets.only(
  //                             left: 5, right: 5, top: 10, bottom: 10),
  //                         child: ElevatedButton(
  //                           onPressed: () {
  //                             widget.onNewPage('ride');
  //                           },
  //                           style: ElevatedButton.styleFrom(
  //                             foregroundColor: Colors.white,
  //                             backgroundColor: const Color(0xff1F41BB),
  //                             minimumSize: const Size(100, 26),
  //                           ),
  //                           child: const Text('Ride'),
  //                         ),
  //                       ),
  //                       Container(
  //                         margin: const EdgeInsets.only(
  //                             left: 5, right: 5, top: 10, bottom: 10),
  //                         child: ElevatedButton(
  //                           onPressed: () {
  //                             Navigator.of(context).pushNamed('/done');
  //                           },
  //                           style: ElevatedButton.styleFrom(
  //                             foregroundColor: Colors.white,
  //                             backgroundColor: const Color(0xff1F41BB),
  //                             minimumSize: const Size(100, 26),
  //                           ),
  //                           child: const Text('Done'),
  //                         ),
  //                       ),
  //                 ],
  //                 ),
  //               ],
  //             )
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

class DataManager {
  static final DataManager _instance = DataManager._internal();

  factory DataManager() {
    return _instance;
  }
  DataManager._internal();

  _MyWidgetState mainwidget = _MyWidgetState();
  //"address","landmark","location_name"
  List<String> origin_information = [];
  List<String> destination_information = [];
  List<LatLng> coordinates = []; //list ng coordinates, point A - point B
  LatLng? origin_coordinates;
  LatLng? destination_coordinates;
  String? temporary_LocationName;
  _Page1State page1 = _Page1State();
  void addMarkerCoordinaates(LatLng latlng) {
    marker_coordinates.add(latlng);
  }

  void set_temporary_LocationName(String locationname) {
    temporary_LocationName = locationname;
    // page1.change_locationName_By_MapClick(temporary_LocationName!);
  }

  String? get_temporary_LocationName() {
    return temporary_LocationName;
  }

  void addOriginCoordinates(LatLng latlng, String address) {
    origin_coordinates = latlng;
    if (origin_information.length == 3) {
      //kapag nakapag pin na ng origin tas gusto imodify
      origin_information[0] = address;
    } else {
      //kapag hindi pa nakaoagpin ng origin (first pin)
      origin_information.add(address); //index 0
    }

    if (coordinates.isEmpty) {
      //kapag wala pang pin
      coordinates.add(latlng);
    } else {
      //kapag may pin na
      coordinates[0] = latlng;
    }
  }

  void addOriginInformation(String landmark, String locationName) {
    if (origin_information.length == 3) {
      origin_information[1] = landmark;
      origin_information[2] = locationName;
    } else {
      origin_information.add(landmark);
      origin_information.add(locationName);
    }
    print(origin_information);
    print(origin_coordinates);
  }

  // return of texts sa origin page
  List<String> getOriginInformation() {
    // return [landmark,location]
    return origin_information;
  }

  // checks if nageexist ba  yung current step number
  bool stepChecker() {
    print('stepChecker:');
    print(stepsMap.containsKey(stepNumber));
    return stepsMap.containsKey(stepNumber);
  }

  void changeStep(int index, String step) {
    if (stepsMap.containsKey(index)) {
      stepsMap[index]![0] = step;
      print('success changeStep in DataManager(): $stepsMap[index]');
    } else {
      print('change unsuccessful [DataManger]');
    }
  }

  //returns [origin/ride/walk[List...],List[...]]
  List<dynamic> get_accessOnValuesInMap() {
    return stepsMap[stepNumber]!;
  }

  //return stepsMap
  Map<int, List<dynamic>> getStepsMap() {
    return stepsMap;
  }

  int getCurrentPageTracker() {
    print('Data Manager currentPageTracker: $stepNumber');
    return stepNumber;
  }

  //returns texts para sa walk and ride widget(situation: during run time or pag napress ang back or forward)
  List<dynamic> getStepsInformation() {
    print('getStepsInformation:');
    print(stepsMap[stepNumber]!);
    return stepsMap[stepNumber]!;
  }

  // _WalkWidgetState walkwidget = _WalkWidgetState();
  final Set<LatLng> marker_coordinates = {};
  Map<int, List<dynamic>> stepsMap = {};
  int stepNumber = 0;

  List<dynamic> getValueInStepsMap() {
    return stepsMap[stepNumber]!;
  }

  // void insertTemporaryLocationName(String placename){
  //   List<dynamic> forLocationDetails = [];
  //     List<dynamic> forStepDetails = [placename];
  //   if(stepsMap[stepNumber]!.length == 1){
  //     //means wala pa laman ex. {walk}

  //     stepsMap[stepNumber]!.add(forLocationDetails);
  //     stepsMap[stepNumber]!.add(forStepDetails);
  //   }
  //   else if(stepsMap[stepNumber]!.length == 2){
  //     //means meron ng laman yung step ex. {walk,[locationDetails]}
  //     stepsMap[stepNumber]!.add(forStepDetails);
  //   }
  //   else{
  //     //means meron ng lahat ex. {walk,[locationDetails],[stepDetails]}
  //      stepsMap[stepNumber]![2][0] = placename;
  //   }
  // }

  // this is to add step details:
  // Walk:[locatio_name,landmark,instructions]
  //Ride"[location_name,landmark,instructions,fare,mode of transpo]
  void insertStepData(List<dynamic> stepData) {
    print("{add step data to Data Manager}");
    print("Data to be inserted:$stepData");
    if (stepsMap.containsKey(stepNumber)) {
      stepsMap[stepNumber]!.add(stepData);
      print("step data added successfully to stepsMap in database");
      print("Update: $stepsMap");
    }
    else{
      print("!!!!!!!!!!!adding step data to stepsMap in Data Manager was unsuccessful");
    }
  }
  void insertStepLocationData(int stepNumber, String step, List<dynamic> locationData){
  if(stepsMap.containsKey(stepNumber)){
    //if momodify lang yung pin and complete na yung steps
    //location data: [address, lat,long]
    stepsMap[stepNumber]![0] = step;
    stepsMap[stepNumber]![1][0] = locationData[0];
    stepsMap[stepNumber]![1][1] = locationData[1];
    stepsMap[stepNumber]![1][2] = locationData[2];
    

  }
  else{
    //if new
    stepsMap[stepNumber] = [step, locationData];
  }
     //locationData:[walk/ride,[location data: address,long,lat]]
    print('add existing/new location data to stepsMap in Data Manager');
    print('Update: $stepsMap');
  }
  void insert_LocationNameLandmark(String locationName, String landmark){
    if(stepsMap.containsKey(stepNumber)){
      if(stepsMap[stepNumber]![1].length == 5){
        stepsMap[stepNumber]![1][3] = locationName;
        stepsMap[stepNumber]![1][4] = landmark;
      }else{
        stepsMap[stepNumber]![1].add(locationName);
        stepsMap[stepNumber]![1].add(landmark);

      }
    }
    else{
      print('!!!!!!!!error adding location name and landmark');
    }
  }
  Future<void> updateCountTracker(int currentpagetracker) async{
    stepNumber = currentpagetracker;
    print("Update CountTracker: $stepNumber");
  }

  List? get_ExistingStepDetails() {
    print('try to fetch data');
    if (stepsMap.containsKey(stepNumber)) {
      if (stepsMap[stepNumber]!.length == 3) {
        print(stepNumber);
        print("fetched data: ${stepsMap[stepNumber]![2]}");
        print('fetching data was successful');
        print('update:$stepsMap');
        return stepsMap[stepNumber]![2];
      } else {
        print("error fetching data");
      }
    } else {
      return null;
    }
    return null;
  }

  String? get_nextButton() {
    if (stepNumber < stepsMap.length) {
      return stepsMap[stepNumber + 1]![0];
    } else {
      return null;
    }
  }

  void updateNextButton(String nextbutton) {
    stepsMap[stepNumber + 1]![0] = nextbutton;
    print('update: $stepsMap');
    //mainwidget.changeWidget_for_changedButton(stepsMap[stepNumber+1]![0]);
    //print("passed to man widget");
  }

  List<int> getCountTrackers() {
    //this will return currentpagetracker and stepsmap length
    print(stepNumber);
    print(stepsMap.length);
    return [stepNumber, stepsMap.length];
  }

  // void insertStep(int stepnum, dynamic value){

  //   // {step number, [walk/ride, (step info)]}

  //   //di pa nagexist yung step
  //   if(!stepsMap.containsKey(stepnum)){
  //     stepsMap[stepnum]!.add(value);
  //   }
  //   //if existing na yung info
  //   else{
  //     //temporary list (a way to access the list inside the map)
  //     List<dynamic> stepInfo = stepsMap[stepnum]!;

  //     //walk: walk,landmark,location_name,address,point b
  //     if(stepInfo[0] == 'walk'){
  //      //change value of an existing value
  //     }
  //     else if(stepInfo[0] == 'ride'){
  //       //change value of an existing value
  //     }

  //   }
  // }

  
Map<int,List<LatLng>> polyline_points_map = {};
Map<int,List<LatLng>> polyline_points = {};
// okay na polylines, storing na
void insert_decodedPolyline_ToDM(List<LatLng> polylinepoints){
  polyline_points_map[stepNumber] = polylinepoints;
  print("needed polyline points added to DM");
  print('update neeeded polyline points: $polyline_points_map');
  // print(polyline_points_map.length);
  // if(polyline_points_map.containsKey(stepNumber) && polyline_points_map.isNotEmpty && polyline_points_map.length > stepNumber -1){
  //   // this is to update the next point from current point
  //   polyline_points_map[stepNumber+1]![0] = polylinepoints[1];
  //   if(stepNumber > 0){
  //     // this is to update previous point from the current point
  //     int lengthOfList = polyline_points_map[stepNumber-1]!.length;//get the length of the list<LatLng>
  //     polyline_points_map[stepNumber-1]![lengthOfList-1] = polylinepoints[0];
  //   }
  // }
  // print('Polyline points: $polyline_points_map');
}
Map<int, List<LatLng>> step_midpoints = {};
void insert_midpoint(int pageTracker, List<LatLng> midpoint, bool notChanged){
  if(notChanged){
    step_midpoints[pageTracker] = midpoint;
  }
  else{
    // if changed, galing sa mapForPolylines
    mainwidget.updatePolylineFromChange(midpoint);
    // midpoint.removeAt(0);
    // midpoint.removeLast();
    step_midpoints[pageTracker] = midpoint;

    //update polyline
  }
  
  print('insert midpoint: $step_midpoints');
}
void insert_AllDecodedPolyline_ToDM(List<LatLng> polylinepoints){
  polyline_points[stepNumber] = polylinepoints;
  print("needed polyline points added to DM");
  print('update All Polylines Points: $polyline_points');

}
List<LatLng> get_AllDecodedPolylines(){
  return polyline_points[stepNumber]!;
}
void insertDetailsToDB() async {
  List<dynamic> origin = stepsMap.entries.first.value[1];
  List<dynamic> destination = stepsMap.entries.last.value[1];

  String url = "https://rutaco.online/insert_userRouteSuggestion.php";

  // Prepare origin and destination data
  Map<String, String> originData = {
    'landmark': origin[4],
    'location_name': origin[3],
    'address': origin[0],
    'longitude': origin[1].toString(),
    'latitude': origin[2].toString(),
    'user_id': '1', 
    'location_type_id': '3', 
  };

  Map<String, String> destinationData = {
    'destination_landmark': destination[4],
    'destination_location_name': destination[3],
    'destination_address': destination[0],
    'destination_longitude': destination[1].toString(),
    'destination_latitude': destination[2].toString(),
    'user_id': '1', 
    'location_type_id': '3', 
  };

  // convert stepsMap to JSON format
  Map<String, dynamic> stringKeyStepsMap = stepsMap.map((key, value) {
    return MapEntry(key.toString(), value);
  });
  for (var key in stringKeyStepsMap.keys) {
    var stepData = stringKeyStepsMap[key];
    if (stepData[1] is List) {
      stepData[1] = stepData[1].map((item) => item.toString()).toList();
    }
    if (stepData.length > 2 && stepData[2] is List) {
      stepData[2] = stepData[2].map((item) => item.toString()).toList();
    }
  }
  Map<String, dynamic> stringKeyStepsPoly = step_midpoints.map((key, value) {
    return MapEntry(key.toString(), value);
  });
  for (var key in stringKeyStepsPoly.keys) {
    var stepData = stringKeyStepsPoly[key];
    if (stepData[1] is List) {
      stepData[1] = stepData[1].map((item) => item.toString()).toList();
    }
    if (stepData.length > 2 && stepData[2] is List) {
      stepData[2] = stepData[2].map((item) => item.toString()).toList();
    }
  }
//  List<List<double>> convert_polylinePointsLatitudeJson(Map<int, List<LatLng>> map) {
//   List<List<double>> latitudesList = [];
//   // List<List<double>> longitudesList = [];

//   map.values.forEach((points) {
//     List<double> latitudes = [];
//     // List<double> longitudes = [];

//     for (var latLng in points) {
//       latitudes.add(latLng.latitude);
//       // longitudes.add(latLng.longitude);
//     }

//     latitudesList.add(latitudes);
//     // longitudesList.add(longitudes);
//   });

//   return latitudesList;
// }
// List<List<double>> convert_polylinePointsLongitudeJson(Map<int, List<LatLng>> map) {
//   // List<List<double>> latitudesList = [];
//   List<List<double>> longitudesList = [];

//   map.values.forEach((points) {
//     // List<double> latitudes = [];
//     List<double> longitudes = [];

//     for (var latLng in points) {
//       longitudes.add(latLng.longitude);
      
//     }

//     // latitudesList.add(latitudes);
//     longitudesList.add(longitudes);
//   });

//   return longitudesList;
// }



//   Map<int, List<Map<String, String>>> convert_polylinePointsJson(Map<int, List<LatLng>> map) {
//   return map.map((key, value) {
//     return MapEntry(
//       key,
//       value.map((latLng) {
//         return {
//           'longitude': latLng.longitude.toString(),
//           'latitude': latLng.latitude.toString(),
//         };
//       }).toList(),
//     );
//   });
// }

  try {
    String stepsMapJson = jsonEncode(stringKeyStepsMap);
    String stepspolyMap = jsonEncode(stringKeyStepsPoly);
    // var polylinePointsJson = jsonEncode(convert_polylinePointsJson(polyline_coordinates_map));
    // var polyline_latitudePointsJson = jsonEncode(convert_polylinePointsLatitudeJson(polyline_coordinates_map));
    // var polyline_longitudePointsJson = jsonEncode(convert_polylinePointsLongitudeJson(polyline_coordinates_map));
    
    print(stepsMapJson);
    // print(polyline_latitudePointsJson);
    // print(polyline_longitudePointsJson);
    //try to send origin,destination, and stepsMapJson to php
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {...originData,
       ...destinationData,
       'steps_map': stepsMapJson,
       },
      //  'lat_polyline_points' : polyline_latitudePointsJson,
      //  'long_polyline_points' : polyline_longitudePointsJson},
    );

    if (response.statusCode == 200) {
      print("Data inserted successfully: ${response.body}");
    } else {
      print("Failed to insert data. Error: ${response.reasonPhrase}");
    }
  } catch (e) {
    print("An error occurred: $e");
  }
}
void insertStepsToDB(){

}

}

class DialogPopUp {
  static final DialogPopUp _instance = DialogPopUp._internal();

  factory DialogPopUp() {
    return _instance;
  }
  DialogPopUp._internal();
  void _show_StartDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "PIN ORIGIN LOCATION",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pin_drop_outlined,
                size: 100,
                color: Color.fromARGB(255, 151, 175, 255),
              ),
              SizedBox(height: 10),
              Text(
                "PIN THE ORIGIN",
                style: TextStyle(fontSize: 25),
                textAlign: TextAlign.center,
              ),
               SizedBox(height: 15),
              Text(
                "Pin the origin of the route you that you want to suggest!",
                style: TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                // print(data[1]['username']); 
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
  Future<bool> _show_ExitDialog(BuildContext context) async {
    // Show the exit confirmation dialog and return true or false based on user input
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevents dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Are you sure you want to go back?",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "All the data you've entered will be lost and not saved. Do you want to continue?",
                style: TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(false); // Close dialog with false (don't pop)
              },
            ),
            TextButton(
              child: const Text("Go Back"),
              onPressed: () {
                Navigator.of(context).pop(true); // Close dialog with true (pop the route)
              },
            ),
          ],
        );
      },
    );

    // Return the result, whether the pop should proceed or not
    return result ?? false; // Default to false if null is returned
  }
  
  void _showDoneDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "CONFIRMATION",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.checklist_rounded,
                size: 100,
                color: Color.fromARGB(255, 151, 175, 255),
              ),
              SizedBox(height: 20),
              Text(
                "Click preview to have an overview of your route",
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    // print(data[1]['username']);
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text("Preview"),
                  onPressed: () {
                    // print(data[1]['username']); 
                    Navigator.of(context).pop(); 
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PreviewOfSteps_Class()),
                    );

                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class PreviewOfSteps_Class extends StatefulWidget {
  const PreviewOfSteps_Class({super.key});

  @override
  State<PreviewOfSteps_Class> createState() => _PreviewOfSteps_ClassState();
}

class _PreviewOfSteps_ClassState extends State<PreviewOfSteps_Class> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFc2d0ff),
        title: const Text(
          'Review your route',
          style: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: DataManager().getStepsMap().entries.map((entry){
          return const Padding(
            padding: EdgeInsets.all(15.0),
            child: Row(

            ),
          );
        }).toList(),

        
      )
    );
  }
}




//Walk widget
 // Retrieve existing data for this page from DataManager if it exists
    // var stepDetails = DataManager().get_ExistingStepDetails();
    // if (stepDetails != null && stepDetails.length >= 3) {
    //   // Populate controllers with existing data
    //   locationName_controller.text = stepDetails[0];
    //   landmarkName_controller.text = stepDetails[1];
    //   instructions_controller.text = stepDetails[2];
    // }
    // Add listeners to save data back to DataManager as the user types
    // locationName_controller.addListener(_saveChangesToDataManager);
    // landmarkName_controller.addListener(_saveChangesToDataManager);
    // instructions_controller.addListener(_saveChangesToDataManager);

    // Add listener to check if all fields are filled
   


    // locationName_controller.addListener(notEmptyChecker);
    // instructions_controller.addListener(notEmptyChecker);
  
    // // if(DataManager().stepChecker() == true){
    // //   List<dynamic> stepDetails = DataManager().getStepsInformation();
    // //  print(stepDetails);
    // //  if(stepDetails.length == 3){
    // //   setState(() {
    // //    locationName_controller.text = stepDetails[2][0];
    // //    landmarkName_controller.text = stepDetails[2][1];
    // //    instructions_controller.text = stepDetails[2][2];
    // //  });
    // //  }
     
    // // } 
    // // if(DataManager().getStepsMap()[DataManager().getCountTrackers()[0]]!.length == 3){
    // //   locationName_controller.addListener((){
    // //       DataManager().get_accessOnValuesInMap()[2][0] = locationName_controller.text;
    // //     });
    // //     landmarkName_controller.addListener((){
    // //       DataManager().get_accessOnValuesInMap()[2][1] = locationName_controller.text;
    // //     });
    // //     instructions_controller.addListener((){
    // //       DataManager().get_accessOnValuesInMap()[2][2] = instructions_controller.text;
    // //     });
    // // }
    
    // // //for existing step
    // // if(DataManager().get_ExistingStepDetails() != null){
    // //   List<dynamic> originDetails = DataManager().get_ExistingStepDetails()!;
    // //   //exameple: [locatiion_name,landmark, instructions]
    // //   setState(() {
    // //     locationName_controller.text = originDetails[0];
    // //     landmarkName_controller.text = originDetails[1];
    // //     instructions_controller.text = originDetails[2];
          
    // //     //for displaying the existing next step
    // //     if(DataManager().get_nextButton() != null){
    // //       nextButton = DataManager().get_nextButton()!;
    // //       hasNextStep = true;
    // //     }
    // //     else{
    // //       hasNextStep = false;
    // //     }
        
    // //   });
      
    // // }else{
    // //   print('error fetching data: ${DataManager().get_ExistingStepDetails()}');
    // // }
    // // if(DataManager().getStepsMap().containsKey(DataManager().getCurrentPageTracker())){
    // //   print('contains key = true');
    // //   locationName_controller.clear();
    // //     landmarkName_controller.clear();
    // //     instructions_controller.clear();
    // //     hasNextStep = false;
    // //     nextButton = '';
    // //     print('clear!');
    // //   // if(DataManager().getStepsMap()[DataManager().getCurrentPageTracker()]!.length == 2){
        
    // //   // }
    // //   if(DataManager().getStepsMap().length > DataManager().getCurrentPageTracker()){
    // //   List<dynamic> stepDetails = DataManager().getValueInStepsMap();
    // //   print('step Details: $stepDetails');
    // //   // example:  [walk, [488,Pandi, Central Luzon, 14.852157652293137, 120.94052150845529][kanto,keme, go to kineme]]
    // //   if(stepDetails.length == 3){ //has walk, location details, and step details
    // //     setState(() {
    // //       locationName_controller.text = stepDetails[2][0];
    // //       landmarkName_controller.text = stepDetails[2][1];
    // //       instructions_controller.text = stepDetails[2][2];
    // //       nextButton = DataManager().getStepsMap()[DataManager().getCurrentPageTracker() +1]![0];
    // //       // print('next Button: $nextButton');
    // //       hasNextStep = true;
    // //       print('update!');
          
    // //     });
        
        

    // //     //get the next step for the button

    // //   }
      
    // //   // example:  [walk, [488,Pandi, Central Luzon, 14.852157652293137, 120.94052150845529][kanto,keme, go to kineme]]
    // //   }
    // // }
    // print('walk add - - - - - -- -- - - - ');
    
    // if(DataManager().getStepsMap().containsKey(DataManager().getCurrentPageTracker())){
    //   if(DataManager().getValueInStepsMap().length == 3){
    //     locationName_controller.text = DataManager().get_ExistingStepDetails()![0];
    //     landmarkName_controller.text = DataManager().get_ExistingStepDetails()![1];
    //     instructions_controller.text = DataManager().get_ExistingStepDetails()![2];
    //   }
    // }
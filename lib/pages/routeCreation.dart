import 'dart:core';
import 'package:capstone/pages/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; //use to convert coordinates to address

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
  //AnimationController? _animationController;
  final PageController pageController = PageController();
  TextEditingController textOriginController = TextEditingController();
  final LatLng _initialCameraPosition = const LatLng(14.831582, 120.903786);
  late LatLng currentPinnedLocation;
  bool textOriginIsNotEmpty = false;
  bool mapClicked = false;
  bool showWalkWidget = false;
  int backButtonPressedCount = 0;

  List<LatLng> pinnedLocations = [];
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  final Set<Marker> _originMarker = {};
  int stepNumber = 1;
  //double sheetSize = 0.0;
  List<double> sheetSizes = [0.25, 0.1, 0.25]; //one question sheet size
  // double currentSheetSize = 0.0;
  // final GlobalKey SheetSizeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDialog(context);
    });
    //animation for bottom sheet
    // _animationController = AnimationController(
    //   vsync: this,
    //   duration: Duration(milliseconds: 300),
    //   );
    //   _animationController?.forward();

    //to identify if the textOrigin is empty or not
    textOriginController.addListener(() {
      setState(() {
        textOriginIsNotEmpty = textOriginController.text.isNotEmpty;
        //print(textOriginIsNotEmpty.toString());
      });
    });
  }
  // void getCurrentSheetSize(){
  //   final RenderBox renderBox = SheetSizeKey.currentContext?.findRenderObject() as RenderBox;
  //   final size = renderBox?.size;
  //   setState(() {
  //     currentSheetSize = size?.height ?? 0.0;
  //   });
  // }

//GET ADDRESS OF PINNED LOCATION
  Future<String> _getAddress(LatLng position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        return '${placemark.name},${placemark.locality}, ${placemark.administrativeArea}';
      }
      return 'No address found';
    } catch (e) {
      return 'Error retrieving address';
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _addOrigin(LatLng pinnedLocation) async {
    currentPinnedLocation = pinnedLocation;
    String address = await _getAddress(pinnedLocation);
    setState(() {
      if (_originMarker.isNotEmpty) {
        _originMarker.clear();
      }
      _originMarker.add(Marker(
        markerId: const MarkerId('origin'),
        position: pinnedLocation,
        infoWindow: InfoWindow(
          title: "Origin",
          snippet: address,
        ),
      ));
    });
  }

  void _addMarkerIcon(LatLng pinnedLocation) {
    setState(() {
      if (_markers.length < stepNumber) {
        //add pin to list
        pinnedLocations.add(pinnedLocation);

        //add marker to markers set
        _markers.add(Marker(
          markerId: MarkerId(pinnedLocation.toString()),
          position: pinnedLocation,
          infoWindow: InfoWindow(
            title: "Step $stepNumber",
          ),
        ));
      } else {
        // Marker(
        // markerId: MarkerId(pinnedLocation.toString()),
        // position: pinnedLocation,
        // infoWindow: InfoWindow(
        //   title: "Step $stepNumber",
        // );
      }
//temporary polyline and marker

      //add polyline
      if (pinnedLocations.length > 1) {
        _polylines.add(Polyline(
          polylineId: PolylineId(pinnedLocation.toString()),
          points: pinnedLocations,
          color: Colors.blue,
          width: 5,
        ));
      }
      stepNumber++;
    });
  }

  //animate camera to last pinned location
  void _focusOnLastPinnedLocation() async {
    if (pinnedLocations.isNotEmpty && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(pinnedLocations.last, 14.0),
      );
    }
  }
  // double _getVisibleMapHeight(BuildContext context) {
  //   final screenHeight = MediaQuery.of(context).size.height;
  //   getCurrentSheetSize();
  //   //final bottomSheetVisibleHeight =   currentSheetSize * screenHeight;
  //   return screenHeight - bottomSheetVisibleHeight;
  // }

//MODIFYING BOTTOM SHEET SIZE
  //sheetsize for one quesstion (ex. What is this location called kinemeerut)
  void _fixedSheetSize() {
    // reset to one question size
    sheetSizes[0] = 0.25; //initialSize
    sheetSizes[1] = 0.1; //minChildSize
    sheetSizes[2] = 0.25; //maxChildSize
  }

  bool _sheetSizeForSecondQuestion() {
    if (textOriginIsNotEmpty == true) {
      sheetSizes[0] = 0.3; //initialSize
      sheetSizes[1] = 0.1; //minChildSize
      sheetSizes[2] = 0.3; //maxChildSize
      print(sheetSizes);
    } else {
      _fixedSheetSize();
      print('initial');
      print(sheetSizes);
    }
    return textOriginIsNotEmpty;
  }

  void _goToNextPage() {
    if (backButtonPressedCount == 1) {
      backButtonPressedCount--;
    }
    pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousPage() {
    pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).push(_gotoDashboard());
          },
        ),
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
                  height: mapClicked ? 630 : double.infinity, // Map height
                  width: double.infinity, // Full width of screen
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _initialCameraPosition,
                      zoom: 12.0,
                    ),
                    markers: {..._originMarker, ..._markers},
                    polylines: _polylines,
                    onTap: (LatLng pinnedLocation) {
                      if (pinnedLocations.isEmpty) {
                        _addOrigin(pinnedLocation);
                        print('tap');
                      } else {
                        _addMarkerIcon(pinnedLocation);
                      }
                      mapClicked = true;
                    },
                  ),
                ),
                if (mapClicked)
                  DraggableScrollableSheet(
                    // key: SheetSizeKey,
                    initialChildSize: sheetSizes[0],
                    minChildSize: sheetSizes[1],
                    maxChildSize: sheetSizes[2],
                    builder: (BuildContext context,
                        ScrollController scrollController) {
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
                        child: PageView(
                          controller: pageController, // Use the page controller
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            Column(
                              //fist page
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  child: Container(
                                    width: 60,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: SingleChildScrollView(
                                    controller: scrollController,
                                    child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 20.0),
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
                                          Container(
                                            margin: const EdgeInsets.only(
                                                right: 20.0, left: 20.0),
                                            height: 37,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xff1D1617)
                                                      .withOpacity(0.11),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                //i dont know pa dito, gusto ko kase na pag clinick is magincrease yung size ng sheet, pagisipan ko pa pano maging smooth haha
                                              },
                                              child: TextFormField(
                                                controller:
                                                    textOriginController,
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          vertical: 10,
                                                          horizontal: 15),
                                                  hintText: 'Type here...',
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          // Align(
                                          //   alignment: Alignment.bottomRight,
                                          //   child: IconButton(
                                          //     icon: const Icon(Icons.arrow_forward_rounded),
                                          //     iconSize: 35.0,
                                          //     onPressed: (){

                                          //     },
                                          //   ),
                                          // ),
                                          if (_sheetSizeForSecondQuestion())
                                            Column(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 20.0),
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: const Text(
                                                    'What is the first step?',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              left: 20,
                                                              right: 5,
                                                              top: 10,
                                                              bottom: 10),
                                                      child: ElevatedButton(
                                                        onPressed: () {
                                                          pinnedLocations.add(
                                                              currentPinnedLocation);
                                                          print(
                                                              'added $currentPinnedLocation');
                                                          pageController.nextPage(
                                                              duration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          300),
                                                              curve: Curves
                                                                  .easeIn);
                                                          //showWalkWidget = true;
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.white,
                                                          backgroundColor:
                                                              const Color(
                                                                  0xff1F41BB),
                                                          minimumSize:
                                                              const Size(
                                                                  131, 26),
                                                        ),
                                                        child:
                                                            const Text('Walk'),
                                                      ),
                                                    ),
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              left: 20,
                                                              right: 5,
                                                              top: 10,
                                                              bottom: 10),
                                                      child: ElevatedButton(
                                                        onPressed: () {
                                                          pinnedLocations.add(
                                                              currentPinnedLocation);
                                                          print(
                                                              'added $currentPinnedLocation');
                                                          pageController.nextPage(
                                                              duration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          300),
                                                              curve: Curves
                                                                  .easeIn);
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.white,
                                                          backgroundColor:
                                                              const Color(
                                                                  0xff1F41BB),
                                                          minimumSize:
                                                              const Size(
                                                                  131, 26),
                                                        ),
                                                        child:
                                                            const Text('Ride'),
                                                      ),
                                                    ),
                                                    // if(showWalkWidget)
                                                    // Container(
                                                    //   child: Column(
                                                    //     children: [
                                                    //       Container(
                                                    //         padding: const EdgeInsets.only(left: 20.0),
                                                    //         alignment: Alignment.centerLeft,
                                                    //         child: const Text(
                                                    //           'Pin your walk destination',
                                                    //           style: TextStyle(
                                                    //             color: Colors.black,
                                                    //             fontSize: 12,
                                                    //             fontWeight: FontWeight.w600,
                                                    //           ),

                                                    //         ),
                                                    //       )
                                                    //     ]
                                                    //   ),

                                                    // ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                //  if (showWalkWidget)
                                //   Expanded(
                                //     child: AnimatedSwitcher(
                                //       duration: const Duration(milliseconds: 500), // Duration of transition
                                //       transitionBuilder: (Widget child, Animation<double> animation) {
                                //         return SlideTransition(
                                //           position: Tween<Offset>(
                                //             begin: const Offset(1, 0),  // Slide in from the right
                                //             end: Offset.zero,  // Final position (center)
                                //           ).animate(animation),
                                //           child: FadeTransition(  // Add fade effect
                                //             opacity: animation,
                                //             child: child,
                                //           ),
                                //         );
                                //       },
                                //       child: SingleChildScrollView(
                                //         key: ValueKey<bool>(showWalkWidget), // Ensures proper widget change
                                //         controller: scrollController,
                                //         child: Padding(
                                //           padding: const EdgeInsets.all(5.0),
                                //           child: Column(
                                //             crossAxisAlignment: CrossAxisAlignment.start,
                                //             children: [
                                //               Container(
                                //                 padding: const EdgeInsets.only(left: 20.0),
                                //                 alignment: Alignment.centerLeft,
                                //                 child: const Text(
                                //                   'Pin your walk destination',
                                //                   style: TextStyle(
                                //                     color: Colors.black,
                                //                     fontSize: 12,
                                //                     fontWeight: FontWeight.w600,
                                //                   ),
                                //                 ),
                                //               ),
                                //             ],
                                //           ),
                                //         ),
                                //       ),
                                //     ),
                                //   ),
                              ],
                            ),
                            Column(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  child: Container(
                                    width: 60,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.arrow_back,
                                                      size: 24),
                                                  onPressed: () {
                                                    backButtonPressedCount++;
                                                    _goToPreviousPage();
                                                  },
                                                ),
                                                const Expanded(
                                                  child: Center(
                                                    child: Text(
                                                      'Pin location',
                                                      style: TextStyle(
                                                          fontSize: 14),
                                                    ),
                                                  ),
                                                ),
                                                if (backButtonPressedCount > 0)
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.arrow_forward,
                                                        size: 24),
                                                    onPressed: () {
                                                      backButtonPressedCount--;
                                                    },
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 20.0),
                                            child: const Text(
                                              'Where can we stop?',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                Positioned(
                  top: 20,
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

  Route _gotoDashboard() {
    return PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const Dashboard(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        });
  }
}

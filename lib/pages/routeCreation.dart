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
  // StoresheetSizes storesheetSizes = StoresheetSizes();
  GoogleMapController? mapController;
  Marker? originMarker;
  Marker? temporaryMarker;
  Polyline? temporaryPolyline;
  //AnimationController? _animationController;
  final PageController pageController = PageController();
  //TextEditingController textOriginController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final LatLng _initialCameraPosition = const LatLng(14.831582, 120.903786);
  late LatLng currentPinnedLocation;
  bool textOriginIsNotEmpty = false;
  bool mapClicked = false;
  bool showWalkWidget = false;
  int backButtonPressedCount = 0;

  int currentpage = 0;
  final List<Widget> pages = [];
  List<LatLng> pinnedLocations = [];
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  final Set<Marker> _originMarker = {};
  int stepNumber = 0;

  List<double> sheetSizes = [0.35, 0.1, 0.35]; //one question sheet size

  Map<int, List> steps = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDialog(context);
    });
    // pages.add(PageOne(onNavigate: _navigateTo));
    // pages.add(PageTwo(onNavigate: _navigateTo));
    // pages.add(PageThree(onNavigate: _navigateTo));
    // pages.add(PageFour());
    //animation for bottom sheet
    // _animationController = AnimationController(
    //   vsync: this,
    //   duration: Duration(milliseconds: 300),
    //   );
    //   _animationController?.forward();

    //to identify if the textOrigin is empty or not
    // textOriginController.addListener((){
    //   setState(() {
    //     textOriginIsNotEmpty = textOriginController.text.isNotEmpty;
    //   //print(textOriginIsNotEmpty.toString());
    //   });
    // });
  }
  // void getCurrentSheetSize(){
  //   final RenderBox renderBox = SheetSizeKey.currentContext?.findRenderObject() as RenderBox;
  //   final size = renderBox?.size;
  //   setState(() {
  //     currentSheetSize = size?.height ?? 0.0;
  //   });
  // }
  // void _navigateTo(int pageIndex,double initialSize,double minChildSize, double maxChildSize){
  //   setState(() {
  //     currentpage = pageIndex;
  //     sheetSizes[0] = initialSize;
  //     sheetSizes[1] = minChildSize;
  //     sheetSizes[2] = maxChildSize;
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
  //MODIFYING BOTTOM SHEET SIZE
  //sheetsize for one quesstion (ex. What is this location called kinemeerut)
  // void updateSheetSizes(double initialSize, double minChildSize, double maxChildSize) {
  //   if(mounted){

  //       setState(() {
  //         sheetSizes[0] = initialSize;
  //         sheetSizes[1] = minChildSize;
  //         sheetSizes[2] = maxChildSize;

  //       print("la");
  //       print(sheetSizes);
  //       });

  //   }
  //   else{
  //     print('not mounted');
  //   }

  // }

  // void _fixedSheetSize(){
  //     // reset to one question size
  //     updateSheetSizes(0.25, 0.1, 0.25);
  // }
  // bool sheetSizeForSecondQuestion(){
  //   if(textOriginIsNotEmpty == true){
  //         updateSheetSizes(0.3, 0.1, 0.3);

  //   }
  //   else{
  //     _fixedSheetSize();
  //   }
  //   return textOriginIsNotEmpty;
  // }

  // void _goToNextPage() {
  //   if(backButtonPressedCount == 1){backButtonPressedCount--;}
  //   pageController.nextPage(
  //     duration: const Duration(milliseconds: 300),
  //     curve: Curves.easeInOut,
  //   );
  // }
  // void _goToPreviousPage() {
  //   pageController.previousPage(
  //     duration: const Duration(milliseconds: 300),
  //     curve: Curves.easeInOut,
  //   );
  // }

// void updateSheetSizes(double initialSize, double minChildSize, double maxChildSize) {
//     setState(() {
//       sheetSizes[0] = initialSize;
//       sheetSizes[1] = minChildSize;
//       sheetSizes[2] = maxChildSize;
//     });
//   }

//   void fixSheetSize(bool textNotEmpty){
//     if(textNotEmpty == true){
//           sheetSizes[0] = 0.4;
//           sheetSizes[1] = 0.1;
//           sheetSizes[2] = 0.4;
//     }
//     else{
//           sheetSizes[0] = 0.25;
//           sheetSizes[1] = 0.1;
//           sheetSizes[2] = 0.25;
//     }
//   }
// void getInfoFromWalk(BuildContext context) async {
//   final description = await Navigator
// }
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
                    builder: (context, scrollController) {
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
                          child: Navigator(
                            onGenerateRoute: (RouteSettings settings) {
                              Widget page = Page1(scrollController);
                              //final args = settings.arguments as Map<int,List>;
                              //steps = args;
                              switch (settings.name) {
                                case '/walk':
                                  page = WalkWidget(
                                      scrollController: scrollController,
                                      onSubmit: (String x) {},
                                      onPop: () {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          setState(() {
                                            sheetSizes[0] = 0.35;
                                            sheetSizes[1] = 0.1;
                                            sheetSizes[2] = 0.35;
                                          });
                                        });
                                      });
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    setState(() {
                                      sheetSizes[0] = 0.40;
                                      sheetSizes[1] = 0.1;
                                      sheetSizes[2] = 0.40;
                                    });
                                  });

                                  break;
                                case '/ride':
                                  page = RideWidget(
                                      scrollController: scrollController);
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    setState(() {
                                      sheetSizes[0] = 0.70;
                                      sheetSizes[1] = 0.1;
                                      sheetSizes[2] = 0.70;
                                    });
                                  });
                                  break;
                              }
                              return PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        page,
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  const begin =
                                      Offset(1.0, 0.0); // Wipe in from right
                                  const end = Offset.zero;
                                  const curve = Curves.ease;

                                  var tween = Tween(begin: begin, end: end)
                                      .chain(CurveTween(curve: curve));
                                  var offsetAnimation = animation.drive(tween);

                                  return SlideTransition(
                                    position: offsetAnimation,
                                    child: child,
                                  );
                                },
                              );
                            },
                          ),
                          // child: PageView(
                          //   controller: pageController, // Use the page controller
                          // physics: const NeverScrollableScrollPhysics(),
                          //   children: [

                          //     Column(
                          //       //fist page
                          //       children: [
                          //         Container(
                          //           margin: const EdgeInsets.only(top: 10),
                          //           child: Container(
                          //             width: 60,
                          //             height: 6,
                          //             decoration: BoxDecoration(
                          //               color: Colors.grey,
                          //               borderRadius: BorderRadius.circular(3),
                          //             ),
                          //           ),
                          //         ),
                          //         Expanded(

                          //           child: SingleChildScrollView(
                          //             controller: scrollController,
                          //             child: Padding(
                          //               padding: const EdgeInsets.all(5.0),
                          //               child: Column(
                          //                 crossAxisAlignment: CrossAxisAlignment.start,
                          //                 children: [
                          //                   Container(
                          //                     alignment: Alignment.center,
                          //                     padding: const EdgeInsets.symmetric(vertical: 20.0),
                          //                     child: const Text(
                          //                       'What is this location called?',
                          //                       style: TextStyle(
                          //                         fontSize: 16,
                          //                         fontWeight: FontWeight.bold,
                          //                       ),
                          //                       textAlign: TextAlign.center,
                          //                     ),
                          //                   ),
                          //                   const SizedBox(height: 3),
                          //                   Container(
                          //                     margin: const EdgeInsets.only(right: 20.0, left: 20.0),
                          //                     height: 37,
                          //                     decoration: BoxDecoration(
                          //                       color: Colors.white,
                          //                       borderRadius: BorderRadius.circular(5),
                          //                       boxShadow: [
                          //                         BoxShadow(
                          //                           color: const Color(0xff1D1617).withOpacity(0.11),
                          //                           blurRadius: 4,
                          //                         ),
                          //                       ],
                          //                     ),
                          //                     child: GestureDetector(
                          //                       onTap: (){
                          //                         //i dont know pa dito, gusto ko kase na pag clinick is magincrease yung size ng sheet, pagisipan ko pa pano maging smooth haha
                          //                       },
                          //                       child: TextFormField(
                          //                         controller: textOriginController,
                          //                         decoration: InputDecoration(
                          //                           filled: true,
                          //                           fillColor: Colors.white,
                          //                           contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          //                           hintText: 'Type here...',
                          //                           border: OutlineInputBorder(
                          //                             borderRadius: BorderRadius.circular(5),
                          //                             borderSide: BorderSide.none,
                          //                           ),
                          //                         ),
                          //                       ),
                          //                     ),
                          //                   ),
                          //                   const SizedBox(height: 10),
                          //                   if(_sheetSizeForSecondQuestion())
                          //                   Column(
                          //                     children: [
                          //                       Container(
                          //                       padding: const EdgeInsets.only(left: 20.0),
                          //                       alignment: Alignment.centerLeft,
                          //                       child: const Text(
                          //                         'What is the first step?',
                          //                         style: TextStyle(
                          //                           color: Colors.black,
                          //                           fontSize: 12,
                          //                           fontWeight: FontWeight.w600,
                          //                         ),
                          //                       ),
                          //                       ),
                          //                       Row(
                          //                         children: [
                          //                           Container(
                          //                           margin: const EdgeInsets.only(left: 20, right: 5, top: 10, bottom: 10),
                          //                           child: ElevatedButton(
                          //                             onPressed: (){
                          //                                 pinnedLocations.add(currentPinnedLocation);
                          //                                 print('added ${currentPinnedLocation}');
                          //                                 _fixedSheetSize();
                          //                                 pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);

                          //                                 //showWalkWidget = true;
                          //                             },
                          //                             style: ElevatedButton.styleFrom(
                          //                               foregroundColor: Colors.white,
                          //                               backgroundColor: const Color(0xff1F41BB),
                          //                               minimumSize: const Size(131, 26),
                          //                             ),
                          //                              child: const Text('Walk'),
                          //                           ),
                          //                           ),
                          //                           Container(
                          //                           margin: const EdgeInsets.only(left: 20, right: 5, top: 10, bottom: 10),
                          //                           child: ElevatedButton(
                          //                             onPressed: (){
                          //                                 pinnedLocations.add(currentPinnedLocation);
                          //                                 print('added ${currentPinnedLocation}');
                          //                                 pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
                          //                             },
                          //                             style: ElevatedButton.styleFrom(
                          //                               foregroundColor: Colors.white,
                          //                               backgroundColor: const Color(0xff1F41BB),
                          //                               minimumSize: const Size(131, 26),
                          //                             ),
                          //                             child: const Text('Ride'),
                          //                           ),
                          //                         ),

                          //                         ],
                          //                       ),

                          //                     ],
                          //                   ),
                          //                 ],
                          //               ),
                          //             ),
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //     Column(
                          //       children: [
                          //         Container(
                          //           margin: const EdgeInsets.only(top: 10),
                          //           child: Container(
                          //             width: 60,
                          //             height: 6,
                          //             decoration: BoxDecoration(
                          //               color: Colors.grey,
                          //               borderRadius: BorderRadius.circular(3),
                          //             ),
                          //           ),
                          //         ),
                          //         const SizedBox(height: 6),
                          //         Expanded(
                          //           child: SingleChildScrollView(
                          //             child: Padding(
                          //               padding: const EdgeInsets.all(5.0),
                          //               child: Column(
                          //                 crossAxisAlignment: CrossAxisAlignment.start,
                          //                 children: [
                          //                   Padding(
                          //                     padding: const EdgeInsets.all(8.0),
                          //                     child: Row(
                          //                       children: [
                          //                         IconButton(
                          //                           icon: const Icon(Icons.arrow_back, size: 24),
                          //                           onPressed: () {
                          //                               backButtonPressedCount++;
                          //                               _goToPreviousPage();
                          //                             },
                          //                           ),
                          //                         const Expanded(
                          //                           child: Center(
                          //                             child: Text(
                          //                               'Pin location',
                          //                               style: TextStyle(fontSize: 14),
                          //                             ),
                          //                           ),
                          //                         ),
                          //                         if(backButtonPressedCount > 0)
                          //                         IconButton(
                          //                           icon: const Icon(Icons.arrow_forward, size: 24),
                          //                           onPressed: () {
                          //                             backButtonPressedCount--;
                          //                             },
                          //                           ),
                          //                       ],
                          //                     ),
                          //                   )
                          //                   ,
                          //                   Container(
                          //                     alignment: Alignment.center,
                          //                     padding: const EdgeInsets.symmetric(vertical: 20.0),
                          //                     child: const Text(
                          //                       'Where can we stop?',
                          //                       style: TextStyle(
                          //                         fontSize: 16,
                          //                         fontWeight: FontWeight.bold,
                          //                       ),
                          //                     ),
                          //                   )
                          //                 ],
                          //               ),
                          //             ),
                          //           ),
                          //         )
                          //       ],
                          //     ),
                          //   ],
                          // ),
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
// Route _gotoDashboard(){
//       return PageRouteBuilder(
//         pageBuilder: (context, animation, secondaryAnimation) => Dashboard(),
//         transitionsBuilder: (context, animation, secondaryAnimation, child) {
//           const begin = Offset(1.0, 0.0);
//           const end = Offset.zero;
//           const curve = Curves.ease;

//           var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
//           var offsetAnimation = animation.drive(tween);

//           return SlideTransition(
//             position: offsetAnimation,
//             child: child,
//           );

//         }
//       );
//     }
}

class Page1 extends StatefulWidget {
  final ScrollController _scrollController;
  const Page1(this._scrollController, {super.key});

  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> {
  final _MyWidgetState mainwidget = _MyWidgetState();
  // StoresheetSizes storesheetSizes = StoresheetSizes();
  TextEditingController textOriginController = TextEditingController();
  bool textOriginIsNotEmpty = false;
  // _Page1State(this._scrollController);

  @override
  void initState() {
    super.initState();
    // to identify if the textOrigin is empty or not
    textOriginController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          textOriginIsNotEmpty = textOriginController.text.isNotEmpty;
          //print(textOriginIsNotEmpty.toString());
        });
      });
    });
  }
  // bool passSizes(){
  //   // mainwidget.fixSheetSize(textOriginIsNotEmpty);
  //   return textOriginIsNotEmpty;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: widget._scrollController,
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                alignment: Alignment.center,
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
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: textOriginController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 15),
                    hintText: 'Type here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (textOriginIsNotEmpty)
                Column(
                  children: [
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
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(
                              left: 20, right: 5, top: 10, bottom: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/walk');
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
                          margin: const EdgeInsets.only(
                              left: 20, right: 5, top: 10, bottom: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/ride');
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xff1F41BB),
                              minimumSize: const Size(131, 26),
                            ),
                            child: const Text('Ride'),
                          ),
                        )
                      ],
                    )
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}

// class StoresheetSizes {
//   _MyWidgetState mainclass = _MyWidgetState();
//   List <double> sheetSizes = [0.25,1,0.25];

//   void setSizes(double initialSize,double minChildSize,double maxChildSize){
//     // mainclass.updateSheetSizes(initialSize, minChildSize, maxChildSize);

//   }

// }
class WalkWidget extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onPop;
  final Function(String) onSubmit;

  const WalkWidget({
    Key? key,
    required this.scrollController,
    required this.onPop,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _WalkWidgetState createState() => _WalkWidgetState();
}

class _WalkWidgetState extends State<WalkWidget> {
  TextEditingController descriptionController = TextEditingController();
  bool descriptionTextIsNotEmpty = false;

  @override
  void initState() {
    super.initState();
    // Initialize the TextEditingController
    descriptionController.addListener(() {
      // WidgetsBinding.instance.addPersistentFrameCallback((_){
      setState(() {
        descriptionTextIsNotEmpty = descriptionController.text.isNotEmpty;
      });
      // });
    });
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: widget.scrollController, // Accessing widget properties
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                alignment: Alignment.center,
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
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      widget.onPop();
                      widget.onSubmit(descriptionController.text);
                      Navigator.pop(context);
                    },
                  ),
                  const Text(
                    'Walk',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
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
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(left: 15.0),
                child: Text(
                  'Description:',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                child: TextFormField(
                  controller: descriptionController,
                  maxLength: 100,
                  maxLines: 2,
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
                ),
              ),
              if (descriptionTextIsNotEmpty)
                Column(
                  children: [
                    Container(
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
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(
                              left: 15, right: 5, top: 10, bottom: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/walk');
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
                              left: 5, right: 5, top: 10, bottom: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/ride');
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
                              left: 5, right: 5, top: 10, bottom: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/done');
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
                )
            ],
          ),
        ),
      ),
    );
  }
}

class RideWidget extends StatefulWidget {
  final ScrollController scrollController;
  const RideWidget({Key? key, required this.scrollController})
      : super(key: key);

  @override
  State<RideWidget> createState() => _RideWidgetState();
}

class _RideWidgetState extends State<RideWidget> {
  TextEditingController descriptionController = TextEditingController();
  bool descriptionTextIsNotEmpty = false;
  List<String> vehicles = ['tricycle', 'jeep', 'e-jeep', 'bus'];
  List<String> busCorporations = ['German Espiritu', 'Victory Liner', 'P2P'];
  List<String> jeepRoutes = [
    'Bocaue',
    'Lolomboy',
    'Balagtas',
    'Plaridel',
    'Marilao',
    'Guiguinto',
    'Meycauayan'
  ];
  List<String> busRoutes = [
    'Balagtas',
    'Bulakan',
    'Balagtas',
    'Plaridel',
    'Monumento'
  ];
  List<bool> checkboxBusTracker = [];
  List<bool> checkboxJeepRoutesTracker = [];
  List<bool> checkboxBusRoutesTracker = [];
  //int listNumber = 0;

  String? selectedValue;
  @override
  void initState() {
    super.initState();
    // Initialize the TextEditingController
    descriptionController.addListener(() {
      WidgetsBinding.instance.addPersistentFrameCallback((_) {
        setState(() {
          descriptionTextIsNotEmpty = descriptionController.text.isNotEmpty;
        });
      });
    });
    _generateJeepRoutesTracker();
    _generateBusCorpTracker();
    _generateBusRoutesTracker();
  }

  void _generateJeepRoutesTracker() {
    for (int i = 0; i < jeepRoutes.length; i++) {
      checkboxJeepRoutesTracker.add(false);
    }
  }

  void _generateBusCorpTracker() {
    for (int i = 0; i < busCorporations.length; i++) {
      checkboxBusTracker.add(false);
    }
  }

  void _generateBusRoutesTracker() {
    for (int i = 0; i < busRoutes.length; i++) {
      checkboxBusRoutesTracker.add(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: widget.scrollController,
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                alignment: Alignment.center,
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
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      //widget.onPop();
                      //widget.onSubmit(descriptionController.text);
                      Navigator.pop(context);
                    },
                  ),
                  const Text(
                    'Ride',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: const Text(
                  'Pin your ride destination',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              // const Padding(
              //   padding: EdgeInsets.only(left: 15.0),
              //   child:  Text('Description:',
              //   style: TextStyle(
              //     color: Colors.black,
              //     fontSize: 12,
              //     fontWeight: FontWeight.w600,
              //   ),),
              // ),
              // const SizedBox(height: 10),
              // Padding(
              //   padding: const EdgeInsets.only(left: 10.0, right: 10.0),
              //   child: TextFormField(
              //     controller: descriptionController,
              //     maxLength: 100,
              //     maxLines: 2,
              //     minLines: 1,
              //     decoration: InputDecoration(
              //       filled: true,
              //       fillColor: Colors.white,
              //       contentPadding:
              //           const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              //       hintText: 'Type here...',
              //       border: OutlineInputBorder(
              //         borderRadius: BorderRadius.circular(5),
              //         borderSide: const BorderSide(
              //           color: Color.fromARGB(255, 255, 255, 255),
              //           width: 1.5,
              //         ),
              //       ),
              //       focusedBorder: OutlineInputBorder(
              //         borderRadius: BorderRadius.circular(5),
              //         borderSide: const BorderSide(
              //           color: Color.fromARGB(255, 76, 174, 255),
              //           width: 2,
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
              const Padding(
                padding: EdgeInsets.only(left: 15.0),
                child: Text(
                  'Mode of Transportation:',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(left: 20, right: 160),
                alignment: Alignment.centerLeft,
                child: DropdownButtonFormField<String>(
                  value: selectedValue,
                  hint: Text('Select mode', style: TextStyle(fontSize: 13)),
                  // isExpanded: true,
                  items: vehicles.map((String item) {
                    return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item, style: TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedValue = newValue;
                    });
                  },
                  // underline: Container(
                  //   height: 2,
                  //   color: Colors.blue,
                  // ),
                ),
              ),
              const SizedBox(height: 12),
              if (selectedValue == 'bus')
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 16.0),
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Bus Name: ',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 0.0,
                      children: List.generate(busCorporations.length, (index) {
                        return SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 16,
                          child: Row(
                            children: [
                              Checkbox(
                                value: checkboxBusTracker[index],
                                onChanged: (bool? value) {
                                  setState(() {
                                    checkboxBusTracker[index] = value ?? false;
                                  });
                                },
                              ),
                              Text(
                                busCorporations[index],
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    Container(
                      padding: const EdgeInsets.only(left: 16.0),
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Bus Route: ',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 0.0,
                      children: List.generate(busRoutes.length, (index) {
                        return SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 16,
                          child: Row(
                            children: [
                              Checkbox(
                                value: checkboxBusRoutesTracker[index],
                                onChanged: (bool? value) {
                                  setState(() {
                                    checkboxBusRoutesTracker[index] =
                                        value ?? false;
                                  });
                                },
                              ),
                              Text(
                                busRoutes[index],
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }),
                    )
                  ],
                ),
              if (descriptionTextIsNotEmpty)
                Column(
                  children: [
                    Container(
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
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(
                              left: 15, right: 5, top: 10, bottom: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/walk');
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
                              left: 5, right: 5, top: 10, bottom: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              //showWalkWidget = true;
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
                              left: 5, right: 5, top: 10, bottom: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/done');
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
                )
            ],
          ),
        ),
      ),
    );
  }
}

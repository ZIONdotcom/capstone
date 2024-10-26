// // import 'package:flutter/material.dart';

// // class RouteCreation extends StatefulWidget {
// //   const RouteCreation({super.key});

// //   @override
// //   _RouteCreationState createState() => _RouteCreationState();
// // }

// // class _RouteCreationState extends State<RouteCreation> {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('DraggableScrollableSheet with Custom Transition'),
// //       ),
// //       body: Stack(
// //         children: [
// //           // Background content (e.g., a map or other content behind the sheet)
// //           Container(color: Colors.blue),

// //           // DraggableScrollableSheet
// //           DraggableScrollableSheet(
// //             initialChildSize: 0.25,
// //             minChildSize: 0.25,
// //             maxChildSize: 0.75,
// //             builder: (context, scrollController) {
// //               return Container(
// //                 color: Colors.white,
// //                 child: Navigator(
// //                   onGenerateRoute: (RouteSettings settings) {
// //                     Widget page = const BottomSheetHomePage(); // Default Page

// //                     if (settings.name == '/page1') {
// //                       page = const Page1();
// //                     } else if (settings.name == '/page2') {
// //                       page = const Page2();
// //                     }

// //                     // Using PageRouteBuilder for custom transition
// //                     return PageRouteBuilder(
// //                       pageBuilder: (context, animation, secondaryAnimation) =>
// //                           page,
// //                       transitionsBuilder: (context, animation, secondaryAnimation, child) {
// //                         const begin = Offset(1.0, 0.0); // Wipe in from right
// //                         const end = Offset.zero;
// //                         const curve = Curves.ease;

// //                         var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
// //                         var offsetAnimation = animation.drive(tween);

// //                         return SlideTransition(
// //                           position: offsetAnimation,
// //                           child: child,
// //                         );
// //                       },
// //                     );
// //                   },
// //                 ),
// //               );
// //             },
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // The first page inside the DraggableScrollableSheet
// // class BottomSheetHomePage extends StatelessWidget {
// //   const BottomSheetHomePage({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return ListView(
// //       padding: const EdgeInsets.all(16.0),
// //       children: [
// //         ListTile(
// //           title: const Text('Navigate to Page 1 with Wipe Transition'),
// //           onTap: () {
// //             // Navigate to Page 1 with wipe transition
// //             Navigator.of(context).pushNamed('/page1');
// //           },
// //         ),
// //         ListTile(
// //           title: const Text('Navigate to Page 2 with Wipe Transition'),
// //           onTap: () {
// //             // Navigate to Page 2 with wipe transition
// //             Navigator.of(context).pushNamed('/page2');
// //           },
// //         ),
// //       ],
// //     );
// //   }
// // }

// // // New Widget (Page1)
// // class Page1 extends StatelessWidget {
// //   const Page1({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Page 1'),
// //         leading: BackButton(
// //           onPressed: () {
// //             Navigator.of(context).pop();
// //           },
// //         ),
// //       ),
// //       body: const Center(
// //         child: Text('This is Page 1 with Wipe Transition'),
// //       ),
// //     );
// //   }
// // }

// // // New Widget (Page2)
// // class Page2 extends StatelessWidget {
// //   const Page2({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Page 2'),
// //         leading: BackButton(
// //           onPressed: () {
// //             Navigator.of(context).pop();
// //           },
// //         ),
// //       ),
// //       body: const Center(
// //         child: Text('This is Page 2 with Wipe Transition'),
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class MapScreen extends StatefulWidget {
//   const MapScreen({super.key});

//   @override
//   _MapScreenState createState() => _MapScreenState();
// }

// class _MapScreenState extends State<MapScreen> {
//   GoogleMapController? mapController;
//   Set<Marker> markers = {};
//   MarkerId? selectedMarkerId; // Store selected marker ID

//   // Example marker positions
//   final List<LatLng> initialMarkerPositions = [
//     const LatLng(14.831582, 120.903786), // Marker 1
//     const LatLng(14.831000, 120.902000), // Marker 2
//     const LatLng(14.832000, 120.901000), // Marker 3
//   ];

//   @override
//   void initState() {
//     super.initState();
//     // Initialize markers
//     for (int i = 0; i < initialMarkerPositions.length; i++) {
//       markers.add(
//         Marker(
//           markerId: MarkerId('marker_$i'),
//           position: initialMarkerPositions[i],
//           infoWindow: InfoWindow(
//             title: 'Marker $i',
//             onTap: () {
//               // When the marker is tapped, store its ID and enable map tapping
//               setState(() {
//                 selectedMarkerId = MarkerId('marker_$i');
//               });
//               _enableMapTapping();
//             },
//           ),
//         ),
//       );
//     }
//   }

//   void _enableMapTapping() {
//     // This function can be used to capture the tap on the map
//     if (selectedMarkerId != null) {
//       // Listen for map taps
//       mapController?.setMapStyle('[]'); // Disable any previous styles if needed
//     }
//   }

//   void _onMapTapped(LatLng position) {
//     if (selectedMarkerId != null) {
//       // Update the position of the selected marker
//       setState(() {
//         markers.removeWhere((marker) => marker.markerId == selectedMarkerId);
//         markers.add(Marker(
//           markerId: selectedMarkerId!,
//           position: position,
//           infoWindow: InfoWindow(title: selectedMarkerId!.value),
//         ));
//       });
//       // Reset selectedMarkerId to null after updating
//       selectedMarkerId = null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Map with Editable Markers'),
//       ),
//       body: GoogleMap(
//         onMapCreated: (controller) {
//           mapController = controller;
//         },
//         initialCameraPosition: const CameraPosition(
//           target: LatLng(14.831582, 120.903786),
//           zoom: 12.0,
//         ),
//         markers: markers,
//         onTap: _onMapTapped, // Capture tap on the map
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Navigation Example',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: PageNavigator(),
//     );
//   }
// }

// class PageNavigator extends StatefulWidget {
//   @override
//   _PageNavigatorState createState() => _PageNavigatorState();
// }

// class _PageNavigatorState extends State<PageNavigator> {
//   // List of pages to navigate
//   final List<Widget> _pages = [
//     FirstPage(),
//     SecondPage(),
//     ThirdPage(),
//     FourthPage(),
//   ];
//   int _currentPageIndex = 0;

//   // Method to navigate forward
//   void _nextPage() {
//     if (_currentPageIndex < _pages.length - 1) {
//       setState(() {
//         _currentPageIndex++;
//       });
//     }
//   }

//   // Method to navigate backward
//   void _previousPage() {
//     if (_currentPageIndex > 0) {
//       setState(() {
//         _currentPageIndex--;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Page ${_currentPageIndex + 1}'),
//       ),
//       body: _pages[_currentPageIndex], // Display the current page
//       bottomNavigationBar: BottomAppBar(
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             IconButton(
//               icon: Icon(Icons.arrow_back),
//               onPressed: _currentPageIndex == 0 ? null : _previousPage, // Disable if on the first page
//               iconSize: 50,
//             ),
//             IconButton(
//               icon: Icon(Icons.arrow_forward),
//               onPressed: _currentPageIndex == _pages.length - 1 ? null : _nextPage, // Disable if on the last page
//               iconSize: 50,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// Define your page widgets
// 


// import 'dart:io';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navigation Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImagePickerButton(),
    );
  }
}

class ImagePickerButton extends StatefulWidget {
  const ImagePickerButton({super.key});

  @override
  _ImagePickerButtonState createState() => _ImagePickerButtonState();
}

class _ImagePickerButtonState extends State<ImagePickerButton> {
  XFile? _image;

  // Function to pick an image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    // Requesting permissions
    await _requestPermissions();

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _image = image;
      });
    }
  }

  // Function to request camera and storage permissions
  Future<void> _requestPermissions() async {
    var cameraStatus = await Permission.camera.request();
    var storageStatus = await Permission.storage.request();

    if (cameraStatus.isDenied || storageStatus.isDenied) {
      // Handle the case when permissions are denied
      print("Permissions denied");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Button to open image picker
        ElevatedButton(
          onPressed: () => _pickImage(ImageSource.gallery),
          child: const Text('Pick Image from Gallery'),
        ),
        ElevatedButton(
          onPressed: () => _pickImage(ImageSource.camera),
          child: const Text('Capture Image with Camera'),
        ),
        const SizedBox(height: 20),
        // Display the selected image
        _image != null
            ? Image.file(File(_image!.path))
            : const Text('No image selected.'),
      ],
    );
  }
}

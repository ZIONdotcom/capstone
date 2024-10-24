import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:capstone/pages/scratch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class SuggestPinLocation extends StatefulWidget {
  const SuggestPinLocation({super.key});

  @override
  SuggestPinLocationState createState() => SuggestPinLocationState();
}

class SuggestPinLocationState extends State<SuggestPinLocation> {
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(14.831582, 120.903786),
    zoom: 13,
  );
  late GoogleMapController _googleMapController;
  Marker? _pinnedMarker;
  String? _address;
  String? selectedMode;

  final bool _showEstablishment = false;
  bool _showOptions = false; // To control visibility of widgets
  bool buttonClicked = false;
  List<double> sheetSizes = [0.25,0.1,0.25];


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


    void changeSheetSize(double initialSize, double minChildSize, double maxChildSize){
    setState(() {
      sheetSizes[0] = initialSize;
      sheetSizes[1] = minChildSize;
      sheetSizes[2] = maxChildSize;

    });
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

    //Fetch the address from coordinates
    await _getAddress(position);

    if (_address != null && _address!.isNotEmpty) {
      LocationInformation().setLatLng(position, _address!);
    } else {
      print('Address retrieval failed or is empty.');
    }
  }


  Future<void> _getAddress(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        print(position);
        
        // print("eeeeeeyyyyyyyyyyyyy"+position.toString());
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
          title: const Text("SUGGEST A LOCATION",
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
              Text("Pin the location you want to suggest!",
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




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Suggest Pin Location',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          
          SizedBox(
            height: _showOptions ? 630 : double.infinity, // Map height
            width: double.infinity,
            child: GoogleMap(
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              initialCameraPosition: _initialCameraPosition,
              onMapCreated: (controller) {
                _googleMapController = controller;
              },
              markers: _pinnedMarker != null ? {_pinnedMarker!} : {},
              onTap: _addMarker,
            ),
          ),
          
          if (_showOptions)
            DraggableScrollableSheet(
              initialChildSize: sheetSizes[0], 
              minChildSize: sheetSizes[1],
              maxChildSize: sheetSizes[2], 
              builder: (BuildContext context, ScrollController scrollController) {
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
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 5,bottom: 15),
                              width: 60,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                           Navigator(
                              onGenerateRoute: (RouteSettings settings){
                                 Widget page;
                                if(settings.name == '/terminal'){
                                  page = const BuildTerminal();
                                  changeSheetSize(0.5, 0.1, 0.5);
                                }
                                else if(settings.name == '/establishment'){
                                  page = const BuildEstablishment();
                                  changeSheetSize(0.55, 0.2, 0.55);
                                }
                                else{
                                  page = const BuildFirst();
                                  
                                }
                                return MaterialPageRoute(
                                  builder: (context) => FadeTransition(
                                    opacity: Tween(begin: 1.0, end: 2.0).animate(
                                      CurvedAnimation(
                                        parent: ModalRoute.of(context)!.animation!, 
                                        curve: Curves.easeIn)
                                    ),
                                    child: page,
                                  )
                                );
                                // return MaterialPageRoute(
                                //   builder: (context){
                                //     return const BuildFirst();
                                //   } 
                                // );
                              },
                            ),
                          ],
                        )
                      ),
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




}












class BuildFirst extends StatefulWidget {
  const BuildFirst({super.key});

  @override
  State<BuildFirst> createState() => _BuildFirstState();
}

class _BuildFirstState extends State<BuildFirst> {
  SuggestPinLocationState mainwidget = SuggestPinLocationState();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Container(
            alignment: Alignment.center,
            child: Column(
              children: [
                 Container(
                  alignment: Alignment.center,
                  child: const Text(
                    'Is this an establishment or terminal?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () { 
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/establishment');
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:const Color(0xff1F41BB),
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
                          Navigator.pop(context);
                          Navigator.of(context).pushNamed('/terminal');
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:  const Color(0xff1F41BB),
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
            ],
          );
  }
}

















class BuildTerminal extends StatefulWidget {
  const BuildTerminal({super.key});

  @override
  State<BuildTerminal> createState() => _BuildTerminalState();
}

class _BuildTerminalState extends State<BuildTerminal> {
  // String? selectedMode;
  
  TextEditingController terminalController = TextEditingController();
  TextEditingController landmarkController = TextEditingController();
  // TextEditingController fareController = TextEditingController();
  // TextEditingController fromRouteController = TextEditingController();
  // TextEditingController toRouteController = TextEditingController();
  List <XFile> images = [];
  final ImagePicker imagePicker = ImagePicker();

  void _clearAll(){
  terminalController.clear();
  landmarkController.clear();
  setState(() {
     images.clear();
  });
 
}
  Future<void> _pickImages() async {
    final List<XFile> selectedImages = await imagePicker.pickMultiImage();
    if (selectedImages != null && mounted) {
      setState(() {
        images = selectedImages; // Update the state with the selected images
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? selectedImage = await imagePicker.pickImage(source: ImageSource.camera);
    if (selectedImage != null && mounted) {
      setState(() {
        images = [selectedImage]; // Update the state with the single image
      });
    }
  }

  void _removeImage(XFile imageToRemove) {
    setState(() {
      images.removeWhere((image) => image.path == imageToRemove.path);
    });
  }

  void passData() {
    LocationInformation().setInfo(terminalController.text, landmarkController.text,'terminal');
    if (images.isNotEmpty) {
      LocationInformation().insertImages(images);
    }
  }
  void _showOptionsForImageUpload(BuildContext context){
    showModalBottomSheet(
      context: context, 
      builder: (BuildContext context){
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Upload from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera();
                },
              ),
              
              
            ],
          ),
          );
      }
    );
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      // crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      //   Container(
      //     alignment: Alignment.centerLeft,
      //     child: IconButton(
      //       onPressed: () {
      //        Navigator.of(context).pop();
      //        Navigator.of(context).pushNamed('/');
      //     },
      //     icon: Icon(Icons.arrow_back),
      //   ),
      // ),
      //   Container(
      //     padding: const EdgeInsets.only(left: 13.0),
      //     child: const Text(
      //       'Choose transportation vehicle',
      //       style: TextStyle(
      //         color: Colors.black,
      //         fontSize: 12,
      //         fontWeight: FontWeight.w600,
      //       ),
      //     ),
      //   ),
      Row(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () {
                  passData();
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/');
                },
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 6),
              alignment: Alignment.center,
              child: const Text(
                'What is this terminal called?',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
            controller: terminalController,
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
        // const SizedBox(height: 10),
        // Container(
        //   width: 363,
        //   height: 64,
        //   margin: const EdgeInsets.only(right: 20.0, left: 20.0),
        //   child: DropdownButton<String>(
        //     value: selectedMode,
        //     hint: const Text('Select Mode'),
        //     onChanged: (String? newValue) {
        //       setState(() {
        //         selectedMode = newValue;
        //       });
        //     },
        //     items: ['Jeep', 'Tricycle', 'Bus', 'E-jeep']
        //         .map((String mode) => DropdownMenuItem<String>(
        //               value: mode,
        //               child: Text(mode),
        //             ))
        //         .toList(),
        //   ),
        // ),
        // const SizedBox(height: 10),
        // Container(
        //   margin: const EdgeInsets.only(right: 20.0, left: 20.0),
        //   height: 37,
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     borderRadius: BorderRadius.circular(5),
        //     boxShadow: [
        //       BoxShadow(
        //         color: const Color(0xff1D1617).withOpacity(0.11),
        //         blurRadius: 4,
        //         spreadRadius: 0.0,
        //       ),
        //     ],
        //   ),
        // ),
       const SizedBox( height: 12),
        Container(
          padding: const EdgeInsets.only(top: 6,left: 8),
          alignment: Alignment.centerLeft,
          child: const Text(
            'Landmark: (optional)',
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox( height: 12),
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
            controller: landmarkController,
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
        // Container(
        //   padding: const EdgeInsets.only(left: 13.0),
        //   child: const Text(
        //     'Route',
        //     style: TextStyle(
        //       color: Colors.black,
        //       fontSize: 12,
        //       fontWeight: FontWeight.w600,
        //     ),
        //   ),
        // ),
        // ElevatedButton(
        //   onPressed: () {
        //     // Handle button press
        //   },
        //   style: ElevatedButton.styleFrom(
        //       alignment: Alignment.center,
        //       foregroundColor: Colors.white,
        //       backgroundColor: const Color(0xff1F41BB),
        //       minimumSize: const Size(120, 26),
        //     ),
        //     child: Text('Pin the route'),
        // ),

        // Row(
        //   children: [
        //     Container(
        //       margin: const EdgeInsets.all(10),
        //       height: 33,
        //       width: 149,
        //       decoration: BoxDecoration(
        //         color: Colors.white,
        //         borderRadius: BorderRadius.circular(5),
        //         boxShadow: [
        //           BoxShadow(
        //             color: const Color(0xff1D1617).withOpacity(0.11),
        //             blurRadius: 4,
        //             spreadRadius: 0.0,
        //           ),
        //         ],
        //       ),
        //       child: TextFormField(
        //         controller: fromRouteController,
        //         decoration: InputDecoration(
        //           filled: true,
        //           fillColor: Colors.white,
        //           contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        //           hintText: 'Type here...',
        //           border: OutlineInputBorder(
        //             borderRadius: BorderRadius.circular(5),
        //             borderSide: BorderSide.none,
        //           ),
        //         ),
        //         validator: (value) {
        //           if (value!.isEmpty) {
        //             return "Fill out this field";
        //           } else {
        //             return null;
        //           }
        //         },
        //       ),
        //     ),
        //     Container(
        //       alignment: Alignment.center,
        //       height: 40,
        //       width: 20,
        //       decoration: BoxDecoration(
        //         color: Colors.white,
        //         borderRadius: BorderRadius.circular(10),
        //       ),
        //       child: SvgPicture.asset('assets/icons/arrow.svg'),
        //     ),
        //     Container(
        //       margin: const EdgeInsets.all(5),
        //       height: 33,
        //       width: 149,
        //       decoration: BoxDecoration(
        //         color: Colors.white,
        //         borderRadius: BorderRadius.circular(5),
        //         boxShadow: [
        //           BoxShadow(
        //             color: const Color(0xff1D1617).withOpacity(0.11),
        //             blurRadius: 4,
        //             spreadRadius: 0.0,
        //           ),
        //         ],
        //       ),
        //       child: TextFormField(
        //         controller: toRouteController,
        //         decoration: InputDecoration(
        //           filled: true,
        //           fillColor: Colors.white,
        //           contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        //           hintText: 'Type here...',
        //           border: OutlineInputBorder(
        //             borderRadius: BorderRadius.circular(5),
        //             borderSide: BorderSide.none,
        //           ),
        //         ),
        //       ), 
              
        //     ),
           
        //   ],
        // ),
        const SizedBox( height: 20),
        Container(
         padding: const EdgeInsets.only(left: 16.0),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Picture of Terminal',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
         SingleChildScrollView(
          scrollDirection: Axis.horizontal,
           child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
             children: [
              OutlinedButton(
                onPressed: () {
                  _showOptionsForImageUpload(context);
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
                //  IconButton(
                //   padding: EdgeInsets.only(left: 10),
                //   onPressed: (){
                //     _s
                //   }, 
                //   icon: const Icon(Icons.add_a_photo_outlined,size: 30)
                //   ),
                const SizedBox(width: 10),
                if(images.isNotEmpty)
                Wrap(
                spacing: 5,
                runSpacing: 10,
                children: images.map((image) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [

                      Image.file(File(image.path), height: 100, width: 100),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          onPressed: (){
                            _removeImage(image);
                          }, 
                          icon: const Icon(Icons.close,color: Colors.grey,size: 20)
                          ),
                      )
                    ],
                  );
                }).toList(),
              )
                
             ],
           ),
         ),
         const SizedBox(height: 5),
         ElevatedButton(
            onPressed: () {
              if (terminalController.text.isNotEmpty && images.isNotEmpty){
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                    return Align(
                      alignment: Alignment.center,
                      child: AlertDialog(
                        title:const Text('Terminal location Submitted'),
                        content: const Text('Your pinned location has been submitted and will be reviewed by the admin. Thank you'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('OK'),
                            onPressed: () {
                              passData();
                            LocationInformation().uploadImages();
                            _clearAll();
                            Navigator.of(context).pop(); //Close the dialog
                            Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
              else if(terminalController.text.isEmpty && images.isNotEmpty){
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please fill out required field.'),
                      duration: Duration(seconds: 2), 
                    ),
                  );  
              }
              else if(terminalController.text.isNotEmpty && images.isEmpty){
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please insert an image.'),
                      duration: Duration(seconds: 2), 
                    ),
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
}


















class BuildEstablishment extends StatefulWidget {
  const BuildEstablishment({super.key});

  @override
  State<BuildEstablishment> createState() => _BuildEstablishmentState();
}

class _BuildEstablishmentState extends State<BuildEstablishment> {
 
  TextEditingController establishmentController = TextEditingController();
  TextEditingController landmarkController = TextEditingController();
  List<XFile> images = [];
  final ImagePicker imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  void _clearAll() {
    establishmentController.clear();
    landmarkController.clear();
    setState(() {
      images.clear();
    });
  }

  Future<void> _pickImages() async {
    final List<XFile> selectedImages = await imagePicker.pickMultiImage();
    if (selectedImages != null && mounted) {
      setState(() {
        images = selectedImages; // Update the state with the selected images
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? selectedImage = await imagePicker.pickImage(source: ImageSource.camera);
    if (selectedImage != null && mounted) {
      setState(() {
        images = [selectedImage]; // Update the state with the single image
      });
    }
  }

  void _removeImage(XFile imageToRemove) {
    setState(() {
      images.removeWhere((image) => image.path == imageToRemove.path);
    });
  }

  void passData() {
    LocationInformation().setInfo(establishmentController.text, landmarkController.text,'establishment');
    if (images.isNotEmpty) {
      LocationInformation().insertImages(images);
    }
  }
  void _showOptionsForImageUpload(BuildContext context){
    showModalBottomSheet(
      context: context, 
      builder: (BuildContext context){
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Upload from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera();
                },
              ),
              
              
            ],
          ),
          );
      }
    );
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () {
                  passData();
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/');
                },
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 6),
              alignment: Alignment.center,
              child: const Text(
                'What is this establishment called?',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
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
            controller: establishmentController,
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
        const SizedBox( height: 12),
        Container(
          padding: const EdgeInsets.only(top: 6,left: 8),
          alignment: Alignment.centerLeft,
          child: const Text(
            'Landmark: (optional)',
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox( height: 12),
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
            controller: landmarkController,
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
            
        const SizedBox( height: 20),
        //ImagePickerButton(),
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
         const SizedBox(height: 10),
         SingleChildScrollView(
          scrollDirection: Axis.horizontal,
           child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            
             children: [
              OutlinedButton(
                onPressed: () {
                  _showOptionsForImageUpload(context);
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
                //  IconButton(
                //   padding: EdgeInsets.only(left: 10),
                //   onPressed: (){
                //     _s
                //   }, 
                //   icon: const Icon(Icons.add_a_photo_outlined,size: 30)
                //   ),
                const SizedBox(width: 10),
                if(images.isNotEmpty)
                Wrap(
                spacing: 5,
                runSpacing: 10,
                children: images.map((image) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [

                      Image.file(File(image.path), height: 100, width: 100),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          onPressed: (){
                            _removeImage(image);
                          }, 
                          icon: const Icon(Icons.close,color: Colors.grey,size: 20)
                          ),
                      )
                    ],
                  );
                }).toList(),
              )
                
             ],
           ),
         ),
         const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            if (establishmentController.text.isNotEmpty && images.isNotEmpty) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Align(
                    alignment: Alignment.center,
                    child: AlertDialog(
                      title: const Text('Establishment location Submitted'),
                      content: const Text('Your pinned location has been submitted and will be reviewed by the admin. Thank you'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('OK'),
                          onPressed: () {
                            passData();
                            LocationInformation().uploadImages();
                            _clearAll();
                            Navigator.of(context).pop(); //Close the dialog
                            Navigator.of(context).pop();  //Close current suggest loc page
                          //   Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => const SuggestPinLocation(),
                          //   ),
                          // );
                    
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            } else {
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
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class LocationInformation {
  static final LocationInformation _instance = LocationInformation._internal();

  factory LocationInformation() {
    return _instance;
  }

  LocationInformation._internal();
  
  String locationName = "", landmark = "",address = "",locationtype="";
  int locationType = 0;
  List<XFile> images = [];
  List<String> imagePaths = [];
  LatLng coordinates =  const LatLng(0,0);

  Future<void> _uploadImages(List<XFile> images) async {
    if (images.isEmpty) return;
  
      String uploadUrl = "https://rutaco.online/image_upload.php"; // Replace with your actual URL
      List<XFile> imagesInstance = List.from(images);
      for (XFile image in imagesInstance) {
        var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
        request.files.add(await http.MultipartFile.fromPath('file', image.path));

        //Send the request for each image
        try {
          var res = await request.send();
          var response = await http.Response.fromStream(res);
          final responseData = jsonDecode(response.body);

          if (responseData['status'] == 'success') {
            String imagePath = responseData['path'];
            imagePaths.add(imagePath);
            print("Image uploaded to: $imagePath");
          } else {
            print("Upload failed for ${image.name}: ${responseData['message']}");
          }
        } catch (e) {
          print("Error uploading image: $e");
        }

      }
    

    
  }

  void setInfo(String locName, String landmark,String locType) {
    locationName = locName;
    this.landmark = landmark;
    locationtype = locType;
  }

  void setLatLng(LatLng position, String address) {
    print(position);
    coordinates = position;
    this.address = address;
  }

  void insertImages(List<XFile> images) {
    this.images = images;
    print("Images ready to be uploaded: $images");
    print("LatLng   : $coordinates");
  }

  String getLocationName() {
    return locationName;
  }

  String getLandmark() {
    return landmark;
  }

  

  List<XFile> getImages() {
    return images;
  }

  Future<void> uploadImages()  async {
  if (images.isNotEmpty) {
    await _uploadImages(images);
    insertToDB();
  } else {
    print("No images to upload.");
  }
} 
  void insertToDB() async{
    String url = 'https://rutaco.online/insert_location_tbl.php';
    switch(locationtype) {
      case 'terminal':
        locationType = 1;
        break;
      case 'establishment':
        locationType = 2;
        break;
    }
    

    
    var data = {
      'landmark': landmark,
      'location_name': locationName,
      'address': address,
      'user_id': '1',
      'location_type_id': locationType.toString(),
      'longitude': coordinates.longitude.toString(),
      'latitude': coordinates.latitude.toString(),
      
      'image_paths': imagePaths.join(',')
  };

   //Sending POST request
  var response = await http.post(
    Uri.parse(url),
    body: data,
  );

  //Check the response from the server
  if (response.statusCode == 200) {
    print('Data inserted successfully: ${response.body}');
  } else {
    print('Failed to insert data: ${response.statusCode}');
  }
  }
}

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class RouteFinder extends StatefulWidget {
  const RouteFinder({super.key});

  @override
  _RouteFinderState createState() => _RouteFinderState();
}

class _RouteFinderState extends State<RouteFinder> {
  TextEditingController fromController = TextEditingController();
  TextEditingController toController = TextEditingController();
  bool isSwapped = false;
  late String lat, long;
  FocusNode fromFocusNode = FocusNode();
  FocusNode toFocusNode = FocusNode();

  void swapFields() {
    setState(() {
      // Swap the text
      String tempText = fromController.text;
      fromController.text = toController.text;
      toController.text = tempText;

      // Toggle the swap state
      isSwapped = !isSwapped;
    });
  }
  void initState(){
    super.initState();

    fromFocusNode.addListener((){
      setState(() {
        
      });
    });
    toFocusNode.addListener((){
      setState(() {
        
      });
    });
  }
  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    fromFocusNode.dispose();
    toFocusNode.dispose();
    super.dispose();
  }


  // For checking permission to access user's current location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location service disabled');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location Permissions are denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }
    return await Geolocator.getCurrentPosition();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // From and To.. with icons
            Container(
              padding: const EdgeInsets.only(bottom: 13, left: 5, right: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 3.5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      if (isSwapped)
                        const Icon(Icons.location_on, size: 25, color: Color(0xff1f41bb))
                      else
                        const Icon(Icons.circle, size: 17, color: Color(0xffc2d0ff)),
                      Container(
                        width: 2,
                        height: 40,
                        color: const Color(0xffc2d0ff),
                      ),
                      if (isSwapped)
                        const Icon(Icons.circle, size: 17, color: Color(0xffc2d0ff))
                      else
                        const Icon(Icons.location_on, size: 25, color: Color(0xff1f41bb)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        if (isSwapped)
                          buildTextField('To...', toController, toFocusNode)
                        else
                          buildTextField('From..', fromController, fromFocusNode),
                        const SizedBox(height: 8),
                        if (isSwapped)
                          buildTextField('From..', fromController, fromFocusNode)
                        else
                          buildTextField('To...', toController, toFocusNode),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.swap_vert, size: 30),
                    onPressed: swapFields,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // user's location
            InkWell(
              onTap: () {
                _getCurrentLocation().then((value) {
                  lat = '${value.latitude}';
                  long = '${value.longitude}';
                  String locationText = "Your Location";
                  setState(() {
                    if (fromFocusNode.hasFocus) {
                      fromController.text = locationText;
                    } else if (toFocusNode.hasFocus) {
                      toController.text = locationText;
                    }
                  });
                  print("Lat: "+lat+" Long: " + long);
                });
              },
              child: Container(
                padding: const EdgeInsets.only(top: 10, bottom: 13, left: 10, right: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 3.5),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.my_location, size: 24, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Your location',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String hintText, TextEditingController controller, FocusNode focusNode) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 3.5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide.none,
          ),
          suffixIcon:focusNode.hasFocus && controller.text.isNotEmpty ?
            IconButton( 
              icon: const Icon(Icons.clear),
              onPressed:(){
                setState(() {
                  controller.clear();
                });
              })
              :null,
        ),
        onChanged: (text){
              setState(() {
                if(controller.text.isEmpty){

                }
              });
            }
      ),
    );
  }
}

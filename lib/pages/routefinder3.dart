
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'searchpage.dart';

class routefinder3 extends StatefulWidget {
  @override
  final List<dynamic> legs;
  final List<dynamic> steps;
  final String origin;
  final String destination;

  const routefinder3({
    super.key,
    required this.legs,
    required this.steps,
    required this.origin,
    required this.destination,
  });

  @override
  ThirdScreenState createState() => ThirdScreenState();
}

class ThirdScreenState extends State<routefinder3> {
  late List<dynamic> legs;
  late List<dynamic> steps;
  late GoogleMapController _mapController;
  final LatLng _startLocation =
      const LatLng(14.831582, 120.903786); //  start location
  final LatLng _destinationLocation =
      const LatLng(34.0522, -118.2437); //  destination location

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  //pictires, icons
  SvgPicture busIcon = SvgPicture.asset('assets/icons/bus2.svg');
  SvgPicture taxiIcon = SvgPicture.asset('assets/icons/taxi.svg');
  SvgPicture walkIcon = SvgPicture.asset('assets/icons/walk2.svg');
  //SvgPicture bus = SvgPicture.asset('assets/icons/bus2.svg');

  //here
  SvgPicture ya = SvgPicture.asset('sample');

  //search page
  @override
  void initState() {
    super.initState();
    legs = widget.legs;
    steps = widget.steps;
    print(legs);
    print(
        '----------------------------------------------------------------\n------------------------------------------------');
    _fromController.text = widget.origin;
    _toController.text = widget.destination;
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  //to searchpage.dart
  void _navigateToSearchPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  //next dots
  List<Widget> _generateDots(int numberOfDots, List<Color> colors) {
    List<Widget> dots = [];
    for (int i = 0; i < numberOfDots; i++) {
      dots.add(
        Container(
          height: 20.0,
          width: 20.0,
          decoration: BoxDecoration(
            color: colors[i],
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    return dots;
  }

  @override
  Widget build(BuildContext context) {
    //next dots
    int numberOfDots = 3; // Number of dots
    List<Color> colors = [
      Colors.blue,
      Colors.black,
      Colors.black,
    ]; // Colors for each dot based on the criteria

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //next from search, navigate search bar finished design
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 20, right: 5, left: 5),
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
                  child: GestureDetector(
                    //search
                    onTap:
                        _navigateToSearchPage, // Navigate when tapped| search
                    child: Container(
                      margin: const EdgeInsets.only(right: 20.0, top: 10),
                      height: 40,
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
                      child: AbsorbPointer(
                        // Prevent user from typing directly
                        child: TextFormField(
                          //navigate to search bar
                          controller: _fromController,
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
                    ),
                  ),
                ),
              ],
            ),

            //next To search, navigate search bar finished design
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 5, left: 5),
                  alignment: Alignment.center,
                  height: 48.89,
                  width: 48.89,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset('assets/icons/pin.svg'),
                ),
                Expanded(
                  child: GestureDetector(
                    //search
                    onTap:
                        _navigateToSearchPage, // Navigate when tapped | search
                    child: Container(
                      margin: const EdgeInsets.only(right: 20.0),
                      height: 40,
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
                      child: AbsorbPointer(
                        // Prevent user from typing directly | search
                        child: TextFormField(
                          controller: _toController,
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
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),

            //next display map and marker - finished design
            SizedBox(
              width: double.infinity,
              height: 300,
              child: GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  _setMarkers();
                },
                initialCameraPosition: CameraPosition(
                  target: _startLocation,
                  zoom: 11.5,
                ),
                markers: _markers,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            //next Routes , save icon - finished design
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 30.0),
                  child: const Text(
                    'Routes',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.only(left: 30),
                  alignment: Alignment.center,
                  height: 48.89,
                  width: 48.89,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset('assets/icons/save.svg'),
                ),
              ],
            ),

            //next 3 icons - unfinished design
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 10, right: 10),
                  alignment: Alignment.center,
                  height: 48.89,
                  width: 48.89,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset('assets/icons/walk2.svg'),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.only(left: 30),
                  alignment: Alignment.center,
                  height: 48.89,
                  width: 48.89,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset('assets/icons/bus2.svg'),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.only(left: 30),
                  alignment: Alignment.center,
                  height: 48.89,
                  width: 48.89,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset('assets/icons/walk2.svg'),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.only(left: 30),
                  alignment: Alignment.center,
                  height: 48.89,
                  width: 48.89,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset('assets/icons/taxi.svg'),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.only(left: 30),
                  alignment: Alignment.center,
                  height: 48.89,
                  width: 48.89,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset('assets/icons/taxi.svg'),
                ),
              ],
            ),

            //next dots with lines -unfinished design
            Stack(
              alignment: Alignment.center,
              children: [
                // Line
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0),
                  height: 2.0,
                  width: 900.0, // Adjust width based on number of dots
                  color: Colors.black,
                ),
                // Dots
                Positioned(
                  bottom:
                      10.0, // Adjust as needed to position dots above the line
                  left: 20.0,
                  right: 20.0,
                  child: Row(
                    // Distribute dots with equal spacing
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Generate dots and wrap each dot in an Expanded widget
                      ..._generateDots(numberOfDots, colors)
                      // .map((dot) => Expanded(child: dot)) // Wrap each dot with Expanded
                      // .toList(), // Convert iterable to list
                    ],
                  ),
                ),
              ],
            ),

            //next
            //  SingleChildScrollView(
            //   child:Column(
            //     children: [
            //     Container(
            //       height: 500,
            //        decoration: BoxDecoration(
            //   color: Colors.white,
            //   borderRadius: BorderRadius.circular(10),
            // ),
            //       child: Container(

            //       ),

            //     )

            //   ],) ,)
            const SizedBox(
              height: 10,
            ),

            // Expanded(
            //   child: ListView.builder(
            //     itemCount: steps.length,
            //     itemBuilder: (context, index) {
            //       final step = steps[index];
            //       return ListTile(
            //         title: Text(
            //             '${step['travel_mode']} - ${step['html_instructions']}'),
            //         subtitle: Text('Duration: ${step['duration']['text']}'),
            //       );
            //     },
            //   ),
            // ),

            Expanded(
              child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: steps.length,
                  itemBuilder: (context, index) {
                    final step = steps[index];

                    // Example SVG Picture, replace with your actual SVG asset
                    SvgPicture picwalk =
                        SvgPicture.asset('assets/icons/walk2.svg');
                    SvgPicture picride =
                        SvgPicture.asset('assets/icons/bus2.svg');

                    // Assuming you have the necessary fields in each leg
                    String transpoName = step['travel_mode'] ?? 'Unknown';
                    String time = step['duration']['text'] ?? 'N/A';
                    String geton = step['html_instructions'] ?? 'N/A';
                    String instruction = step['html_instructions'] ?? 'N/A';
                    String fare = step['fare'] ?? 'N/A';
                    String getoff = step['getoff'] ?? 'N/A';
                    String route = step['route'] ?? 'N/A';

                    if (transpoName == 'TRANSIT') {
                      return ride(transpoName, fare, time, route, geton, getoff,
                          picride);
                    } else {
                      return walk(instruction, picwalk);
                    }
                  }),
            ),

            // Container(
            //   height: 290,
            //   child: SingleChildScrollView(
            //     child: Column(
            //       children: <Widget>[
            //         walk("Walk towards the highway", walkIcon),
            //         //transpoName, fare, time, route, geton, getoff
            //         ride("Jeep", "12.00", "25 mins", "Malolos - Marilao",
            //             "waltermart malolos", "sm marilao", busIcon),
            //         walk("Walk a little", walkIcon),
            //         ride("Trycicle", "12.00", "25 mins", "Malolos - Marilao",
            //             "waltermart malolos", "sm marilao", taxiIcon),
            //         ride("Bus", "12.00", "25 mins", "Malolos - Marilao",
            //             "waltermart malolos", "sm marilao", taxiIcon),
            //         // Container(
            //         //   height: 200,
            //         //   padding: EdgeInsets.all(16.0),
            //         //   margin: EdgeInsets.all(8.0),
            //         //   color: Colors.blue,
            //         //   child: Text(
            //         //     'Container 2',
            //         //     style: TextStyle(color: Colors.white),
            //         //   ),
            //         // ),
            //       ],
            //     ),
            //   ),
            // ),

            //end
          ],
        ),
      ),
    );
  }

  //next marker
  final Set<Marker> _markers = {};

  void _setMarkers() {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('start_marker'),
          position: _startLocation,
          infoWindow: const InfoWindow(title: 'Start Location'),
        ),
      );
      _markers.add(
        Marker(
          markerId: const MarkerId('destination_marker'),
          position: _destinationLocation,
          infoWindow: const InfoWindow(title: 'Destination Location'),
        ),
      );
    });
  }

  //next transportation info
  //next walk
  Widget walk(String text, SvgPicture pic) {
    return Container(
      width: double.infinity, // Make the width match the parent
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Shadow color with opacity
            offset: const Offset(0, 4), // Offset for the shadow
            blurRadius: 8, // Blur radius for the shadow
            spreadRadius: 2, // Spread radius for the shadow
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 2, // 20% of the width
              child: Container(
                child: pic,
              ),
            ),
            Expanded(
              flex: 8, // 80% of the width
              child: Container(
                color: Colors.white, // Right side color
                child: Center(
                  child: Text(
                    text,
                    style: const TextStyle(
                        color: Colors.black), // Adjust text color for contrast
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //next ride
  //transpoName, fare, time, route, geton, getoff
  Widget ride(String transpoName, String fare, String time, String route,
      String geton, String getoff, SvgPicture pic) {
    return Container(
      width: double.infinity, // Make the width match the parent
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Shadow color with opacity
            offset: const Offset(0, 4), // Offset for the shadow
            blurRadius: 8, // Blur radius for the shadow
            spreadRadius: 2, // Spread radius for the shadow
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 2, // 20% of the width
              child: Container(
                child: pic,
              ),
            ),
            Expanded(
              flex: 8, // 80% of the width
              child: Column(
                children: [
                  //transpoName, fare, time
                  Row(
                    children: [
                      Text(
                        transpoName,
                        style: const TextStyle(color: Colors.black),
                      ),
                      const Spacer(),
                      Text(
                        fare,
                        style: const TextStyle(
                            color:
                                Colors.black), // Adjust text color for contrast
                      ),
                      const Spacer(),
                      Text(
                        time,
                        style: const TextStyle(
                            color:
                                Colors.black), // Adjust text color for contrast
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  //route
                  Row(
                    children: [
                      Expanded(
                        flex: 4, // 20% of the space
                        child: Container(
                          padding: const EdgeInsets.only(
                              right: 8.0), // Space between the two texts
                          child: const Text(
                            "Route",
                            style: TextStyle(color: Colors.black),
                            textAlign:
                                TextAlign.start, // Align text to the start
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6, // 80% of the space
                        child: Text(
                          route,
                          style: const TextStyle(color: Colors.black),
                          textAlign: TextAlign.start, // Align text to the start
                        ),
                      ),
                    ],
                  ),

                  //get on
                  Row(
                    children: [
                      Expanded(
                        flex: 4, // 20% of the space
                        child: Container(
                          padding: const EdgeInsets.only(
                              right: 8.0), // Space between the two texts
                          child: const Text(
                            "Get on",
                            style: TextStyle(color: Colors.black),
                            textAlign:
                                TextAlign.start, // Align text to the start
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6, // 80% of the space
                        child: Text(
                          geton,
                          style: const TextStyle(color: Colors.black),
                          textAlign: TextAlign.start, // Align text to the start
                        ),
                      ),
                    ],
                  ),
                  //get off
                  Row(
                    children: [
                      Expanded(
                        flex: 4, // 20% of the space
                        child: Container(
                          padding: const EdgeInsets.only(
                              right: 8.0), // Space between the two texts
                          child: const Text(
                            "Get off",
                            style: TextStyle(color: Colors.black),
                            textAlign:
                                TextAlign.start, // Align text to the start
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6, // 80% of the space
                        child: Text(
                          getoff,
                          style: const TextStyle(color: Colors.black),
                          textAlign: TextAlign.start, // Align text to the start
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

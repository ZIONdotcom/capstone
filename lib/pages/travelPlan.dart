import 'package:flutter/material.dart';
import 'package:capstone/pages/travelPlan2.dart';
import 'package:capstone/pages/travelPlan3.dart';

class travelPlan extends StatefulWidget {
  const travelPlan({super.key});

  @override
  State<travelPlan> createState() => _TravelPlanState();
}

class _TravelPlanState extends State<travelPlan> {
  bool isVisible = true;
  // List to hold selected locations with their latitudes and longitudes
  List<Map<String, String>> _selectedLocations = [];

  void _navigateToSearchPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const travelPlan2()),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        // Add the selected location to the list
        _selectedLocations.add({
          'location': result['location'] ?? '',
          'latitude': result['latitude'] ?? '',
          'longitude': result['longitude'] ?? '',
        });
        //text visibility
        isVisible = !isVisible;
      });
    }
  }

  //remove location
  void _removeLocation(int index) {
    setState(() {
      _selectedLocations.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: <Widget>[
          // Background
          Column(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  color: const Color(0xFFC2D0FF),
                ),
              ),
              Expanded(
                flex: 6,
                child: Container(
                  color: Colors.white,
                ),
              ),
            ],
          ),

          Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 150, bottom: 30),
                  child: const Text(
                    'We will help you plan your trip!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              //visibility
              Visibility(
                visible: isVisible,
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 30),
                  width: 250,
                  child: const Text(
                    'You can search several destinations and we will suggest you an efficient itinerary!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              Center(
                child: Container(
                  //mainAxisSize: MainAxisSize.min,
                  // width: 350,
                  // height: 250,
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  margin:
                      const EdgeInsets.only(bottom: 150, left: 20, right: 20),
                  decoration: BoxDecoration(
                    color: Colors.white, // Background color of the box
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(0.3), // Shadow color with opacity
                        offset: const Offset(
                            0, 4), // Horizontal and vertical offset
                        blurRadius: 8.0, // Blur radius
                        spreadRadius: 2.0, // Spread radius
                      ),
                    ], // Corner radius
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: const Text(
                          'Where are your destinations?',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _navigateToSearchPage,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                    0.2), // Shadow color with opacity
                                offset: const Offset(
                                    0, 2), // Horizontal and vertical offset
                                blurRadius: 4.0, // Blur radius
                                spreadRadius: 1.0, // Spread radius
                              ),
                            ],
                          ),
                          child: TextFormField(
                            enabled: false,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 15.0, vertical: 8.0),
                              border: InputBorder.none,
                              fillColor: Colors.white,
                              filled: true,
                              hintText: 'Type destination here..',
                            ),
                            onTap: _navigateToSearchPage,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Displaying the list of selected locations
                      ListView.builder(
                        shrinkWrap: true,
                        //physics: NeverScrollableScrollPhysics(),
                        itemCount: _selectedLocations.length,
                        padding: EdgeInsets.all(0),
                        itemBuilder: (context, index) {
                          final location = _selectedLocations[index];
                          return ListTile(
                            title: Text(location['location'] ?? ''),
                            // subtitle: Text('Lat: ${location['latitude']}, Long: ${location['longitude']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _removeLocation(index);
                              },
                            ),
                          );
                        },
                      ),

                      if (_selectedLocations.length >= 2)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => travelPlan3()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xff1F41BB),
                            minimumSize: const Size(275, 40),
                          ),
                          child: const Text('Submit'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Content
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'polylineDecoder.dart';
import 'package:capstone/pages/routeCreation.dart';

class MapForPolylines extends StatefulWidget {
  final Set<Polyline> polyline;

  const MapForPolylines({
    super.key,
    required this.polyline,
  });

  @override
  _MapForPolylinesState createState() => _MapForPolylinesState();
}

class _MapForPolylinesState extends State<MapForPolylines> {
  bool addpointClicked = false;
  bool pointAdded = false;
  double _zoom = 14.0;
  GoogleMapController? _mapController;
  final String apiKey = 'AIzaSyC88-Wkb5_LmPU5OCQwPOMDTry3RGh1J00'; 
  final Polylinedecoder _polylineDecoder = Polylinedecoder('AIzaSyC88-Wkb5_LmPU5OCQwPOMDTry3RGh1J00');
  //final Set<Polyline> _polylines = {};
  int numberOfPoints = 0;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List <LatLng> pinnedLocations = [];
  Map <int, List<LatLng>> step_polyline = {};

  @override
  void initState(){
    super.initState();
    addStartPolyline();

  }
  // This method will be called when the map is ready and its controller is available
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void addStartPolyline() async{
    if (widget.polyline.isNotEmpty && pinnedLocations.isEmpty) {
      List<LatLng> firstPolylinePoints = widget.polyline.first.points;
      List<LatLng> lastPolylinePoints = widget.polyline.last.points;
      pinnedLocations.add(firstPolylinePoints.first);
      pinnedLocations.add(lastPolylinePoints.last);

      // Marker for the first point
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: firstPolylinePoints.first,
          infoWindow: const InfoWindow(title: 'Start Point'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      // Marker for the last point
      markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: lastPolylinePoints.last,
          infoWindow: const InfoWindow(title: 'End Point'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      print(markers);
    }
  List<LatLng> startPolylinepoints;
    if(polylines.isEmpty){
      startPolylinepoints = await _polylineDecoder.getRoutePolyline([pinnedLocations[numberOfPoints], pinnedLocations[numberOfPoints+1]]);
      Polyline startPoly = Polyline(
        polylineId: const PolylineId('polyline0'),
        points: startPolylinepoints,
        color: Colors.blue,
        width: 5
      );
      polylines.add(startPoly);
      print(polylines);
    }
    else{
      print('start point not added');
    }
  }
  Future<String> _getAddress(LatLng position) async {
  try {
    String address = 'No address found';
    String placeName = 'Unknown Place';
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

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
        // placeName = data['results'][1]['name']; 
        // print('place name: $placeName $address');
        // DataManager().set_temporary_LocationName(placeName);
       
        // print('temporary location: $temporary_LocationName');
      }
    }
    return address;
  } catch (e) {
    return 'Error retrieving location data: ${e.toString()}';
  }
}

  void addMarker(LatLng pinnedLocation) async {
    List<LatLng> polylinePoints, prevPolylinepoints, nextPolylinepoints;
    String address = await _getAddress(pinnedLocation);
    print(address);
    print(pinnedLocation);
    MarkerId markerID = MarkerId("point$numberOfPoints");
    Marker? existingMarker;

    setState(() {
      for (Marker _marker in markers){
        if(_marker.markerId == markerID){
          existingMarker = _marker;
        }
      }
      if(existingMarker !=null){
        markers.remove(existingMarker);
        pinnedLocations.removeAt(numberOfPoints);
      }
      Marker newMarker = Marker(
        markerId: markerID,
        position: pinnedLocation
      );
      markers.add(newMarker);
      pinnedLocations.insert(numberOfPoints,pinnedLocation);
      print(pinnedLocations);
    });
    
    
    // for polyline
    polylinePoints = await _polylineDecoder.getRoutePolyline([pinnedLocations[numberOfPoints], pinnedLocations[numberOfPoints+1]]);
    PolylineId nextPolylineid = PolylineId('polyline${numberOfPoints+1}');
     PolylineId previousPolylineid = PolylineId('polyline${numberOfPoints-1}');
    PolylineId polylineID = PolylineId('polyline$numberOfPoints');
    Polyline? existingPolyline;
    Polyline? nextPolyline;
    Polyline? prevPolyline;

      for (Polyline poly in polylines){
        setState(() {
          if(poly.polylineId == polylineID){
            existingPolyline = poly;           
          }
          if(poly.polylineId == previousPolylineid){
            prevPolyline = poly;            
          }
          if(poly.polylineId == nextPolylineid){
            nextPolyline = poly;               
          }
          
        });
        
      }
      if(existingPolyline!= null){
            polylines.remove(existingPolyline);
          }
          Polyline newPolyline = Polyline(
            polylineId: polylineID,
            points: polylinePoints,
            color: Colors.blue,
            width: 5,
          );
          
          polylines.add(newPolyline);
      
      if(prevPolyline != null){
        prevPolylinepoints = await _polylineDecoder.getRoutePolyline([pinnedLocations[numberOfPoints-1], pinnedLocations[numberOfPoints]]);
        setState(() {
          Polyline prevPolyline = Polyline(
            polylineId: previousPolylineid,
            points: prevPolylinepoints,
            color: Colors.blue,
            width: 5,
          );
          polylines.remove(prevPolyline);
          polylines.add(prevPolyline);
        });
        // previous polylime
        
        
      }
      if(nextPolyline != null){
        nextPolylinepoints = await _polylineDecoder.getRoutePolyline([pinnedLocations[numberOfPoints], pinnedLocations[numberOfPoints+1]]);
        setState(() {
          Polyline nextPolyline = Polyline(
            polylineId: nextPolylineid,
            points: nextPolylinepoints,
            color: Colors.blue,
            width: 5,
          );
          polylines.remove(nextPolyline);
          polylines.add(nextPolyline);
        });
      print(polylines);
    }
  }

  @override
  Widget build(BuildContext context) {
    LatLng initialPosition = widget.polyline.isNotEmpty
        ? widget.polyline.first.points.first
        : const LatLng(14.831582, 120.903786);

    return Scaffold(
      body: Stack(
        children: [
          // Dialog for the map content
          Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 300,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: initialPosition,
                    zoom: _zoom,
                  ),
                  markers: markers,
                  polylines: pointAdded ? polylines : widget.polyline,
                  onMapCreated: _onMapCreated, 
                  onTap: (LatLng pinnedLocation){
                    if(addpointClicked){
                      setState(() {
                        pointAdded = true;
                        addpointClicked = false;
                        addMarker(pinnedLocation);
                      });
                      
                    }
                    
                  },
                ),
              ),
            ),
          ),

          // Add point button or text based on state
          Positioned(
            top: 25,
            left: 0,
            right: 0,
            child: Center(
              child: addpointClicked
                  ? const Padding(
                    padding: EdgeInsets.only(top:25.0),
                    child: Text(
                        "(pin a point)",
                        style: TextStyle(
                          fontSize: 13, 
                          color: Colors.black,
                          letterSpacing: 1.2, 
                          wordSpacing: 2.0,      
                        ),
                      ),
                  )
                  : TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color.fromARGB(255, 99, 131, 249),
                        minimumSize: const Size(100, 10),
                      ),
                      child: const Text("Add point", style: TextStyle(fontSize: 13),),
                      onPressed: () {
                        setState(() {
                          _zoom = 17.0;  
                          addpointClicked = true; 
                          numberOfPoints++;
                        });
                        //Now you can access the _mapController to animate the camera
                        if (_mapController != null) {
                          _mapController!.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: initialPosition,
                                zoom: _zoom,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    

            ),
          ),
          Positioned(
            bottom: 10,
            right: 15,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color.fromARGB(255, 99, 131, 249),
                minimumSize: const Size(60, 2),
              ),
              child: const Text("Confirm", style: TextStyle(fontSize: 13),),
              onPressed: () {
                
                print('Confirm: $pinnedLocations');
                DataManager().insert_midpoint(DataManager().getCurrentPageTracker(), pinnedLocations,false);
                Navigator.of(context).pop();

                //Now you can access the _mapController to animate the camera
              },
            ),
          ),

          // Close button
          Positioned(  
            right: 8,
            top: 5,
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.polyline.clear();
              },
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }
}

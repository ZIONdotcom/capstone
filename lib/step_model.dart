import 'package:capstone/terminal_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WalkStepModel {
  final String instruction;
  final LatLng endlocation;
  //final String walkingRequirement; // Specific requirement for walking

  WalkStepModel({
    required this.instruction,
    required this.endlocation,
    // required this.walkingRequirement,
  });

  //for testing only
  @override
  String toString() {
    return 'WalkStep: $instruction, End location: (${endlocation.latitude}, ${endlocation.longitude})';
  }
}

class TransportStepModel {
  final String transportation;
  final double fare;
  final String time;
  final LatLng geton;
  final LatLng getoff;

  TransportStepModel({
    required this.transportation,
    required this.fare,
    required this.time,
    required this.geton,
    required this.getoff,
  });

  //for testing only
  @override
  String toString() {
    return 'TransportStep: $transportation, Fare: $fare, Time: $time, Get on at: (${geton.latitude}, ${geton.longitude}), Get off at: (${getoff.latitude}, ${getoff.longitude})';
  }
}

class RouteSuggestion {
  final String puvName;
  final String puvType;
  final Terminal startTerminal;
  final Terminal endTerminal;

  RouteSuggestion({
    required this.puvName,
    required this.puvType,
    required this.startTerminal,
    required this.endTerminal,
  });
}

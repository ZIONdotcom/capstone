//dapat nasa labas to nung page file natin-----------------
//ginamit na class pag store----------------------------------------------------------
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PolyPoints {
  final int id;
  final LatLng origin;
  final LatLng destination;
  final List<LatLng> polylinePoints;

  PolyPoints({
    required this.id,
    required this.origin,
    required this.destination,
    required this.polylinePoints,
  });
}

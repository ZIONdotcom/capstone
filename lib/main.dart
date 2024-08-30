import 'package:capstone/pages/draft_routecreation.dart';
import 'package:capstone/pages/routefinder3.dart';
import 'package:flutter/material.dart';
import 'package:capstone/pages/routeCreation.dart';
import 'package:capstone/pages/test.dart';
import 'package:capstone/pages/searchpage.dart';
import 'package:capstone/pages/routeFinder.dart';
import 'package:capstone/pages/routeFinder2.dart';
import 'package:capstone/pages/travelPlan.dart';
import 'package:capstone/pages/travelPlan2.dart';
import 'package:capstone/pages/travelPlan3.dart';
import 'package:capstone/pages/travelPlan4.dart';
import 'package:capstone/pages/pinLocation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      home: PinLocation(),
      //home:  RouteFinder2(latOrigin: '', longOrigin: '', latDestination: '', longDestination: '', destinationName: '', originName: '',)
    );
  }
}

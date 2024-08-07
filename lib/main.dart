import 'package:capstone/pages/routeFinder.dart';
import 'package:flutter/material.dart';
import 'package:capstone/pages/routeCreation.dart';
import 'api_services.dart';

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
        home: Routecreation());
  }
}

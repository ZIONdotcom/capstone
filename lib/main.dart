import 'package:capstone/pages/dashboard.dart';
import 'package:capstone/pages/routeFinder.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            fontFamily: 'Poppins', scaffoldBackgroundColor: Colors.white),
        //home: const RouteFinder()
        home: Dashboard());
  }
}

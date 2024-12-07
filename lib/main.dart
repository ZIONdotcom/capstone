import 'package:capstone/pages/dashboard.dart';
import 'package:capstone/pages/testlang.dart';
import 'package:flutter/material.dart';
//import 'package:capstone/pages/routeFinderAlgo.dart';
import 'package:capstone/pages/userRouteSuggest.dart';
import 'package:capstone/pages/userRouteSuggest.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    // home: const Userroutesuggest(
    //   latOrigin: '32',
    //   longOrigin: '32',
    //   latDestination: '43',
    //   longDestination: '242',
    //   destinationName: 'dfger',
    //   originName: 'srgwr',
    // ));
  }
}

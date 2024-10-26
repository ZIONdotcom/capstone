import 'package:capstone/pages/suggestPinLocation.dart';
import 'package:flutter/material.dart';
import 'routeCreation.dart';
import 'package:capstone/pages/routeFinder.dart';
import 'package:capstone/pages/travelPlan.dart';
import 'package:capstone/pages/commutingGuide.dart';
import 'package:capstone/pages/popularRoutes.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Future<List<dynamic>>? _popularRoutes;
  Future<List<dynamic>> fetchRoutes() async {
    final response = await http.get(Uri.parse('https://rutaco.online/get_dataPopularRoutes.php'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load routes');
    }
  }

  @override
  void initState(){
    super.initState();
    _popularRoutes = fetchRoutes();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: const Color(0xFFc2d0ff),
        title: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Routa Co',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1f41bb)),
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 8),
              Text(
                'Travel Efficiently',
                style: TextStyle(
                  //fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.only(
                    right: 20.0, left: 10.0, top: 5.0, bottom: 5.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1f41bb),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded,
                        color: Colors.white, size: 15),
                    SizedBox(width: 10),
                    Text(
                      '00.0',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.account_circle_rounded,
                    color: Colors.black, size: 35),
                onPressed: () {},
              )
            ],
          )
        ],
      ),
      body: Stack(
        children: [
          //BACKGROUND
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height / 6,
            child: Container(
              color: const Color(0xFFc2d0ff),
            ),
          ),

          //FLOATING CONTAINER
          Align(
            alignment: const Alignment(0.0, -0.80),
            child: Container(
              padding: const EdgeInsets.only(
                  right: 40.0, left: 40.0, top: 30, bottom: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Planning to commute?',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            offset: const Offset(0, 2.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ]),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.search_outlined,
                          color: Colors.white, size: 18),
                      onPressed: () {
                        //SEARCH LOCATION

                        //christine
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RouteFinder(),
                          ),
                        );
                      },
                      label: const Text(
                        'Search Location',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.only(right: 30.0, left: 30.0),
                          backgroundColor: const Color(0xff1F41BB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 50),
          Positioned(
            top: 250,
            left: 10,
            child: Column(
              children: [
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.menu_book_outlined,
                          color: Colors.black, size: 25),
                      onPressed: () {
                        // COMMUTING GUIDE
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CommutingGuide(),
                          ),
                        );
                      },
                      label: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Commuting Guide',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Know the basics of commuting',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.only(
                              right: 12.0, left: 11.0, top: 13, bottom: 9.0),
                          backgroundColor: Colors.white,
                          fixedSize: const Size(167, 71),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                  color: Color(0xFFc2d0ff), width: 0.3)),
                          elevation: 2),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.directions_train_outlined,
                          color: Colors.black, size: 25),
                      onPressed: () {
                        //PLAN TRAVEL
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const travelPlan(),
                          ),
                        );
                      },
                      label: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plan Commute Travel',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Select several destinations',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.only(
                              right: 12.0, left: 9.0, top: 13, bottom: 9.0),
                          backgroundColor: Colors.white,
                          fixedSize: const Size(167, 71),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                  color: Color(0xFFc2d0ff), width: 0.3)),
                          elevation: 2),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.route_outlined,
                          color: Colors.black, size: 25),
                      onPressed: () {
                        //ROUTE CREATION
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RouteCreation(),
                          ),
                        );
                      },
                      label: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create your route',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Earn when you',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                            ),
                          ),
                          Text(
                            'submit a route',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.only(
                              right: 12.0, left: 7.0, top: 13, bottom: 9.0),
                          backgroundColor: Colors.white,
                          fixedSize: const Size(167, 71),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                  color: Color(0xFFc2d0ff), width: 0.3)),
                          elevation: 2),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.pin_drop_outlined,
                          color: Colors.black, size: 25),
                      onPressed: () {
                        //PIN SUGGESTION
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SuggestPinLocation(),
                          ),
                        );
                      },
                      label: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Suggest Pin Locations',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Earn points when sharing missing locations',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                            ),
                          ),
                          //   Text(
                          // 'location',
                          // style: TextStyle(
                          //   color: Colors.black,
                          //   fontSize: 9,
                          //   ),
                          //   ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.only(
                              right: 4.0, left: 10.0, top: 11.5, bottom: 9.0),
                          backgroundColor: Colors.white,
                          fixedSize: const Size(167, 71),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                  color: Color(0xFFc2d0ff), width: 0.3)),
                          elevation: 2),
                    ),
                  ],
                ),

                 
              ],
            ),
            
          ),
          Positioned(
            left: 10,
            bottom: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                'Popular Routes',
                  style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: FutureBuilder(
                  future: _popularRoutes,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No routes found"));
                    } 

                    // Remove the ListView.builder and directly build the widgets using Row.
                    return Row(
                      children: [
                        for (var route in snapshot.data!)
                          Container(
                            width: 100,
                            margin: const EdgeInsets.only(left: 1, right: 4.0, top: 2, bottom: 2),
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) => const PopularRoutes(),
                                //   ),
                                // );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.only(right: 3.0, left: 12.0,bottom: 3,top: 3),
                                backgroundColor: Colors.white,
                                fixedSize: const Size(100, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(
                                    color: Color(0xFFc2d0ff), 
                                    width: 0.8,
                                  ),
                                ),
                                elevation: 0.5,
                              ),
                              child: Text(
                                "${route['origin_name']} - ${route['destination_name']}",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        
                        // Add the FloatingActionButton at the end
                        SizedBox(
                          width: 30,
                          height: 50,
                          child: FloatingActionButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PopularRoutes(),
                                ),
                              );
                            },
                            backgroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_forward, color: Color(0xFF1f41bb)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  //ROUTES TO NEXT PAGE
  // Route _gotoRouteCreation() {
  //   return PageRouteBuilder(
  //       pageBuilder: (context, animation, secondaryAnimation) =>
  //           const RouteCreation(),
  //       transitionsBuilder: (context, animation, secondaryAnimation, child) {
  //         const begin = Offset(1.0, 0.0);
  //         const end = Offset.zero;
  //         const curve = Curves.ease;

  //         var tween =
  //             Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
  //         var offsetAnimation = animation.drive(tween);

  //         return SlideTransition(
  //           position: offsetAnimation,
  //           child: child,
  //         );
  //       });
  // }

  // Route _gotoSuggestPinLocation() {
  //   return PageRouteBuilder(
  //       pageBuilder: (context, animation, secondaryAnimation) =>
  //           const SuggestPinLocation(),
  //       transitionsBuilder: (context, animation, secondaryAnimation, child) {
  //         const begin = Offset(1.0, 0.0);
  //         const end = Offset.zero;
  //         const curve = Curves.ease;

  //         var tween =
  //             Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
  //         var offsetAnimation = animation.drive(tween);

  //         return SlideTransition(
  //           position: offsetAnimation,
  //           child: child,
  //         );
  //       });
  // }
}

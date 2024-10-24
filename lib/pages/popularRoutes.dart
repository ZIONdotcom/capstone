import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class PopularRoutes extends StatefulWidget {
  const PopularRoutes({super.key});

  @override
  State<PopularRoutes> createState() => _PopularRoutesState();
}

class _PopularRoutesState extends State<PopularRoutes> {
  Future<List<dynamic>>? _popularroutes;
  Future<List<dynamic>> fetchRoutes() async {
    final response = await http.get(Uri.parse('https://rutaco.online/get_dataPopularRoutes.php'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load routes');
    }
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _popularroutes = fetchRoutes();
  }
  

  @override
  Widget build(BuildContext context) {  
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Popular Routes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: FutureBuilder(
        future: _popularroutes, 
        builder: (context, snapshot){
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No routes found"));
          }
          return Container(
            padding: const EdgeInsets.only(left:4.0,right:4.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var route = snapshot.data![index];
                      return ListTile(
                        contentPadding: const EdgeInsets.only(left: 4.0,right:4.0),
                        title: SizedBox(
                          width: double.infinity,
                          // padding: const EdgeInsets.only( left: 10.0,top:10.0,bottom: 10.0), // Optional: add padding
                          // decoration: BoxDecoration(
                          //   color: Colors.grey[200], // Optional: background color
                          //   borderRadius: BorderRadius.circular(8.0), // Optional: rounded corners
                          // ),
                          child: ElevatedButton.icon(
 
                            onPressed: (){

                            },
                            label: Row(
                               mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Icon(Icons.directions_bus_outlined,color: Color(0xFF1f41bb), size: 50),
                                Column(
                                  
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    
                                    Text("${route['origin_name']} --> ${route['destination_name']}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black
                                    ),),
                                    Text("Popularity: ${route['popularitynumber']}",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black
                                    ),),
                                  ],
                                ),
                              ],
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.only(top: 13, bottom: 9.0,left: 5),
                              backgroundColor: Colors.white,
                              fixedSize: const Size(167, 75),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(
                                      color: Colors.white, width: 0.3)),
                              elevation: 1
                            ),
                          )
                          ),
                        
                      );
                    },
                  )
                )
              ],
            ),
          );

        }
      )
    );
  }
}

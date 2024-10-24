import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CommutingGuide extends StatefulWidget {
  const CommutingGuide({super.key});

  @override
  State<CommutingGuide> createState() => _CommutingGuideState();
}

class _CommutingGuideState extends State<CommutingGuide> {
  Future<List<dynamic>>? commutingGuidedescription;
  bool isTagalog = false;

  Future<List<dynamic>> fetchDescription() async{
    final response = await http.get(Uri.parse('https://rutaco.online/get_dataCommutingGuide.php'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load Commuting guides');
    }
  }

  void _switchLanguage() {
    setState(() {
      isTagalog = !isTagalog; // Toggle language
      commutingGuidedescription = fetchDescription();
    });
  }

  void _showCommutingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12.0),
          insetAnimationCurve: Curves.fastEaseInToSlowEaseOut,
          insetAnimationDuration: const Duration(milliseconds: 300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Stack(
            children: [
              Scrollbar(
                thumbVisibility: true,
                thickness: 5.0,
                radius: const Radius.circular(10),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          isTagalog
                              ? 'Paano magkomyut gamit ang jeep?'
                              : 'How to commute using a jeep?',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(isTagalog
                            ? "Ang jeepney (jeep) ay isang sikat na pampublikong transportasyon sa Pilipinas na kilala sa makulay na disenyo at bukas na upuan."
                            : 'A jeepney (jeep) is a popular public transportation vehicle in the Philippines, known for its vibrant designs and open-air seating.'),
                        Center(
                          child: SvgPicture.asset(
                            'assets/icons/jeep_icon.svg',
                            height: 150,
                            width: 150,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Text(isTagalog
                            ? "Tumayo sa gilid ng kalsada malapit sa isang designated jeepney stop o sa kahabaan ng ruta kung saan madalas dumadaan ang mga jeep."
                            : 'Stand at the roadside near a designated jeepney stop or along the route where jeepneys frequently pass.'),
                        const SizedBox(height: 25),
                        Text(isTagalog
                            ? "Ang mga jeepney ay may signboard sa harap na nagpapakita ng mga stops. Tignan ang signboard para makita kung dumadaan ito sa iyong patutunguhan. Kung papalapit na ang jeep, itaas ang iyong kamay upang ipakita sa drayber na nais mong sumakay."
                            : 'Jeepneys have a signboard with their stops in front. Check the signboard for your stop. When you see a jeepney with your stop approaching, raise your hand to signal the driver to stop.'),
                        const SizedBox(height: 25),
                        Text(isTagalog
                            ? "Sumakay sa likuran o gilid ng jeep. Kung puno, maghintay ng mga pasaherong bababa bago sumakay."
                            : 'You can ask the driver how much is the fare by asking how much and tell your destination.'),
                        const SizedBox(height: 25),
                        const Text(
                          "Pass your fare to the driver, usually through other passengers. It's common to say the fare amount and ask for change if needed.",
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          "As you approach your destination, signal the driver by saying para or tapping on the roof or metal handrails.",
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          "Once the jeepney stops, carefully exit through the back or side entrance.",
                        ),
                        const SizedBox(height: 25),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        isTagalog = !isTagalog;
                      });
                      Navigator.of(context).pop(); 
                      _showCommutingDialog();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(isTagalog ? 'Tagalog' : 'English'),
                        const SizedBox(width: 8),
                        Switch(
                          value: isTagalog,
                          onChanged: (value) {
                            setState(() {
                              isTagalog = value;
                            });
                            Navigator.of(context).pop();
                            _showCommutingDialog();
                          },
                          activeColor: const Color(0xFF1f41bb),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Commuting Guide',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'kheh eehkd jbe e sejfs klefj se nk hrfksje fsjrbs jksbgksj bg sjkefbse',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: _showCommutingDialog,
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2 - 20,
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10), // Border radius
                          border: Border.all(
                            color: const Color(0xFFc2d0ff), // Border color
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/jeep_icon.svg',
                              height: 100,
                              width: 100,
                            ),
                            const Text(
                              'Jeep',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

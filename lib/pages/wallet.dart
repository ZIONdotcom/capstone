import 'package:flutter/material.dart';

class wallet extends StatefulWidget {
  const wallet({super.key});

  @override
  State<wallet> createState() => Wallet();
}

class Wallet extends State<wallet> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            const Center(
              child: Text(
                'Wallet',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,

                  //fontWeight: FontWeight.bold
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding:
                  const EdgeInsets.symmetric(horizontal: 120, vertical: 30),
              decoration: BoxDecoration(
                color: const Color(0xFF1F41BB), // Light blue background
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                children: [
                  const Text(
                    'Points',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    '209.0',
                    style: TextStyle(
                      fontSize: 36.0,
                      fontWeight: FontWeight.bold,
                      //color: Color(0xFF1F41BB),
                      color: Colors.white,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Handle cash out action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFC2D0FF), // Blue background
                      //padding: EdgeInsets.symmetric(horizontal: 50.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text(
                      'Cash Out',
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40.0),
          ],
        ),
      ),
    );
  }
}

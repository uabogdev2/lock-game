import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    // You can replace this with a FlutterLogo or an Image widget later
    return const Text(
      'LOCK GAME',
      style: TextStyle(
        fontSize: 40, // Increased size
        fontWeight: FontWeight.bold,
        color: Colors.blueAccent, // Example color
      ),
      textAlign: TextAlign.center,
    );
  }
}

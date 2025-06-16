import 'package:flutter/material.dart';

void main() {
  runApp(const LockGameApp());
}

class LockGameApp extends StatelessWidget {
  const LockGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lock Game',
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lock Game')),
      body: const Center(
        child: Text('Bienvenue dans Lock Game'),
      ),
    );
  }
}

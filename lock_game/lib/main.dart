import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lock Game',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Lock Game'),
        ),
        body: Center(
          child: Text('Welcome to Lock Game!'),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String name;

  const HomeScreen({required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: Center(
        child: Text("Welcome $name", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

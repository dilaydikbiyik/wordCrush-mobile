import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word Crush')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {},
          child: const Text('Start Game'),
        ),
      ),
    );
  }
}

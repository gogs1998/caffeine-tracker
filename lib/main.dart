import 'package:flutter/material.dart';

void main() {
  runApp(const CaffeineTrackerApp());
}

class CaffeineTrackerApp extends StatelessWidget {
  const CaffeineTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caffeine Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('Caffeine Tracker')),
      ),
    );
  }
}

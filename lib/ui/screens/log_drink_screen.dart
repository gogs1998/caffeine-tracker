import 'package:flutter/material.dart';

/// Placeholder screen for logging a drink.
/// Will be replaced in Phase 2b.
class LogDrinkScreen extends StatelessWidget {
  const LogDrinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A28),
        title: const Text('Log a Drink',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: const Center(
        child: Text(
          '☕  Coming soon in Phase 2b',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      ),
    );
  }
}

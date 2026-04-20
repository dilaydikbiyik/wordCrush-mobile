import 'package:flutter/material.dart';

/// Market where players spend gold to buy jokers.
///
/// TODO (Phase 6): Read PlayerProfile.goldBalance and JokerInventory from providers.
/// TODO (Phase 6): Implement purchase flow with gold sufficiency check.
class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Market')),
      body: const Center(
        child: Text('Market yakında hazır olacak.'),
      ),
    );
  }
}

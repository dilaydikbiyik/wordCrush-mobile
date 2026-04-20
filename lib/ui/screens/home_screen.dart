import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';

/// Main hub: New Game, Scoreboard, Market.
///
/// TODO (Phase 6): Show username (tappable → rename dialog) in top-left.
/// TODO (Phase 6): Show gold balance in top-right via PlayerProvider.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word Crush')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.difficulty),
                child: const Text('Yeni Oyun'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.score),
                child: const Text('Skor Tablosu'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.market),
                child: const Text('Market'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

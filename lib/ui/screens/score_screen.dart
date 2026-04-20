import 'package:flutter/material.dart';

/// Displays overall performance stats (top) and per-game cards (bottom).
///
/// TODO (Phase 6): Load GameRecord list from ObjectBoxService via ScoreProvider.
/// TODO (Phase 6): Build summary stats (total games, best score, avg score, etc.)
class ScoreScreen extends StatelessWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skor Tablosu')),
      body: const Center(
        child: Text('Skor tablosu yakında hazır olacak.'),
      ),
    );
  }
}

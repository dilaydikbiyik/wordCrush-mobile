import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../logic/providers/game_provider.dart';
import '../../router/app_router.dart';
import '../widgets/grid_board.dart';

/// Main game screen: grid, move counter, score, joker bar.
///
/// TODO (Phase 6): Add 8-directional swipe gesture detection.
/// TODO (Phase 6): Add joker button bar at bottom (active/locked state).
/// TODO (Phase 6): Add exit confirmation dialog.
/// TODO (Phase 6): Auto-navigate to home when moves run out.
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final controller = ref.read(gameProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oyun'),
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hamle: ${state.movesLeft}'),
                Text('Skor: ${state.score}'),
              ],
            ),
          ),
          Expanded(child: GridBoard(grid: state.grid)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: controller.reset,
              child: const Text('Yeniden Başlat'),
            ),
          ),
        ],
      ),
    );
  }
}

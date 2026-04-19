import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers/game_provider.dart';
import '../widgets/grid_board.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final controller = ref.read(gameProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Oyun Ekranı')),
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
          Expanded(
            child: GridBoard(grid: state.grid),
          ),
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

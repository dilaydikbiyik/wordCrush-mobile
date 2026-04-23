import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../logic/providers/game_provider.dart';
import '../../router/app_router.dart';

class MoveCountScreen extends ConsumerWidget {
  final int gridSize;
  const MoveCountScreen({super.key, required this.gridSize});

  void _selectMoveCount(BuildContext context, WidgetRef ref, int moveCount) {
    ref.read(gameProvider.notifier).startNewGame(gridSize, moveCount);
    context.push(AppRoutes.game);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            Image.asset(
              'assets/images/move_count_bg.png',
              fit: BoxFit.fill,
              width: size.width,
              height: size.height,
            ),

            // 15 Hamle — Zor
            Positioned(
              top: size.height * 0.225,
              left: size.width * 0.05,
              right: size.width * 0.05,
              child: GestureDetector(
                onTap: () => _selectMoveCount(context, ref, 15),
                child: Container(
                  height: 200,
                  color: Colors.transparent,
                ),
              ),
            ),

            // 20 Hamle — Orta
            Positioned(
              top: size.height * 0.48,
              left: size.width * 0.06,
              right: size.width * 0.05,
              child: GestureDetector(
                onTap: () => _selectMoveCount(context, ref, 20),
                child: Container(
                  height: 205,
                  color: Colors.transparent,
                ),
              ),
            ),

            // 25 Hamle — Kolay
            Positioned(
              top: size.height * 0.74,
              left: size.width * 0.06,
              right: size.width * 0.05,
              child: GestureDetector(
                onTap: () => _selectMoveCount(context, ref, 25),
                child: Container(
                  height: 195,
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

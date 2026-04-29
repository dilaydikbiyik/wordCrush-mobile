import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../logic/providers/game_provider.dart';
import '../../router/app_router.dart';
import '../widgets/press_3d_button.dart';

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
              child: Press3DButton(
                onTap: () => _selectMoveCount(context, ref, 15),
                height: 200,
                color: Colors.transparent,
                depthColor: Colors.black,
                depth: 7,
                leftDepth: 3,
                tornAmplitude: 10,
                tornSegments: 28,
                tornSeed: 5,
                child: Image.asset(
                  'assets/images/btn_move_15.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),

            // 20 Hamle — Orta
            Positioned(
              top: size.height * 0.48,
              left: size.width * 0.06,
              right: size.width * 0.05,
              child: Press3DButton(
                onTap: () => _selectMoveCount(context, ref, 20),
                height: 205,
                color: Colors.transparent,
                depthColor: Colors.black,
                depth: 7,
                leftDepth: 3,
                tornAmplitude: 10,
                tornSegments: 28,
                tornSeed: 13,
                child: Image.asset(
                  'assets/images/btn_move_20.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),

            // 25 Hamle — Kolay
            Positioned(
              top: size.height * 0.74,
              left: size.width * 0.06,
              right: size.width * 0.05,
              child: Press3DButton(
                onTap: () => _selectMoveCount(context, ref, 25),
                height: 195,
                color: Colors.transparent,
                depthColor: Colors.black,
                depth: 7,
                leftDepth: 3,
                tornAmplitude: 10,
                tornSegments: 28,
                tornSeed: 21,
                child: Image.asset(
                  'assets/images/btn_move_25.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

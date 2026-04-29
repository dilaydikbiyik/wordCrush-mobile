import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../widgets/press_3d_button.dart';

class GridSizeScreen extends StatelessWidget {
  const GridSizeScreen({super.key});

  void _selectGrid(BuildContext context, int gridSize) {
    context.push(AppRoutes.moveCount, extra: gridSize);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            Image.asset(
              'assets/images/grid_size_bg.png',
              fit: BoxFit.fill,
              width: size.width,
              height: size.height,
            ),

            // 6×6 Zor
            Positioned(
              top: size.height * 0.235,
              left: size.width * 0.08,
              right: size.width * 0.1,
              child: Press3DButton(
                onTap: () => _selectGrid(context, 6),
                height: 195,
                color: Colors.transparent,
                depthColor: Colors.black,
                depth: 6,
                leftDepth: 3,
                tornAmplitude: 10,
                tornSegments: 28,
                tornSeed: 12,
                child: Image.asset(
                  'assets/images/btn_grid_hard.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),

            // 8×8 Orta
            Positioned(
              top: size.height * 0.495,
              left: size.width * 0.08,
              right: size.width * 0.1,
              child: Press3DButton(
                onTap: () => _selectGrid(context, 8),
                height: 192,
                color: Colors.transparent,
                depthColor: Colors.black,
                depth: 7,
                leftDepth: 3,
                tornAmplitude: 10,
                tornSegments: 28,
                tornSeed: 11,
                child: Image.asset(
                  'assets/images/btn_grid_medium.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),

            // 10×10 Kolay
            Positioned(
              top: size.height * 0.745,
              left: size.width * 0.08,
              right: size.width * 0.1,
              child: Press3DButton(
                onTap: () => _selectGrid(context, 10),
                height: 192,
                color: Colors.transparent,
                depthColor: Colors.black,
                depth: 7,
                leftDepth: 3,
                tornAmplitude: 10,
                tornSegments: 28,
                tornSeed: 15,
                child: Image.asset(
                  'assets/images/btn_grid_easy.png',
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

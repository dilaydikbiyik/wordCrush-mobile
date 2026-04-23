import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';

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
              child: GestureDetector(
                onTap: () => _selectGrid(context, 6),
                child: Container(
                  height: 195,
                  color: Colors.transparent,
                ),
              ),
            ),

            // 8×8 Orta
            Positioned(
              top: size.height * 0.495,
              left: size.width * 0.08,
              right: size.width * 0.1,
              child: GestureDetector(
                onTap: () => _selectGrid(context, 8),
                child: Container(
                  height: 192,
                  color: Colors.transparent,
                ),
              ),
            ),

            // 10×10 Kolay
            Positioned(
              top: size.height * 0.745,
              left: size.width * 0.08,
              right: size.width * 0.1,
              child: GestureDetector(
                onTap: () => _selectGrid(context, 10),
                child: Container(
                  height: 192,
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

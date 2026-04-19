import 'package:flutter/material.dart';

class GridAnimation extends StatelessWidget {
  final Widget child;

  const GridAnimation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }
}

import 'package:flutter/material.dart';

class GridAnimation extends StatefulWidget {
  final Widget child;

  const GridAnimation({super.key, required this.child});

  @override
  State<GridAnimation> createState() => _GridAnimationState();
}

class _GridAnimationState extends State<GridAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.85, end: 1.0).animate(_controller),
      child: widget.child,
    );
  }
}

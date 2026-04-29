import 'package:flutter/material.dart';

/// Transparent hit area with a press-feedback overlay.
///
/// Wraps invisible button zones (drawn in background assets) so the player
/// gets a subtle white flash + scale-down when they tap.
class PressableArea extends StatefulWidget {
  final VoidCallback onTap;
  final double height;
  final double? width;
  final Widget? child;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry? padding;

  const PressableArea({
    super.key,
    required this.onTap,
    required this.height,
    this.width,
    this.child,
    this.alignment = Alignment.center,
    this.padding,
  });

  @override
  State<PressableArea> createState() => _PressableAreaState();
}

class _PressableAreaState extends State<PressableArea> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Stack(
          children: [
            Container(
              height: widget.height,
              width: widget.width,
              alignment: widget.alignment,
              padding: widget.padding,
              color: Colors.transparent,
              child: widget.child,
            ),
            if (_pressed)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers/audio_provider.dart';
import 'torn_edge_clipper.dart';

class Press3DButton extends ConsumerStatefulWidget {
  final VoidCallback onTap;
  final double height;
  final double? width;
  final Color color;
  final Color? depthColor;
  final double depth;
  final double leftDepth;
  final double rightDepth;
  final BorderRadius borderRadius;
  final double tornAmplitude;
  final int tornSegments;
  final int tornSeed;
  final Widget? child;
  /// Butona basıldığında çalınacak ses. Varsayılan: [SoundType.buttonTap].
  final SoundType soundType;
  /// true iken buton kalıcı olarak basılı görünür (joker hedef seçim modu).
  final bool forcePressed;
  /// false yapılırsa ses çalınmaz (dışarıdan ses yönetiliyorsa).
  final bool playSoundOnTap;

  const Press3DButton({
    super.key,
    required this.onTap,
    required this.height,
    required this.color,
    this.depthColor,
    this.width,
    this.depth = 8,
    this.leftDepth = 0,
    this.rightDepth = 0,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.tornAmplitude = 0,
    this.tornSegments = 24,
    this.tornSeed = 7,
    this.child,
    this.soundType = SoundType.buttonTap,
    this.forcePressed = false,
    this.playSoundOnTap = true,
  });

  @override
  ConsumerState<Press3DButton> createState() => _Press3DButtonState();
}

class _Press3DButtonState extends ConsumerState<Press3DButton> {
  bool _pressed = false;

  bool get _isDown => _pressed || widget.forcePressed;
  bool get _torn => widget.tornAmplitude > 0;

  Color get _resolvedDepthColor {
    if (widget.depthColor != null) return widget.depthColor!;
    final hsl = HSLColor.fromColor(widget.color);
    return hsl.withLightness((hsl.lightness - 0.28).clamp(0.0, 1.0)).toColor();
  }

  Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  Widget _clipFace(Widget child) {
    return ClipRRect(borderRadius: widget.borderRadius, child: child);
  }

  Widget _buildFace() {
    return _clipFace(
      Stack(
        fit: StackFit.expand,
        children: [
          if (widget.child == null)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _lighten(widget.color, 0.12),
                    widget.color,
                    _darken(widget.color, 0.06),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          if (widget.child != null) widget.child!,
          if (widget.child == null)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 4,
                color: _lighten(widget.color, 0.3).withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.depth;
    final ld = widget.leftDepth;
    final rd = widget.rightDepth;

    if (_torn) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          if (widget.playSoundOnTap) {
            ref.read(audioProvider.notifier).playSound(widget.soundType);
          }
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: SizedBox(
          height: widget.height + d,
          width: widget.width,
          child: Stack(
            children: [
              // Bottom depth block
              Positioned(
                bottom: 0, left: 0, right: 0,
                height: widget.height,
                child: AnimatedOpacity(
                  opacity: _isDown ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 80),
                  curve: Curves.easeOut,
                  child: ClipPath(
                    clipper: TornBothEdgesClipper(
                      amplitude: widget.tornAmplitude,
                      segments: widget.tornSegments,
                      seed: widget.tornSeed,
                    ),
                    child: Container(color: _resolvedDepthColor),
                  ),
                ),
              ),
              // Left depth strip
              if (ld > 0)
                Positioned(
                  top: d, left: 0, width: ld, height: widget.height,
                  child: AnimatedOpacity(
                    opacity: _isDown ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 80),
                    curve: Curves.easeOut,
                    child: Container(color: _resolvedDepthColor),
                  ),
                ),
              // Face slides down on press
              AnimatedPositioned(
                duration: const Duration(milliseconds: 80),
                curve: Curves.easeOut,
                top: _isDown ? d : 0,
                left: ld,
                right: rd,
                height: widget.height,
                child: _buildFace(),
              ),
            ],
          ),
        ),
      );
    }

    // Standard layout with BoxShadow
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (widget.playSoundOnTap) {
          ref.read(audioProvider.notifier).playSound(widget.soundType);
        }
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        height: widget.height,
        width: widget.width,
        transform: Matrix4.translationValues(0, _isDown ? d : 0, 0),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          gradient: widget.child == null
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _lighten(widget.color, 0.12),
                    widget.color,
                    _darken(widget.color, 0.06),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: _isDown
                  ? _resolvedDepthColor.withValues(alpha: 0)
                  : _resolvedDepthColor,
              offset: Offset(rd, d),
              blurRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.child != null) widget.child!,
              if (widget.child == null)
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 4,
                    color: _lighten(widget.color, 0.3).withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

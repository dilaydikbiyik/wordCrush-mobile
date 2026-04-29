import 'dart:math';
import 'package:flutter/material.dart';

/// Clips a widget so its BOTTOM edge looks like torn paper.
class TornEdgeClipper extends CustomClipper<Path> {
  final double amplitude;
  final int segments;
  final int seed;

  const TornEdgeClipper({
    this.amplitude = 12,
    this.segments = 24,
    this.seed = 7,
  });

  @override
  Path getClip(Size size) {
    final rng = Random(seed);
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - amplitude);
    final step = size.width / segments;
    for (int i = segments - 1; i >= 0; i--) {
      path.lineTo(i * step, size.height - rng.nextDouble() * amplitude);
    }
    path.lineTo(0, size.height - amplitude);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(TornEdgeClipper old) =>
      old.seed != seed || old.amplitude != amplitude || old.segments != segments;
}

/// Clips a widget so its TOP edge looks like torn paper.
/// Use the same seed/amplitude/segments as [TornEdgeClipper] to get matching edges.
class TornTopClipper extends CustomClipper<Path> {
  final double amplitude;
  final int segments;
  final int seed;

  const TornTopClipper({
    this.amplitude = 12,
    this.segments = 24,
    this.seed = 7,
  });

  @override
  Path getClip(Size size) {
    final rng = Random(seed);
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, amplitude);
    final step = size.width / segments;
    for (int i = segments - 1; i >= 0; i--) {
      path.lineTo(i * step, rng.nextDouble() * amplitude);
    }
    path.lineTo(0, amplitude);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(TornTopClipper old) =>
      old.seed != seed || old.amplitude != amplitude || old.segments != segments;
}

/// Clips a widget so BOTH top and bottom edges look like torn paper.
class TornBothEdgesClipper extends CustomClipper<Path> {
  final double amplitude;
  final int segments;
  final int seed;

  const TornBothEdgesClipper({
    this.amplitude = 12,
    this.segments = 24,
    this.seed = 7,
  });

  @override
  Path getClip(Size size) {
    final rng = Random(seed);
    final step = size.width / segments;
    final path = Path();

    // Torn top edge: left to right
    path.moveTo(0, rng.nextDouble() * amplitude);
    for (int i = 1; i <= segments; i++) {
      path.lineTo(i * step, rng.nextDouble() * amplitude);
    }
    // Right side down
    path.lineTo(size.width, size.height - rng.nextDouble() * amplitude);
    // Torn bottom edge: right to left
    for (int i = segments - 1; i >= 0; i--) {
      path.lineTo(i * step, size.height - rng.nextDouble() * amplitude);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(TornBothEdgesClipper old) =>
      old.seed != seed || old.amplitude != amplitude || old.segments != segments;
}

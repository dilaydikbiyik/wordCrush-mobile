import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../logic/providers/player_provider.dart';
import '../../logic/providers/trie_provider.dart';
import '../../router/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final AnimationController _floatController;
  late final AnimationController _glowController;

  late final Animation<double> _fadeAnim;
  late final Animation<double> _slideAnim;
  late final Animation<double> _floatAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideAnim = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _enterController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _navigate() {
    if (!mounted) return;
    final player = ref.read(playerProvider);
    if (player.isLoaded && player.username.isNotEmpty) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(trieProvider, (previous, next) {
      if (next is AsyncData) {
        ref.read(playerProvider.notifier).loadProfile();
        Future.delayed(const Duration(seconds: 2), _navigate);
      }
    });

    final trieState = ref.watch(trieProvider);

    return Scaffold(
      body: Stack(
        children: [
          // — Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0015),
                  Color(0xFF120826),
                  Color(0xFF0D1B3E),
                  Color(0xFF0A0015),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),

          // — Ambient glow orbs
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, _) => Stack(
              children: [
                Positioned(
                  top: -80,
                  left: -60,
                  child: _GlowOrb(
                    color: const Color(0xFFE94560),
                    size: 280,
                    opacity: 0.18 * _glowAnim.value,
                  ),
                ),
                Positioned(
                  bottom: -60,
                  right: -40,
                  child: _GlowOrb(
                    color: const Color(0xFF6C63FF),
                    size: 240,
                    opacity: 0.15 * _glowAnim.value,
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.45,
                  left: MediaQuery.of(context).size.width * 0.3,
                  child: _GlowOrb(
                    color: const Color(0xFF00D4FF),
                    size: 180,
                    opacity: 0.10 * _glowAnim.value,
                  ),
                ),
              ],
            ),
          ),

          // — Main content
          SafeArea(
            child: Center(
              child: FadeTransition(
              opacity: _fadeAnim,
              child: AnimatedBuilder(
                animation: _slideAnim,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: child,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Floating letter tiles
                    AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (context, _) => Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: const _LogoTiles(),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Title
                    const Text(
                      'Word Crush',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Color(0x99E94560),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Subtitle — glass pill
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withAlpha(40),
                            ),
                          ),
                          child: const Text(
                            'Türkçe Kelime Bulmaca',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 72),

                    // Loading status
                    _GlassStatusPill(state: trieState),
                  ],
                ),
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}

// — W O R D harflerinden oluşan liquid glass logo
class _LogoTiles extends StatelessWidget {
  const _LogoTiles();

  @override
  Widget build(BuildContext context) {
    const tiles = [
      ('W', Color(0xFFE94560), Color(0xFFFF6B8A)),
      ('O', Color(0xFFFF6B35), Color(0xFFFFAA70)),
      ('R', Color(0xFFFFD93D), Color(0xFFFFEA8A)),
      ('D', Color(0xFF4CD964), Color(0xFF8AFFA0)),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: tiles
          .map((t) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: _GlassTile(letter: t.$1, baseColor: t.$2, glowColor: t.$3),
              ))
          .toList(),
    );
  }
}

class _GlassTile extends StatelessWidget {
  final String letter;
  final Color baseColor;
  final Color glowColor;

  const _GlassTile({
    required this.letter,
    required this.baseColor,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: baseColor.withAlpha(120),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  glowColor.withAlpha(180),
                  baseColor.withAlpha(220),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withAlpha(80),
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                // Shine highlight top-left
                Positioned(
                  top: 6,
                  left: 8,
                  child: Container(
                    width: 28,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(60),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _GlowOrb({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: opacity), Colors.transparent],
        ),
      ),
    );
  }
}

class _GlassStatusPill extends StatelessWidget {
  final AsyncValue<dynamic> state;
  const _GlassStatusPill({required this.state});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withAlpha(30)),
          ),
          child: state.when(
            data: (_) => const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Color(0xFF4CD964), size: 18),
                SizedBox(width: 8),
                Text('Sözlük yüklendi',
                    style:
                        TextStyle(color: Color(0xFF4CD964), fontSize: 14)),
              ],
            ),
            loading: () => const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFE94560),
                  ),
                ),
                SizedBox(width: 10),
                Text('Sözlük yükleniyor...',
                    style: TextStyle(color: Colors.white60, fontSize: 14)),
              ],
            ),
            error: (e, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Text('Hata: $e',
                    style:
                        const TextStyle(color: Colors.red, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

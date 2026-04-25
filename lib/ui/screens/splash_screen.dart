import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../logic/providers/joker_provider.dart';
import '../../logic/providers/player_provider.dart';
import '../../router/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fillController;
  late final Animation<double> _fillAnim;

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    _fillAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 2400), _navigate);
  }

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  void _navigate() {
    if (!mounted) return;
    ref.read(playerProvider.notifier).loadProfile();
    ref.read(jokerProvider.notifier).loadInventory();
    final player = ref.read(playerProvider);
    if (player.isLoaded && player.username.isNotEmpty) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/splash_bg.png',
              fit: BoxFit.fill,
              width: size.width,
              height: size.height,
            ),
            Positioned(
              top: size.height * 0.621,
              left: 0,
              right: 5,
              child: Center(
                child: AnimatedBuilder(
                  animation: _fillAnim,
                  builder: (context, _) => Container(
                    width: 155,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: LinearProgressIndicator(
                        value: _fillAnim.value,
                        backgroundColor: Colors.black.withAlpha(20),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF6B35),
                        ),
                        minHeight: 36,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


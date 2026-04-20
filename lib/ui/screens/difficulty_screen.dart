import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';

/// Player selects grid size / difficulty before a new game starts.
///
/// TODO (Phase 6): Pass selected difficulty as GoRouter extra to GameScreen.
/// TODO (Phase 6): Show move count alongside each option.
class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zorluk Seç')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _DifficultyCard(
              label: 'Kolay',
              detail: '10×10 — 25 Hamle',
              onTap: () => context.go(AppRoutes.game),
            ),
            const SizedBox(height: 16),
            _DifficultyCard(
              label: 'Orta',
              detail: '8×8 — 20 Hamle',
              onTap: () => context.go(AppRoutes.game),
            ),
            const SizedBox(height: 16),
            _DifficultyCard(
              label: 'Zor',
              detail: '6×6 — 15 Hamle',
              onTap: () => context.go(AppRoutes.game),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(detail, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../logic/providers/player_provider.dart';
import '../../router/app_router.dart';
import '../widgets/press_3d_button.dart';
import '../widgets/pressable_area.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showRenameDialog(BuildContext context, WidgetRef ref, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kullanıcı Adını Değiştir'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(hintText: 'Yeni kullanıcı adı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(playerProvider.notifier).updateUsername(name);
              }
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final username = ref.watch(playerProvider).username;

    return Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            Image.asset(
              'assets/images/home_bg.png',
              fit: BoxFit.fill,
              width: size.width,
              height: size.height,
            ),

            // Username — üst torn paper alanına hizalı
            Positioned(
              top: size.height * 0.075,
              left: size.width * 0.075,
              right: size.width * 0.36,
              child: Press3DButton(
                onTap: () => _showRenameDialog(context, ref, username),
                height: 55,
                color: Colors.transparent,
                depthColor: Colors.black,
                depth: 8,
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/btn_username.png',
                      fit: BoxFit.fill,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          username,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Yeni Oyun butonu
            Positioned(
              top: size.height * 0.515,
              left: size.width * 0.1,
              right: size.width * 0.1,
              child: Press3DButton(
                onTap: () => context.push(AppRoutes.gridSize),
                height: 120,
                color: Colors.transparent,
                depthColor: Colors.black,
                depth: 7,
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                child: Image.asset(
                  'assets/images/btn_new_game.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),

            // Skor Tablosu butonu
            Positioned(
              top: size.height * 0.671,
              left: size.width * 0.1,
              right: size.width * 0.1,
              child: Press3DButton(
                onTap: () => context.push(AppRoutes.score),
                height: 122,
                color: Colors.transparent,
                depthColor: Colors.black,
                depth: 7,
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                child: Image.asset(
                  'assets/images/btn_score.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),

            // Market butonu — 3D test
            Positioned(
              top: size.height * 0.83,
              left: size.width * 0.1,
              right: size.width * 0.1,
              child: Press3DButton(
                onTap: () => context.push(AppRoutes.market),
                height: 120,
                color: const Color(0xFFE53935),
                depthColor: Colors.black,
                depth: 8,
                child: Image.asset(
                  'assets/images/btn_market.png',
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

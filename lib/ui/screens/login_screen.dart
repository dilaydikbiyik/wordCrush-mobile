import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';

/// First-run username entry. Skipped on subsequent launches (profile exists).
///
/// TODO (Phase 6): Check ObjectBox for existing PlayerProfile → auto-navigate to home.
/// TODO (Phase 6): Save username + initial gold to ObjectBox.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    final username = _controller.text.trim();
    if (username.isEmpty) return;
    // TODO (Phase 6): persist PlayerProfile via ObjectBoxService
    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Hoş Geldin!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Kullanıcı Adın',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Devam Et'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

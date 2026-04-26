import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../logic/providers/player_provider.dart';
import '../../router/app_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  void _submit() {
    final username = _controller.text.trim();
    if (username.isEmpty) {
      setState(() => _errorText = 'Kullanıcı adı boş olamaz');
      return;
    }
    if (username.length > 20) {
      setState(() => _errorText = 'En fazla 20 karakter');
      return;
    }
    setState(() => _errorText = null);
    ref.read(playerProvider.notifier).createProfile(username);
    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeIn,
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: child,
          );
        },
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              Image.asset(
                'assets/images/login_bg.png',
                fit: BoxFit.fill,
                width: size.width,
                height: size.height,
              ),

              // TextField — PNG'deki boş input alanına hizalı
              Positioned(
                top: size.height * 0.505,
                left: size.width * 0.13,
                right: size.width * 0.12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _controller,
                      onSubmitted: (_) => _submit(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Kullanıcı adınızı girin',
                        hintStyle: TextStyle(
                          color: Colors.black38,
                          fontSize: 15,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    if (_errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 12),
                        child: Text(
                          _errorText!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Başla butonu — PNG'deki buton alanına hizalı
              Positioned(
                top: size.height * 0.60,
                left: size.width * 0.21,
                right: size.width * 0.16,
                child: GestureDetector(
                  onTap: _submit,
                  child: Container(
                    height: 80,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

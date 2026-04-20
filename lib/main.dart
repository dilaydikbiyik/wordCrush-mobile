import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: WordCrushApp()));
}

class WordCrushApp extends StatelessWidget {
  const WordCrushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Word Crush',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'data/services/objectbox_service.dart';
import 'logic/providers/game_provider.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ObjectBox local database
  final objectbox = ObjectBoxService();
  await objectbox.init();

  runApp(
    ProviderScope(
      overrides: [
        // Inject the initialized database into our Riverpod tree
        objectBoxServiceProvider.overrideWithValue(objectbox),
      ],
      child: const WordCrushApp(),
    ),
  );
}

class WordCrushApp extends StatelessWidget {
  const WordCrushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Word Crush',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}


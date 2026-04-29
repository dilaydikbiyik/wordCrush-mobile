import 'package:flutter/material.dart';

/// Word Crush uygulamasının merkezi tema tanımı.
///
/// Mevcut ekran kodu kendi renklerini doğrudan kullanmaya devam eder;
/// bu tema sadece Material widget'ların (AppBar, Dialog, SnackBar vb.)
/// varsayılan görünümünü oyunun renk paletine göre ayarlar.
class AppTheme {
  AppTheme._();

  // ─── Renk Paleti ───────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFFF6B35);      // Turuncu ana renk
  static const Color primaryDark = Color(0xFFD94F1A);  // Koyu turuncu
  static const Color accent = Color(0xFFFFB800);        // Altın sarısı (combo)
  static const Color surface = Color(0xFFF5F0E8);       // Bej (hücre arka planı)
  static const Color background = Color(0xFF1A1A2E);    // Koyu arka plan
  static const Color onPrimary = Colors.white;
  static const Color onSurface = Color(0xFF1A1A1A);

  // ─── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: accent,
          surface: surface,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: 'Roboto',

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: onSurface,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),

        // Dialog (GameOver, Exit)
        dialogTheme: DialogThemeData(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
          contentTextStyle: const TextStyle(
            fontSize: 16,
            color: onSurface,
          ),
        ),

        // SnackBar (geçerli / geçersiz kelime bildirimi)
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentTextStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),

        // TextButton (dialog butonları)
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),

        // ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),

        // LinearProgressIndicator (Splash)
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: primary,
          linearTrackColor: Colors.black12,
        ),
      );
}

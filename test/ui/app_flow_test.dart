import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:word_crush_mobile/main.dart';

// Not: Gerçek cihaz entegrasyon testleri (integration_test) paketi
// yerine, tüm akışı simüle eden kapsamlı bir Widget Test kullanıyoruz.
// Çünkü riverpod, go_router ve widget etkileşimleri bu sayede daha hızlı
// ve stabil test edilebiliyor.

void main() {
  testWidgets('App Flow Test: Home -> GridSize -> MoveCount -> Game -> Score', (WidgetTester tester) async {
    // Uygulamayı başlat
    await tester.pumpWidget(const ProviderScope(child: WordCrushApp()));
    await tester.pumpAndSettle(); // Splash screen ve asset yüklemeleri için bekle

    // 1. Ana Ekran (HomeScreen)
    // "Yeni Oyun" butonunu bul (buton resmine veya Press3DButton'a basılabilir)
    final newGameButton = find.byType(GestureDetector).at(1); 
    expect(newGameButton, findsWidgets);

    // Yeni Oyuna tıkla
    await tester.tap(newGameButton);
    await tester.pumpAndSettle();

    // 2. Grid Size Ekranı (6x6 Zor seçimi)
    final hardGridButton = find.byType(GestureDetector).first;
    expect(hardGridButton, findsWidgets);
    
    // 6x6'ya tıkla
    await tester.tap(hardGridButton);
    await tester.pumpAndSettle();

    // 3. Move Count Ekranı (15 Hamle seçimi)
    final move15Button = find.byType(GestureDetector).first;
    expect(move15Button, findsWidgets);

    // 15 Hamle'ye tıkla ve oyuna gir
    await tester.tap(move15Button);
    await tester.pumpAndSettle();

    // 4. Oyun Ekranı (GameScreen)
    // Kalan Hamle etiketinin 15 olduğunu kontrol et
    expect(find.text('15'), findsWidgets);
    
    // Grid oluşturulduğunu kontrol et (6x6 = 36 hücre)
    final cells = find.byType(AnimatedContainer);
    expect(cells, findsWidgets);

    // Oyun içi geri (Exit) butonuna bas
    final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(backButton, findsOneWidget);
    
    await tester.tap(backButton);
    await tester.pumpAndSettle(); // Dialog animasyonu

    // Çıkış onayı ver (Evet)
    final yesButton = find.text('Evet');
    expect(yesButton, findsOneWidget);
    
    await tester.tap(yesButton);
    await tester.pumpAndSettle(); // Score ekranına geçiş animasyonu

    // 5. Skor Tablosu (ScoreScreen)
    expect(find.text('SKOR TABLOSU'), findsOneWidget);
  });
}

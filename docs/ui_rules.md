# UI Rules — Word Crush

## Genel Kurallar

- Tüm widget'lar `const` constructor kullanmalı (mümkün olduğunda)
- `dynamic` tipi yasaktır — her widget parametresi açıkça tiplendirilmeli
- `Navigator.push` kullanma — sadece `context.go()` / `context.push()` (GoRouter)
- Widget dosyası = tek public widget. Küçük private yardımcı widget'lar aynı dosyada olabilir

## Ekran Listesi ve Route'ları

| Ekran | Route | Amaç |
|-------|-------|-------|
| SplashScreen | `/splash` | Trie yükleme, ObjectBox init |
| LoginScreen | `/login` | İlk açılış kullanıcı adı |
| HomeScreen | `/home` | Ana menü |
| DifficultyScreen | `/difficulty` | Zorluk seçimi |
| GameScreen | `/game` | Oyun alanı |
| ScoreScreen | `/score` | Skor tablosu |
| MarketScreen | `/market` | Joker satın alma |

## Grid Widget Tasarımı

- Grid hücreleri `GestureDetector` ile sarmalanır (swipe detection)
- 8 yönlü komşuluk: sadece dokunuşun geçtiği hücreler seçilir
- Seçili hücreler mavi highlight, geçerli kelime yeşil, geçersiz kırmızı + shake animasyonu
- Özel güç simgesi hücreleri farklı renk/ikon ile gösterilir

## GameScreen Layout

```
┌─────────────────────────────┐
│  Kullanıcı Adı   🪙 Altın   │  ← üst bar
│  Skor: 0   Hamle: 25        │
│  Kelime Sayısı: 3           │
├─────────────────────────────┤
│                             │
│         NxN GRID            │  ← genişler
│                             │
├─────────────────────────────┤
│  [J1] [J2] [J3] [J4] [J5] [J6] │  ← joker bar
└─────────────────────────────┘
```

## Tema

- Renk paleti: TODO (Phase 8)
- Responsive: `MediaQuery` ile farklı iPhone boyutlarına uyum
- Tüm string'ler Türkçe

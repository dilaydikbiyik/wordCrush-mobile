# Game Engine Rules

## Trie (lib/data/services/trie_service.dart)

- Kelimeler **Türkçe büyük harf** olarak saklanır: `CharNormalizer.toTurkishUpper()`
- `i → İ`, `ı → I` dönüşümü zorunludur (standart Dart `toUpperCase()` yanlış sonuç verir)
- `contains(word)` → O(m) kelime doğrulama
- `hasPrefix(prefix)` → O(p) DFS pruning — bu olmadan GridSolver yavaş kalır

## GridGenerator (lib/logic/algorithms/grid_generator.dart)

- Harfler `LetterFrequencies.weightedPool`'dan rastgele seçilir
- 3 katmanlı frekans: Yüksek (6×), Orta (3×), Normal (2×), Düşük (1×)
- `dart:math` `Random` kullanılır

## GridSolver (lib/logic/algorithms/grid_solver.dart) — TODO Phase 4

- Her hamle sonrası `Flutter.compute()` ile Isolate'de çalışır (UI donmaz)
- DFS + Trie `hasPrefix` pruning algoritması
- **Grid asla çözümsüz kalmamalıdır** — kelime bulunamazsa kurallı üretim devreye girer

## GravityEngine (lib/logic/algorithms/gravity_engine.dart)

- Harf patlatıldıktan sonra üstteki harfler aşağı kayar (sütun bazlı)
- Boş hücreler `GridGenerator` ile frekans tablosuna göre doldurulur
- Gravity her joker ve özel güç kullanımı sonrasında da çalışır

## ComboEngine (lib/logic/scoring/combo_engine.dart) — TODO Phase 4

- Ana kelime içinde 3+ harfli **subsequence** alt kelimeler aranır
- Harf **sırası** korunmalıdır (sadece harf içermesi yetmez)
- Aynı alt kelime birden fazla sayılamaz
- Trie `contains()` ile her aday doğrulanır

## ScoreCalculator (lib/logic/scoring/score_calculator.dart)

- Her harfin puanı `LetterScores.getScore(char)` ile alınır
- Combo puanları ana kelime puanına eklenir

## Özel Güçler (lib/logic/powers/power_executor.dart) — TODO Phase 7

| Uzunluk | Güç | Etki |
|---------|-----|------|
| 4 harf | Satır Temizleme | Tüm satırı sil |
| 5 harf | Alan Patlatma | Komşu hücreleri sil |
| 6 harf | Sütun Temizleme | Tüm sütunu sil |
| 7+ harf | Mega Patlatma | 2 birim çevre sil |

Güç simgesi kelimenin **son harfinin** konumuna yerleşir.
Simge yeni bir kelimede kullanıldığında güç tetiklenir.

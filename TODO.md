# 📋 TODO.md — Word Crush Gelişmiş Yol Haritası

---

## ⚠️⚠️⚠️ KRİTİK KURAL ⚠️⚠️⚠️

# **AGENT RULE: NEVER check off checkboxes (`- [x]`) without EXPLICIT user approval!**

### Bu kural ihlal edilemez. Bir görev tamamlandığında agent, kullanıcıya Türkçe olarak bilgi verir ve onay bekler. Kullanıcı "tamam" veya benzeri bir onay vermeden checkbox işaretlenemez.

---

## Phase 1: Proje Başlatma & Altyapı ✅
- [x] Flutter projesini oluştur (iOS hedef, `flutter create`)
- [x] `pubspec.yaml` — tüm bağımlılıkları ekle (INSTALL_LOG.md'ye kaydet)
- [x] `analysis_options.yaml` — strict linter kurallarını ayarla
- [x] `.gitignore` güncelle (build/, .dart_tool/, *.g.dart, objectbox vb.)
- [x] Klasör yapısını oluştur:
  - [x] `lib/core/`, `lib/data/models/`, `lib/data/services/`
  - [x] `lib/logic/algorithms/`, `lib/logic/scoring/`, `lib/logic/powers/`, `lib/logic/providers/`
  - [x] `lib/ui/screens/`, `lib/ui/widgets/`, `lib/ui/animations/`
  - [x] `assets/data/`, `assets/sounds/`, `assets/animations/`
  - [x] `test/`
- [x] Riverpod entegrasyonu (`ProviderScope` → `main.dart`)
- [x] ObjectBox ilk kurulumu (Store init + `path_provider`)
- [x] GoRouter temel route yapısı (tüm ekranlar için placeholder)
- [x] `docs/` klasörünü oluştur (ui_rules.md, state_rules.md, game_engine_rules.md)

## Phase 2: Veri Katmanı ✅
- [x] ObjectBox Entity: `PlayerProfile`
  - [x] Alanlar: id, username, goldBalance, createdAt
- [x] ObjectBox Entity: `GameRecord`
  - [x] Alanlar: id, gameNumber, date, gridSize, score, wordCount, longestWord, duration
- [x] ObjectBox Entity: `JokerInventory`
  - [x] Alanlar: id, jokerType, quantity
- [x] `ObjectBoxStore` — singleton service sınıfı
- [x] Türkçe kelime listesini `assets/data/turkish_words.txt`'ye ekle
  - [x] Kaynak: `CanNuhlar/Turkce-Kelime-Listesi` reposundan al (59.828 kelime)
- [x] Trie veri yapısını implement et
  - [x] `TrieNode` sınıfı (children map, isEndOfWord)
  - [x] `Trie` sınıfı (insert, search, startsWith)
- [x] Asset'ten Trie'ye yükleme fonksiyonu (`rootBundle.loadString`)
- [x] Trie Riverpod Provider'ı (`FutureProvider`)

## Phase 3: Oyun Motoru — Temel ✅
- [x] `core/constants/` — tüm sabit dosyaları:
  - [x] `app_constants.dart` — grid boyutları, hamle limitleri, başlangıç altını
  - [x] `letter_scores.dart` — 29 harfin puan tablosu (Map)
  - [x] `letter_frequencies.dart` — 3 katmanlı Türkçe harf frekansları
- [x] `GridModel` — 2D `List<List<Cell>>` yapısı
- [x] `GridGenerator` — frekans tabanlı rastgele harf üretimi
- [x] 8 yönlü komşuluk hesaplama fonksiyonu (adjacency check)
- [x] Kelime doğrulama: seçilen path → string → Trie lookup
- [x] Minimum 3 harf kontrolü (2 harf → geçersiz)

## Phase 4: Oyun Motoru — İleri Seviye ✅
- [x] `GravityEngine`
  - [x] Patlatılan harfleri sil
  - [x] Üstteki harfleri aşağı düşür
  - [x] Boş hücrelere yeni harf üret (frekans tabanlı)
- [x] `ScoreCalculator`
  - [x] Harf bazlı puan hesaplama
  - [x] Toplam kelime puanı
- [x] `ComboEngine`
  - [x] Ana kelime içinde 3+ harfli alt kelime tespiti
  - [x] Harf sırası korunarak subsequence arama
  - [x] Alt kelime puanlama ve toplam puana ekleme
  - [x] Tekrar filtreleme
- [x] `GridSolver` — arka plan kelime tarama
  - [x] DFS + Trie prefix pruning algoritması
  - [x] `Flutter.compute()` / Isolate kullanımı (UI donmaması için)
  - [x] Kelime kalmama durumu tespiti
  - [x] Kurallı harf üretimi (kelime garantisi mekanizması)
  - [x] Otomatik karıştırma mekaniği
  - [x] Oluşturulabilir kelime sayısını hesaplama

## Phase 5: Riverpod State Management ✅
- [x] `GameStateProvider` — hamle sayısı, oyun aktif/bitti, grid boyutu, seviye
- [x] `GridProvider` — grid matrisi, seçili hücreler, harf güncelleme
- [x] `ScoreProvider` — anlık skor, combo çarpanı, toplam puan
- [x] `PlayerProvider` — kullanıcı adı, altın bakiyesi
- [x] `JokerProvider` — joker envanteri, aktif joker seçimi
- [x] `MarketProvider` — satın alma işlemleri, altın kontrolü
- [x] `TrieProvider` — sözlük erişimi (yüklenme durumu dahil)
- [x] `AudioProvider` — ses efektleri açma/kapama/çalma

## Phase 6: UI/UX — Ekranlar
- [ ] `SplashScreen`
  - [ ] Sözlük yükleme progress göstergesi
  - [ ] ObjectBox initialization
- [ ] `LoginScreen`
  - [ ] Kullanıcı adı girişi
  - [ ] ObjectBox'a kaydetme
  - [ ] Mevcut kullanıcı varsa otomatik giriş
- [ ] `HomeScreen`
  - [ ] 3 buton: Yeni Oyun, Skor Tablosu, Market
  - [ ] Sol üst: kullanıcı adı (tıkla → değiştir dialogu)
  - [ ] Altın göstergesi
- [ ] `DifficultyScreen`
  - [ ] 3 seçenek: 6×6 (Zor/15 hamle), 8×8 (Orta/20 hamle), 10×10 (Kolay/25 hamle)
- [ ] `GameScreen`
  - [ ] NxN grid widget (GestureDetector tabanlı)
  - [ ] 8 yönlü sürükleme algılama (swipe detection)
  - [ ] Üst bar: skor, kalan hamle, oluşturulabilir kelime sayısı
  - [ ] Alt bar: joker butonları (satın alınmışsa aktif, değilse kilitli)
  - [ ] Seçili harflerin görsel vurgulanması
  - [ ] Geçerli kelime → yeşil feedback + puan animasyonu
  - [ ] Geçersiz kelime → kırmızı feedback + sallama efekti
  - [ ] Çıkış onay dialogu ("Çıkmak istediğinize emin misiniz?")
  - [ ] Hamle bittiğinde otomatik oyun sonu → skor kaydetme
- [ ] `ScoreScreen`
  - [ ] Üst kısım: 6 istatistik özet kartı (toplam oyun, en yüksek puan, ortalama, vb.)
  - [ ] Alt kısım: oyun kartları listesi (en son oynanan üstte)
  - [ ] Her kartta: oyun no, tarih, grid, puan, kelime sayısı, en uzun kelime, süre
- [ ] `MarketScreen`
  - [ ] 6 joker kartı (simge, isim, fiyat, açıklama)
  - [ ] Satın alma butonu + altın yeterliliği kontrolü
  - [ ] Mevcut altın göstergesi (üst kısım)

## Phase 7: Özel Güçler & Jokerler
- [ ] `PowerType` enum (RowClear, AreaBlast, ColumnClear, MegaBlast)
- [ ] `PowerExecutor`
  - [ ] 4 harf → Satır Temizleme (tüm satırı sil)
  - [ ] 5 harf → Alan Patlatma (komşu hücreleri sil)
  - [ ] 6 harf → Sütun Temizleme (tüm sütunu sil)
  - [ ] 7+ harf → Mega Patlatma (2 birim çevre sil)
- [ ] Özel simge hücreleri (güç simgesi grid'e yerleştirme)
- [ ] Güç aktivasyon mekaniği (simgeyi kelimede kullanma → tetikleme)
- [ ] `JokerType` enum (6 joker)
- [ ] `JokerExecutor`
  - [ ] Balık: rastgele harfleri yok et
  - [ ] Tekerlek: satır + sütun sil
  - [ ] Lolipop Kırıcı: tek harf sil
  - [ ] Serbest Değiştirme: iki harf yer değiştir
  - [ ] Harf Karıştırma: grid shuffle
  - [ ] Parti Güçlendiricisi: tümünü sil + yeniden doldur
- [ ] Joker kullanımı sonrası gravity + solvability kontrolü

## Phase 8: Animasyonlar, Ses & Polish
- [ ] Lottie animasyon dosyaları bul/oluştur:
  - [ ] Harf düşme (gravity) animasyonu
  - [ ] Harf patlatma animasyonu
  - [ ] Satır/sütun temizleme efekti
  - [ ] Bomba/mega patlatma efekti
  - [ ] Combo popup animasyonu
- [ ] Ses efektleri entegrasyonu (`audioplayers`):
  - [ ] Harf seçme sesi
  - [ ] Geçerli kelime sesi
  - [ ] Geçersiz kelime sesi
  - [ ] Combo sesi
  - [ ] Özel güç aktivasyon sesi
  - [ ] Oyun sonu sesi
- [ ] UI polish:
  - [ ] Uygun renk paleti ve tema tasarımı
  - [ ] Responsive layout (farklı iPhone boyutları)
  - [ ] Loading state'leri ve skeleton ekranları
  - [ ] Error handling UI (hata mesajları)

## Phase 9: Test & Final
- [x] Unit test: Trie (insert, search, startsWith)
- [ ] Unit test: GridGenerator (frekans dağılımı doğrulama)
- [ ] Unit test: GridSolver (kelime bulma doğruluğu)
- [ ] Unit test: ScoreCalculator (puan hesaplama)
- [ ] Unit test: ComboEngine (alt kelime tespiti doğruluğu)
- [ ] Integration test: Oyun akışı (başla → oyna → bitir → skor kaydet)
- [ ] Performans testi: 10×10 grid solvability tarama süresi
- [ ] Edge case: Grid'de kelime kalmama senaryoları
- [ ] Edge case: Altın yetersiz durumu (market)
- [ ] Edge case: Tüm jokerler kullanılmış durumu
- [ ] Edge case: Kullanıcı adı boş / çok uzun
- [ ] iOS emülatör üzerinde son test
- [ ] Sunum hazırlığı

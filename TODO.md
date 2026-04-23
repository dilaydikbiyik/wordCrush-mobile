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
- [x] `.gitignore` güncelle (build/, .dart_tool/, \*.g.dart, objectbox vb.)
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

### Asset Listesi (`assets/images/`)
- [ ] `splash_bg.png` — SplashScreen arka planı
- [ ] `login_bg.png` — LoginScreen arka planı (input alanı boş)
- [ ] `home_bg.png` — HomeScreen arka planı (username kutusu boş)
- [ ] `grid_size_bg.png` — GridSizeScreen arka planı
- [ ] `move_count_bg.png` — MoveCountScreen arka planı
- [ ] `game_bg.png` — GameScreen arka planı (üst 3 kutu + kağıt grid alanı + 6 gri joker yuvası)
- [ ] `score_bg.png` — ScoreScreen arka planı (sadece kırmızı doku, UI yok)
- [ ] `market_bg.png` — MarketScreen arka planı (bakiye/fiyat kutuları boş)

### Ekranlar

- [ ] `SplashScreen`
  - [ ] Asset: `splash_bg.png` arka plana ekle
  - [ ] Sözlük yükleme progress göstergesi
  - [ ] ObjectBox initialization
- [ ] `LoginScreen`
  - [ ] Asset: `login_bg.png` arka plana ekle
  - [ ] TextField PNG'deki boş input alanına hizala
  - [ ] Kullanıcı adı girişi
  - [ ] ObjectBox'a kaydetme
  - [ ] Mevcut kullanıcı varsa otomatik giriş
- [ ] `HomeScreen`
  - [ ] Asset: `home_bg.png` arka plana ekle
  - [ ] Username widget'ını PNG'deki torn paper kutusuna hizala (altın göstergesi yok)
  - [ ] 3 buton: Yeni Oyun, Skor Tablosu, Market
  - [ ] Sol üst: kullanıcı adı (tıkla → değiştir dialogu)
- [ ] `GridSizeScreen`
  - [ ] Asset: `grid_size_bg.png` arka plana ekle
  - [ ] 3 kart: 6×6 (Zor), 8×8 (Orta), 10×10 (Kolay)
  - [ ] Seçilen grid boyutunu GameStateProvider'a kaydet
  - [ ] Router: AppRoutes.gridSize rotası ekle
- [ ] `MoveCountScreen`
  - [ ] Asset: `move_count_bg.png` arka plana ekle
  - [ ] 3 kart: 15 Hamle (Zor), 20 Hamle (Orta), 25 Hamle (Kolay)
  - [ ] Seçilen hamle sayısını GameStateProvider'a kaydet
  - [ ] Router: AppRoutes.moveCount rotası ekle
  - [ ] Akış: HomeScreen → GridSizeScreen → MoveCountScreen → GameScreen
- [ ] `GameScreen`
  - [ ] Asset: `game_bg.png` Stack ile arka plana ekle
  - [ ] Üst bar: PNG'deki 3 kutuya skor / kalan hamle / kelime sayısı Flutter widget hizala
  - [ ] NxN grid widget (GestureDetector tabanlı) PNG'deki kağıt alana bindirme
  - [ ] Grid boyutunu GameStateProvider'dan oku (6, 8 veya 10)
  - [ ] 8 yönlü sürükleme algılama (swipe detection)
  - [ ] Alt bar: 6 joker butonu PNG yuvalarına Flutter widget hizala
  - [ ] Joker aktifse renkli, yoksa gri (Flutter tarafında kontrol)
  - [ ] Seçili harflerin görsel vurgulanması
  - [ ] Geçerli kelime → yeşil feedback + puan animasyonu
  - [ ] Geçersiz kelime → kırmızı feedback + sallama efekti
  - [ ] Çıkış onay dialogu ("Çıkmak istediğinize emin misiniz?")
  - [ ] Hamle bittiğinde otomatik oyun sonu → skor kaydetme
- [ ] `ScoreScreen`
  - [ ] Asset: `score_bg.png` arka plana ekle (sadece kırmızı doku)
  - [ ] Üst kısım: 6 istatistik kartı Flutter widget (bej container + siyah border)
  - [ ] Alt kısım: ListView.builder ile oyun kartları (en son oynanan üstte)
  - [ ] Her kartta: oyun no, tarih, grid, puan, kelime sayısı, en uzun kelime, süre
  - [ ] Kart stili: bej/kağıt renkli container, siyah border, Courier/typewriter font
- [ ] `MarketScreen`
  - [ ] Asset: `market_bg.png` arka plana ekle
  - [ ] 6 joker kartı — isim ve açıklamalar:
    - Balık: "Rastgele harfleri yok eder"
    - Tekerlek: "Seçilen harfin satır ve sütununu temizler"
    - Lolipop: "Seçilen tek harfi yok eder"
    - Değiştir: "Birbirine değen iki harfi yer değiştirir"
    - Karıştır: "Gridteki tüm harfleri karıştırır"
    - Parti: "Tüm harfleri yok eder, yenileri yukarıdan düşer"
  - [ ] Satın alma butonu + altın yeterliliği kontrolü (Flutter widget)
  - [ ] Mevcut altın göstergesi (üst kısım, Flutter widget)
  - [ ] (OPSİYONEL) Karta tıklayınca detay ekranı aç (joker açıklaması + satın al butonu)
  - [ ] (OPSİYONEL) Joker kullanım animasyonu (Lottie)

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

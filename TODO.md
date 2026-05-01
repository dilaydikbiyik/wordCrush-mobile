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

### Açık Buglar & Kontrol Edilecekler

- [x] **Grid shake bug**: Geçersiz kelime sonrası sallama animasyonu tamamlanınca grid eski konumuna oturmuyor
- [x] **Çıkış butonu**: Bazen tıklamayı algılamıyor; ikon/buton alanı küçük olabilir, tasarım değiştirilebilir
- [x] **Joker veritabanı & senkronizasyon**: `loadInventory()` SplashScreen'de hiç çağrılmıyordu — uygulama her açılışta envanter boş başlıyordu. `splash_screen.dart`'a eklendi, düzeltildi.
- [x] **Joker butonları tıklama bağlantısı eksik**: `_JokerBtn`'larda `onTap` yok, `JokerExecutor` GameScreen'e hiç bağlanmamış — jokerler görsel var ama işlev yapmıyor
- [x] **Solvability check hiç çağrılmıyor**: `GridProvider.scanAsync()` her hamle sonrası tetiklenmesi gerekirken GameScreen'den hiç çağrılmıyor — grid çözümsüz kalabilir, auto-shuffle devreye girmiyor
- [x] **Harf düşme animasyonu**: Kelime patlatılınca üstteki harfler aşağı kayarken animasyon yok — `GravityEngine` sonrası her hücre için aşağı kayma animasyonu eklenecek
- [x] **Patlama animasyonu**: Geçerli kelime seçilince hücreler kaybolmadan önce patlama/silme efekti eklenecek (Lottie veya Flutter animasyonu)

### Sıradaki Ekran: Animasyonlar ve Özel Güçler

- Harf düşme ve patlatma efektleri için animasyonların eklenmesi.
- Phase 7 kapsamındaki kelime uzunluğuna bağlı PowerExecutor entegrasyonu.

### Navigation Mimarisi (Tüm Ekranlarda Geçerli)

- `context.go()` → Splash→Home, GameOver→Home (geçmiş silinir)
- `context.push()` → Home→GridSize→MoveCount→Game, Home→Score, Home→Market (geri swipe çalışır)
- PopScope → Game ekranında back button yakalar → exit dialog

---

## Phase 6: UI/UX — Ekranlar

### Asset Listesi (`assets/images/`)

- [x] `splash_bg.png` — SplashScreen arka planı
- [x] `login_bg.png` — LoginScreen arka planı (input alanı boş)
- [x] `home_bg.png` — HomeScreen arka planı (username kutusu boş)
- [x] `grid_size_bg.png` — GridSizeScreen arka planı
- [x] `move_count_bg.png` — MoveCountScreen arka planı
- [x] `game_bg.png` — GameScreen arka planı (üst 3 kutu + kağıt grid alanı + 6 gri joker yuvası)
- [x] `score_bg.png` — ScoreScreen arka planı (sadece kırmızı doku, UI yok)
- [x] `market_bg.png` — MarketScreen arka planı (bakiye/fiyat kutuları boş)

### Ekranlar

- [x] `SplashScreen`
  - [x] Asset: `splash_bg.png` arka plana ekle
  - [x] Sözlük yükleme progress göstergesi
  - [x] ObjectBox initialization
- [x] `LoginScreen`
  - [x] Asset: `login_bg.png` arka plana ekle
  - [x] TextField PNG'deki boş input alanına hizala
  - [x] Kullanıcı adı girişi
  - [x] ObjectBox'a kaydetme
  - [x] Mevcut kullanıcı varsa otomatik giriş
- [x] `HomeScreen`
  - [x] Asset: `home_bg.png` arka plana ekle
  - [x] Username widget'ını PNG'deki torn paper kutusuna hizala (altın göstergesi yok)
  - [x] 3 buton: Yeni Oyun, Skor Tablosu, Market
  - [x] Sol üst: kullanıcı adı (tıkla → değiştir dialogu)
- [x] `GridSizeScreen`
  - [x] Asset: `grid_size_bg.png` arka plana ekle
  - [x] 3 kart: 6×6 (Zor), 8×8 (Orta), 10×10 (Kolay)
  - [x] Seçilen grid boyutunu GameStateProvider'a kaydet
  - [x] Router: AppRoutes.gridSize rotası ekle
- [x] `MoveCountScreen`
  - [x] Asset: `move_count_bg.png` arka plana ekle
  - [x] 3 kart: 15 Hamle (Zor), 20 Hamle (Orta), 25 Hamle (Kolay)
  - [x] Seçilen hamle sayısını GameStateProvider'a kaydet
  - [x] Router: AppRoutes.moveCount rotası ekle
  - [x] Akış: HomeScreen → GridSizeScreen → MoveCountScreen → GameScreen
- [x] `GameScreen`
  - [x] Asset: `game_bg.png` Stack ile arka plana ekle
  - [x] Üst bar: PNG'deki 3 kutuya skor / kalan hamle / kelime sayısı Flutter widget hizala
  - [x] NxN grid widget (GestureDetector tabanlı) PNG'deki kağıt alana bindirme
  - [x] Grid boyutunu GameStateProvider'dan oku (6, 8 veya 10)
  - [x] 8 yönlü sürükleme algılama (swipe detection)
  - [x] Alt bar: 6 joker butonu PNG yuvalarına Flutter widget hizala
  - [x] Joker aktifse renkli, yoksa gri (Flutter tarafında kontrol)
  - [x] Seçili harflerin görsel vurgulanması
  - [x] Geçerli kelime → yeşil feedback + puan animasyonu
  - [x] Geçersiz kelime → kırmızı feedback + sallama efekti
  - [x] Çıkış onay dialogu ("Çıkmak istediğinize emin misiniz?")
  - [x] Hamle bittiğinde otomatik oyun sonu → skor kaydetme
- [x] `ScoreScreen`
  - [x] Asset: `score_bg.png` arka plana ekle (sadece kırmızı doku)
  - [x] Üst kısım: 6 istatistik kartı Flutter widget (bej container + siyah border)
  - [x] Alt kısım: ListView.builder ile oyun kartları (en son oynanan üstte)
  - [x] Her kartta: oyun no, tarih, grid, puan, kelime sayısı, en uzun kelime, süre
  - [x] Kart stili: bej/kağıt renkli container, siyah border, Courier/typewriter font
- [x] `MarketScreen`
  - [x] Asset: `market_bg.png` arka plana ekle
  - [x] 6 joker kartı — isim ve açıklamalar:
    - Balık: "Rastgele harfleri yok eder"
    - Tekerlek: "Seçilen harfin satır ve sütununu temizler"
    - Lolipop: "Seçilen tek harfi yok eder"
    - Değiştir: "Birbirine değen iki harfi yer değiştirir"
    - Karıştır: "Gridteki tüm harfleri karıştırır"
    - Parti: "Tüm harfleri yok eder, yenileri yukarıdan düşer"
  - [x] Satın alma butonu + altın yeterliliği kontrolü (Flutter widget)
  - [x] Mevcut altın göstergesi (üst kısım, Flutter widget)
  - [ ] (OPSİYONEL) Karta tıklayınca detay ekranı aç (joker açıklaması + satın al butonu)
  - [ ] (OPSİYONEL) Joker kullanım animasyonu (Lottie)

## Phase 7: Özel Güçler & Jokerler ✅

- [x] `PowerType` enum (RowClear, AreaBlast, ColumnClear, MegaBlast)
- [x] `PowerExecutor`
  - [x] 4 harf → Satır Temizleme (tüm satırı sil)
  - [x] 5 harf → Alan Patlatma (komşu hücreleri sil)
  - [x] 6 harf → Sütun Temizleme (tüm sütunu sil)
  - [x] 7+ harf → Mega Patlatma (2 birim çevre sil)
- [x] Özel simge hücreleri (güç simgesi grid'e yerleştirme)
- [x] Güç aktivasyon mekaniği (simgeyi kelimede kullanma → tetikleme)
- [x] `JokerType` enum (6 joker)
- [x] `JokerExecutor`
  - [x] Balık: rastgele harfleri yok et
  - [x] Tekerlek: satır + sütun sil
  - [x] Lolipop Kırıcı: tek harf sil
  - [x] Serbest Değiştirme: iki harf yer değiştir
  - [x] Harf Karıştırma: grid shuffle
  - [x] Parti Güçlendiricisi: tümünü sil + yeniden doldur
- [x] Joker kullanımı sonrası gravity + solvability kontrolü

## Phase 8: Animasyonlar, Ses & Polish [/]

- [x] Yerleşik Flutter animasyonları (Lottie yerine assetlerle):
  - [x] Harf düşme (gravity) animasyonu (`AnimatedPositioned`)
  - [x] Harf patlatma animasyonu (`TweenAnimationBuilder`)
  - [x] Satır/sütun temizleme efekti
  - [x] Bomba/mega patlatma efekti
  - [x] Combo popup animasyonu
- [x] Ses efektleri entegrasyonu (`audioplayers`):
  - [x] Harf seçme sesi
  - [x] Geçerli kelime sesi
  - [x] Geçersiz kelime sesi
  - [x] Combo sesi
  - [x] Özel güç aktivasyon sesi
  - [x] Oyun sonu sesi
- [ ] UI polish:
  - [x] Uygun renk paleti ve tema tasarımı
  - [x] Loading state'leri ve skeleton ekranları
  - [x] Error handling UI (hata mesajları)

## Phase 9: Test & Final

- [x] Unit test: Trie (insert, search, startsWith)
- [x] Unit test: GridGenerator (frekans dağılımı doğrulama)
- [x] Unit test: GridSolver (kelime bulma doğruluğu)
- [x] Unit test: ScoreCalculator (puan hesaplama)
- [x] Unit test: ComboEngine (alt kelime tespiti doğruluğu)
- [x] Integration test: Oyun akışı (başla → oyna → bitir → skor kaydet)
- [ ] Performans testi: 10×10 grid solvability tarama süresi
- [x] Edge case: Grid'de kelime kalmama senaryoları
- [x] Edge case: Altın yetersiz durumu (market)
- [x] Edge case: Tüm jokerler kullanılmış durumu
- [x] Edge case: Kullanıcı adı boş / çok uzun
- [ ] iOS emülatör üzerinde son test
- [ ] Sunum hazırlığı

# Word Crush — Proje Denetim Raporu

> Tarih: 2026-04-28
> Kapsam: PROJECT_INSTRUCTIONS.md, TODO.md, tüm `lib/`, `test/`, `assets/` ve `pubspec.yaml`

---

## ✅ TAMAMLANAN / KAPATILAN MADDELER

| #     | Madde                                                | Durum              | Not                                                                               |
| ----- | ---------------------------------------------------- | ------------------ | --------------------------------------------------------------------------------- |
| 6     | Çıkış dialogu boş oyun kaydı yaratıyor               | ✅ Düzeltildi      | `wordCount == 0` ise `endGame()` çağrılmıyor                                      |
| 8     | "Gridde Oluşturulabilir Kelime Sayısı" etiketi       | ⏭️ Atlandı         | Mevcut hali yeterli görüldü                                                       |
| 15d   | Skor tablosu başlığı + boş kayıt yazısı arka plansız | ✅ Düzeltildi      | Her ikisine de bej Container + siyah border eklendi                               |
| 3     | Power tile simgesi                                   | 🔄 Sonra Dönülecek | İkonlar eklendi ama tasarım arkadaşla birlikte gözden geçirilecek                 |
| 5     | Düşme animasyonu key hatası                          | ✅ Düzeltildi      | `_GridWidget` StatefulWidget'a çevrildi, yeni hücreler tepeden animasyonla iniyor |
| 11    | ScoreScreen Riverpod'u bypass ediyor                 | ✅ Düzeltildi      | `gameRecordsProvider` eklendi, ekran artık reaktif                                |
| 16    | Lint uyarıları (4 adet)                              | ✅ Düzeltildi      | `flutter analyze` artık `No issues found` veriyor                                 |
| 2     | Splash sözlük yüklemesi sahte                        | ✅ Düzeltildi      | `trieProvider` splash'ta tetikleniyor, log ile doğrulandı                         |
| 15a   | Hatalı kelimede hamle azalmıyor                      | ✅ Düzeltildi      | 3+ harf yanlış kelimede `decrementMove()` çağrılıyor                              |
| UX1   | Shake sonrası yeni seçim gecikmesi                   | ✅ Düzeltildi      | `onPanStart` ile her gesture'da seçim sıfırlanıp ilk hücre ekleniyor              |
| UX2   | Hücre seçim hassasiyeti (çapraz)                     | ✅ Düzeltildi      | `floor()` + `clamp` ile kenar taşması giderildi, ilk hücre doğru seçiliyor        |
| 14    | Power aktivasyon sesi                                | 🔄 Sonra Dönülecek | Sesler değiştikten sonra eklenecek (madde 15c ile birlikte)                       |
| 20    | InfoBox + currentWord çakışma                        | ✅ Düzeltildi      | `currentWord` pozisyonu aşağı kaydırıldı                                          |
| 21    | fish joker magic number                              | ✅ Düzeltildi      | `AppConstants.fishDeleteCount = 3` sabiti eklendi                                 |
| 22    | Audio race condition                                 | 🔄 Sonra Dönülecek | Sesler değiştikten sonra 14 ve 15c ile birlikte ele alınacak                      |
| 19    | Username Türkçe karakter sapması                     | ✅ Düzeltildi      | `username.length` → `username.runes.length`                                       |
| S5/S6 | Fix sonrası `wordCount` yanlış (0) dönüyordu         | ✅ Düzeltildi      | `ensureSolvable()` sonrası düzeltilmiş grid yeniden taranıyor, doğru sayı dönüyor |

---

## ⛔ KRİTİK SORUNLAR

---

### 1. Riverpod Sürüm İhlali

**Sorun nedir?**
`PROJECT_INSTRUCTIONS.md §3`'te açıkça yazıyor: Riverpod `^3.3.1` kullanılacak.
Ancak `pubspec.yaml:15`'te şu an `flutter_riverpod: ^2.4.0` yazıyor — uygulama Riverpod 2.x ile çalışıyor.

**Riverpod 2.x ile 3.x arasındaki fark neden önemli?**

- Riverpod 2.x → `StateNotifier` + `StateNotifierProvider` kullanır (şu an projede olan budur)
- Riverpod 3.x → `Notifier` sınıfı + `@riverpod` code-generation annotation ile çalışır (yeni yol)

Riverpod 3, `StateNotifier`'ı deprecated (kullanım dışı) saydı. Bu, projenin spec'te belirtilen versiyonu kullanmadığı anlamına gelir.

**Seçenekler:**

1. Riverpod 3'e geçiş yapılır → tüm provider sınıfları baştan yazılır (büyük değişiklik)
2. `PROJECT_INSTRUCTIONS.md §3` güncellenerek "^2.4.0 kullanılıyor, gerekçe: API kararlılığı" notu düşülür ve `INSTALL_LOG.md`'ye kaydedilir

**Sunum notu:** Hoca bu soruyu sorabilir. "Riverpod 2 kullandım çünkü 3'ün API'si değişkendir ve projenin teslim tarihi bu geçişe izin vermiyordu" gibi bilinçli bir cevap verebilmek için bu kararın netleştirilmesi gerekiyor.

---

### 3. Özel Güç (Power Tile) Görsel İşareti Yok

**Sorun nedir?**
Mantık katmanı doğru çalışıyor: 4+ harfli kelime bulunduğunda `power_executor.dart` ve `grid_provider.dart:167` birlikte son harfin hücresine `PowerType` bilgisi (RowClear, AreaBlast, ColumnClear, MegaBlast) yazıyor.

Ancak `_CellTile` widget'ı (her hücreyi ekranda çizen widget) bu bilgiyi **hiç kullanmıyor.** Hücre sadece harfi gösteriyor, güç simgesi yok.

**Oyuncu ne görüyor?**
4 harfli kelime buldu, harfler patladı, son harfin yerine… yine normal bir harf gelmiş gibi görünüyor. Oyuncu güç simgesinin orada olduğunu bilmiyor; kullanamıyor.

**Spec ne diyor?**
`PROJECT_INSTRUCTIONS.md §5`:
| Kelime Uzunluğu | Simge |
|---|---|
| 4 harf | A ↔ |
| 5 harf | A 💣 |
| 6 harf | A ↕ |
| 7+ harf | A ⚙ |

**TODO'da ne yazıyor?**
"Özel simge hücreleri ✅" — bu da **yanlış işaretlenmiş.**

**Düzeltme:**
`_CellTile` içinde `Stack` yapısı kurularak `cell.powerType != PowerType.none` koşulunda hücrenin üzerine simge overlay eklenmeli.

---

### 4. Solvability Isolate Her Hamlede 60.000 Kelimeyi Kopyalıyor

**Sorun nedir?**
Her hamle sonrası grid'in çözülebilir olup olmadığı kontrol ediliyor — bu doğru bir yaklaşım. Ama nasıl çalıştığına bakılırsa:

`grid_solver_isolate.dart:53-61`: `compute()` her çağrıda **tüm `wordList`'i** (~60.000 kelime) isolate'e gönderiyor. Isolate bu listeyi alıp **sıfırdan Trie inşa ediyor**, kontrolü yapıp sonucu döndürüyor.

**Performans maliyeti:**

- Her hamlede 60.000 kelime serialize edilip kopyalanıyor
- Isolate içinde Trie yeniden build ediliyor (bu başlı başına ağır bir işlem)
- 10×10 grid'de her hamlede bu döngü tekrarlanıyor

**Sonuç:** Sunumda telefonun donması veya belirgin gecikme yaşanması ihtimali var. Özellikle 10×10 grid'de, yoğun hamle serilerinde bu fark edilecek kadar belirgin olabilir.

**Doğru mimari:** Trie'nin bir kez build edilmiş halini paylaşmak — ama Flutter isolate'leri bellek paylaşamadığı için bu mimari açıdan uğraştırır. Alternatif olarak isolate'i kalıcı tutup (long-lived isolate) sadece grid matrisini göndermek daha verimli olurdu.

---

### 7. Combo Puanlama — Test ve Runtime Tutarlı Ama İsimlendirme Kafa Karıştırıcı

**Durum:**
`score_calculator_test.dart:67`'de `SARI + ARI = 6 + 4 = 10` testi var ve geçiyor — bu doğru.

`game_screen.dart:142-144`'te `combos = allCombos.where((w) => w != word).toList()` ile ana kelime listeden çıkarılıyor ve ayrıca bir kez sayılıyor. Davranış tutarlı.

**Sorun:**
Test kodu ana kelimeyi baştan dışarıda bırakarak yazılmış (`['ARI']` gibi). Runtime'da ise filtre ile çıkarılıyor. İkisi aynı sonucu veriyor ama farklı yollarla geliyor — bu ilerleyen zamanda bakım sırasında kafa karışıklığı yaratabilir.

---

## ❓ SORULAN SORULAR — MEVCUT DURUM (Kod Analizi ile Cevaplandı)

---

### S2. Kombo sayısı ekranda yazıyor mu?

**Evet, ama sınırlı.**
`game_screen.dart:179-181`: 2 veya daha fazla kombo bulununca bir popup açılıyor. Popup sadece `"4× COMBO! +21"` yazıyor — kaç kombo olduğu ve toplam puan görünüyor, ama hangi alt kelimeler bulundu gösterilmiyor.

Madde 12'de bu eksiklik zaten kayıtlı.

---

### S3. Kelime kalmama kontrolü nasıl yapılıyor?

**Mekanizma şu şekilde çalışıyor:**

1. Oyuncu geçerli bir kelime bulur / joker kullanır / oyun başlar
2. `game_screen.dart` → `_runSolvabilityCheck()` çağrılır (3 tetiklenme noktası: initState, geçerli kelime, joker)
3. Bu, `grid_provider.dart`'daki `scanAsync()` metodunu tetikler
4. `scanAsync()` tüm grid'i arka planda (isolate) tarar
5. Eğer geçerli kelime yoksa `fixedLetters` dolarak gelir → grid otomatik değiştirilir, ardından düzeltilmiş grid **tekrar** taranır (`isRetry`)

**Hâlâ eksik olan:**

- Kullanıcıya "grid taranıyor" veya "harfler değiştirildi" bildirimi yok
- Madde 4'teki performans sorunu (60.000 kelime her seferinde kopyalanıyor) gecikmeye yol açabilir

---

### S4. Grid ilk oluşturulurken kelime var mı kontrol ediliyor?

**Evet, düzeltildi.**
`game_screen.dart:87`: `initState` → `postFrameCallback` içinde `_runSolvabilityCheck()` çağrılıyor. Grid oluşturulur oluşturulmaz arka planda taranıyor; kelime yoksa otomatik fix uygulanıyor.

---

### S7. Oyun ne zaman bitiyor?

**İki koşul var ve ikisi de çalışıyor:**

1. **Hamle sayısı bitince:** `game_screen.dart:187-194` — `gameState.isGameOver` true olunca `endGame()` çağrılıyor ve oyun sonu dialogu gösteriliyor
2. **Oyuncu çıkmak istediğinde:** `game_screen.dart:394-399` — çıkış dialogunda "Evet" basılınca da `endGame()` çağrılıyor

Her ikisi de spec ile uyumlu.

---

### S8. Çıkış dialogunda "Evet" dersek oyun kaydediliyor mu?

**Evet, kaydediliyor.**
`game_screen.dart:394-399`: Çıkış dialogu "Evet" basıldığında `endGame(finalScore)` çağrısı yapılıyor. Bu kayıt ObjectBox'a yazılıyor ve skor tablosunda görünüyor.

Madde 6 düzeltildi: `wordCount == 0` ise `endGame()` çağrılmıyor → boş kayıt yazılmıyor.

---

## 📭 EKSİK — TODO İLE TUTARSIZ YA DA HİÇ YAPILMAMIŞ

---

### 9. Phase 8 UI Polish — 4 Madde Yapılmadı (TODO Bu Sefer Doğru İşaretli)

Bu maddeler TODO'da işaretsiz — rapor da bunu doğruluyor:

**a) Renk paleti / tema:**
`MaterialApp.router`'a `theme:` parametresi verilmemiş. Uygulama default Material tema renkleriyle çalışıyor. Projeye özgü bir renk paleti yok.

**b) Responsive layout:**
Tüm ekranlar arka plan asset'i için `BoxFit.fill` kullanıyor. Bu, görseli her zaman ekrana sığdırmak için uzatır/sıkıştırır. iPhone SE'de (küçük ekran) veya iPhone Pro Max'te (büyük ekran) görseller orantısız görünebilir. `BoxFit.cover` + merkez hizalama veya `AspectRatio` sarması daha doğru yaklaşım olurdu.

**c) Loading state:**
`trieProvider` bir `FutureProvider` — yani üç durumu var: yükleniyor, hata, hazır. Hiçbir ekranda `ref.watch(trieProvider).when(data: ..., loading: ..., error: ...)` yapısı kullanılmamış. Sözlük yüklenirken ne olduğu belirsiz.

**d) Error UI:**
Sözlük `assets/data/turkish_words.txt` yüklenemezse veya ObjectBox başlatılamazsa kullanıcıya hiçbir mesaj gösterilmiyor. Uygulama sessizce hatalı çalışıyor.

---

### 10. Phase 9 Test Eksikleri (TODO Doğru İşaretli)

- **Integration test:** Oyun akışı uçtan uca test edilmemiş — başla → kelime bul → hamle bit → skor kaydet → skor tablosunda görün.
- **Performans testi:** 10×10 grid'de solvability taramasının kaç milisaniyede tamamlandığı hiç ölçülmemiş. Sunumda donma yaşanırsa sayısal bir cevap verilemiyor.
- **Edge case akış testi:** Birim testlerde kelime kalmama senaryosu var ama bunun gerçek oyun akışında (gravity + yeniden üretim zincirleriyle birlikte) nasıl çalıştığı test edilmemiş.
- **iOS emülatör son test** ve **sunum hazırlığı:** Bunlar kullanıcının yapması gerekiyor.

---

### 12. Combo Popup Alt Kelimeleri Göstermiyor

**Sorun nedir?**
"ADANA" yazıldığında combo popup açılıyor: "4× COMBO! +21 puan" yazıyor.

Hangi alt kelimelerin bulunduğu (ADANA, DANA, ANA, ADA) gösterilmiyor.

**Neden önemli?**
Oyuncu combo sistemini nasıl çalıştığını göremeden anlayamaz. Öğretici değil. Spec bunu zorunlu kılmıyor ama sunum için etkileyici bir detay olurdu.

---

### 13. `docs/` Rule Dosyaları Doğrulanmadı

**Durum:**
`docs/ui_rules.md`, `state_rules.md`, `game_engine_rules.md` dosyaları mevcut. `PROJECT_INSTRUCTIONS.md §13` bu dosyalara her görev tipinde başvurulmasını zorunlu kılıyor. Rapor bu dosyaların içeriklerini doğrulamadı — kontrol edilmeli.

---

### 14. Power Aktivasyon Sesi Joker Dışında Çalmıyor

**Sorun nedir?**
`game_screen.dart:313`'te `playSound(SoundType.powerActivation)` çağrısı sadece `_executeJoker` metodunun içinde var.

4+ harfli kelime bulunup `PowerExecutor` devreye girdiğinde (satır/sütun temizleme, alan patlatma vb.) ses çalmıyor. Oyuncu güç aktivasyonunu görüntü olarak anlıyor ama ses geri bildirimi yok.

---

### 15b. Joker Animasyonu Yok

**Sorun nedir?**
`game_screen.dart`'ta `_executeJoker` metodunda joker çalıştırıldıktan sonra hiçbir animasyon kodu yok. Grid hücreler aniden değişiyor.

Örneğin Parti jokeri tüm harfleri silip yenilerini üstten düşürüyor — ama bu işlem animasyonsuz, anlık gerçekleşiyor. Balık, Tekerlek, Lolipop jokerlerinin de kendine özgü görsel efekti yok.

**TODO'da ne yazıyor?**
`TODO.md` Phase 8'de `(OPSİYONEL) Joker kullanım animasyonu` olarak işaretsiz duruyor — doğru kayıtlı.

**Ne yapılmalı?**
Her joker tipi için en azından basit bir efekt:

- Silinen hücreler için `TweenAnimationBuilder` ile fade-out veya scale-down
- Tekerlek için satır/sütun boyunca silme animasyonu
- Parti için tüm grid'de cascade fade

---

### 15c. Ses Efektleri Yetersiz / Değiştirilmesi Gerekiyor

**Sorun nedir?**
`assets/sounds/` klasöründeki mevcut ses dosyaları kalite veya uyum açısından yetersiz.

**Etkilenen sesler:**

- `valid_word.mp3` — geçerli kelime sesi
- `invalid_word.mp3` — geçersiz kelime sesi
- `combo.mp3` — combo sesi
- `power_activation.mp3` — güç aktivasyon sesi
- `game_over.mp3` — oyun sonu sesi

**Ne yapılmalı?**
Ücretsiz ses kütüphanelerinden (örn: Freesound, Mixkit, ZapSplat) kelime oyununa uygun, daha kaliteli ses efektleri indirilerek değiştirilmeli. Dosya adları aynı kalmalı, sadece içerik değişmeli.

---

### 15. Joker Testleri Yüzeysel

**Sorun nedir?**
`edge_cases_test.dart:57-90`'daki joker testleri yalnızca `qty > 0` kontrolünü test ediyor — "miktar sıfırdan büyük mü?"

Test edilmeyen asıl iş mantığı:

- `JokerNotifier.useJoker()` çağrıldığında envanterin gerçekten 1 azalıp azalmadığı
- Bu değişikliğin ObjectBox'a yazılıp yazılmadığı (kalıcılık)
- Uygulama kapatılıp açıldığında joker sayısının doğru geri gelip gelmediği

Joker satın alma ve kullanımı en kritik iş mantıklarından biri — bu test kapsamı yetersiz.

---

## 🔧 İYİLEŞTİRİLEBİLİR

---

### 17. `Cell._idCounter` Sonsuz Büyüyen Statik Sayaç

**Sorun nedir?**
`cell.dart:6`'da `static int _idCounter = 0` tanımlı. Her yeni `Cell` oluşturulduğunda bu sayaç artıyor.

Uzun oturumda, hot-reload sonrasında ve birim testlerde bu sayaç sıfırlanmadan monoton artmaya devam ediyor. Bellek sorunu yaratmıyor ama diagnostic amaçlı ID'lere bakıldığında okunaksız büyük sayılar görünebiliyor. Test izolasyonunu zorlaştırıyor.

---

### 18. `MarketProvider` ile `JokerProvider` Sıkı Bağlı

**Sorun nedir?**
`market_provider.dart:99-101`: Market işlemi sırasında `ref.read(playerProvider.notifier)` ve `ref.read(jokerProvider.notifier)` doğrudan çağrılıyor.

Bu bağlantı Riverpod 2.x'te çalışıyor. Ancak Riverpod 3'e geçiş yapılırsa `Notifier` API'sindeki `ref` kullanım pattern'ı değiştiğinden bu kısımlar yeniden yazılmak zorunda kalınacak.

---

### 22. `AudioNotifier.playSound` Race Condition

**Sorun nedir?**
`audio_provider.dart:86-87`:

```dart
await player.stop();
await player.play();
```

Oyuncu çok hızlı kelimeler yazarsa (özellikle combo'lu) sesler art arda tetikleniyor. İlk `stop` tamamlanmadan ikinci çağrı gelirse sesler üst üste binebiliyor veya biri aniden kesilebiliyor.

---

### 23. `formableWordCount` Etiketi Spec Metniyle Uyuşmuyor

Madde 8 ile bağlantılı. Hesaplama mantığı doğru (non-overlapping greedy, spec ile uyumlu) ama UI'daki "KELİME" etiketi spec'teki tam ifadeyle eşleşmiyor.

---

### 24. Oyun Sonu Altın Ödülü Yok

**Sorun nedir?**
`PROJECT_INSTRUCTIONS.md §4.4`: "Altın oyunlar arası birikir."

`GameScreen.endGame` çalışınca skor kaydediliyor ama oyuncuya altın eklenmiyor. Market başlangıçta 5000 altınla dolu olduğu için bu fark edilmiyor — ama spec "birikir" ifadesiyle bir kazanım mekanizması olduğunu ima ediyor.

---

### 25. `pubspec.yaml` Paket Sürümleri Geride

14 paket mevcut sürümlerin gerisinde kalmış. Normal koşullarda bu büyük sorun değil, ama Riverpod 3'e geçiş kararı alınırsa zincirleme bağımlılık güncellemeleri gerekecek. `flutter pub outdated` ile mevcut durumu görmek faydalı.

---

## 📊 ÖZET TABLO

| #   | Sorun                            | Durum                     | Aciliyet        |
| --- | -------------------------------- | ------------------------- | --------------- |
| 1   | Riverpod 2 → 3 sürüm ihlali      | Spec ihlali               | 🔴 Kritik       |
| 2   | Splash sahte progress bar        | ✅ Düzeltildi             | 🔴 Kritik       |
| 3   | Power tile simgesi yok           | Yanlış işaretlenmiş       | 🔴 Kritik       |
| 4   | Solvability isolate performans   | ✅ Düzeltildi             | 🟡 Orta         |
| 5   | Düşme animasyonu key hatası      | Görsel kalite sorunu      | 🟡 Orta         |
| 6   | Çıkış → boş kayıt                | Veri kirliliği            | 🟢 Düşük        |
| 7   | Combo isimlendirme               | Bakım riski               | 🟢 Düşük        |
| 8   | Kelime sayısı etiketi eksik      | Spec metni yok            | 🟡 Orta         |
| 9   | UI polish 4 madde                | ✅ Düzeltildi             | 🟡 Plan dahili  |
| 10  | Integration / performans testi   | Yapılmamış                | 🟡 Sunum öncesi |
| 11  | ScoreScreen reaktif değil        | Mimari sorun              | 🟢 Düşük        |
| 12  | Combo popup alt kelime yok       | ✅ Düzeltildi             | 🟢 Düşük        |
| 13  | docs/ dosyaları doğrulanmadı     | Kontrol gerekli           | 🟢 Düşük        |
| 14  | Power sesi çalmıyor              | Ses geri bildirimi eksik  | 🟢 Düşük        |
| 15a | Hatalı kelimede hamle azalmıyor  | Karar bekleniyor          | 🟡 Orta         |
| 15b | Joker animasyonu yok             | ✅ Düzeltildi             | 🟡 Orta         |
| 15c | Ses efektleri yetersiz           | Kalite sorunu             | 🟡 Orta         |
| 15  | Joker testleri yüzeysel          | ✅ Düzeltildi             | 🟡 Orta         |
| 16  | Lint uyarıları (4 adet)          | Küçük                     | 🟢 Düşük        |
| 17  | Cell.\_idCounter sonsuz artar    | ✅ Düzeltildi             | 🟢 Düşük        |
| 18  | Market-Joker sıkı bağlantı       | Riverpod 3 riski          | 🟢 Düşük        |
| 19  | Username Türkçe karakter sapması | Edge case                 | 🟢 Düşük        |
| 20  | InfoBox + currentWord çakışma    | UI sorunu                 | 🟢 Düşük        |
| 21  | fish joker magic number          | Kod standardı             | 🟢 Düşük        |
| 22  | Audio race condition             | Ses kalitesi              | 🟢 Düşük        |
| 23  | formableWordCount etiketi        | Spec uyumsuzluğu          | 🟡 Orta         |
| 24  | Oyun sonu altın ödülü yok        | ✅ Düzeltildi             | 🟢 Düşük        |
| 25  | Grid başlangıçta taranmıyor      | Edge case                 | 🟡 Orta         |
| 26  | pubspec.yaml paketler geride     | Bağımlılık riski          | 🟢 Düşük        |

---

## 💡 ÖNERİLEN DÜZELTME SIRASI

| #   | Yapılacak                                                       | Tahmini Süre    |
| --- | --------------------------------------------------------------- | --------------- |
| 1   | Hatalı kelimede hamle azalsın mı? — karar ver, uygula           | ~5 dk           |
| 2   | Splash'ta `trieProvider` await et, gerçek progress bar yap      | ~10 dk          |
| 3   | `_CellTile`'a power simgesi overlay ekle (Stack + koşullu Icon) | ~15 dk          |
| 4   | "Gridde Oluşturulabilir Kelime Sayısı" tam metnini ekle         | ~5 dk           |
| 5   | Çıkış dialogu — `wordCount == 0` ise kayıt yazma                | ~3 dk           |
| 6   | Skor tablosu başlığına background container ekle                | ~5 dk           |
| 7   | Gravity engine key stabilizasyonu — yeni Cell üretme, refill et | ~20 dk          |
| 8   | `gameRecordsProvider` ekle, ScoreScreen reaktif hale getir      | ~15 dk          |
| 9   | Lint uyarılarını temizle (`flutter analyze`)                    | ~5 dk           |
| 10  | Ses dosyalarını değiştir (aynı isimler, yeni içerik)            | ~30 dk          |
| 11  | Joker animasyonları (fade-out, cascade efektler)                | ~45 dk          |
| 12  | Phase 8 UI polish — tema + responsive layout                    | ~1-2 saat       |
| 13  | Riverpod 3 geçiş kararı netleştir (ya geç ya spec'i güncelle)   | Karar gerekiyor |

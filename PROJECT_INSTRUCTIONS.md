# 📜 PROJECT_INSTRUCTIONS.md — Word Crush Proje Anayasası

> Bu dosya, projede çalışan tüm geliştiriciler ve AI agentler için **bağlayıcı kurallar** içerir.
> Kod yazmadan önce bu dosyanın tamamı okunmalıdır.

---

## 1. Proje Kimliği

| Alan | Bilgi |
|------|-------|
| **Proje** | Word Crush — Mobil Kelime Bulmaca Oyunu |
| **Kurum** | Kocaeli Üniversitesi, Bilgisayar Mühendisliği Bölümü |
| **Ders** | Yazılım Laboratuvarı-II (Yazlab-II) |
| **Teslim Tarihi** | 01.05.2026 |
| **Sunum** | 4-8 Mayıs 2026 haftası |
| **Platform** | iOS (Flutter / Dart) |
| **Sunum Ortamı** | Emülatör veya fiziksel telefon (Web/Masaüstü KABUL EDİLMEZ) |

---

## 2. Hybrid Data Architecture

Bu proje **iki katmanlı** bir veri mimarisi kullanır:

### 2.1 RAM Katmanı — Trie (Prefix Tree)

**Amaç:** Sözlük aramalarında ultra hızlı kelime doğrulama ve grid taraması.

- **Karmaşıklık:** `O(m)` — m = kelime uzunluğu
- **Kullanım Alanları:**
  - Kelime doğrulama (oyuncu sürükleme bitirdiğinde)
  - Grid solvability arka plan taraması (her hamle sonrası)
  - Combo alt kelime tespiti
  - Prefix kontrolü (`startsWith`) ile grid taramada dalbudama (pruning)
- **Veri Kaynağı:** `assets/data/turkish_words.txt` → Splash screen'de Trie'ye yüklenir
- **Tahmini boyut:** ~50,000+ kelime, RAM'de tutulur

**Neden Trie, neden HashSet değil?**
HashSet `O(1)` lookup sağlar ama prefix search yapamaz. Grid solvability taramasında her hücreden 8 yönlü DFS yapılırken, "bu prefix ile başlayan herhangi bir kelime var mı?" sorusunu `O(p)` ile cevaplayarak **binlerce gereksiz dalı budayabiliriz**. Bu, 10×10 grid'de tarama süresini saniyelerden milisaniyelere düşürür.

### 2.2 Disk Katmanı — ObjectBox NoSQL (v5.3.1)

**Amaç:** Kalıcı veri depolama (uygulama kapatılsa bile veri korunur).

- **Kullanım Alanları:**
  - Oyuncu profili (kullanıcı adı, altın bakiyesi)
  - Skor geçmişi (tüm oyun kayıtları)
  - Joker envanteri (sahip olunan jokerler ve adetleri)
- **Neden ObjectBox?**
  - Aktif olarak bir şirket tarafından geliştirilip destekleniyor
  - NoSQL yapısı — esnek şema
  - Yüksek performanslı, type-safe Dart API
  - iOS tam destek, native kütüphaneler dahil
  - Code generation ile `@Entity` annotation desteği

---

## 3. Temel Gereksinimler

| Kategori | Teknoloji | Versiyon |
|----------|-----------|----------|
| Framework | Flutter (Dart) | Latest stable |
| State Management | **Riverpod** | ^2.4.0 (3.x değil — StateNotifier API kararlılığı ve teslim tarihi nedeniyle 2.x tercih edildi) |
| Veritabanı | **ObjectBox** | ^5.3.1 |
| Router | go_router | Latest |
| Animasyon | Lottie | Latest |
| Ses | audioplayers | Latest |

> ⚠️ **Riverpod ZORUNLUDUR.** Başka state management çözümü (Provider, Bloc, GetX vb.) kullanılamaz.

---

## 4. Oyun Sabitleri (Constants)

### 4.1 Grid & Hamle Tablosu

| Grid Boyutu | Seviye | Hamle Sayısı |
|-------------|--------|-------------|
| 10×10 | Kolay | 25 hamle |
| 8×8 | Orta | 20 hamle |
| 6×6 | Zor | 15 hamle |

### 4.2 Harf Puanlama Tablosu (29 Türkçe Harf)

| Harf | Puan | Harf | Puan | Harf | Puan | Harf | Puan |
|------|------|------|------|------|------|------|------|
| A | 1 | B | 3 | C | 4 | Ç | 4 |
| D | 3 | E | 1 | F | 7 | G | 5 |
| Ğ | 8 | H | 5 | I | 2 | İ | 1 |
| J | 10 | K | 1 | L | 1 | M | 2 |
| N | 1 | O | 2 | Ö | 7 | P | 5 |
| R | 1 | S | 2 | Ş | 4 | T | 1 |
| U | 2 | Ü | 3 | V | 7 | Y | 3 |
| Z | 4 | | | | | | |

> Örnek: "SORU" = S(2) + O(2) + R(1) + U(2) = **7 puan**

### 4.3 Türkçe Harf Frekansları

Harfler rastgele üretilirken aşağıdaki 3 katmanlı frekans sistemi uygulanır:

| Katman | Harfler | Olasılık |
|--------|---------|----------|
| **Yüksek** | A, E, İ, L, R, N | Daha sık üretilir |
| **Orta** | K, D, M, U, T, S, Y, B, O | Normal sıklıkta |
| **Düşük** | J, Ğ, F, V | Daha nadir üretilir |

> ⚠️ Harfler **tamamen rastgele DEĞİLDİR.** Bu frekans tablosu zorunludur.

### 4.4 Altın Sistemi

- Başlangıçta test amaçlı **bol miktarda altın** verilir (örn: 5000)
- Altın oyunlar arası **birikir**, yeni oyun başlatılınca **sıfırlanmaz**
- Joker satın almak için harcanır
- Gerçek para ile satın alma sistemi **YOKTUR**

---

## 5. Özel Güçler (Kelime Uzunluğuna Göre)

Oyuncu belirli uzunlukta kelime bulduğunda, kelimenin **son harfinin konumuna** özel güç simgesi bırakılır. Bu simge daha sonra bir kelimede tekrar kullanıldığında etki tetiklenir.

| Kelime Uzunluğu | Güç Adı | Simge | Etki |
|-----------------|---------|-------|------|
| **4 harf** | Satır Temizleme | A ↔ | Simgenin bulunduğu **tüm satır** temizlenir |
| **5 harf** | Alan Patlatma | A 💣 | Simgenin **çevresindeki tüm komşu** harfler yok edilir |
| **6 harf** | Sütun Temizleme | A ↕ | Simgenin bulunduğu **tüm sütun** temizlenir |
| **7+ harf** | Mega Patlatma | A ⚙ | Simgenin **2 birim çevresindeki tüm** harfler yok edilir |

**Akış:**
1. 4+ harfli geçerli kelime bulunur → harfler patlatılır
2. Son harfin yerine özel güç simgesi yerleşir
3. Oyuncu bu simgeyi yeni bir kelimede kullandığında güç tetiklenir
4. Güç efekti sonrası gravity (yerçekimi) uygulanır

---

## 6. Joker Tablosu

Market'ten altın karşılığı satın alınabilen jokerler:

| İsim | Altın | Açıklama |
|------|-------|----------|
| **Balık** | 100 | Gridde rastgele harfleri yok eder. Üzerindeki harfler aşağı düşer. |
| **Tekerlek** | 200 | Seçilen harfin bulunduğu satır ve sütundaki tüm harfler yok olur. |
| **Lolipop Kırıcı** | 75 | Seçilen tek bir harfi yok eder. Üstündeki harfler aşağı düşer. |
| **Serbest Değiştirme** | 125 | Birbirine temas eden iki harfin yerini değiştirir. |
| **Harf Karıştırma** | 300 | Gridde bulunan tüm harfleri rastgele karıştırır. |
| **Parti Güçlendiricisi** | 400 | Tüm harfleri yok eder, yukarıdan rastgele yeni harfler düşer. |

Jokerler oyun ekranının **alt kısmında** seçilebilir şekilde gösterilir. Marketten alınmamışsa pasif/kilitli görünür.

---

## 7. Combo Mekaniği

Oyuncunun oluşturduğu **ana kelimenin içindeki anlamlı alt kelimeler** üzerinden bonus puan kazanma sistemi.

### Kurallar:
1. **Ana Kelime Seçimi:** Oyuncu grid üzerinde anlamlı bir kelime oluşturur → "ana kelime"
2. **Alt Kelime Tespiti:** Ana kelime içinde **3 harf veya daha uzun** anlamlı kelimeler aranır
3. **Combo Sayımı:** Bulunan her alt kelime combo sayısını artırır. Ana kelime her zaman combo sayısına **dahildir**
4. **Tekrarlama Kısıtlaması:** Aynı alt kelime birden fazla kez sayılamaz
5. **Harf Sırası:** Alt kelimeler, ana kelimenin **harf sırasına göre** bulunmalıdır
6. **Puanlama:** Alt kelimelerin de harf bazlı puanları hesaplanıp **ana kelime puanına eklenir**

### Örnekler:

| Ana Kelime | İç Kelimeler | Combo Sayısı |
|------------|-------------|--------------|
| ADANA | ADANA, DANA, ANA, ADA | 4× combo |
| MASAL | MASAL, MASA, ASA, SAL | 4× combo |
| SARI | SARI, ARI | 2× combo |

> Örnek hesaplama: SARI = 2+1+1+2 = 6 puan, ARI = 1+1+2 = 4 puan → **Toplam: 10 puan**

---

## 8. Kelime Kalmama Kontrolü (Grid Solvability)

Bu projenin **en kritik algoritmik gereksinimi:**

1. Her hamle sonrası grid **arka planda** taranır (`Flutter.compute()` / Isolate)
2. Grid üzerinde **en az 1 geçerli kelime** bulunup bulunmadığı kontrol edilir
3. Eğer geçerli kelime **yoksa** → sistem **kurallı harf üretimi** uygular:
   - Sözlükten rastgele bir kelime seçilir
   - Harfleri grid'e stratejik olarak yerleştirilir
   - Kalan hücreler frekans tablosuna göre doldurulur
4. Ya da **otomatik karıştırma** / yeniden üretme devreye girer
5. Oluşturulabilir kelime sayısı **ekrandaki üst kısımda** gösterilir:
   `"Gridde Oluşturulabilir Kelime Sayısı: 3"`
6. Kelime sayısı, kelimelerin ortak harf kullanamayacak şekilde oluşturulmasıyla bulunur

> **Grid ASLA çözümsüz kalmamalıdır.** Bu kural mutlak zorunluluktur.

---

## 9. Skor Tablosu Yapısı

### Üst Kısım — Genel Performans Özeti:

| İstatistik | Örnek |
|------------|-------|
| Toplam Oynanan Oyun Sayısı | 12 |
| En Yüksek Puan | 1450 |
| Ortalama Puan | 860 |
| Toplam Bulunan Kelime Sayısı | 132 |
| En Uzun Kelime | "KELİMELER" |
| Toplam Oyun Süresi | 1 saat 25 dakika |

### Alt Kısım — Oyun Kartları Listesi (en son oynanan üstte):

Her kart şu bilgileri içerir:
- Oyun numarası
- Oyun tarihi
- Grid boyutu (6×6 / 8×8 / 10×10)
- Toplam puan
- Bulunan kelime sayısı
- En uzun kelime
- Oyun süresi

---

## 10. Oyun Bitirme Koşulları

Oyun aşağıdaki durumlarda sona erer:

1. **Hamle sayısı bittiğinde:** Oyun otomatik olarak biter → mevcut sonuç skor tablosuna yazılır → ana ekrana döner
2. **Oyuncu çıkmak istediğinde:** "Çıkmak istediğinize emin misiniz?" dialogu gösterilir:
   - **Hayır** → oyuna kaldığı yerden devam eder
   - **Evet** → mevcut sonuç skor tablosuna yazılır → ana ekrana döner

---

## 11. Kullanıcı Adı Sistemi

- Oyun ilk açıldığında **kullanıcı adı** istenir
- Kullanıcı adı saklanır, sonraki açılışlarda **otomatik giriş**
- Ana ekranın **sol üst kısmında** kullanıcı adı gösterilir
- Tıklanarak **değiştirilebilir**

---

## 12. Kodlama Standartları

- **Küçük, modüler fonksiyonlar** — tek sorumluluk prensibi
- **Strict type safety** — `dynamic` kullanımı **yasaktır**
- **Effective Dart** kurallarına tam uyum
- `analysis_options.yaml` ile linter kuralları **enforce** edilir
- **Extension methods** aktif kullanımı
- **Magic number yasak** — her sabit `core/constants/` altında tanımlanır
- Her public sınıf ve fonksiyon için **docstring** yazılır

---

## 13. Mimari Kurallar (Context Rooting)

AI agentler ve geliştiriciler, görev tipine göre aşağıdaki context dosyalarına **başvurmalıdır:**

| Görev Tipi | Referans Dosya |
|------------|---------------|
| UI tasarımı, widget, ekran | `docs/ui_rules.md` |
| State management, Riverpod | `docs/state_rules.md` |
| Oyun motoru, algoritmalar | `docs/game_engine_rules.md` |

> Bu dosyalar, Phase 1'de oluşturulacaktır.

---

## 14. AI / Copilot Davranış Kuralları

1. **Kod yazmadan ÖNCE** mevcut dosya yapısını tara
2. Dosya yapısını **bozma** — yeni dosya eklemeden planla
3. Gereksiz paket **ekleme** — `INSTALL_LOG.md`'ye kaydetmeden ekleme yapma
4. Her değişiklikten önce etkilenen dosyaları **kontrol et**
5. Mevcut comment ve docstring'leri **koru** (değiştirmene gerek yoksa dokunma)
6. Bir dosyada değişiklik yapmadan önce **bağımlılıkları** kontrol et

---

## 15. Git & Commit Kuralları

### Format:
```
type(scope): title
 - detail line 1
 - detail line 2
```

### Type'lar:
`feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`

### Scope'lar:
`engine`, `ui`, `data`, `providers`, `config`, `docs`

### Örnekler:
```
feat(engine): add Trie data structure
 - implement TrieNode with children map
 - add insert, search, startsWith methods

fix(ui): correct grid cell alignment on 10x10

docs(config): update PROJECT_INSTRUCTIONS with combo rules
```

### Kurallar:
- Commit mesajları **İNGİLİZCE** yazılır
- Agent, commit yapmadan **ÖNCE** kullanıcıdan **onay almalıdır**
- `.gitignore` güncel tutulmalıdır (build/, .dart_tool/, *.g.dart vb.)

---

## 16. İletişim Kuralları (KRİTİK)

| Ne? | Dil |
|-----|-----|
| Agent ↔ Kullanıcı iletişimi | 🇹🇷 **TÜRKÇE** |
| Teknik açıklamalar, analiz, sorular | 🇹🇷 **TÜRKÇE** |
| Kod (değişken adları, fonksiyonlar, yorumlar) | 🇬🇧 İngilizce |
| Commit mesajları | 🇬🇧 İngilizce |
| Dosya/klasör adları | 🇬🇧 İngilizce |

---

## 17. Proje Klasör Yapısı

```
wordCrush-mobile/
├── PROJECT_INSTRUCTIONS.md
├── TODO.md
├── INSTALL_LOG.md
├── lib/
│   ├── main.dart              # ObjectBox & Trie init
│   ├── core/                  # Constants (Puanlar, Frekanslar), Theme, Utils
│   ├── data/
│   │   ├── models/            # @Entity (PlayerProfile, GameRecord, JokerInventory)
│   │   └── services/          # ObjectBox Store & Trie Service
│   ├── logic/                 # OYUNUN BEYNİ
│   │   ├── algorithms/        # Trie, GridSolver, GravityEngine, GridGenerator
│   │   ├── scoring/           # ComboEngine, ScoreCalculator
│   │   ├── powers/            # Özel Güç & Joker Logic'leri
│   │   └── providers/         # Riverpod States (Game, Grid, Score, Player, Joker)
│   └── ui/                    # GÖRSEL DÜNYA
│       ├── screens/           # Splash, Login, Home, Game, Market, Scoreboard
│       ├── widgets/           # Grid, Cell, Popups, ScoreCard
│       └── animations/        # Lottie Efektleri
├── assets/
│   ├── data/                  # turkish_words.txt
│   ├── sounds/                # Ses efektleri
│   └── animations/            # Lottie JSON dosyaları
└── test/                      # Unit & Integration testleri
```

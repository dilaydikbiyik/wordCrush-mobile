# 🏁 Word Crush - TODO List
**Teslim Tarihi:** 01.05.2026 
**Ekip:** Dilay & Onur

---

## 🧱 FAZ 1: Altyapı ve Katmanlı Mimari (Hemen)
- [ ] **Riverpod State Yönetimi:** Skor, hamle ve grid senkronizasyonu için `StateNotifierProvider` kurulumu.
- [x] **Klasör Yapılandırması:** `core`, `data`, `logic` ve `ui` katmanlarının oluşturulması.
- [ ] **Dinamik Grid Modeli:** - [ ] `LetterModel` (x, y, char, isSelected) oluşturulması.
    - [ ] Seviyeye göre (`6x6`, `8x8`, `10x10`) grid üretim logic'i.
- [ ] **NLP Tabanlı Harf Üreticisi:** - [ ] Türkçe harf frekans haritası (`Map<String, double>`).
    - [ ] Olasılık tabanlı "Weighted Random" dolum algoritması.

## 🧠 FAZ 2: Hibrit Veri Yönetimi (Sözlük & Isar)
- [ ] **Isar Database (Kalıcı Veri):**
    - [ ] Isar paketlerinin kurulması ve `UserScore`, `Settings` koleksiyonlarının tanımlanması.
    - [ ] Uygulama açılışında Isar servisinin başlatılması.
- [ ] **Trie Yapısı (Yüksek Performans):**
    - [ ] `TrieNode` ve `TrieService` sınıflarının yazılması.
    - [ ] `words.txt` asset dosyasının açılışta RAM'e Trie olarak yüklenmesi.
- [ ] **Arama & Combo Algoritması:**
    - [ ] Trie üzerinden $O(L)$ hızında kelime ve prefix kontrolü.
    - [ ] Recursive (özyinelemeli) alt kelime bulucu (Combo Logic).

## 🕹️ FAZ 3: Oyun Mekaniği ve Swipe (Oynanış)
- [ ] **Gesture & UI:**
    - [ ] `GestureDetector` ile harf seçme ve sürükleme mekaniği.
    - [ ] Seçilen harfler arasına dinamik çizgi çizen `CustomPainter`.
- [ ] **Yerçekimi (Gravity):**
    - [ ] Silinen harflerin yerine üsttekilerin düşmesi ve boşlukların yeni harflerle dolması.
- [ ] **Oyun Akışı:**
    - [ ] Hamle sayacı (15, 20, 25) ve "Oyun Bitti" kontrolü.

## 📊 FAZ 4: Skorlama ve Gelişmiş Persistence
- [ ] **Skor Motoru:** `Harf * 10 + (Her Combo * 5)` formülünün işletilmesi.
- [ ] **Isar Persistence:** Rekor skorların ve oyun istatistiklerinin Isar NoSQL'e asenkron kaydedilmesi.
- [ ] **UX & Görsellik:**
    - [ ] Kelime patlama efektleri (Lottie veya Custom Animations).
    - [ ] Akıcı ekran geçişleri.

## 📝 FAZ 5: LaTeX Raporlama (KRİTİK!)
- [ ] **IEEE Şablonu:** Overleaf üzerinde projenin başlatılması (Min. 4 sayfa).
- [ ] **Teknik Analiz:**
    - [ ] Hibrit mimarinin (Trie vs Isar) avantajlarının anlatılması.
    - [ ] Harf frekans motorunun matematiksel olasılık analizi.
- [ ] **Teslimat Paketi:** `.tex` kaynak dosyaları, resimler ve kaynak kodların ZIP haline getirilmesi.

## 🚀 FAZ 6: Final Test ve Sunum
- [ ] **iOS 19 Simulator:** M5 Pro üzerinde farklı iPhone modellerinde performans testi.
- [ ] **Türkçe Karakter Fix:** `İ-I`, `Ş-S` gibi karakterlerin arama motorunda normalize edilmesi.
- [ ] **Bireysel Sorumluluk:** Onur ile karşılıklı kod incelemesi ve sunum provası.

---

### ⚠️ ÖNEMLİ HATIRLATMALAR
* **Sunum:** Sadece mobil emülatör/cihaz (Web/Desktop yasak!).
* **Rapor:** Sadece LaTeX (Sadece PDF = 0 Puan! Kaynak kodlar/zip şart).
* **Format:** IEEE formatı, minimum 4 sayfa.
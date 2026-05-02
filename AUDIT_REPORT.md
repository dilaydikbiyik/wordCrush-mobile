# Word Crush — Proje Denetim Raporu

> Tarih: 2026-04-28
> Kapsam: PROJECT_INSTRUCTIONS.md, TODO.md, tüm `lib/`, `test/`, `assets/` ve `pubspec.yaml`

---

## ✅ TAMAMLANAN / KAPATILAN MADDELER

### 15b. Joker Animasyonu + Shuffle Animasyonu Yok

**Sorun nedir?**
`game_screen.dart`'ta `_executeJoker` metodunda joker çalıştırıldıktan sonra hiçbir animasyon kodu yok. Grid hücreler aniden değişiyor.

Örneğin Parti jokeri tüm harfleri silip yenilerini üstten düşürüyor — ama bu işlem animasyonsuz, anlık gerçekleşiyor. Balık, Tekerlek, Lolipop jokerlerinin de kendine özgü görsel efekti yok.

Aynı şekilde shuffle (karıştır) butonu da hücreleri anlık değiştiriyor — hiçbir geçiş animasyonu yok.

**Ne yapıldı?**
Balık, Lolipop (`joker_pop_smoke_p.json`), Swap, Shuffle, Party jokerlerine Lottie animasyonu eklendi. Tekerlek jokeri için satır + sütun boyunca çift animasyon (yatay Positioned + 90° RotatedBox dikey) yapısı kuruldu; `joker_sweep_wave.json` dalga çizgisi genişliği 2× artırıldı. Auto-shuffle durumunda da Lottie animasyonu tetikleniyor. Joker butonuna basıldığında `SoundType.buttonTap`, joker çalıştırıldığında `SoundType.jokerActivation` çağrıları eklendi — ses dosyası seçimi bekliyor. **Tekerlek için yatay hareket eden (kayan) animasyon versiyonu planlanıyor — şu an sabit dalga kullanılıyor.**

---

### UX4. Onaylama Ekranları Görsel İyileştirme (Opsiyonel)

**Sorun nedir?**
Oyundan çıkış, joker kullanım onayı gibi `AlertDialog`'lar Flutter varsayılan görünümünde. Oyunun genel tasarımıyla uyumsuz.

**Ne yapılmalı?**
Özel styled dialog widget'ı: oyun temasına uygun arka plan, düğme stilleri, tipografi. Opsiyonel — temel işlevselliği etkilemiyor.

---

### UX7. Oyun Sonu Ekranı Görsel Yetersizliği

**Sorun nedir?**
`score_screen.dart` işlevsel ama görsel olarak zayıf. Skor, kelimeler ve altın gösterimi sadece metin bazlı; animasyon veya görsel öğe yok.

**Ne yapılmalı?**
- Skor açılış animasyonu (count-up efekti)
- Altın kazanımı için kısa coin animasyonu
- En uzun kelime vurgusu
- Genel kart/panel tasarımı iyileştirmesi

---

### UX9. Market Hızlı Satın Alma + Joker Kullanım Animasyonu (Opsiyonel)

**Sorun nedir?**
Market ekranında "hızlı al" benzeri bir akış yok — her satın alma için onay adımları var. Ayrıca joker panelinde joker kullanıldığında görsel geri bildirim (animasyon) yok.

**Ne yapılmalı?**
- Market için tek tıkla satın alma seçeneği (onay atla) — opsiyonel
- Joker ikonunun kullanım anında scale/shake animasyonu — opsiyonel

---

### UX10. Arka Plan Müziği Yok (Opsiyonel)

**Sorun nedir?**
Oyunun hiçbir ekranında arka plan müziği çalmıyor. Ses efektleri var ama ambiyans müziği eksik.

**Ne yapılmalı?**
`audioplayers` paketi loop modunu destekliyor. Oyun içi ve menü için ayrı ambient müzik dosyası eklenip `AudioNotifier`'a `playBgm` / `stopBgm` metotları eklenebilir. Opsiyonel — teslim kapsamı dışında.

---

### DEV1. Altın Harcama Bypass (Test Amaçlı)

**Sorun nedir?**
`player_provider.dart`'taki `spendGold` metodu geçici olarak bypass edildi — her satın almada `true` döner, altın düşmez.

**Ne yapılmalı?**
Sunum öncesi orijinal koda (`if (state.goldBalance < amount) return false`) geri döndürülmeli. Dosyada `TODO: remove before release` yorumu mevcut.

---

## 💡 KALAN AÇIK MADDELER

| #    | Yapılacak                                                                   | Öncelik    | Tahmini Süre |
| ---- | --------------------------------------------------------------------------- | ---------- | ------------ |
| 15b  | Tekerlek jokeri: kayan/hareket eden animasyon versiyonu                     | Yüksek     | ~45 dk       |
| DEV1 | `spendGold` bypass'ını sunum öncesi geri al                                 | KRİTİK     | ~5 dk        |
| UX4  | Onaylama dialog'larını oyun temasına uygun stilize et                       | Opsiyonel  | ~30 dk       |
| UX7  | Oyun sonu ekranı görsel iyileştirme (animasyon, kart tasarımı)              | Orta       | ~45 dk       |
| 15b-ses | Joker buton + aktivasyon ses dosyalarını seç ve ata                    | Yüksek     | ~10 dk       |
| UX9  | Market hızlı satın alma + joker kullanım animasyonu                         | Opsiyonel  | ~45 dk       |
| UX10 | Arka plan müziği (loop BGM)                                                 | Opsiyonel  | ~60 dk       |

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
Balık, Lolipop, Swap, Shuffle, Party jokerlerine Lottie animasyonu eklendi. Tekerlek jokeri için satır + sütun boyunca çift animasyon (yatay + 90° dikey) yapısı kuruldu. Auto-shuffle durumunda da Lottie animasyonu tetikleniyor. **Son dokunuşlar devam ediyor — Lolipop animasyonu seçimi bekleniyor, Tekerlek için hareketli animasyon planlanıyor.**

---

### UX3. Sayfa Geçişi Ses Gecikmesi

**Sorun nedir?**
Ana menü butonlarına basıldığında ses efekti gecikmeli çalıyor — sese tıklandıktan ~200–400ms sonra ses geliyor. Bu, ses dosyasının başında sessizlik bulunmasından kaynaklanıyor.

**Ne yapılmalı?**
Ses dosyalarının başındaki boş kısmı bir ses editörü ile (Audacity vb.) kırpılmalı. Kod tarafında önceden yükleme (`setSource` + `seek`) yapıldı ama ses dosyasındaki gecikme kod ile giderilemiyor.

---

### UX4. Onaylama Ekranları Görsel İyileştirme (Opsiyonel)

**Sorun nedir?**
Oyundan çıkış, joker kullanım onayı gibi `AlertDialog`'lar Flutter varsayılan görünümünde. Oyunun genel tasarımıyla uyumsuz.

**Ne yapılmalı?**
Özel styled dialog widget'ı: oyun temasına uygun arka plan, düğme stilleri, tipografi. Opsiyonel — temel işlevselliği etkilemiyor.

---

### UX6. MarketScreen 3D Buton Eksikliği

**Sorun nedir?**
`market_screen.dart`'taki satın alma butonları düz tasarımda. `Press3DButton` kullanılmıyor.

**Ne yapılmalı?**
Market kartlarındaki butonları `Press3DButton` ile güncellemek görsel tutarlılık sağlar.

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

### UX8. Marketten Satın Alırken Altın Sesi Yok

**Sorun nedir?**
Market ekranında joker veya altın paketi satın alındığında hiçbir ses çalmıyor. `spinningCoin` sesi mevcut ama tetiklenmiyor.

**Ne yapılmalı?**
`market_screen.dart`'ta satın alma işlemi başarılı olduğunda `audioProvider.playSound(SoundType.spinningCoin)` çağrılmalı.

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

### UX11. Geçersiz Kelime Emoji Render Sorunu

**Sorun nedir?**
Geçersiz kelime girildiğinde gösterilen popup/toast'ta emoji karakterleri render edilmiyor veya bozuk görünüyor (platform font desteği sorunu).

**Ne yapılmalı?**
Emoji yerine SVG/PNG ikonları veya Flutter `Icon` widget'ı kullanılmalı. Alternatif olarak `Text` widget'ındaki emoji, `RichText` + özel font ile render edilebilir.

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
| 15b  | Joker animasyonları son dokunuş: Lolipop seçimi + Tekerlek hareketli anim  | Yüksek     | ~60 dk       |
| DEV1 | `spendGold` bypass'ını sunum öncesi geri al                                 | KRİTİK     | ~5 dk        |
| UX3  | Ses dosyası başındaki sessizliği kırp (Audacity)                            | Düşük      | ~15 dk       |
| UX4  | Onaylama dialog'larını oyun temasına uygun stilize et                       | Opsiyonel  | ~30 dk       |
| UX6  | MarketScreen butonlarını Press3DButton ile güncelle                         | Orta       | ~20 dk       |
| UX7  | Oyun sonu ekranı görsel iyileştirme (animasyon, kart tasarımı)              | Orta       | ~45 dk       |
| UX8  | Marketten satın alırken spinningCoin sesi tetikle                           | Yüksek     | ~10 dk       |
| UX9  | Market hızlı satın alma + joker kullanım animasyonu                         | Opsiyonel  | ~45 dk       |
| UX10 | Arka plan müziği (loop BGM)                                                 | Opsiyonel  | ~60 dk       |
| UX11 | Geçersiz kelime emoji render sorunu — ikon ile değiştir                     | Yüksek     | ~20 dk       |

# 📦 INSTALL_LOG.md — Bağımlılık Takip Dosyası

---

## Kurallar

1. **Her eklenen paket** bu dosyaya loglanmalıdır
2. **Exact version** belirtilmelidir (`^X.Y.Z`)
3. Her paket eklenmeden **ÖNCE** kullanıcı onayı alınmalıdır
4. Ekleme sonrası `flutter pub get` ile **validation** yapılmalıdır
5. Validation başarısız olursa paketi kaldır ve not düş

## Şablon

```
### [Tarih] - [Paket Adı]
- **Type:** system | frontend | dev-tool
- **Version:** ^X.Y.Z
- **Install command:** `flutter pub add ...`
- **Validation result:** ✅ Başarılı / ❌ Başarısız
- **Notes:** Kısa açıklama
```

---

## Kurulu Paketler

---

### [2026-04-20] - flutter_riverpod
- **Type:** frontend
- **Version:** ^2.4.0
- **Install command:** `flutter pub add flutter_riverpod`
- **Validation result:** ✅ Başarılı
- **Notes:** State management. `ProviderScope` ile main.dart'ta sarmalandı.

---

### [2026-04-20] - objectbox
- **Type:** system
- **Version:** ^5.3.1
- **Install command:** `flutter pub add objectbox`
- **Validation result:** ✅ Başarılı
- **Notes:** NoSQL veritabanı. PlayerProfile, GameRecord, JokerInventory entity'leri için.

---

### [2026-04-20] - objectbox_flutter_libs
- **Type:** system
- **Version:** ^5.3.1
- **Install command:** `flutter pub add objectbox_flutter_libs`
- **Validation result:** ✅ Başarılı
- **Notes:** ObjectBox iOS native kütüphaneleri.

---

### [2026-04-20] - path_provider
- **Type:** system
- **Version:** ^2.0.15
- **Install command:** `flutter pub add path_provider`
- **Validation result:** ✅ Başarılı
- **Notes:** ObjectBox store dizin yolu için.

---

### [2026-04-20] - go_router
- **Type:** frontend
- **Version:** ^14.8.1
- **Install command:** `flutter pub add go_router`
- **Validation result:** ⏳ flutter pub get bekleniyor
- **Notes:** Deklaratif routing. Splash→Login→Home→Difficulty→Game→Score→Market akışı.

---

### [2026-04-20] - lottie
- **Type:** frontend
- **Version:** ^3.3.1
- **Install command:** `flutter pub add lottie`
- **Validation result:** ⏳ flutter pub get bekleniyor
- **Notes:** Phase 8 animasyonları için (patlatma, combo popup, gravity).

---

### [2026-04-20] - audioplayers
- **Type:** frontend
- **Version:** ^6.1.0
- **Install command:** `flutter pub add audioplayers`
- **Validation result:** ⏳ flutter pub get bekleniyor
- **Notes:** Phase 8 ses efektleri için.

---

### [2026-04-20] - build_runner (dev)
- **Type:** dev-tool
- **Version:** ^2.4.13
- **Install command:** `flutter pub add --dev build_runner`
- **Validation result:** ✅ Başarılı
- **Notes:** Code generation runner.

---

### [2026-04-20] - objectbox_generator (dev)
- **Type:** dev-tool
- **Version:** ^5.3.1
- **Install command:** `flutter pub add --dev objectbox_generator`
- **Validation result:** ✅ Başarılı
- **Notes:** ObjectBox entity code generation.

---

## Planlanan Paketler (Henüz Eklenmedi)

---

### [Henüz kurulmadı] - flutter_riverpod
- **Type:** frontend
- **Version:** ^3.3.1
- **Install command:** `flutter pub add flutter_riverpod`
- **Validation result:** ⏳ Bekliyor
- **Notes:** State management çözümü. `ProviderScope` ile `main.dart`'ta sarmalanacak. Projenin tüm state yönetimi bu paket üzerinden yapılır.

---

### [Henüz kurulmadı] - riverpod_annotation
- **Type:** frontend
- **Version:** ^3.3.1
- **Install command:** `flutter pub add riverpod_annotation`
- **Validation result:** ⏳ Bekliyor
- **Notes:** `@riverpod` annotation desteği. Code generation ile provider oluşturma.

---

### [Henüz kurulmadı] - objectbox
- **Type:** system
- **Version:** ^5.3.1
- **Install command:** `flutter pub add objectbox`
- **Validation result:** ⏳ Bekliyor
- **Notes:** NoSQL veritabanı. `@Entity` annotation ile model tanımı. PlayerProfile, GameRecord, JokerInventory entity'leri için kullanılacak.

---

### [Henüz kurulmadı] - objectbox_flutter_libs
- **Type:** system
- **Version:** ^5.3.1
- **Install command:** `flutter pub add objectbox_flutter_libs`
- **Validation result:** ⏳ Bekliyor
- **Notes:** ObjectBox'ın native (iOS/Android) kütüphanelerini sağlar. `objectbox` paketi ile birlikte çalışır.

---

### [Henüz kurulmadı] - objectbox_generator
- **Type:** dev-tool
- **Version:** ^5.3.1
- **Install command:** `flutter pub add --dev objectbox_generator`
- **Validation result:** ⏳ Bekliyor
- **Notes:** ObjectBox entity model code generation. `build_runner` ile çalışır. `dart run build_runner build` komutu ile model dosyaları üretilir.

---

### [Henüz kurulmadı] - build_runner
- **Type:** dev-tool
- **Version:** ^2.4.13
- **Install command:** `flutter pub add --dev build_runner`
- **Validation result:** ⏳ Bekliyor
- **Notes:** Code generation runner. `objectbox_generator` ve `riverpod_generator` için gerekli.

---

### [Henüz kurulmadı] - path_provider
- **Type:** system
- **Version:** ^2.1.5
- **Install command:** `flutter pub add path_provider`
- **Validation result:** ⏳ Bekliyor
- **Notes:** Cihaz dosya yollarını sağlar. ObjectBox store konumunu belirlemek için gerekli.

---

### [Henüz kurulmadı] - go_router
- **Type:** frontend
- **Version:** ^14.8.1
- **Install command:** `flutter pub add go_router`
- **Validation result:** ⏳ Bekliyor
- **Notes:** Deklaratif routing çözümü. Google tarafından desteklenir. Splash → Login → Home → Game → Score → Market akışı.

---

### [Henüz kurulmadı] - lottie
- **Type:** frontend
- **Version:** ^3.3.1
- **Install command:** `flutter pub add lottie`
- **Validation result:** ⏳ Bekliyor
- **Notes:** Lottie JSON animasyon dosyalarını render eder. Patlatma, gravity düşme, combo popup efektleri için.

---

### [Henüz kurulmadı] - audioplayers
- **Type:** frontend
- **Version:** ^6.1.0
- **Install command:** `flutter pub add audioplayers`
- **Validation result:** ⏳ Bekliyor
- **Notes:** Ses efektleri için. Kısa ses dosyalarını (.mp3) düşük gecikmeyle çalma. Harf patlatma, combo, geçersiz kelime sesleri.

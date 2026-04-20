# State Rules — Riverpod

## Zorunlu Kurallar

- **Sadece Riverpod** kullanılır (`flutter_riverpod ^2.4.0`)
- `Provider`, `Bloc`, `GetX`, `setState` (iş mantığı için) YASAKTIR
- Her provider tek bir sorumluluğa sahip olur
- `ref.read()` sadece event handler'larda, `ref.watch()` build metodunda

## Provider Listesi

| Provider | Tip | Sorumluluk |
|----------|-----|------------|
| `gameStateProvider` | `StateNotifierProvider` | Hamle sayısı, oyun aktif/bitti, seviye |
| `gridProvider` | `StateNotifierProvider` | Grid matrisi, seçili hücreler |
| `scoreProvider` | `StateNotifierProvider` | Anlık skor, combo çarpanı |
| `playerProvider` | `StateNotifierProvider` | Kullanıcı adı, altın bakiyesi |
| `jokerProvider` | `StateNotifierProvider` | Joker envanteri, aktif joker |
| `marketProvider` | `StateNotifierProvider` | Satın alma işlemleri |
| `trieProvider` | `FutureProvider` | Sözlük erişimi (yüklenme durumu dahil) |
| `audioProvider` | `StateNotifierProvider` | Ses açma/kapama/çalma |

## Dosya Yapısı

Her provider kendi dosyasında: `lib/logic/providers/<name>_provider.dart`

## State Sınıfları

Her provider için immutable state sınıfı tanımlanır:

```dart
class GameState {
  final int movesLeft;
  final bool isGameOver;
  final int gridSize;
  // ...
  GameState copyWith({...}) => ...;
}
```

## ObjectBox Entegrasyonu

Provider'lar ObjectBox'a doğrudan erişmez — `ObjectBoxService` singleton aracılığıyla çağırır.

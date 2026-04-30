import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sound effect types used throughout the game.
enum SoundType {
  letterSelect,
  validWord,
  invalidWord,
  combo,
  powerActivation,  /// Satır/sütun temizleme (güç) aktivasyonları
  jokerActivation,  /// Alt paneldeki joker aktivasyonları
  gameOver,
  gameStart,
  spinningCoin,
}

/// Maps each [SoundType] to its asset path under `assets/sounds/`.
const _soundAssets = {
  SoundType.letterSelect:    'sounds/select.mp3',
  SoundType.validWord:       'sounds/valid_word.mp3',
  SoundType.invalidWord:     'sounds/invalid_word.mp3',
  SoundType.combo:           'sounds/combo.mp3',
  SoundType.powerActivation: 'sounds/power_activation.mp3',
  SoundType.jokerActivation: 'sounds/power_activationj.wav',
  SoundType.gameOver:        'sounds/game_over.mp3',
  SoundType.gameStart:       'sounds/game_start.mp3',
  SoundType.spinningCoin:    'sounds/spinning_coin.mp3',
};

/// Immutable state for audio settings.
class AudioState {
  final bool isMuted;

  const AudioState({this.isMuted = false});

  AudioState copyWith({bool? isMuted}) =>
      AudioState(isMuted: isMuted ?? this.isMuted);
}

/// Manages audio playback and mute toggle using `audioplayers`.
/// Uses an "Audio Pool" architecture to prevent race conditions (Hata #22).
class AudioNotifier extends StateNotifier<AudioState> {
  static const int _poolSize = 3;
  final Map<SoundType, List<AudioPlayer>> _pools = {};
  final Map<SoundType, int> _poolIndexes = {};

  AudioNotifier() : super(const AudioState()) {
    // Pre-create a pool of players for each type
    for (final type in SoundType.values) {
      _pools[type] = List.generate(
        _poolSize,
        (_) => AudioPlayer()..setReleaseMode(ReleaseMode.stop),
      );
      _poolIndexes[type] = 0;
    }
  }

  @override
  void dispose() {
    for (final pool in _pools.values) {
      for (final player in pool) {
        player.dispose();
      }
    }
    super.dispose();
  }

  void toggleMute() => state = state.copyWith(isMuted: !state.isMuted);
  void setMuted(bool muted) => state = state.copyWith(isMuted: muted);

  Future<void> playSound(SoundType type) async {
    if (state.isMuted) return;
    final asset = _soundAssets[type];
    if (asset == null) return;
    
    try {
      final pool = _pools[type]!;
      final idx = _poolIndexes[type]!;
      final player = pool[idx];
      
      await player.stop();
      await player.play(AssetSource(asset));
      
      // Move to the next player in the pool
      _poolIndexes[type] = (idx + 1) % _poolSize;
    } catch (_) {
      // Silently ignore audio errors
    }
  }
}

final audioProvider =
    StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  return AudioNotifier();
});

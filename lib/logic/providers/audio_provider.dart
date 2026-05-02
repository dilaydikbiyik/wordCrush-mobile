import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sound effect types used throughout the game.
enum SoundType {
  letterSelect,    /// Grid harf seçimi (swipe)
  buttonTap,       /// Ana aksiyon butonu (yeni oyun, skor, market vb.)
  uiTap,           /// Yardımcı UI butonu (müzik toggle, çıkış, kullanıcı adı vb.)
  validWord,
  invalidWord,
  combo,
  powerActivation, /// Satır/sütun temizleme (güç) aktivasyonları
  jokerActivation, /// Genel joker aktivasyonu (fallback)
  gameOver,
  gameStart,
  spinningCoin,
  // Joker buton seçme
  jokerSelect,
  // Joker uygulanma sesleri
  jokerFish,
  jokerWheel,
  jokerLollipop,
  jokerSwap,
  jokerShuffle,
  jokerParty,
}

/// Maps each [SoundType] to its asset path under `assets/sounds/`.
const _soundAssets = {
  SoundType.letterSelect:    'sounds/select.mp3',
  SoundType.buttonTap:       'sounds/button_tap.mp3',
  SoundType.uiTap:           'sounds/ui_tap.wav',
  SoundType.validWord:       'sounds/valid_word.mp3',
  SoundType.invalidWord:     'sounds/invalid_word.mp3',
  SoundType.combo:           'sounds/combo.mp3',
  SoundType.powerActivation: 'sounds/power_activation.mp3',
  SoundType.jokerActivation: 'sounds/power_activationj.wav',
  SoundType.gameOver:        'sounds/game_over.mp3',
  SoundType.gameStart:       'sounds/game_start.mp3',
  SoundType.spinningCoin:    'sounds/spinning_coin.mp3',
  SoundType.jokerSelect:     'sounds/joker_select.wav',
  SoundType.jokerFish:       'sounds/joker_fish.wav',
  SoundType.jokerWheel:      'sounds/joker_wheel.wav',
  SoundType.jokerLollipop:   'sounds/joker_lollipop.wav',
  SoundType.jokerSwap:       'sounds/joker_swap.wav',
  SoundType.jokerShuffle:    'sounds/joker_shuffle.wav',
  SoundType.jokerParty:      'sounds/joker_party.mp3',
};

/// Immutable state for audio settings.
class AudioState {
  final bool isMuted;
  final bool isBgmEnabled;

  const AudioState({this.isMuted = false, this.isBgmEnabled = true});

  AudioState copyWith({bool? isMuted, bool? isBgmEnabled}) => AudioState(
        isMuted: isMuted ?? this.isMuted,
        isBgmEnabled: isBgmEnabled ?? this.isBgmEnabled,
      );
}

/// Manages audio playback and mute toggle using `audioplayers`.
/// Uses an "Audio Pool" architecture to prevent race conditions (Hata #22).
class AudioNotifier extends StateNotifier<AudioState> {
  static const int _poolSize = 3;
  static const String _bgmAsset = 'sounds/bgm_game.mp3';

  final Map<SoundType, List<AudioPlayer>> _pools = {};
  final Map<SoundType, int> _poolIndexes = {};
  final AudioPlayer _bgmPlayer = AudioPlayer();

  AudioNotifier() : super(const AudioState()) {
    _initPools();
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    _bgmPlayer.setVolume(0.3);
  }

  static const _volumeOverrides = {
    SoundType.invalidWord: 0.25,
    SoundType.jokerSelect: 0.45,
  };

  Future<void> _initPools() async {
    for (final type in SoundType.values) {
      final asset = _soundAssets[type];
      final volume = _volumeOverrides[type] ?? 1.0;
      final players = <AudioPlayer>[];
      for (int i = 0; i < _poolSize; i++) {
        final player = AudioPlayer()
          ..setReleaseMode(ReleaseMode.stop)
          ..setVolume(volume);
        if (asset != null) {
          await player.setSource(AssetSource(asset));
        }
        players.add(player);
      }
      _pools[type] = players;
      _poolIndexes[type] = 0;
    }
  }

  @override
  void dispose() {
    _bgmPlayer.dispose();
    for (final pool in _pools.values) {
      for (final player in pool) {
        player.dispose();
      }
    }
    super.dispose();
  }

  void toggleMute() => state = state.copyWith(isMuted: !state.isMuted);
  void setMuted(bool muted) => state = state.copyWith(isMuted: muted);

  Future<void> playBgm() async {
    if (!state.isBgmEnabled) return;
    try {
      await _bgmPlayer.play(AssetSource(_bgmAsset));
    } catch (_) {}
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (_) {}
  }

  Future<void> toggleBgm() async {
    final enabled = !state.isBgmEnabled;
    state = state.copyWith(isBgmEnabled: enabled);
    if (enabled) {
      await playBgm();
    } else {
      await stopBgm();
    }
  }

  Future<void> playSound(SoundType type) async {
    if (state.isMuted) return;
    final asset = _soundAssets[type];
    if (asset == null) return;
    
    try {
      final pool = _pools[type]!;
      final idx = _poolIndexes[type]!;
      final player = pool[idx];

      player.seek(Duration.zero);
      await player.resume();

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

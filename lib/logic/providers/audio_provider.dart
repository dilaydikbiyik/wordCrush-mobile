import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sound effect types used throughout the game.
enum SoundType {
  /// Played when a letter cell is selected (soft tick).
  letterSelect,

  /// Played when a valid word is confirmed (ascending arpeggio).
  validWord,

  /// Played when an invalid word attempt is made (descending buzz).
  invalidWord,

  /// Played on combo bonus (bright fanfare).
  combo,

  /// Played when a special power or joker activates (dramatic sweep).
  powerActivation,

  /// Played when the game ends (descending 3-tone finisher).
  gameOver,
}

/// Maps each [SoundType] to its asset path under `assets/sounds/`.
const _soundAssets = {
  SoundType.letterSelect:    'sounds/letter_select.wav',
  SoundType.validWord:       'sounds/valid_word.wav',
  SoundType.invalidWord:     'sounds/invalid_word.wav',
  SoundType.combo:           'sounds/combo.wav',
  SoundType.powerActivation: 'sounds/power_activation.wav',
  SoundType.gameOver:        'sounds/game_over.wav',
};

/// Immutable state for audio settings.
class AudioState {
  /// Whether all sounds are muted.
  final bool isMuted;

  const AudioState({this.isMuted = false});

  AudioState copyWith({bool? isMuted}) =>
      AudioState(isMuted: isMuted ?? this.isMuted);
}

/// Manages audio playback and mute toggle using `audioplayers`.
///
/// Each [SoundType] maps to a dedicated [AudioPlayer] instance so that
/// overlapping sounds (e.g. combo + letter_select) play without cutting
/// each other off.
class AudioNotifier extends StateNotifier<AudioState> {
  /// One player per sound type to allow simultaneous playback.
  final Map<SoundType, AudioPlayer> _players = {};

  AudioNotifier() : super(const AudioState()) {
    // Pre-create players for all types
    for (final type in SoundType.values) {
      _players[type] = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    }
  }

  @override
  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    super.dispose();
  }

  /// Toggles the mute state.
  void toggleMute() => state = state.copyWith(isMuted: !state.isMuted);

  /// Sets mute status explicitly.
  void setMuted(bool muted) => state = state.copyWith(isMuted: muted);

  /// Plays a sound effect of [type].
  ///
  /// No-op when muted. Uses [AssetSource] so the file is read from the
  /// Flutter asset bundle without any additional permissions.
  Future<void> playSound(SoundType type) async {
    if (state.isMuted) return;
    final asset = _soundAssets[type];
    if (asset == null) return;
    try {
      final player = _players[type]!;
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (_) {
      // Silently ignore audio errors — game must not crash over sound
    }
  }
}

/// Provider for audio settings and playback.
final audioProvider =
    StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  return AudioNotifier();
});

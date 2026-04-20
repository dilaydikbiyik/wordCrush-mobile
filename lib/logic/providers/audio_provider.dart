import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sound effect types used throughout the game.
enum SoundType {
  /// Played when a letter cell is selected.
  letterSelect,

  /// Played when a valid word is confirmed.
  validWord,

  /// Played when an invalid word attempt is made.
  invalidWord,

  /// Played on combo bonus.
  combo,

  /// Played when a special power activates.
  powerActivation,

  /// Played when the game ends.
  gameOver,
}

/// Immutable state for audio settings.
class AudioState {
  /// Whether all sounds are muted.
  final bool isMuted;

  const AudioState({this.isMuted = false});

  AudioState copyWith({bool? isMuted}) {
    return AudioState(isMuted: isMuted ?? this.isMuted);
  }
}

/// Manages audio playback and mute toggle.
///
/// **Phase 8 will add actual sound playback via `audioplayers`.**
/// For now this provider offers the mute toggle and a placeholder
/// [playSound] method that the UI can call from day one.
class AudioNotifier extends StateNotifier<AudioState> {
  AudioNotifier() : super(const AudioState());

  /// Toggles the mute state.
  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  /// Sets mute status explicitly.
  void setMuted(bool muted) {
    state = state.copyWith(isMuted: muted);
  }

  /// Plays a sound effect of [type].
  ///
  /// No-op when muted. Actual audio file playback will be implemented
  /// in Phase 8 using the `audioplayers` package.
  void playSound(SoundType type) {
    if (state.isMuted) return;

    // TODO(phase-8): Map SoundType → asset path and play via AudioPlayer.
    // For now this is a no-op placeholder.
  }
}

/// Provider for audio settings and playback.
final audioProvider =
    StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  return AudioNotifier();
});

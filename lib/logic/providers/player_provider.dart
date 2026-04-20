import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/player_profile.dart';
import '../../data/services/objectbox_service.dart';
import 'game_provider.dart';

/// Immutable state for the player profile.
class PlayerState {
  /// Player's display name.
  final String username;

  /// Current gold balance (persists across games).
  final int goldBalance;

  /// ObjectBox entity ID for updating the stored profile.
  final int profileId;

  /// Whether a profile has been loaded/created.
  final bool isLoaded;

  const PlayerState({
    this.username = '',
    this.goldBalance = 0,
    this.profileId = 0,
    this.isLoaded = false,
  });

  PlayerState copyWith({
    String? username,
    int? goldBalance,
    int? profileId,
    bool? isLoaded,
  }) {
    return PlayerState(
      username: username ?? this.username,
      goldBalance: goldBalance ?? this.goldBalance,
      profileId: profileId ?? this.profileId,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

/// Manages the player profile: username and gold balance.
///
/// All changes are immediately persisted to ObjectBox.
class PlayerNotifier extends StateNotifier<PlayerState> {
  final ObjectBoxService _db;

  PlayerNotifier(this._db) : super(const PlayerState());

  /// Loads the existing profile from ObjectBox, or returns default state.
  void loadProfile() {
    final profile = _db.getProfile();
    if (profile != null) {
      state = PlayerState(
        username: profile.username,
        goldBalance: profile.goldBalance,
        profileId: profile.id,
        isLoaded: true,
      );
    }
  }

  /// Creates a new profile with the given [username] and initial gold.
  void createProfile(String username) {
    final profile = PlayerProfile(
      username: username,
      goldBalance: AppConstants.initialGold,
    );
    _db.saveProfile(profile);

    state = PlayerState(
      username: profile.username,
      goldBalance: profile.goldBalance,
      profileId: profile.id,
      isLoaded: true,
    );
  }

  /// Updates the player's username.
  void updateUsername(String username) {
    state = state.copyWith(username: username);
    _persistProfile();
  }

  /// Adds [amount] gold to the balance (e.g. from game rewards).
  void addGold(int amount) {
    state = state.copyWith(goldBalance: state.goldBalance + amount);
    _persistProfile();
  }

  /// Attempts to spend [amount] gold.
  ///
  /// Returns true if the balance was sufficient, false otherwise.
  bool spendGold(int amount) {
    if (state.goldBalance < amount) return false;
    state = state.copyWith(goldBalance: state.goldBalance - amount);
    _persistProfile();
    return true;
  }

  void _persistProfile() {
    final profile = PlayerProfile(
      username: state.username,
      goldBalance: state.goldBalance,
    )..id = state.profileId;
    _db.saveProfile(profile);
  }
}

/// Provider for the player profile state.
final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  final db = ref.watch(objectBoxServiceProvider);
  return PlayerNotifier(db);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/joker_inventory.dart';
import '../../data/services/objectbox_service.dart';
import 'game_provider.dart';

/// Immutable state for the joker inventory.
class JokerState {
  /// Owned joker quantities: jokerType → count.
  final Map<String, int> inventory;

  /// Currently active (selected for use) joker type, or null.
  final String? activeJoker;

  const JokerState({
    this.inventory = const {},
    this.activeJoker,
  });

  JokerState copyWith({
    Map<String, int>? inventory,
    String? activeJoker,
    bool clearActiveJoker = false,
  }) {
    return JokerState(
      inventory: inventory ?? this.inventory,
      activeJoker: clearActiveJoker ? null : (activeJoker ?? this.activeJoker),
    );
  }

  /// Returns the quantity of [jokerType] owned.
  int getQuantity(String jokerType) => inventory[jokerType] ?? 0;

  /// Returns true if the player owns at least one of [jokerType].
  bool hasJoker(String jokerType) => getQuantity(jokerType) > 0;
}

/// Manages the joker inventory with ObjectBox persistence.
class JokerNotifier extends StateNotifier<JokerState> {
  final ObjectBoxService _db;

  JokerNotifier(this._db) : super(const JokerState());

  /// Loads all joker inventories from ObjectBox into state.
  void loadInventory() {
    final jokers = _db.getAllJokers();
    final inventoryMap = <String, int>{};
    for (final joker in jokers) {
      inventoryMap[joker.jokerType] = joker.quantity;
    }
    state = JokerState(inventory: inventoryMap);
  }

  /// Adds [count] jokers of [type] to the inventory.
  void addJoker(String type, int count) {
    final newInventory = Map<String, int>.from(state.inventory);
    newInventory[type] = (newInventory[type] ?? 0) + count;
    state = state.copyWith(inventory: newInventory);
    _persistJoker(type, newInventory[type]!);
  }

  /// Attempts to use one joker of [type].
  ///
  /// Returns true if successful (at least one was owned), false otherwise.
  bool useJoker(String type) {
    final current = state.getQuantity(type);
    if (current <= 0) return false;

    final newInventory = Map<String, int>.from(state.inventory);
    newInventory[type] = current - 1;
    state = state.copyWith(
      inventory: newInventory,
      activeJoker: type,
    );
    _persistJoker(type, current - 1);
    return true;
  }

  /// Sets the active joker type (for UI highlighting).
  void setActiveJoker(String type) {
    state = state.copyWith(activeJoker: type);
  }

  /// Clears the active joker selection.
  void clearActiveJoker() {
    state = state.copyWith(clearActiveJoker: true);
  }

  void _persistJoker(String type, int quantity) {
    final existing = _db.getJoker(type);
    if (existing != null) {
      existing.quantity = quantity;
      _db.saveJoker(existing);
    } else {
      _db.saveJoker(JokerInventory(jokerType: type, quantity: quantity));
    }
  }
}

/// Provider for the joker inventory state.
final jokerProvider =
    StateNotifierProvider<JokerNotifier, JokerState>((ref) {
  final db = ref.watch(objectBoxServiceProvider);
  return JokerNotifier(db);
});

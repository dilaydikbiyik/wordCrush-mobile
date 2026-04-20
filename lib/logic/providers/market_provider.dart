import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/joker_inventory.dart';
import 'player_provider.dart';
import 'joker_provider.dart';

/// Result of a market purchase attempt.
enum PurchaseResult {
  /// Purchase succeeded.
  success,

  /// Player does not have enough gold.
  insufficientGold,
}

/// Joker price lookup from [AppConstants].
class JokerPrices {
  static const Map<String, int> prices = {
    JokerType.fish: AppConstants.fishPrice,
    JokerType.wheel: AppConstants.wheelPrice,
    JokerType.lollipop: AppConstants.lollipopPrice,
    JokerType.swap: AppConstants.swapPrice,
    JokerType.shuffle: AppConstants.shufflePrice,
    JokerType.party: AppConstants.partyPrice,
  };

  /// Returns the gold cost for [jokerType], or 0 if unknown.
  static int getPrice(String jokerType) => prices[jokerType] ?? 0;
}

/// Immutable state for the market screen.
class MarketState {
  /// Result of the last purchase attempt, or null if none yet.
  final PurchaseResult? lastResult;

  /// The joker type from the last purchase attempt.
  final String? lastPurchasedType;

  const MarketState({
    this.lastResult,
    this.lastPurchasedType,
  });

  MarketState copyWith({
    PurchaseResult? lastResult,
    String? lastPurchasedType,
  }) {
    return MarketState(
      lastResult: lastResult ?? this.lastResult,
      lastPurchasedType: lastPurchasedType ?? this.lastPurchasedType,
    );
  }
}

/// Coordinates joker purchases between [PlayerProvider] and [JokerProvider].
///
/// Checks gold sufficiency, deducts gold, and adds the joker to inventory
/// in a single transactional operation.
class MarketNotifier extends StateNotifier<MarketState> {
  final PlayerNotifier _playerNotifier;
  final JokerNotifier _jokerNotifier;

  MarketNotifier(this._playerNotifier, this._jokerNotifier)
      : super(const MarketState());

  /// Attempts to purchase one [jokerType].
  ///
  /// Returns [PurchaseResult.success] if the player had enough gold,
  /// [PurchaseResult.insufficientGold] otherwise.
  PurchaseResult purchaseJoker(String jokerType) {
    final price = JokerPrices.getPrice(jokerType);

    // Try to deduct gold
    final success = _playerNotifier.spendGold(price);
    if (!success) {
      state = MarketState(
        lastResult: PurchaseResult.insufficientGold,
        lastPurchasedType: jokerType,
      );
      return PurchaseResult.insufficientGold;
    }

    // Add joker to inventory
    _jokerNotifier.addJoker(jokerType, 1);

    state = MarketState(
      lastResult: PurchaseResult.success,
      lastPurchasedType: jokerType,
    );

    return PurchaseResult.success;
  }
}

/// Provider for the market state.
final marketProvider =
    StateNotifierProvider<MarketNotifier, MarketState>((ref) {
  final playerNf = ref.read(playerProvider.notifier);
  final jokerNf = ref.read(jokerProvider.notifier);
  return MarketNotifier(playerNf, jokerNf);
});

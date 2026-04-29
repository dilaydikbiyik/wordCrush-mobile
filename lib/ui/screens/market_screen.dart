import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/joker_inventory.dart';
import '../../logic/providers/joker_provider.dart';
import '../../logic/providers/market_provider.dart';
import '../../logic/providers/player_provider.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  static const _jokers = [
    (JokerType.fish, 'Balık', AppConstants.fishPrice),
    (JokerType.wheel, 'Tekerlek', AppConstants.wheelPrice),
    (JokerType.lollipop, 'Lolipop', AppConstants.lollipopPrice),
    (JokerType.swap, 'Değiştir', AppConstants.swapPrice),
    (JokerType.shuffle, 'Karıştır', AppConstants.shufflePrice),
    (JokerType.party, 'Parti', AppConstants.partyPrice),
  ];

  void _purchase(BuildContext context, WidgetRef ref, String jokerType) {
    final result = ref.read(marketProvider.notifier).purchaseJoker(jokerType);
    final msg = result == PurchaseResult.success
        ? 'Satın alındı!'
        : 'Yetersiz altın!';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final gold = ref.watch(playerProvider).goldBalance;
    final jokerState = ref.watch(jokerProvider);

    const buttonLayout = [
      (0.17, 0.08, 0.53, 236.0, 0.8),
      (0.17, 0.52, 0.099, 236.0, 0.8),
      (0.45, 0.09, 0.53, 236.0, 0.83),
      (0.45, 0.52, 0.099, 236.0, 0.83),
      (0.73, 0.09, 0.53, 229.0, 0.8),
      (0.73, 0.52, 0.099, 229.0, 0.8),
    ];

    return Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            Image.asset(
              'assets/images/market_bg.png',
              fit: BoxFit.fill,
              width: size.width,
              height: size.height,
            ),

            // Altın göstergesi
            Positioned(
              top: size.height * 0.090,
              right: size.width * 0.13,
              child: Text(
                '$gold',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
            ),

            // 6 joker satın al butonu
            for (int i = 0; i < _jokers.length; i++)
              Positioned(
                top: size.height * buttonLayout[i].$1,
                left: size.width * buttonLayout[i].$2,
                right: size.width * buttonLayout[i].$3,
                child: _JokerButton(
                  jokerType: _jokers[i].$1,
                  price: _jokers[i].$3,
                  quantity: jokerState.getQuantity(_jokers[i].$1),
                  canAfford: gold >= _jokers[i].$3,
                  height: buttonLayout[i].$4,
                  alignmentY: buttonLayout[i].$5,
                  onTap: () => _purchase(context, ref, _jokers[i].$1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _JokerButton extends StatelessWidget {
  final String jokerType;
  final int price;
  final int quantity;
  final bool canAfford;
  final double height;
  final double alignmentY;
  final VoidCallback onTap;

  const _JokerButton({
    required this.jokerType,
    required this.price,
    required this.quantity,
    required this.canAfford,
    required this.height,
    required this.alignmentY,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canAfford ? onTap : null,
      child: Container(
        height: height,
        alignment: Alignment(0, alignmentY),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$price',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: canAfford ? Colors.black87 : Colors.black38,
              ),
            ),
            if (quantity > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'x$quantity',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/joker_inventory.dart';
import '../../logic/providers/audio_provider.dart';
import '../../logic/providers/joker_provider.dart';
import '../../logic/providers/market_provider.dart';
import '../../logic/providers/player_provider.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  static const _jokers = [
    (JokerType.fish, AppConstants.fishPrice),
    (JokerType.wheel, AppConstants.wheelPrice),
    (JokerType.lollipop, AppConstants.lollipopPrice),
    (JokerType.swap, AppConstants.swapPrice),
    (JokerType.shuffle, AppConstants.shufflePrice),
    (JokerType.party, AppConstants.partyPrice),
  ];

  static const _cardAssets = [
    'assets/images/btn_joker_fish.png',
    'assets/images/btn_joker_wheel.png',
    'assets/images/btn_joker_lollipop.png',
    'assets/images/btn_joker_swap.png',
    'assets/images/btn_joker_shuffle.png',
    'assets/images/btn_joker_party.png',
  ];

  void _purchase(BuildContext context, WidgetRef ref, String jokerType) {
    final result = ref.read(marketProvider.notifier).purchaseJoker(jokerType);
    if (result == PurchaseResult.success) {
      ref.read(audioProvider.notifier).playSound(SoundType.spinningCoin);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Satın alındı!'),
            ],
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.money_off_outlined, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Yetersiz altın!'),
            ],
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final gold = ref.watch(playerProvider).goldBalance;
    final jokerState = ref.watch(jokerProvider);

    // top, left, right, height
    const cardLayout = [
      (0.17, 0.08, 0.53, 236.0),
      (0.17, 0.52, 0.099, 236.0),
      (0.45, 0.09, 0.53, 236.0),
      (0.45, 0.52, 0.099, 236.0),
      (0.73, 0.09, 0.53, 229.0),
      (0.73, 0.52, 0.099, 229.0),
    ];

    // dx, dy — her kart için bağımsız ince ayar (piksel)
    // pozitif dx → sağa, negatif → sola
    // pozitif dy → aşağı, negatif → yukarı
    const cardOffsets = [
      (-15.0, 1.0), // fish
      (-5.0, -2.0), // wheel
      (-18.0, 0.0), // lollipop
      (-5.0, 7.0), // swap
      (-6.0, 0.0), // shuffle
      (-8.0, 1.0), // party
    ];

    // null → varsayılan 230 yükseklik kullanılır
    // width null → orantılı genişlik (doğal oran korunur)
    const cardSizes = [
      (237.0, null), // fish    — height, width
      (239.0, null), // wheel
      (238.0, null), // lollipop
      (230.0, null), // swap
      (null, null), // shuffle
      (null, null), // party
    ];

    // rozet konumu — bottom, right (piksel)
    // kartın sağ alt köşesine göre ayarla
    const badgeOffsets = [
      (198.0, 12.0), // fish
      (196.0, 24.0), // wheel
      (198.0, 12.0), // lollipop
      (198.0, 12.0), // swap
      (191.0, 12.0), // shuffle
      (192.0, 30.0), // party
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

            // 6 joker kartı
            for (int i = 0; i < _jokers.length; i++)
              Positioned(
                top: size.height * cardLayout[i].$1,
                left: size.width * cardLayout[i].$2,
                child: _JokerCard(
                  cardAsset: _cardAssets[i],
                  quantity: jokerState.getQuantity(_jokers[i].$1),
                  canAfford: gold >= _jokers[i].$2,
                  offsetDx: cardOffsets[i].$1,
                  offsetDy: cardOffsets[i].$2,
                  cardHeight: cardSizes[i].$1,
                  cardWidth: cardSizes[i].$2,
                  badgeBottom: badgeOffsets[i].$1,
                  badgeRight: badgeOffsets[i].$2,
                  onTap: () => _purchase(context, ref, _jokers[i].$1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _JokerCard extends StatefulWidget {
  final String cardAsset;
  final int quantity;
  final bool canAfford;
  final double offsetDx;
  final double offsetDy;
  final double? cardHeight;
  final double? cardWidth;
  final double badgeBottom;
  final double badgeRight;
  final VoidCallback onTap;

  const _JokerCard({
    required this.cardAsset,
    required this.quantity,
    required this.canAfford,
    required this.onTap,
    this.offsetDx = 0.0,
    this.offsetDy = 0.0,
    this.cardHeight,
    this.cardWidth,
    this.badgeBottom = 14.0,
    this.badgeRight = 12.0,
  });

  @override
  State<_JokerCard> createState() => _JokerCardState();
}

class _JokerCardState extends State<_JokerCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          widget.offsetDx,
          widget.offsetDy + (_pressed ? 6.0 : 0),
          0,
        ),
        child: Stack(
          children: [
            Image.asset(
              widget.cardAsset,
              height: widget.cardHeight ?? 230,
              width: widget.cardWidth,
              color: widget.canAfford
                  ? null
                  : Colors.black.withValues(alpha: 0.35),
              colorBlendMode:
                  widget.canAfford ? null : BlendMode.darken,
            ),
            if (widget.quantity > 0)
              Positioned(
                bottom: widget.badgeBottom,
                right: widget.badgeRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'x${widget.quantity}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

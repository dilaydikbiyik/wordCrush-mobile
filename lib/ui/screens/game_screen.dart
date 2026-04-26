import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/char_normalizer.dart';
import '../../data/models/cell.dart';
import '../../data/models/joker_inventory.dart';
import '../../logic/providers/game_provider.dart';
import '../../logic/providers/grid_provider.dart';
import '../../logic/providers/joker_provider.dart';
import '../../logic/providers/score_provider.dart';
import '../../logic/providers/trie_provider.dart';
import '../../logic/scoring/combo_engine.dart';
import '../../logic/scoring/score_calculator.dart';
import '../../logic/powers/joker_executor.dart';
import '../../router/app_router.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  final GlobalKey _gridKey = GlobalKey();

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;

  Color _gridOverlay = Colors.transparent;
  int? _lastScore;
  bool _gameOverHandled = false;

  // Joker target selection state
  String? _activeJokerType;
  Cell? _jokerFirstCell;

  static const _jokerTypes = [
    JokerType.fish,
    JokerType.wheel,
    JokerType.lollipop,
    JokerType.swap,
    JokerType.shuffle,
    JokerType.party,
  ];

  static const _jokerAssets = [
    'assets/images/joker_fish.png',
    'assets/images/joker_wheel.png',
    'assets/images/joker_lollipop.png',
    'assets/images/joker_swap.png',
    'assets/images/joker_shuffle.png',
    'assets/images/joker_party.png',
  ];

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    // Reset position when shake animation completes so grid returns to origin
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameState = ref.read(gameProvider);
      ref.read(gridProvider.notifier).initializeGrid(gameState.gridSize);
      ref.read(scoreProvider.notifier).reset();
      _runSolvabilityCheck();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  (int, int)? _cellFromOffset(Offset localPos) {
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final size = box.size;
    final gridSize = ref.read(gridProvider).grid.size;
    final cellW = size.width / gridSize;
    final cellH = size.height / gridSize;
    final col = (localPos.dx / cellW).floor();
    final row = (localPos.dy / cellH).floor();
    if (row < 0 || row >= gridSize || col < 0 || col >= gridSize) return null;
    return (row, col);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_activeJokerType != null) return; // Disable swipe during joker mode
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(d.globalPosition);
    final pos = _cellFromOffset(local);
    if (pos != null) {
      ref.read(gridProvider.notifier).selectCell(pos.$1, pos.$2);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_activeJokerType != null) return; // Disable swipe during joker mode
    final gridState = ref.read(gridProvider);
    final word = CharNormalizer.toTurkishUpper(gridState.currentWord);

    if (word.length < 3) {
      ref.read(gridProvider.notifier).clearSelection();
      _shake();
      return;
    }

    final trie = ref.read(trieProvider).valueOrNull;
    if (trie == null) {
      ref.read(gridProvider.notifier).clearSelection();
      return;
    }

    if (trie.contains(word)) {
      // Get combo sub-words, excluding main word to avoid double scoring
      final allCombos = ComboEngine(trie).findComboWords(word);
      final combos = allCombos.where((w) => w != word).toList();
      final score = ScoreCalculator().calculateTotalScore(word, combos);

      debugPrint('✅ KABUL: "$word" → puan=$score, combo=${combos.join(", ")}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ KABUL: $word (+$score puan)'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );

      ref.read(scoreProvider.notifier).addWordScore(score, combos);
      ref.read(gameProvider.notifier).recordWord(word);
      ref.read(gameProvider.notifier).decrementMove();
      ref.read(gridProvider.notifier).removeAndRefill(gridState.selectedCells);

      setState(() => _lastScore = score);
      _flashGreen();

      // Check solvability after grid changes
      _runSolvabilityCheck();

      final gameState = ref.read(gameProvider);
      if (gameState.isGameOver && !_gameOverHandled) {
        _gameOverHandled = true;
        final finalScore = ref.read(scoreProvider).totalScore;
        ref.read(gameProvider.notifier).endGame(finalScore);
        Future.delayed(
          const Duration(milliseconds: 600),
          () => _showGameOverDialog(finalScore),
        );
      }
    } else {
      debugPrint('❌ RED: "$word" sözlükte bulunamadı');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ GEÇERSİZ: $word'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _lastScore = null);
      ref.read(gridProvider.notifier).clearSelection();
      _shake();
      _flashRed();
    }
  }

  void _shake() {
    _shakeController.forward(from: 0);
  }

  /// Runs solvability check in background isolate.
  /// Updates formable word count and auto-shuffles if grid has no valid words.
  void _runSolvabilityCheck() {
    final trie = ref.read(trieProvider).valueOrNull;
    if (trie == null) return;
    ref.read(gridProvider.notifier).scanAsync(trie);
  }

  // ─── Joker Handlers ─────────────────────────────────────────────────

  void _onJokerTap(String jokerType) {
    final jokerState = ref.read(jokerProvider);
    if (!jokerState.hasJoker(jokerType)) return;

    // If already in this joker mode, cancel
    if (_activeJokerType == jokerType) {
      _cancelJokerMode();
      return;
    }

    // Jokers that don't need target: execute immediately
    if (!JokerExecutor.requiresTarget(jokerType)) {
      final used = ref.read(jokerProvider.notifier).useJoker(jokerType);
      if (!used) return;
      _executeJoker(jokerType, null, null);
      return;
    }

    // Enter target selection mode
    setState(() {
      _activeJokerType = jokerType;
      _jokerFirstCell = null;
    });
  }

  void _onGridTapForJoker(TapUpDetails details) {
    if (_activeJokerType == null) return;
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(details.globalPosition);
    final pos = _cellFromOffset(local);
    if (pos == null) return;

    final cell = ref.read(gridProvider).grid.getCell(pos.$1, pos.$2);
    if (cell.isEmpty) return;

    if (JokerExecutor.requiresTwoTargets(_activeJokerType!)) {
      // Swap: need two cells
      if (_jokerFirstCell == null) {
        setState(() => _jokerFirstCell = cell);
        return;
      }
      // Second cell must be adjacent
      if (!_jokerFirstCell!.isAdjacentTo(cell)) {
        setState(() => _jokerFirstCell = null); // Reset
        return;
      }
      final used = ref.read(jokerProvider.notifier).useJoker(_activeJokerType!);
      if (!used) { _cancelJokerMode(); return; }
      _executeJoker(_activeJokerType!, _jokerFirstCell, cell);
    } else {
      // Single target (Lollipop, Wheel)
      final used = ref.read(jokerProvider.notifier).useJoker(_activeJokerType!);
      if (!used) { _cancelJokerMode(); return; }
      _executeJoker(_activeJokerType!, cell, null);
    }
  }

  void _executeJoker(String jokerType, Cell? target, Cell? second) {
    final grid = ref.read(gridProvider).grid;
    final executor = JokerExecutor();
    final newGrid = executor.execute(
      jokerType: jokerType,
      grid: grid,
      targetCell: target,
      secondCell: second,
    );
    ref.read(gridProvider.notifier).setGrid(newGrid);
    _cancelJokerMode();
    _runSolvabilityCheck();
  }

  void _cancelJokerMode() {
    setState(() {
      _activeJokerType = null;
      _jokerFirstCell = null;
    });
  }

  void _flashGreen() {
    setState(() => _gridOverlay = Colors.green.withAlpha(60));
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _gridOverlay = Colors.transparent);
    });
  }

  void _flashRed() {
    setState(() => _gridOverlay = Colors.red.withAlpha(50));
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _gridOverlay = Colors.transparent);
    });
  }

  void _showGameOverDialog(int finalScore) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Oyun Bitti!'),
        content: Text('Toplam Puan: $finalScore'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.home);
            },
            child: const Text('Ana Menü'),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Çıkmak istiyor musun?'),
        content: const Text('Oyun kaydedilmeyecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hayır'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.home);
            },
            child: const Text('Evet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final gameState = ref.watch(gameProvider);
    final gridState = ref.watch(gridProvider);
    final scoreState = ref.watch(scoreProvider);
    final jokerState = ref.watch(jokerProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _showExitDialog(),
      child: Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              // Arka plan
              Container(
                width: size.width,
                height: size.height,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/game_bg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Üst bar — skor
              Positioned(
                top: size.height * 0.107,
                left: size.width * 0.082,
                width: size.width * 0.255,
                child: _InfoBox(label: '${scoreState.totalScore}'),
              ),

              // Üst bar — kalan hamle
              Positioned(
                top: size.height * 0.107,
                left: size.width * 0.366,
                width: size.width * 0.268,
                child: _InfoBox(label: '${gameState.movesLeft}'),
              ),

              // Üst bar — kelime sayısı
              Positioned(
                top: size.height * 0.107,
                right: size.width * 0.086,
                width: size.width * 0.25,
                child: _InfoBox(label: '${gridState.formableWordCount}'),
              ),

              // Grid alanı
              Positioned(
                top: size.height * 0.305,
                left: size.width * 0.075,
                right: size.width * 0.075,
                child: AspectRatio(
                aspectRatio: 1.0,
                child: GestureDetector(
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  onTapUp: _onGridTapForJoker,
                  child: AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(
                        _shakeAnim.value *
                            (_shakeController.value < 0.5 ? 1 : -1),
                        0,
                      ),
                      child: child,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          key: _gridKey,
                          color: Colors.transparent,
                          child: _GridWidget(
                            gridState: gridState,
                            overlay: _gridOverlay,
                          ),
                        ),
                        if (_lastScore != null && _gridOverlay != Colors.transparent)
                          Center(
                            child: Text(
                              '+$_lastScore',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.green,
                                shadows: [
                                  Shadow(color: Colors.black26, blurRadius: 8),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                ),
              ),

              // Joker — Balık
              Positioned(
                bottom: size.height * 0.060,
                left: size.width * 0.02,
                right: size.width * 0.83,
                height: size.width * 0.105,
                child: _JokerBtn(assetPath: _jokerAssets[0], quantity: jokerState.getQuantity(_jokerTypes[0]), active: jokerState.getQuantity(_jokerTypes[0]) > 0, iconSize: 100, alignment: Alignment(0.1, 0.05), isActiveMode: _activeJokerType == _jokerTypes[0], onTap: () => _onJokerTap(_jokerTypes[0])),
              ),
              // Joker — Tekerlek
              Positioned(
                bottom: size.height * 0.060,
                left: size.width * 0.18,
                right: size.width * 0.67,
                height: size.width * 0.105,
                child: _JokerBtn(assetPath: _jokerAssets[1], quantity: jokerState.getQuantity(_jokerTypes[1]), active: jokerState.getQuantity(_jokerTypes[1]) > 0, iconSize: 85, alignment: Alignment(0, -0.18), isActiveMode: _activeJokerType == _jokerTypes[1], onTap: () => _onJokerTap(_jokerTypes[1])),
              ),
              // Joker — Lolipop
              Positioned(
                bottom: size.height * 0.060,
                left: size.width * 0.34,
                right: size.width * 0.51,
                height: size.width * 0.105,
                child: _JokerBtn(assetPath: _jokerAssets[2], quantity: jokerState.getQuantity(_jokerTypes[2]), active: jokerState.getQuantity(_jokerTypes[2]) > 0, iconSize: 80, alignment: Alignment(0.00, -0.28), isActiveMode: _activeJokerType == _jokerTypes[2], onTap: () => _onJokerTap(_jokerTypes[2])),
              ),
              // Joker — Değiştir
              Positioned(
                bottom: size.height * 0.060,
                left: size.width * 0.50,
                right: size.width * 0.35,
                height: size.width * 0.105,
                child: _JokerBtn(assetPath: _jokerAssets[3], quantity: jokerState.getQuantity(_jokerTypes[3]), active: jokerState.getQuantity(_jokerTypes[3]) > 0, iconSize: 77, alignment: Alignment(0.3, -0.2), isActiveMode: _activeJokerType == _jokerTypes[3], onTap: () => _onJokerTap(_jokerTypes[3])),
              ),
              // Joker — Karıştır
              Positioned(
                bottom: size.height * 0.060,
                left: size.width * 0.658,
                right: size.width * 0.19,
                height: size.width * 0.105,
                child: _JokerBtn(assetPath: _jokerAssets[4], quantity: jokerState.getQuantity(_jokerTypes[4]), active: jokerState.getQuantity(_jokerTypes[4]) > 0, iconSize: 40, alignment: Alignment.center, isActiveMode: _activeJokerType == _jokerTypes[4], onTap: () => _onJokerTap(_jokerTypes[4])),
              ),
              // Joker — Parti
              Positioned(
                bottom: size.height * 0.060,
                left: size.width * 0.817,
                right: size.width * 0.03,
                height: size.width * 0.105,
                child: _JokerBtn(assetPath: _jokerAssets[5], quantity: jokerState.getQuantity(_jokerTypes[5]), active: jokerState.getQuantity(_jokerTypes[5]) > 0, iconSize: 100, alignment: Alignment(0.3, -0.45), isActiveMode: _activeJokerType == _jokerTypes[5], onTap: () => _onJokerTap(_jokerTypes[5])),
              ),

              // Mevcut kelime
              if (gridState.currentWord.isNotEmpty)
                Positioned(
                  top: size.height * 0.11,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        gridState.currentWord,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),

              // Joker mode indicator
              if (_activeJokerType != null)
                Positioned(
                  top: size.height * 0.27,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _cancelJokerMode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade800,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          JokerExecutor.requiresTwoTargets(_activeJokerType!)
                              ? (_jokerFirstCell == null ? 'İlk hücreye dokun' : 'Komşu hücreye dokun')
                              : 'Hedef hücreye dokun',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),

              // Çıkış butonu — hit area büyütüldü
              Positioned(
                top: size.height * 0.04,
                left: size.width * 0.03,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _showExitDialog,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridWidget extends StatelessWidget {
  final GridState gridState;
  final Color overlay;

  const _GridWidget({required this.gridState, required this.overlay});

  @override
  Widget build(BuildContext context) {
    final grid = gridState.grid;
    final selected = gridState.selectedCells;

    return Stack(
      fit: StackFit.expand,
      children: [
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: grid.size,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: grid.size * grid.size,
          itemBuilder: (_, index) {
            final row = index ~/ grid.size;
            final col = index % grid.size;
            final cell = grid.getCell(row, col);
            final isSelected = selected.contains(cell);
            final selIndex = isSelected ? selected.indexOf(cell) : -1;

            return _CellTile(
              cell: cell,
              isSelected: isSelected,
              selectionIndex: selIndex,
              totalSelected: selected.length,
            );
          },
        ),
        if (overlay != Colors.transparent)
          Positioned.fill(
            child: Container(
              color: overlay,
              child: const SizedBox.expand(),
            ),
          ),
      ],
    );
  }
}

class _CellTile extends StatelessWidget {
  final Cell cell;
  final bool isSelected;
  final int selectionIndex;
  final int totalSelected;

  const _CellTile({
    required this.cell,
    required this.isSelected,
    required this.selectionIndex,
    required this.totalSelected,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = const Color(0xFFF5F0E8);
    Color textColor = Colors.black87;
    double elevation = 1;

    if (isSelected) {
      bgColor = const Color(0xFF4A90D9);
      textColor = Colors.white;
      elevation = 4;
    }

    if (cell.isEmpty) bgColor = Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected ? const Color(0xFF2C5F8A) : Colors.black26,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation),
          ),
        ],
      ),
      child: cell.isEmpty
          ? null
          : Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  cell.letter,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
              ),
            ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  const _InfoBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: Colors.transparent,
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _JokerBtn extends StatelessWidget {
  final String assetPath;
  final int quantity;
  final bool active;
  final double? iconSize;
  final Alignment alignment;
  final VoidCallback? onTap;
  final bool isActiveMode;

  const _JokerBtn({
    required this.assetPath,
    required this.quantity,
    required this.active,
    this.iconSize,
    this.alignment = Alignment.center,
    this.onTap,
    this.isActiveMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: active ? onTap : null,
      child: Opacity(
        opacity: active ? 1.0 : 0.35,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isActiveMode ? Colors.orange.withAlpha(40) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isActiveMode
                    ? Border.all(color: Colors.orange, width: 2)
                    : null,
              ),
              child: OverflowBox(
                alignment: alignment,
                minWidth: 0,
                minHeight: 0,
                maxWidth: iconSize ?? double.infinity,
                maxHeight: iconSize ?? double.infinity,
                child: Image.asset(
                  assetPath,
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (quantity > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$quantity',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
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

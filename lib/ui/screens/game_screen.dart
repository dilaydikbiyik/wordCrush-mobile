import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/char_normalizer.dart';
import '../../data/models/cell.dart';
import '../../data/models/joker_inventory.dart';
import '../../logic/providers/audio_provider.dart';
import '../../logic/providers/game_provider.dart';
import '../../logic/providers/grid_provider.dart';
import '../../logic/providers/joker_provider.dart';
import '../../logic/providers/player_provider.dart';
import '../../logic/providers/score_provider.dart';
import '../../logic/providers/trie_provider.dart';
import '../../logic/scoring/combo_engine.dart';
import '../../logic/scoring/score_calculator.dart';
import '../../logic/powers/joker_executor.dart';
import '../../logic/powers/power_type.dart';
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

  // Animation states
  List<Cell> _explodingCells = [];
  Offset? _lollipopSlamPos;
  double _lollipopSlamSize = 0;

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
    final col = (localPos.dx / cellW).floor().clamp(0, gridSize - 1);
    final row = (localPos.dy / cellH).floor().clamp(0, gridSize - 1);
    return (row, col);
  }

  void _onPanStart(DragStartDetails d) {
    if (_activeJokerType != null) return;
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(d.globalPosition);
    final pos = _cellFromOffset(local);
    ref.read(gridProvider.notifier).clearSelection();
    if (pos != null) {
      ref.read(gridProvider.notifier).selectCell(pos.$1, pos.$2);
      ref.read(audioProvider.notifier).playSound(SoundType.letterSelect);
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_activeJokerType != null) return; // Disable swipe during joker mode
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(d.globalPosition);
    final pos = _cellFromOffset(local);
    if (pos != null) {
      final added = ref.read(gridProvider.notifier).selectCell(pos.$1, pos.$2);
      if (added) {
        ref.read(audioProvider.notifier).playSound(SoundType.letterSelect);
      }
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

      debugPrint('\u2705 KABUL: "$word" \u2192 puan=$score, combo=${combos.join(", ")}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('\u2705 KABUL: $word (+$score puan)'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );

      ref.read(scoreProvider.notifier).addWordScore(score, combos);
      ref.read(gameProvider.notifier).recordWord(word);
      ref.read(gameProvider.notifier).decrementMove();

      // Play valid word sound (combo sound overrides if 2+ combos)
      if (allCombos.length >= 2) {
        ref.read(audioProvider.notifier).playSound(SoundType.combo);
      } else {
        ref.read(audioProvider.notifier).playSound(SoundType.validWord);
      }
      
      final destroyed = ref.read(gridProvider.notifier).removeAndRefill(gridState.selectedCells);
      
      if (destroyed.isNotEmpty) {
        setState(() => _explodingCells = destroyed);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _explodingCells = []);
        });
      }

      setState(() => _lastScore = score);
      _flashGreen();

      // Show combo popup if 2+ combos found (including main word)
      final totalCombos = allCombos.length;
      if (totalCombos >= 2) {
        // Pass sub-words (excluding main word) so popup can display them
        _showComboPopup(totalCombos, score, combos);
      }

      // Check solvability after grid changes
      _runSolvabilityCheck();

      final gameState = ref.read(gameProvider);
      if (gameState.isGameOver && !_gameOverHandled) {
        _gameOverHandled = true;
        final finalScore = ref.read(scoreProvider).totalScore;
        // #24: Oyun sonunda puana göre altın ödülü ver
        final goldEarned = (finalScore / AppConstants.goldPerScore).round();
        if (goldEarned > 0) {
          ref.read(playerProvider.notifier).addGold(goldEarned);
        }
        ref.read(gameProvider.notifier).endGame(finalScore);
        Future.delayed(
          const Duration(milliseconds: 600),
          () => _showGameOverDialog(finalScore, goldEarned),
        );
      }
    } else {
      debugPrint('\u274c RED: "$word" s\u00f6zl\u00fckte bulunamad\u0131');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('\u274c GE\u00c7ERSS\u0130Z: $word'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _lastScore = null);
      ref.read(gridProvider.notifier).clearSelection();
      ref.read(gameProvider.notifier).decrementMove();
      ref.read(audioProvider.notifier).playSound(SoundType.invalidWord);
      _shake();
      _flashRed();
      final gameState = ref.read(gameProvider);
      if (gameState.isGameOver && !_gameOverHandled) {
        _gameOverHandled = true;
        final finalScore = ref.read(scoreProvider).totalScore;
        // #24: Oyun sonunda puana göre altın ödülü ver
        final goldEarned = (finalScore / AppConstants.goldPerScore).round();
        if (goldEarned > 0) {
          ref.read(playerProvider.notifier).addGold(goldEarned);
        }
        ref.read(gameProvider.notifier).endGame(finalScore);
        Future.delayed(
          const Duration(milliseconds: 600),
          () => _showGameOverDialog(finalScore, goldEarned),
        );
      }
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

    // Setup Lollipop Slam Animation
    if (jokerType == JokerType.lollipop && target != null) {
      final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final cellW = box.size.width / grid.size;
        final cellH = box.size.height / grid.size;
        setState(() {
          _lollipopSlamPos = Offset(target.col * cellW, target.row * cellH);
          _lollipopSlamSize = cellW;
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _lollipopSlamPos = null);
        });
      }
    }

    final newGrid = executor.execute(
      jokerType: jokerType,
      grid: grid,
      targetCell: target,
      secondCell: second,
    );
    ref.read(gridProvider.notifier).setGrid(newGrid);
    ref.read(audioProvider.notifier).playSound(SoundType.powerActivation);
    // #15b: Joker görsel geri bildirimi — turuncu flash efekti
    _flashOrange();
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

  /// #15b: Joker kullanım görsel geri bildirimi — kısa turuncu flash.
  void _flashOrange() {
    setState(() => _gridOverlay = Colors.orange.withAlpha(70));
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _gridOverlay = Colors.transparent);
    });
  }

  /// Displays a floating combo banner above the grid when 2+ sub-words are found.
  ///
  /// Uses an [OverlayEntry] with a [TweenAnimationBuilder] so the banner
  /// slides up and fades out without touching the widget tree below.
  /// [subWords] are the combo sub-words (excluding the main word) to display.
  void _showComboPopup(int comboCount, int totalScore, List<String> subWords) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _ComboPopup(
        comboCount: comboCount,
        totalScore: totalScore,
        subWords: subWords,
        onDone: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }

  void _showGameOverDialog(int finalScore, [int goldEarned = 0]) {
    ref.read(audioProvider.notifier).playSound(SoundType.gameOver);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Oyun Bitti!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toplam Puan: $finalScore'),
            if (goldEarned > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '🪙 +$goldEarned Altın Kazandın!',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFB800),
                  ),
                ),
              ),
          ],
        ),
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
        content: const Text('En az bir kelime bulduysan skorun kaydedilecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hayır'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (!_gameOverHandled) {
                _gameOverHandled = true;
                final gameState = ref.read(gameProvider);
                if (gameState.wordCount > 0) {
                  final finalScore = ref.read(scoreProvider).totalScore;
                  // #24: Çıkış yapılırken de altın ver
                  final goldEarned = (finalScore / AppConstants.goldPerScore).round();
                  if (goldEarned > 0) {
                    ref.read(playerProvider.notifier).addGold(goldEarned);
                  }
                  ref.read(gameProvider.notifier).endGame(finalScore);
                }
              }
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
    // #9c/d: Trie yükleme durumunu izle — loading/error UI
    final trieAsync = ref.watch(trieProvider);

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
                child: _InfoBox(
                  title: 'SKOR',
                  label: '${scoreState.totalScore}',
                ),
              ),

              // Üst bar — kalan hamle
              Positioned(
                top: size.height * 0.107,
                left: size.width * 0.366,
                width: size.width * 0.268,
                child: _InfoBox(
                  title: 'HAMLE',
                  label: '${gameState.movesLeft}',
                ),
              ),

              // Üst bar — kelime sayısı
              Positioned(
                top: size.height * 0.107,
                right: size.width * 0.086,
                width: size.width * 0.25,
                child: _InfoBox(
                  title: 'KELİME',
                  label: '${gridState.formableWordCount}',
                ),
              ),

              // Grid alanı
              Positioned(
                top: size.height * 0.305,
                left: size.width * 0.075,
                right: size.width * 0.075,
                child: AspectRatio(
                aspectRatio: 1.0,
                child: GestureDetector(
                  onPanStart: _onPanStart,
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
                            explodingCells: _explodingCells,
                            lollipopSlamPos: _lollipopSlamPos,
                            lollipopSlamSize: _lollipopSlamSize,
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
                child: _JokerBtn(assetPath: _jokerAssets[0], quantity: jokerState.getQuantity(_jokerTypes[0]), active: jokerState.getQuantity(_jokerTypes[0]) > 0, iconSize: 100, alignment: const Alignment(0.1, 0.05), isActiveMode: _activeJokerType == _jokerTypes[0], onTap: () => _onJokerTap(_jokerTypes[0])),
              ),
              // Joker — Tekerlek
              Positioned(
                bottom: size.height * 0.060,
                left: size.width * 0.18,
                right: size.width * 0.67,
                height: size.width * 0.105,
                child: _JokerBtn(assetPath: _jokerAssets[1], quantity: jokerState.getQuantity(_jokerTypes[1]), active: jokerState.getQuantity(_jokerTypes[1]) > 0, iconSize: 85, alignment: const Alignment(0, -0.18), isActiveMode: _activeJokerType == _jokerTypes[1], onTap: () => _onJokerTap(_jokerTypes[1])),
              ),
              // Joker — Lolipop
              Positioned(
                bottom: size.height * 0.060,
                left: size.width * 0.34,
                right: size.width * 0.51,
                height: size.width * 0.105,
                child: _JokerBtn(assetPath: _jokerAssets[2], quantity: jokerState.getQuantity(_jokerTypes[2]), active: jokerState.getQuantity(_jokerTypes[2]) > 0, iconSize: 80, alignment: const Alignment(0.00, -0.28), isActiveMode: _activeJokerType == _jokerTypes[2], onTap: () => _onJokerTap(_jokerTypes[2])),
              ),
              // Joker — Değiştir
              Positioned(
                bottom: size.height * 0.060,
                left: size.width * 0.50,
                right: size.width * 0.35,
                height: size.width * 0.105,
                child: _JokerBtn(assetPath: _jokerAssets[3], quantity: jokerState.getQuantity(_jokerTypes[3]), active: jokerState.getQuantity(_jokerTypes[3]) > 0, iconSize: 77, alignment: const Alignment(0.3, -0.2), isActiveMode: _activeJokerType == _jokerTypes[3], onTap: () => _onJokerTap(_jokerTypes[3])),
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
                child: _JokerBtn(assetPath: _jokerAssets[5], quantity: jokerState.getQuantity(_jokerTypes[5]), active: jokerState.getQuantity(_jokerTypes[5]) > 0, iconSize: 100, alignment: const Alignment(0.3, -0.45), isActiveMode: _activeJokerType == _jokerTypes[5], onTap: () => _onJokerTap(_jokerTypes[5])),
              ),

              // Mevcut kelime
              if (gridState.currentWord.isNotEmpty)
                Positioned(
                  top: size.height * 0.2,
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

              // #9c/d: Trie yükleme / hata overlay
              if (trieAsync.isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFFFF6B35)),
                          SizedBox(height: 12),
                          Text(
                            'Sözlük yükleniyor...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (trieAsync.hasError)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(32),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D1010),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade700, width: 2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                            const SizedBox(height: 10),
                            const Text(
                              'Sözlük yüklenemedi',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Lütfen uygulamayı yeniden başlatın.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: () => context.go(AppRoutes.home),
                              child: const Text(
                                'Ana Menüye Dön',
                                style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
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


class _GridWidget extends StatefulWidget {
  final GridState gridState;
  final Color overlay;
  final List<Cell> explodingCells;
  final Offset? lollipopSlamPos;
  final double lollipopSlamSize;

  const _GridWidget({
    required this.gridState,
    required this.overlay,
    this.explodingCells = const [],
    this.lollipopSlamPos,
    this.lollipopSlamSize = 0,
  });

  @override
  State<_GridWidget> createState() => _GridWidgetState();
}

class _GridWidgetState extends State<_GridWidget> {
  // Maps cell.id → displayed row (used to start new cells above the grid).
  final Map<int, int> _displayRows = {};

  @override
  void didUpdateWidget(_GridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldIds =
        oldWidget.gridState.grid.allCells.map((c) => c.id).toSet();
    final gridSize = widget.gridState.grid.size;

    // New cells (not in previous grid) start above the visible area.
    for (final cell in widget.gridState.grid.allCells) {
      if (!oldIds.contains(cell.id)) {
        _displayRows[cell.id] = -gridSize;
      }
    }

    // One frame later, snap them to their actual rows → AnimatedPositioned animates the drop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        for (final cell in widget.gridState.grid.allCells) {
          _displayRows[cell.id] = cell.row;
        }
      });
    });
  }

  int _displayRow(Cell cell) => _displayRows[cell.id] ?? cell.row;

  @override
  Widget build(BuildContext context) {
    final grid = widget.gridState.grid;
    final selected = widget.gridState.selectedCells;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cellSize = constraints.maxWidth / grid.size;

        return Stack(
          fit: StackFit.expand,
          children: [
            for (final cell in grid.allCells)
              AnimatedPositioned(
                key: ValueKey(cell.id),
                duration: const Duration(milliseconds: 300),
                curve: Curves.bounceOut,
                left: cell.col * cellSize,
                top: _displayRow(cell) * cellSize,
                width: cellSize,
                height: cellSize,
                child: _CellTile(
                  cell: cell,
                  isSelected: selected.contains(cell),
                  selectionIndex: selected.contains(cell) ? selected.indexOf(cell) : -1,
                  totalSelected: selected.length,
                ),
              ),

            // Exploding Cells Effect
            for (final exp in widget.explodingCells)
              Positioned(
                left: exp.col * cellSize,
                top: exp.row * cellSize,
                width: cellSize,
                height: cellSize,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 2.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, scale, child) {
                    return Opacity(
                      opacity: (2.0 - scale).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: scale,
                        child: _CellTile(
                          cell: exp,
                          isSelected: true,
                          selectionIndex: -1,
                          totalSelected: 1,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Lollipop Slam Effect
            if (widget.lollipopSlamPos != null)
              Positioned(
                left: widget.lollipopSlamPos!.dx - (widget.lollipopSlamSize * 0.25),
                top: widget.lollipopSlamPos!.dy - (widget.lollipopSlamSize * 0.25),
                width: widget.lollipopSlamSize * 1.5,
                height: widget.lollipopSlamSize * 1.5,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: (value > 0.8 ? (1.0 - value) * 5 : 1.0).clamp(0.0, 1.0),
                        child: Image.asset('assets/images/joker_lollipop.png'),
                      ),
                    );
                  },
                ),
              ),

            if (widget.overlay != Colors.transparent)
              Positioned.fill(
                child: Container(
                  color: widget.overlay,
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        );
      },
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
          : Stack(
              children: [
                Center(
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
                if (cell.powerType != PowerType.none)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Icon(
                      _powerIcon(cell.powerType),
                      size: 10,
                      color: isSelected ? Colors.white70 : Colors.deepOrange,
                    ),
                  ),
              ],
            ),
    );
  }

  IconData _powerIcon(PowerType type) {
    switch (type) {
      case PowerType.rowClear:
        return Icons.swap_horiz;
      case PowerType.areaBlast:
        return Icons.local_fire_department;
      case PowerType.columnClear:
        return Icons.swap_vert;
      case PowerType.megaBlast:
        return Icons.rocket_launch;
      case PowerType.none:
        return Icons.circle;
    }
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String label;
  const _InfoBox({required this.title, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      color: Colors.transparent,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ],
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

// ─── Combo Popup Overlay ──────────────────────────────────────────────────────


/// A self-removing overlay banner shown when the player earns a combo.
///
/// Slides upward while fading out over 1.2 s, then calls [onDone] to remove
/// itself from the [Overlay] without requiring any parent state changes.
/// [subWords] are the discovered combo sub-words (excluding the main word).
class _ComboPopup extends StatefulWidget {
  final int comboCount;
  final int totalScore;
  final List<String> subWords;
  final VoidCallback onDone;

  const _ComboPopup({
    required this.comboCount,
    required this.totalScore,
    required this.subWords,
    required this.onDone,
  });

  @override
  State<_ComboPopup> createState() => _ComboPopupState();
}

class _ComboPopupState extends State<_ComboPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.45, 1.0)),
    );

    _slide = Tween<double>(begin: 0.0, end: -70.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final subText = widget.subWords.isNotEmpty
        ? widget.subWords.join(' • ')
        : null;

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: size.height * 0.38),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _slide.value),
              child: Opacity(
                opacity: _opacity.value,
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFB800),
                    Color(0xFFFF6B00),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withAlpha(80),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.comboCount}× COMBO!  +${widget.totalScore}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(color: Colors.black38, blurRadius: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (subText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



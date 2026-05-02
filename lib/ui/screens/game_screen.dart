
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

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
import '../../data/models/grid_model.dart';
import '../../router/app_router.dart';
import '../widgets/press_3d_button.dart';


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
  Cell? _jokerSecondCell;

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
  List<(int, int)> _jokerAffectedPositions = [];
  List<(int, int)> _wheelPreviewPositions = [];
  List<(int, int)> _fishPreviewPositions = [];
  List<Cell> _fishPreviewCells = [];
  String? _jokerAnimationAsset;
  double _jokerAnimationScale = 1.0;
  Offset? _jokerSwapCenter;
  bool _jokerIsFullGrid = false;
  bool _jokerIsParty = false;
  bool _jokerIsWheel = false;
  double _jokerFullGridOffsetY = 0.0;
  VoidCallback? _onLottieLoaded;
  Offset? _lollipopSlamPos;
  double _lollipopSlamSize = 0;
  double _gridScale = 1.0;

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

    // Only register if touch lands within the inner 70% of the cell.
    // This prevents accidental diagonal jumps when swiping along cell borders.
    const innerRatio = 0.70;
    const padding = (1.0 - innerRatio) / 2;
    final localX = localPos.dx - col * cellW;
    final localY = localPos.dy - row * cellH;
    if (localX < cellW * padding || localX > cellW * (1 - padding) ||
        localY < cellH * padding || localY > cellH * (1 - padding)) {
      return null;
    }

    return (row, col);
  }

  /// Tap için hücre hesabı — swiping'deki %70 iç bölge filtresi olmadan.
  /// Joker tap seçimlerinde kullanılır, tüm hücre alanı kabul edilir.
  (int, int)? _cellFromTap(Offset localPos) {
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

  void _onTapDown(TapDownDetails d) {
    if (_activeJokerType != null) return;
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(d.globalPosition);
    final pos = _cellFromTap(local);
    ref.read(gridProvider.notifier).clearSelection();
    if (pos != null) {
      ref.read(gridProvider.notifier).selectCell(pos.$1, pos.$2);
      ref.read(audioProvider.notifier).playSound(SoundType.letterSelect);
    }
  }

  void _onPanStart(DragStartDetails d) {
    // İlk hücre _onTapDown'da zaten seçildi — burada sadece gerekirse reset
    if (_activeJokerType != null) return;
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
      // allWords: main word + sub-words; subWords: only sub-words (for scoring/display)
      final allWords = ComboEngine(trie).findComboWords(word);
      final subWords = allWords.where((w) => w != word).toList();
      final score = ScoreCalculator().calculateTotalScore(word, subWords);

      debugPrint('\u2705 KABUL: "$word" \u2192 puan=$score, combo=${subWords.join(", ")}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('KABUL: $word (+$score puan)'),
            ],
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );

      ref.read(scoreProvider.notifier).addWordScore(score, subWords);
      ref.read(gameProvider.notifier).recordWord(word);
      ref.read(gameProvider.notifier).decrementMove();

      // combo sesi: ana kelime dahil 2+ kelime varsa (yani en az 1 alt kelime)
      if (allWords.length >= 2) {
        ref.read(audioProvider.notifier).playSound(SoundType.combo);
      } else {
        ref.read(audioProvider.notifier).playSound(SoundType.validWord);
      }

      // Play power activation sound if a power cell was triggered
      final usedPower = gridState.selectedCells.any((c) => c.powerType != PowerType.none);
      if (usedPower) {
        ref.read(audioProvider.notifier).playSound(SoundType.powerActivation);
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

      if (allWords.length >= 2) {
        _showComboPopup(allWords.length, score, subWords);
      }

      // Check solvability after grid changes
      _runSolvabilityCheck();

      final gameState = ref.read(gameProvider);
      if (gameState.isGameOver && !_gameOverHandled) {
        _gameOverHandled = true;
        final finalScore = ref.read(scoreProvider).totalScore;
        final goldEarned = (finalScore / AppConstants.goldPerScore).round();
        if (goldEarned > 0) {
          ref.read(playerProvider.notifier).addGold(goldEarned);
        }
        final wordCount = gameState.wordCount;
        final longestWord = gameState.longestWord;
        final durationSeconds = gameState.startTime != null
            ? DateTime.now().difference(gameState.startTime!).inSeconds
            : 0;
        ref.read(gameProvider.notifier).endGame(finalScore);
        Future.delayed(
          const Duration(milliseconds: 600),
          () => _showGameOverDialog(finalScore, goldEarned, wordCount, longestWord, durationSeconds),
        );
      }
    } else {
      debugPrint('\u274c RED: "$word" s\u00f6zl\u00fckte bulunamad\u0131');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cancel_outlined,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('GEÇERSİZ: $word'),
            ],
          ),
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
        final goldEarned = (finalScore / AppConstants.goldPerScore).round();
        if (goldEarned > 0) {
          ref.read(playerProvider.notifier).addGold(goldEarned);
        }
        final wordCount = gameState.wordCount;
        final longestWord = gameState.longestWord;
        final durationSeconds = gameState.startTime != null
            ? DateTime.now().difference(gameState.startTime!).inSeconds
            : 0;
        ref.read(gameProvider.notifier).endGame(finalScore);
        Future.delayed(
          const Duration(milliseconds: 600),
          () => _showGameOverDialog(finalScore, goldEarned, wordCount, longestWord, durationSeconds),
        );
      }
    }
  }

  void _shake() {
    _shakeController.forward(from: 0);
  }

  /// Grid otomatik karıştırıldığında (kelime kalmadığında) animasyon gösterir.
  void _triggerAutoShuffleAnimation(int gridSize) {
    setState(() {
      _jokerAffectedPositions = [];
      _jokerAnimationAsset  = 'assets/animations/joker_shuffle_grid2.json';
      _jokerAnimationScale  = gridSize / 2.0;
      _jokerSwapCenter      = Offset(gridSize / 2.0, gridSize / 2.0);
      _jokerIsFullGrid      = true;
      _jokerFullGridOffsetY = 7.0;
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _jokerAnimationAsset  = null;
          _jokerIsFullGrid      = false;
          _jokerFullGridOffsetY = 0.0;
        });
      }
    });
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

    // Jokers that don't need target: joker_select sesi bitince çalıştır (~1s)
    if (!JokerExecutor.requiresTarget(jokerType)) {
      final used = ref.read(jokerProvider.notifier).useJoker(jokerType);
      if (!used) return;
      if (jokerType == JokerType.fish) {
        final grid = ref.read(gridProvider).grid;
        final picked = JokerExecutor.pickFishCells(grid);
        setState(() {
          _fishPreviewCells = picked;
          _fishPreviewPositions = picked.map((c) => (c.row, c.col)).toList();
        });
      }
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) _executeJoker(jokerType, null, null);
      });
      return;
    }

    // Enter target selection mode
    setState(() {
      _activeJokerType = jokerType;
      _jokerFirstCell = null;
      _jokerSecondCell = null;
    });
  }

  void _onGridTapForJoker(TapUpDetails details) {
    if (_activeJokerType == null) return;
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(details.globalPosition);
    // Tap için %70 iç bölge filtresi yok — tüm hücre alanı kabul edilir
    final pos = _cellFromTap(local);
    if (pos == null) return;

    final cell = ref.read(gridProvider).grid.getCell(pos.$1, pos.$2);
    if (cell.isEmpty) return;

    if (JokerExecutor.requiresTwoTargets(_activeJokerType!)) {
      // Swap: iki hücre seç
      if (_jokerFirstCell == null) {
        // İlk hücreyi seç ve görsel geri bildirim ver
        setState(() => _jokerFirstCell = cell);
        ref.read(audioProvider.notifier).playSound(SoundType.letterSelect);
        return;
      }
      // Aynı hücreye tekrar tap → seçimi iptal et
      if (_jokerFirstCell!.row == cell.row && _jokerFirstCell!.col == cell.col) {
        setState(() => _jokerFirstCell = null);
        return;
      }
      // İkinci hücre komşu olmalı
      if (!_jokerFirstCell!.isAdjacentTo(cell)) {
        // Komşu değilse, tıklanan hücreyi yeni birinci hücre yap
        setState(() => _jokerFirstCell = cell);
        ref.read(audioProvider.notifier).playSound(SoundType.letterSelect);
        return;
      }
      final used = ref.read(jokerProvider.notifier).useJoker(_activeJokerType!);
      if (!used) { _cancelJokerMode(); return; }
      setState(() => _jokerSecondCell = cell);
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted) _executeJoker(_activeJokerType!, _jokerFirstCell, cell);
      });
    } else {
      // Tek hedef (Lolipop, Tekerlek)
      final used = ref.read(jokerProvider.notifier).useJoker(_activeJokerType!);
      if (!used) { _cancelJokerMode(); return; }
      if (_activeJokerType == JokerType.wheel) {
        final gridSize = ref.read(gridProvider).grid.size;
        setState(() {
          _wheelPreviewPositions = [
            for (int i = 0; i < gridSize; i++) (cell.row, i),
            for (int i = 0; i < gridSize; i++)
              if (i != cell.row) (i, cell.col),
          ];
        });
        _executeJoker(_activeJokerType!, cell, null);
      } else {
        _executeJoker(_activeJokerType!, cell, null);
      }
    }
  }

  void _pulseGrid() {
    setState(() => _gridScale = 1.05);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _gridScale = 1.0);
    });
  }

  void _executeJoker(String jokerType, Cell? target, Cell? second) {
    final jokerSound = switch (jokerType) {
      JokerType.fish     => SoundType.jokerFish,
      JokerType.wheel    => SoundType.jokerWheel,
      JokerType.lollipop => null, // Lottie onLoaded'da çalacak
      JokerType.swap     => SoundType.jokerSwap,
      JokerType.shuffle  => SoundType.jokerShuffle,
      JokerType.party    => SoundType.jokerParty,
      _                  => SoundType.jokerActivation,
    };
    if (jokerSound != null) {
      ref.read(audioProvider.notifier).playSound(jokerSound);
    }
    if (jokerType == JokerType.lollipop) {
      _onLottieLoaded = () =>
          ref.read(audioProvider.notifier).playSound(SoundType.jokerLollipop);
    } else {
      _onLottieLoaded = null;
    }
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
      preselectedCells: jokerType == JokerType.fish ? _fishPreviewCells : null,
    );
    if (jokerType == JokerType.fish) {
      setState(() {
        _fishPreviewPositions = [];
        _fishPreviewCells = [];
      });
    }

    // Direkt etkilenen hücre pozisyonlarını joker tipine göre hesapla
    final affected = _jokerDirectPositions(jokerType, grid, newGrid, target, second);

    // Her joker türü için lottie asset ata
    final animAsset = switch (jokerType) {
      JokerType.fish     => 'assets/animations/joker_bubble.json',
      JokerType.wheel    => 'assets/animations/joker_sweep_wave.json',
      JokerType.lollipop => 'assets/animations/joker_pop_smoke_p.json',
      JokerType.swap     => 'assets/animations/joker_swap.json',
      JokerType.shuffle  => 'assets/animations/joker_shuffle_spin.json',
      JokerType.party    => 'assets/animations/party_confetti1.json',
      _                  => null,
    };

    // Bazı jokerler için animasyon hücre boyutundan büyük gösterilir
    final animScale = switch (jokerType) {
      JokerType.fish     => 3.0,
      JokerType.lollipop => 3.0,
      JokerType.wheel    => 4.0,
      JokerType.swap     => 0.5,
      JokerType.shuffle  => grid.size / 2.0, // tüm gridi kaplar
      JokerType.party    => grid.size / 2.0, // parti de tüm grid
      _                  => 1.0,
    };

    // Swap + Shuffle + Party için iki hücrenin / grid merkezini hesapla
    Offset? animCenter;
    if (jokerType == JokerType.swap && target != null && second != null) {
      // İki hücrenin piksel merkezi
      animCenter = Offset(
        (target.col + second.col + 1) / 2.0,
        (target.row + second.row + 1) / 2.0,
      );
    } else if (jokerType == JokerType.shuffle || jokerType == JokerType.party) {
      // Tüm gridin merkezi
      animCenter = Offset(
        grid.size / 2.0,
        grid.size / 2.0,
      );
    }

    setState(() {
      _jokerAffectedPositions = (jokerType == JokerType.swap ||
              jokerType == JokerType.shuffle ||
              jokerType == JokerType.party ||
              jokerType == JokerType.wheel)
          ? []
          : affected;
      _jokerAnimationAsset = animAsset;
      _jokerAnimationScale = animScale;
      _jokerSwapCenter = jokerType == JokerType.wheel && target != null
          ? Offset(target.col + 0.5, target.row + 0.5)
          : animCenter;
      _jokerIsFullGrid = jokerType == JokerType.shuffle || jokerType == JokerType.party;
      _jokerIsParty = jokerType == JokerType.party;
      _jokerIsWheel = jokerType == JokerType.wheel;
      // Y ekseni kaydırma: pozitif = aşağı, negatif = yukarı (px)
      _jokerFullGridOffsetY = switch (jokerType) {
        JokerType.shuffle => 43.0,
        _                 => 0.0,
      };
    });
    // Animasyon bitiş süresi joker tipine göre belirlenir
    final hideDelay = switch (jokerType) {
      JokerType.party   => const Duration(milliseconds: 2000), // konfeti tam oynasın
      JokerType.wheel   => const Duration(milliseconds: 1500), // ses ~1.5s
      JokerType.shuffle => const Duration(milliseconds: 1150), // ses ~1.15s
      _                 => const Duration(milliseconds: 800),
    };
    Future.delayed(hideDelay, () {
      if (mounted) {
        setState(() {
          _jokerAffectedPositions = [];
          _wheelPreviewPositions = [];
          _jokerAnimationAsset = null;
          _jokerAnimationScale = 1.0;
          _jokerSwapCenter = null;
          _jokerIsFullGrid = false;
          _jokerIsParty = false;
          _jokerIsWheel = false;
          _jokerFullGridOffsetY = 0.0;
        });
      }
    });

    // Grid değişme gecikmesi — animasyon bitmeden grid değişmesin
    final gridDelay = switch (jokerType) {
      JokerType.wheel   => const Duration(milliseconds: 1500), // ses ~1.5s ile eşzamanlı
      JokerType.shuffle => const Duration(milliseconds: 1150),  // animasyon dönerken harfler değişsin
      JokerType.party   => const Duration(milliseconds: 500),
      _                 => const Duration(milliseconds: 300),
    };
    Future.delayed(gridDelay, () {
      if (!mounted) return;
      ref.read(gridProvider.notifier).setGrid(newGrid);
      _pulseGrid();
      _cancelJokerMode();
      _runSolvabilityCheck();
    });
  }

  List<(int, int)> _jokerDirectPositions(
    String jokerType,
    GridModel grid,
    GridModel newGrid,
    Cell? target,
    Cell? second,
  ) {
    final size = grid.size;
    switch (jokerType) {
      case JokerType.lollipop:
        return target != null ? [(target.row, target.col)] : [];
      case JokerType.wheel:
        if (target == null) return [];
        return [
          for (int i = 0; i < size; i++) (target.row, i),
          for (int i = 0; i < size; i++)
            if (i != target.row) (i, target.col),
        ];
      case JokerType.swap:
        return [
          if (target != null) (target.row, target.col),
          if (second != null) (second.row, second.col),
        ];
      case JokerType.fish:
        // Yeni grid'deki ID'leri topla; eski grid'de bu set'te olmayan = direkt silinen
        final newIds = newGrid.allCells.map((c) => c.id).toSet();
        return grid.allCells
            .where((c) => !newIds.contains(c.id))
            .map((c) => (c.row, c.col))
            .toList();
      case JokerType.shuffle:
      case JokerType.party:
        return [
          for (int r = 0; r < size; r++)
            for (int c = 0; c < size; c++) (r, c),
        ];
      default:
        return [];
    }
  }

  void _cancelJokerMode() {
    setState(() {
      _activeJokerType = null;
      _jokerFirstCell = null;
      _jokerSecondCell = null;
      _wheelPreviewPositions = [];
      _fishPreviewPositions = [];
      _fishPreviewCells = [];
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

  void _showGameOverDialog(
    int finalScore, [
    int goldEarned = 0,
    int wordCount = 0,
    String longestWord = '',
    int durationSeconds = 0,
  ]) {
    ref.read(audioProvider.notifier).playSound(SoundType.gameOver);
    if (goldEarned > 0) {
      ref.read(audioProvider.notifier).playSound(SoundType.spinningCoin);
    }
    final dur = durationSeconds < 60
        ? '${durationSeconds}s'
        : '${durationSeconds ~/ 60}d ${durationSeconds % 60}s';

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(160),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: _GameOverCard(
          finalScore: finalScore,
          goldEarned: goldEarned,
          wordCount: wordCount,
          longestWord: longestWord,
          duration: dur,
          onHome: () {
            Navigator.pop(context);
            context.go(AppRoutes.home);
          },
        ),
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
    final trieAsync = ref.watch(trieProvider);

    // Auto-shuffle animasyonu: kelime kalmayınca grid yenilendiğinde tetiklenir
    ref.listen<GridState>(gridProvider, (prev, next) {
      if (next.wasAutoShuffled && !(prev?.wasAutoShuffled ?? false)) {
        _triggerAutoShuffleAnimation(next.grid.size);
      }
    });

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

              // Market butonu — info box'ların hemen altında, sağ taraf
              Positioned(
                top: size.height * 0.225,
                right: size.width * 0.04,
                child: IntrinsicWidth(
                  child: Press3DButton(
                    onTap: () => context.push(AppRoutes.market),
                    height: 34,
                    color: const Color(0xFFF5EFE0),
                    depthColor: const Color(0xFF8B7355),
                    depth: 4,
                    rightDepth: 3,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EFE0),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black87, width: 1.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storefront_outlined, color: Colors.deepOrange, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'MARKET',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                  title: 'KALAN\nKELİME',
                  label: '${gridState.formableWordCount}',
                  titleSpacing: 0,
                  labelYOffset: -4,
                ),
              ),

              // Grid alanı
              Positioned(
                top: size.height * 0.305,
                left: size.width * 0.075,
                right: size.width * 0.075,
                child: AnimatedScale(
                  scale: _gridScale,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: GestureDetector(
                  onTapDown: _onTapDown,
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
                            jokerAffectedPositions: _jokerAffectedPositions,
                            lollipopSlamPos: _lollipopSlamPos,
                            lollipopSlamSize: _lollipopSlamSize,
                            wheelPreviewPositions: _wheelPreviewPositions,
                            fishPreviewPositions: _fishPreviewPositions,
                            jokerFirstCell: _jokerFirstCell,
                            jokerSecondCell: _jokerSecondCell,
                            jokerAnimationAsset: _jokerAnimationAsset,
                            jokerAnimationScale: _jokerAnimationScale,
                            jokerSwapCenter: _jokerSwapCenter,
                            jokerIsFullGrid: _jokerIsFullGrid,
                            jokerIsParty: _jokerIsParty,
                            jokerIsWheel: _jokerIsWheel,
                            jokerFullGridOffsetY: _jokerFullGridOffsetY,
                            onLottieLoaded: _onLottieLoaded,
                            loopLottie: _jokerIsWheel || (_jokerIsFullGrid && !_jokerIsParty),
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
              ),

              // Joker — Balık
              Positioned(
                bottom: size.height * 0.060,
                left: size.width * 0.02,
                right: size.width * 0.83,
                height: size.width * 0.105,
                child: _JokerBtn(assetPath: _jokerAssets[0], quantity: jokerState.getQuantity(_jokerTypes[0]), active: jokerState.getQuantity(_jokerTypes[0]) > 0, iconSize: 100, alignment: const Alignment(0.1, 0.05), isActiveMode: _activeJokerType == _jokerTypes[0], onPointerDown: () => ref.read(audioProvider.notifier).playSound(SoundType.jokerSelect), onTap: () => _onJokerTap(_jokerTypes[0])),
              ),
              // Joker — Tekerlek
              Positioned(
                bottom: size.height * 0.060,
                left: size.width * 0.18,
                right: size.width * 0.67,
                height: size.width * 0.105,
                child: _JokerBtn(assetPath: _jokerAssets[1], quantity: jokerState.getQuantity(_jokerTypes[1]), active: jokerState.getQuantity(_jokerTypes[1]) > 0, iconSize: 85, alignment: const Alignment(0, -0.18), isActiveMode: _activeJokerType == _jokerTypes[1], onPointerDown: () => ref.read(audioProvider.notifier).playSound(SoundType.jokerSelect), onTap: () => _onJokerTap(_jokerTypes[1])),
              ),
              // Joker — Lolipop
              Positioned(
                bottom: size.height * 0.060,
                left: size.width * 0.34,
                right: size.width * 0.51,
                height: size.width * 0.105,
                child: _JokerBtn(assetPath: _jokerAssets[2], quantity: jokerState.getQuantity(_jokerTypes[2]), active: jokerState.getQuantity(_jokerTypes[2]) > 0, iconSize: 80, alignment: const Alignment(0.00, -0.28), isActiveMode: _activeJokerType == _jokerTypes[2], onPointerDown: () => ref.read(audioProvider.notifier).playSound(SoundType.jokerSelect), onTap: () => _onJokerTap(_jokerTypes[2])),
              ),
              // Joker — Değiştir
              Positioned(
                bottom: size.height * 0.060,
                left: size.width * 0.50,
                right: size.width * 0.35,
                height: size.width * 0.105,
                child: _JokerBtn(assetPath: _jokerAssets[3], quantity: jokerState.getQuantity(_jokerTypes[3]), active: jokerState.getQuantity(_jokerTypes[3]) > 0, iconSize: 77, alignment: const Alignment(0.3, -0.2), isActiveMode: _activeJokerType == _jokerTypes[3], onPointerDown: () => ref.read(audioProvider.notifier).playSound(SoundType.jokerSelect), onTap: () => _onJokerTap(_jokerTypes[3])),
              ),
              // Joker — Karıştır
              Positioned(
                bottom: size.height * 0.060,
                left: size.width * 0.658,
                right: size.width * 0.19,
                height: size.width * 0.105,
                child: _JokerBtn(assetPath: _jokerAssets[4], quantity: jokerState.getQuantity(_jokerTypes[4]), active: jokerState.getQuantity(_jokerTypes[4]) > 0, iconSize: 40, alignment: Alignment.center, isActiveMode: _activeJokerType == _jokerTypes[4], onPointerDown: () => ref.read(audioProvider.notifier).playSound(SoundType.jokerSelect), onTap: () => _onJokerTap(_jokerTypes[4])),
              ),
              // Joker — Parti
              Positioned(
                bottom: size.height * 0.060,
                left: size.width * 0.817,
                right: size.width * 0.03,
                height: size.width * 0.105,
                child: _JokerBtn(assetPath: _jokerAssets[5], quantity: jokerState.getQuantity(_jokerTypes[5]), active: jokerState.getQuantity(_jokerTypes[5]) > 0, iconSize: 100, alignment: const Alignment(0.3, -0.45), isActiveMode: _activeJokerType == _jokerTypes[5], onPointerDown: () => ref.read(audioProvider.notifier).playSound(SoundType.jokerSelect), onTap: () => _onJokerTap(_jokerTypes[5])),
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
                  top: size.height * 0.215,
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

              // Çıkış butonu
              Positioned(
                top: size.height * 0.225,
                left: size.width * 0.04,
                child: Press3DButton(
                  onTap: _showExitDialog,
                  soundType: SoundType.uiTap,
                  height: 34,
                  width: 34,
                  color: const Color(0xFFF5EFE0),
                  depthColor: const Color(0xFF8B7355),
                  depth: 4,
                  rightDepth: 3,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EFE0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black87, width: 1.5),
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: Transform.scale(
                        scaleX: -1,
                        alignment: Alignment.center,
                        child: const Icon(Icons.logout, color: Colors.black87, size: 22),
                      ),
                    ),
                  ),
                ),
              ),

              // Müzik aç/kapat butonu — çıkış butonunun yanında
              Positioned(
                top: size.height * 0.225,
                left: size.width * 0.04 + 42,
                child: Consumer(
                  builder: (context, ref, _) {
                    final isBgmEnabled = ref.watch(audioProvider).isBgmEnabled;
                    return Press3DButton(
                      onTap: () => ref.read(audioProvider.notifier).toggleBgm(),
                      soundType: SoundType.uiTap,
                      height: 34,
                      width: 34,
                      color: const Color(0xFFF5EFE0),
                      depthColor: const Color(0xFF8B7355),
                      depth: 4,
                      rightDepth: 3,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5EFE0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black87, width: 1.5),
                        ),
                        child: Icon(
                          isBgmEnabled ? Icons.music_note : Icons.music_off,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                    );
                  },
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
  final List<(int, int)> jokerAffectedPositions;
  final Offset? lollipopSlamPos;
  final double lollipopSlamSize;
  /// Wheel joker önizleme: etkilenecek satır+sütun hücreleri — kırmızı vurgulu gösterilir.
  final List<(int, int)> wheelPreviewPositions;
  /// Fish joker önizleme: silinecek hücreler — mavi vurgulu gösterilir.
  final List<(int, int)> fishPreviewPositions;
  /// Swap joker'ın ilk seçilen hücresi — turuncu vurgulu gösterilir.
  final Cell? jokerFirstCell;
  /// Swap joker'ın ikinci seçilen hücresi — turuncu vurgulu gösterilir.
  final Cell? jokerSecondCell;
  /// Joker animasyonu için lottie asset yolu.
  /// null → eski turuncu flash, değer var → Lottie oynatılır.
  final String? jokerAnimationAsset;
  final double jokerAnimationScale;
  final Offset? jokerSwapCenter;
  final bool jokerIsFullGrid;
  final bool jokerIsParty;
  final bool jokerIsWheel;
  final double jokerFullGridOffsetY;
  final VoidCallback? onLottieLoaded;
  final bool loopLottie;

  const _GridWidget({
    required this.gridState,
    required this.overlay,
    this.explodingCells = const [],
    this.jokerAffectedPositions = const [],
    this.lollipopSlamPos,
    this.lollipopSlamSize = 0,
    this.wheelPreviewPositions = const [],
    this.fishPreviewPositions = const [],
    this.jokerFirstCell,
    this.jokerSecondCell,
    this.jokerAnimationAsset,
    this.jokerAnimationScale = 1.0,
    this.jokerSwapCenter,
    this.jokerIsFullGrid = false,
    this.jokerIsParty = false,
    this.jokerIsWheel = false,
    this.jokerFullGridOffsetY = 0.0,
    this.loopLottie = false,
    this.onLottieLoaded,
  });

  @override
  State<_GridWidget> createState() => _GridWidgetState();
}

class _GridWidgetState extends State<_GridWidget> with TickerProviderStateMixin {
  final Map<int, int> _displayRows = {};
  AnimationController? _lottieController;

  @override
  void didUpdateWidget(_GridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Joker animasyonu değişti — yeni controller başlat
    if (widget.jokerAnimationAsset != oldWidget.jokerAnimationAsset) {
      _lottieController?.stop();
      _lottieController?.dispose();
      if (widget.jokerAnimationAsset != null) {
        _lottieController = AnimationController(vsync: this);
      } else {
        _lottieController = null;
      }
    }

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
                  isJokerTarget: (widget.jokerFirstCell != null &&
                      widget.jokerFirstCell!.row == cell.row &&
                      widget.jokerFirstCell!.col == cell.col) ||
                      (widget.jokerSecondCell != null &&
                      widget.jokerSecondCell!.row == cell.row &&
                      widget.jokerSecondCell!.col == cell.col),
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

            // Fish joker önizleme: silinecek hücreler mavi vurgu
            for (final pos in widget.fishPreviewPositions)
              Positioned(
                left: pos.$2 * cellSize,
                top: pos.$1 * cellSize,
                width: cellSize,
                height: cellSize,
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('fish_preview_${pos.$1}_${pos.$2}'),
                    tween: Tween(begin: 0.0, end: 0.35),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeIn,
                    builder: (context, opacity, _) => Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha((opacity * 255).round()),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

            // Wheel joker önizleme: etkilenecek satır+sütun kırmızı vurgu
            for (final pos in widget.wheelPreviewPositions)
              Positioned(
                left: pos.$2 * cellSize,
                top: pos.$1 * cellSize,
                width: cellSize,
                height: cellSize,
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('wheel_preview_${pos.$1}_${pos.$2}'),
                    tween: Tween(begin: 0.0, end: 0.55),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeIn,
                    builder: (context, opacity, _) => Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((opacity * 255).round()),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

            // Joker etki alanı animasyonu
            for (final pos in widget.jokerAffectedPositions)
              Positioned(
                left: pos.$2 * cellSize,
                top: pos.$1 * cellSize,
                width: cellSize,
                height: cellSize,
                child: IgnorePointer(
                  child: widget.jokerAnimationAsset != null
                      // ── Lottie animasyonu ──────────────────────────────
                      ? OverflowBox(
                          maxWidth: cellSize * widget.jokerAnimationScale,
                          maxHeight: cellSize * widget.jokerAnimationScale,
                          alignment: Alignment.center,
                          child: Lottie.asset(
                            widget.jokerAnimationAsset!,
                            key: ValueKey('joker_lottie_${pos.$1}_${pos.$2}'),
                            controller: _lottieController,
                            onLoaded: (composition) {
                              if (_lottieController?.isDismissed ?? false) {
                                _lottieController?.duration = composition.duration;
                                if (widget.loopLottie) {
                                  _lottieController?.repeat();
                                } else {
                                  _lottieController?.forward(from: 0);
                                }
                                widget.onLottieLoaded?.call();
                              }
                            },
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stack) {
                              debugPrint('⚠️ Lottie yüklenemedi: ${widget.jokerAnimationAsset} → $error');
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 1.0, end: 0.0),
                                duration: const Duration(milliseconds: 450),
                                curve: Curves.easeOut,
                                builder: (context, opacity, _) => Container(
                                  margin: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withAlpha((opacity * 180).round()),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      // ── Eski turuncu flash (fallback) ─────────────────
                      : TweenAnimationBuilder<double>(
                          key: ValueKey('joker_flash_${pos.$1}_${pos.$2}'),
                          tween: Tween(begin: 1.0, end: 0.0),
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOut,
                          builder: (context, opacity, _) => Container(
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha((opacity * 180).round()),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                ),
              ),

            // Swap jokeri: iki hücrenin ortasında tek konumlu animasyon
            if (widget.jokerSwapCenter != null &&
                widget.jokerAnimationAsset != null &&
                !widget.jokerIsFullGrid &&
                !widget.jokerIsWheel)
              Positioned(
                left: widget.jokerSwapCenter!.dx * cellSize - (cellSize * widget.jokerAnimationScale),
                top:  widget.jokerSwapCenter!.dy * cellSize - (cellSize * widget.jokerAnimationScale),
                width:  cellSize * widget.jokerAnimationScale * 2,
                height: cellSize * widget.jokerAnimationScale * 2,
                child: IgnorePointer(
                  child: Lottie.asset(
                    widget.jokerAnimationAsset!,
                    key: const ValueKey('joker_swap_center'),
                    controller: _lottieController,
                    onLoaded: (composition) {
                      _lottieController
                        ?..duration = composition.duration * 2
                        ..forward(from: 0);
                    },
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) {
                      debugPrint('⚠️ Swap Lottie yüklenemedi: $error');
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),

            // Wheel — yatay: tıklanan hücrenin satırını tam kapsar
            if (widget.jokerSwapCenter != null &&
                widget.jokerAnimationAsset != null &&
                widget.jokerIsWheel)
              Positioned(
                left: 0,
                top: widget.jokerSwapCenter!.dy * cellSize - cellSize * 1.25,
                width: widget.gridState.grid.size * cellSize,
                height: cellSize * 2.5,
                child: IgnorePointer(
                  child: Lottie.asset(
                    widget.jokerAnimationAsset!,
                    key: const ValueKey('wheel_horizontal'),
                    controller: _lottieController,
                    onLoaded: (composition) {
                      if (_lottieController?.isDismissed ?? false) {
                        _lottieController?.duration = composition.duration;
                        widget.loopLottie
                            ? _lottieController?.repeat()
                            : _lottieController?.forward(from: 0);
                      }
                    },
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),

            // Wheel — dikey: tıklanan hücrenin sütununu tam kapsar (90° döndürülmüş)
            if (widget.jokerSwapCenter != null &&
                widget.jokerAnimationAsset != null &&
                widget.jokerIsWheel)
              Positioned(
                left: widget.jokerSwapCenter!.dx * cellSize - cellSize * 1.25,
                top: 0,
                width: cellSize * 2.5,
                height: widget.gridState.grid.size * cellSize,
                child: IgnorePointer(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Lottie.asset(
                      widget.jokerAnimationAsset!,
                      key: const ValueKey('wheel_vertical'),
                      controller: _lottieController,
                      onLoaded: (composition) {
                        if (_lottieController?.isDismissed ?? false) {
                          _lottieController?.duration = composition.duration;
                          widget.loopLottie
                              ? _lottieController?.repeat()
                              : _lottieController?.forward(from: 0);
                        }
                      },
                      fit: BoxFit.fill,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

            // Shuffle: tek büyük merkez animasyonu + arkaplan
            if (widget.jokerAnimationAsset != null &&
                widget.jokerIsFullGrid &&
                !widget.jokerIsParty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: const Color(0xFF2A1A0A).withAlpha(100),
                    child: Transform.translate(
                      offset: Offset(0, widget.jokerFullGridOffsetY),
                      child: Lottie.asset(
                        widget.jokerAnimationAsset!,
                        key: const ValueKey('joker_full_grid'),
                        controller: _lottieController,
                        onLoaded: (composition) {
                          _lottieController?.duration = composition.duration;
                          widget.loopLottie
                              ? _lottieController?.repeat()
                              : _lottieController?.forward(from: 0);
                        },
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),

            // Party: 5 noktadan konfeti — her biri bağımsız
            if (widget.jokerAnimationAsset != null && widget.jokerIsParty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    children: [
                      for (final entry in const [
                        (Alignment.topLeft,     'tl'),
                        (Alignment.topRight,    'tr'),
                        (Alignment.bottomLeft,  'bl'),
                        (Alignment.bottomRight, 'br'),
                        (Alignment.center,      'c'),
                      ])
                        Positioned.fill(
                          child: Lottie.asset(
                            widget.jokerAnimationAsset!,
                            key: ValueKey('party_${entry.$2}'),
                            animate: true,
                            repeat: false,
                            fit: BoxFit.cover,
                            alignment: entry.$1,
                          ),
                        ),
                    ],
                  ),
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
  /// Swap joker için seçilen ilk hücre ise true — turuncu vurgu gösterilir.
  final bool isJokerTarget;

  const _CellTile({
    required this.cell,
    required this.isSelected,
    required this.selectionIndex,
    required this.totalSelected,
    this.isJokerTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = const Color(0xFFF5F0E8);
    Color textColor = Colors.black87;

    if (isJokerTarget) {
      bgColor = const Color(0xFFFF8C00);
      textColor = Colors.white;
    } else if (isSelected) {
      bgColor = const Color(0xFF4A90D9);
      textColor = Colors.white;
    }

    if (cell.isEmpty) bgColor = Colors.transparent;

    final bool isPressed = isSelected || isJokerTarget;
    final shadowColor = isJokerTarget
        ? const Color(0xFF994400)
        : isSelected
            ? const Color(0xFF1A3D5C)
            : const Color(0xFF5A4A3A);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isJokerTarget
              ? const Color(0xFFCC5500)
              : isSelected
                  ? const Color(0xFF2C5F8A)
                  : Colors.black38,
          width: (isSelected || isJokerTarget) ? 2 : 1,
        ),
        boxShadow: cell.isEmpty
            ? []
            : isPressed
                ? [] // basılı → shadow yok, içe battı hissi
                : [
                    BoxShadow(
                      color: shadowColor,
                      offset: const Offset(3, 3),
                      blurRadius: 0,
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
                    right: 0,
                    top: 0,
                    child: Icon(
                      _powerIcon(cell.powerType),
                      size: 14,
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
        return Icons.emergency;
      case PowerType.columnClear:
        return Icons.swap_vert;
      case PowerType.megaBlast:
        return Icons.stars;
      case PowerType.none:
        return Icons.circle;
    }
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String label;
  final double titleSpacing;
  /// Sayıyı dikey eksen üzerinde kaydırır (px). Negatif = yukarı.
  final double labelYOffset;
  const _InfoBox({
    required this.title,
    required this.label,
    this.titleSpacing = 1,
    this.labelYOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF3B2A1A),
            offset: Offset(5, 5),
            blurRadius: 0,
          ),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/info_box_bg.png'),
          fit: BoxFit.fill,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: titleSpacing),
          Transform.translate(
            offset: Offset(0, labelYOffset),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JokerBtn extends StatefulWidget {
  final String assetPath;
  final int quantity;
  final bool active;
  final double? iconSize;
  final Alignment alignment;
  final VoidCallback? onTap;
  final VoidCallback? onPointerDown;
  final bool isActiveMode;

  const _JokerBtn({
    required this.assetPath,
    required this.quantity,
    required this.active,
    this.iconSize,
    this.alignment = Alignment.center,
    this.onTap,
    this.onPointerDown,
    this.isActiveMode = false,
  });

  @override
  State<_JokerBtn> createState() => _JokerBtnState();
}

class _JokerBtnState extends State<_JokerBtn> {
  bool _localPressed = false;

  bool get _showOrange => widget.isActiveMode || _localPressed;

  Widget _buildImage() => OverflowBox(
        alignment: widget.alignment,
        minWidth: 0,
        minHeight: 0,
        maxWidth: widget.iconSize ?? double.infinity,
        maxHeight: widget.iconSize ?? double.infinity,
        child: Image.asset(widget.assetPath, width: widget.iconSize, height: widget.iconSize, fit: BoxFit.contain),
      );

  Widget _buildFaceContainer() => Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/joker_slot_bg.png'),
            fit: BoxFit.cover,
            colorFilter: _showOrange
                ? ColorFilter.mode(Colors.orange.withAlpha(120), BlendMode.srcATop)
                : null,
          ),
        ),
        child: _buildImage(),
      );

  Widget _buildBadge() => Positioned(
        top: -4,
        right: -4,
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
          child: Center(
            child: Text(
              '${widget.quantity}',
              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Opacity(
        opacity: 0.35,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildFaceContainer(),
            if (widget.quantity > 0) _buildBadge(),
          ],
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Listener(
          onPointerDown: (_) {
            setState(() => _localPressed = true);
            widget.onPointerDown?.call();
          },
          onPointerUp: (_) => setState(() => _localPressed = false),
          onPointerCancel: (_) => setState(() => _localPressed = false),
          child: LayoutBuilder(
            builder: (_, constraints) => Press3DButton(
              onTap: widget.onTap ?? () {},
              height: constraints.maxHeight,
              width: constraints.maxWidth,
              color: const Color(0xFFC8BCA8),
              depthColor: const Color(0xFF3B2A1A),
              depth: 5,
              rightDepth: 5,
              borderRadius: BorderRadius.circular(19),
              forcePressed: widget.isActiveMode,
              playSoundOnTap: false,
              child: _buildFaceContainer(),
            ),
          ),
        ),
        if (widget.quantity > 0) _buildBadge(),
      ],
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
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        subText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
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



// ─────────────────────────────────────────────────────────
// GAME OVER CARD
// ─────────────────────────────────────────────────────────
class _GameOverCard extends StatefulWidget {
  final int finalScore;
  final int goldEarned;
  final int wordCount;
  final String longestWord;
  final String duration;
  final VoidCallback onHome;

  const _GameOverCard({
    required this.finalScore,
    required this.goldEarned,
    required this.wordCount,
    required this.longestWord,
    required this.duration,
    required this.onHome,
  });

  @override
  State<_GameOverCard> createState() => _GameOverCardState();
}

class _GameOverCardState extends State<_GameOverCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Opacity(
        opacity: _fadeIn.value,
        child: Transform.translate(offset: Offset(0, _slideUp.value), child: child),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── ana kağıt kart ──
          Container(
            margin: const EdgeInsets.only(top: 22),
            decoration: BoxDecoration(
              color: const Color(0xFFF5EFE0),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2A1E0F), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(200),
                  blurRadius: 20,
                  offset: const Offset(4, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 28),

                // ── skor kutusu (SKOR/HAMLE kutularıyla aynı stil) ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE5CE),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF2A1E0F), width: 2),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'TOPLAM PUAN',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7A6B52),
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.finalScore}',
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1008),
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── altın kazanımı ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE5CE),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF2A1E0F), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.monetization_on_rounded,
                          color: widget.goldEarned > 0
                              ? const Color(0xFFD4A017)
                              : const Color(0xFF7A6B52),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.goldEarned > 0
                              ? '+ ${widget.goldEarned} ALTIN KAZANDIN'
                              : '0 ALTIN KAZANILDI',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: widget.goldEarned > 0
                                ? const Color(0xFF3D2E1A)
                                : const Color(0xFF7A6B52),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 3 istatistik kutusu ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _GoStatBox(
                        label: 'KELIME',
                        value: '${widget.wordCount}',
                      ),
                      const SizedBox(width: 8),
                      _GoStatBox(
                        label: 'SÜRE',
                        value: widget.duration,
                      ),
                      const SizedBox(width: 8),
                      _GoStatBox(
                        label: 'EN UZUN',
                        value: widget.longestWord.isEmpty
                            ? '-'
                            : widget.longestWord.toUpperCase(),
                        small: widget.longestWord.length > 5,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Ana Menü butonu (oyunun kırmızı arka planıyla uyumlu koyu ton) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: GestureDetector(
                    onTap: widget.onHome,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C0A0A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF2A1E0F), width: 2),
                        boxShadow: [
                          const BoxShadow(
                            color: Color(0xFF2A0000),
                            offset: Offset(0, 5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Text(
                        'ANA MENÜ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF5EFE0),
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── üstteki yırtık bant başlık (Stack'te öne çıkıyor) ──
          Positioned(
            top: 0,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EFE0),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF2A1E0F), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(160),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: const Text(
                'OYUN BİTTİ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5C0A0A),
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoStatBox extends StatelessWidget {
  final String label;
  final String value;
  final bool small;

  const _GoStatBox({
    required this.label,
    required this.value,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE5CE),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF2A1E0F), width: 1.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: small ? 11 : 15,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1A1008),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: Color(0xFF7A6B52),
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

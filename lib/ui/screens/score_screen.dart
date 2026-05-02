import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/game_record.dart';
import '../../logic/providers/game_provider.dart';

// ─────────────────────────────────────────────
// Palette / constants matching the game theme
// ─────────────────────────────────────────────
const _kCream = Color(0xFFF5EFE0);
const _kCreamy = Color(0xFFEDE5CE);
const _kPaper = Color(0xFFD6C9AA);
const _kInk = Color(0xFF1A1008);
const _kInkLight = Color(0xFF3D2E1A);
const _kInkFaint = Color(0xFF7A6B52);
const _kRed = Color(0xFF8B0000);
const _kGold = Color(0xFFD4A017);
const _kBorder = Color(0xFF2A1E0F);

// ─────────────────────────────────────────────
// Score Screen
// ─────────────────────────────────────────────
class ScoreScreen extends ConsumerWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final records = ref.watch(gameRecordsProvider);

    // ── aggregate stats ──
    final totalGames = records.length;
    final bestScore = records.isEmpty
        ? 0
        : records.map((r) => r.score).reduce((a, b) => a > b ? a : b);
    final totalWords = records.isEmpty
        ? 0
        : records.map((r) => r.wordCount).reduce((a, b) => a + b);
    final avgScore = totalGames > 0
        ? (records.map((r) => r.score).reduce((a, b) => a + b) / totalGames)
            .round()
        : 0;
    final longestWord = records.isEmpty
        ? '-'
        : records
            .map((r) => r.longestWord)
            .where((w) => w.isNotEmpty)
            .fold<String>('', (a, b) => b.length > a.length ? b : a);
    final totalSeconds = records.isEmpty
        ? 0
        : records.map((r) => r.durationSeconds).reduce((a, b) => a + b);

    return Scaffold(
      body: Stack(
        children: [
          // ── red textured background ──
          Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/score_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ── red noise overlay for depth ──
          Container(
            width: size.width,
            height: size.height,
            color: const Color(0x22000000),
          ),

          SafeArea(
            child: Column(
              children: [
                // ══════════════════════════════
                // TOP BAR – torn-paper title
                // ══════════════════════════════
                _TopBar(),

                // ══════════════════════════════
                // SCROLLABLE BODY
                // ══════════════════════════════
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                        size.width * 0.04, 4, size.width * 0.04, 24),
                    children: [
                      // ── 6-stat summary grid ──
                      _SummaryPanel(
                        totalGames: totalGames,
                        bestScore: bestScore,
                        totalWords: totalWords,
                        avgScore: avgScore,
                        longestWord:
                            longestWord.isEmpty ? '-' : longestWord,
                        totalTime: _fmtDuration(totalSeconds),
                      ),

                      const SizedBox(height: 14),

                      // ── section divider ──
                      const _TornDivider(label: 'GEÇMİŞ OYUNLAR'),

                      const SizedBox(height: 10),

                      // ── per-game cards ──
                      if (records.isEmpty)
                        _EmptyState()
                      else
                        ...records.map(
                          (r) => _GameCard(record: r),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDuration(int s) {
    if (s < 60) return '${s}s';
    final m = s ~/ 60;
    final sec = s % 60;
    if (m < 60) return '${m}d ${sec}s';
    final h = m ~/ 60;
    return '${h}sa ${m % 60}d';
  }
}

// ─────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // torn-paper title card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 52),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: _kCream,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _kBorder, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 6,
                  offset: const Offset(3, 4),
                ),
              ],
            ),
            child: const Text(
              'SKOR TABLOSU',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _kInk,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // back button (left)
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kInk,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kPaper, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(2, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: _kCream,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SUMMARY PANEL (6 stat cards, 3-per-row)
// ─────────────────────────────────────────────
class _SummaryPanel extends StatelessWidget {
  final int totalGames;
  final int bestScore;
  final int totalWords;
  final int avgScore;
  final String longestWord;
  final String totalTime;

  const _SummaryPanel({
    required this.totalGames,
    required this.bestScore,
    required this.totalWords,
    required this.avgScore,
    required this.longestWord,
    required this.totalTime,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData('Toplam\nOyun', '$totalGames', Icons.sports_esports_outlined),
      _StatData('En Yüksek\nPuan', '$bestScore', Icons.emoji_events_outlined),
      _StatData('Toplam\nKelime', '$totalWords', Icons.text_fields_outlined),
      _StatData('Ortalama\nSkor', '$avgScore', Icons.analytics_outlined),
      _StatData('En Uzun\nKelime', longestWord, Icons.straighten_outlined),
      _StatData('Toplam\nSüre', totalTime, Icons.timer_outlined),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kInk.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kPaper.withValues(alpha: 0.3), width: 1),
      ),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final cardW = (constraints.maxWidth - 16) / 3;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stats
                .map((s) => SizedBox(
                      width: cardW,
                      child: _StatCard(data: s),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  const _StatData(this.label, this.value, this.icon);
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: _kCream,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 18, color: _kInkFaint),
          const SizedBox(height: 5),
          Text(
            data.value,
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _kInk,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 3),
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _kInkFaint,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TORN PAPER DIVIDER
// ─────────────────────────────────────────────
class _TornDivider extends StatelessWidget {
  final String label;
  const _TornDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _kPaper.withValues(alpha: 0.6)],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _kInk,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: _kPaper.withValues(alpha: 0.5), width: 1),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _kCream,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kPaper.withValues(alpha: 0.6), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: _kCream,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(3, 4),
              ),
            ],
          ),
          child: const Column(
            children: [
              Icon(Icons.sports_esports_outlined,
                  size: 36, color: _kInkFaint),
              SizedBox(height: 8),
              Text(
                'Henüz oyun kaydı yok.',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 14,
                  color: _kInkLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'İlk oyununu oyna ve burada görün!',
                style: TextStyle(
                  fontSize: 11,
                  color: _kInkFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// GAME RECORD CARD
// ─────────────────────────────────────────────
class _GameCard extends StatelessWidget {
  final GameRecord record;
  const _GameCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${record.date.day.toString().padLeft(2, '0')}.'
        '${record.date.month.toString().padLeft(2, '0')}.'
        '${record.date.year}';
    final gridLabel = '${record.gridSize}×${record.gridSize}';
    final dur = _fmt(record.durationSeconds);

    // difficulty colour accent
    final accentColor = record.gridSize == 6
        ? const Color(0xFFB71C1C) // hard – red
        : record.gridSize == 8
            ? const Color(0xFFE65100) // medium – orange
            : const Color(0xFF1B5E20); // easy – green

    final diffLabel = record.gridSize == 6
        ? 'ZOR'
        : record.gridSize == 8
            ? 'ORTA'
            : 'KOLAY';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kCream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 5,
            offset: const Offset(3, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── coloured left accent bar + game # ──
              Container(
                width: 52,
                color: accentColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '#${record.gameNumber}',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        diffLabel,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── card body ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // date + grid label
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 11, color: _kInkFaint),
                              const SizedBox(width: 4),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 11,
                                  color: _kInkLight,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _kInk,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              gridLabel,
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _kCream,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _MiniStat(
                              icon: Icons.star_rounded,
                              value: '${record.score}',
                              color: _kGold),
                          _MiniStat(
                              icon: Icons.text_fields,
                              value: '${record.wordCount} kelime',
                              color: _kInkLight),
                          _MiniStat(
                              icon: Icons.timer_outlined,
                              value: dur,
                              color: _kInkLight),
                        ],
                      ),

                      // longest word
                      if (record.longestWord.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kCreamy,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: _kPaper, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.straighten_outlined,
                                  size: 11, color: _kInkFaint),
                              const SizedBox(width: 4),
                              const Text(
                                'En uzun: ',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _kInkFaint,
                                  fontFamily: 'Courier',
                                ),
                              ),
                              Text(
                                record.longestWord.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: _kInk,
                                  fontFamily: 'Courier',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}d ${s}s';
  }
}

// ─────────────────────────────────────────────
// MINI STAT (icon + label)
// ─────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color == _kGold ? _kInk : _kInkLight,
          ),
        ),
      ],
    );
  }
}
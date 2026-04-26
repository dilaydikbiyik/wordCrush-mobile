import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/game_record.dart';
import '../../logic/providers/game_provider.dart';

/// Displays overall performance stats (top) and per-game cards (bottom).
///
/// Loads GameRecord list from ObjectBoxService and computes summary stats.
class ScoreScreen extends ConsumerWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final db = ref.read(objectBoxServiceProvider);
    final records = db.getAllGameRecords(); // sorted newest first

    // Compute summary stats
    final totalGames = records.length;
    final bestScore =
        records.isEmpty ? 0 : records.map((r) => r.score).reduce((a, b) => a > b ? a : b);
    final totalWords =
        records.isEmpty ? 0 : records.map((r) => r.wordCount).reduce((a, b) => a + b);
    final avgScore = totalGames > 0
        ? (records.map((r) => r.score).reduce((a, b) => a + b) / totalGames).round()
        : 0;
    final longestWord = records.isEmpty
        ? '-'
        : records
            .map((r) => r.longestWord)
            .where((w) => w.isNotEmpty)
            .fold<String>('', (a, b) => b.length > a.length ? b : a);
    final totalMoves = records.isEmpty
        ? 0
        : records.map((r) => r.durationSeconds).reduce((a, b) => a + b);

    return Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            // Background
            Image.asset(
              'assets/images/score_bg.png',
              fit: BoxFit.fill,
              width: size.width,
              height: size.height,
            ),

            // Back button
            Positioned(
              top: size.height * 0.05,
              left: size.width * 0.04,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 22),
                ),
              ),
            ),

            // Title
            Positioned(
              top: size.height * 0.055,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  'Skor Tablosu',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            // Stats cards (top)
            Positioned(
              top: size.height * 0.11,
              left: size.width * 0.04,
              right: size.width * 0.04,
              child: _StatsGrid(
                totalGames: totalGames,
                bestScore: bestScore,
                totalWords: totalWords,
                avgScore: avgScore,
                longestWord: longestWord.isEmpty ? '-' : longestWord,
                totalTime: _formatDuration(totalMoves),
              ),
            ),

            // Game records list (bottom)
            Positioned(
              top: size.height * 0.42,
              left: size.width * 0.04,
              right: size.width * 0.04,
              bottom: size.height * 0.02,
              child: records.isEmpty
                  ? const Center(
                      child: Text(
                        'Henüz oyun kaydı yok',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: records.length,
                      itemBuilder: (_, i) =>
                          _GameRecordCard(record: records[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) return '${totalSeconds}s';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes < 60) return '${minutes}d ${seconds}s';
    final hours = minutes ~/ 60;
    return '${hours}sa ${minutes % 60}d';
  }
}

/// 2×3 grid of summary statistic cards.
class _StatsGrid extends StatelessWidget {
  final int totalGames;
  final int bestScore;
  final int totalWords;
  final int avgScore;
  final String longestWord;
  final String totalTime;

  const _StatsGrid({
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
      ('Toplam Oyun', '$totalGames', Icons.games_outlined),
      ('En Yüksek', '$bestScore', Icons.emoji_events_outlined),
      ('Toplam Kelime', '$totalWords', Icons.text_fields),
      ('Ort. Skor', '$avgScore', Icons.analytics_outlined),
      ('En Uzun', longestWord, Icons.straighten),
      ('Toplam Süre', totalTime, Icons.timer_outlined),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: stats
          .map((s) => SizedBox(
                width: (MediaQuery.of(context).size.width - 40) / 3,
                child: _StatCard(title: s.$1, value: s.$2, icon: s.$3),
              ))
          .toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFE0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black87, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              fontFamily: 'Courier',
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A single game record card with typewriter-style font.
class _GameRecordCard extends StatelessWidget {
  final GameRecord record;

  const _GameRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${record.date.day.toString().padLeft(2, '0')}.'
        '${record.date.month.toString().padLeft(2, '0')}.'
        '${record.date.year}';
    final durationStr = _formatGameDuration(record.durationSeconds);
    final gridLabel = '${record.gridSize}×${record.gridSize}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFE0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black87, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Game number badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#${record.gameNumber}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Courier',
                      ),
                    ),
                    Text(
                      gridLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RecordStat(icon: Icons.star, value: '${record.score}'),
                    _RecordStat(
                        icon: Icons.text_fields, value: '${record.wordCount}'),
                    _RecordStat(icon: Icons.timer, value: durationStr),
                  ],
                ),
                if (record.longestWord.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'En uzun: ${record.longestWord}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatGameDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}d ${s}s';
  }
}

class _RecordStat extends StatelessWidget {
  final IconData icon;
  final String value;

  const _RecordStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.black54),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            fontFamily: 'Courier',
          ),
        ),
      ],
    );
  }
}

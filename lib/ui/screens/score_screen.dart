import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/game_record.dart';
import '../../logic/providers/game_provider.dart';

class ScoreScreen extends ConsumerWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final records = ref.watch(gameRecordsProvider);

    final totalGames = records.length;
    final bestScore = records.isEmpty
        ? 0
        : records.map((r) => r.score).reduce((a, b) => a > b ? a : b);
    final totalWords = records.isEmpty
        ? 0
        : records.map((r) => r.wordCount).reduce((a, b) => a + b);
    final avgScore = totalGames > 0
        ? (records.map((r) => r.score).reduce((a, b) => a + b) / totalGames).round()
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
          // Background
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

          // Scrollable content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.04, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 22),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5EFE0),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: Colors.black87, width: 1.5),
                            ),
                            child: const Text(
                              'Skor Tablosu',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                                fontFamily: 'Courier',
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.04, vertical: 8),
                    children: [
                      // 6 stat cards — 2 per row
                      _StatsGrid(
                        totalGames: totalGames,
                        bestScore: bestScore,
                        totalWords: totalWords,
                        avgScore: avgScore,
                        longestWord: longestWord.isEmpty ? '-' : longestWord,
                        totalTime: _formatDuration(totalSeconds),
                      ),

                      const SizedBox(height: 12),

                      // Game record cards
                      if (records.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5EFE0),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.black87, width: 1.5),
                              ),
                              child: const Text(
                                'Henüz oyun kaydı yok.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black54,
                                  fontFamily: 'Courier',
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        ...records.map((r) => _GameRecordCard(record: r)),
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

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) return '${totalSeconds}s';
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    if (m < 60) return '${m}d ${s}s';
    final h = m ~/ 60;
    return '${h}sa ${m % 60}d';
  }
}

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
      children: stats.map((s) {
        final cardWidth = (MediaQuery.of(context).size.width -
                MediaQuery.of(context).size.width * 0.08 -
                16) /
            3;
        return SizedBox(
          width: cardWidth,
          child: _StatCard(title: s.$1, value: s.$2, icon: s.$3),
        );
      }).toList(),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(2, 3),
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

class _GameRecordCard extends StatelessWidget {
  final GameRecord record;

  const _GameRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${record.date.day.toString().padLeft(2, '0')}.'
        '${record.date.month.toString().padLeft(2, '0')}.'
        '${record.date.year}';
    final gridLabel = '${record.gridSize}×${record.gridSize}';
    final dur = _fmt(record.durationSeconds);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFE0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black87, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 3,
            offset: Offset(2, 3),
          ),
        ],
      ),
      child: Row(
        children: [
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
                    _Stat(icon: Icons.star, value: '${record.score}'),
                    _Stat(icon: Icons.text_fields, value: '${record.wordCount}'),
                    _Stat(icon: Icons.timer, value: dur),
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

  String _fmt(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}d ${s}s';
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;

  const _Stat({required this.icon, required this.value});

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

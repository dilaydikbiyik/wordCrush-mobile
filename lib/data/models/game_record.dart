import 'package:objectbox/objectbox.dart';

/// One completed game session stored persistently.
@Entity()
class GameRecord {
  @Id()
  int id = 0;

  int gameNumber;

  @Property(type: PropertyType.date)
  DateTime date;

  /// Grid dimension (6, 8, or 10).
  int gridSize;

  int score;
  int wordCount;
  String longestWord;

  /// Total game duration in seconds.
  int durationSeconds;

  GameRecord({
    this.gameNumber = 0,
    DateTime? date,
    this.gridSize = 10,
    this.score = 0,
    this.wordCount = 0,
    this.longestWord = '',
    this.durationSeconds = 0,
  }) : date = date ?? DateTime.now();
}

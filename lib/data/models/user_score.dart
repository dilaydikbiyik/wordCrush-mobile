import 'package:isar/isar.dart';

part 'user_score.g.dart';

@Collection()
class UserScore {
  Id id = Isar.autoIncrement;
  int score = 0;
  DateTime achievedAt = DateTime.now();
}

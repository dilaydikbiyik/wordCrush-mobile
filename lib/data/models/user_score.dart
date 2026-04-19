import 'package:objectbox/objectbox.dart';

@Entity()
class UserScore {
  @Id()
  int id = 0;
  int score;
  DateTime achievedAt;

  UserScore({
    this.score = 0,
    DateTime? achievedAt,
  }) : achievedAt = achievedAt ?? DateTime.now();
}

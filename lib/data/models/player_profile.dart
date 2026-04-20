import 'package:objectbox/objectbox.dart';

/// Persistent player data: username and gold balance.
@Entity()
class PlayerProfile {
  @Id()
  int id = 0;

  String username;
  int goldBalance;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  PlayerProfile({
    this.username = '',
    this.goldBalance = 5000,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

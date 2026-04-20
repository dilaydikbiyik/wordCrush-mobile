import 'package:objectbox/objectbox.dart';

/// Joker type identifiers — matches JokerExecutor switch cases.
class JokerType {
  static const String fish = 'fish';
  static const String wheel = 'wheel';
  static const String lollipop = 'lollipop';
  static const String swap = 'swap';
  static const String shuffle = 'shuffle';
  static const String party = 'party';
}

/// How many of each joker type the player owns.
@Entity()
class JokerInventory {
  @Id()
  int id = 0;

  /// One of the [JokerType] string constants.
  String jokerType;
  int quantity;

  JokerInventory({
    this.jokerType = '',
    this.quantity = 0,
  });
}

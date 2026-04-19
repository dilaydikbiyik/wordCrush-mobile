import 'package:objectbox/objectbox.dart';

@Entity()
class SettingsModel {
  @Id()
  int id = 0;
  bool soundEnabled;
  int currentLevel;

  SettingsModel({
    this.soundEnabled = true,
    this.currentLevel = 1,
  });
}

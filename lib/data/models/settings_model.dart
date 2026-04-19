import 'package:isar/isar.dart';

part 'settings_model.g.dart';

@Collection()
class SettingsModel {
  Id id = Isar.autoIncrement;
  bool soundEnabled = true;
  int currentLevel = 1;
}

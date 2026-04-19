import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/settings_model.dart';
import '../models/user_score.dart';

class IsarService {
  late final Isar _isar;

  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    _isar = await Isar.open([UserScoreSchema, SettingsModelSchema], directory: dir.path);
  }

  Future<void> saveUserScore(UserScore score) async {
    await _isar.writeTxn(() async {
      await _isar.userScores.put(score);
    });
  }

  Future<List<UserScore>> fetchTopScores() async {
    return await _isar.userScores.where().sortByScoreDesc().findAll();
  }

  Future<SettingsModel?> loadSettings() async {
    return await _isar.settingsModels.where().findFirst();
  }

  Future<void> saveSettings(SettingsModel settings) async {
    await _isar.writeTxn(() async {
      await _isar.settingsModels.put(settings);
    });
  }
}

import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';

import '../../objectbox.g.dart';
import '../models/settings_model.dart';
import '../models/user_score.dart';

class ObjectBoxService {
  late final Store _store;
  late final Box<SettingsModel> _settingsBox;
  late final Box<UserScore> _scoreBox;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _store = Store(getObjectBoxModel(), directory: dir.path);
    _settingsBox = Box<SettingsModel>(_store);
    _scoreBox = Box<UserScore>(_store);
  }

  Future<void> saveSettings(SettingsModel settings) async {
    _settingsBox.put(settings);
  }

  SettingsModel? loadSettings() {
    return _settingsBox.getAll().isNotEmpty ? _settingsBox.getAll().first : null;
  }

  Future<void> saveUserScore(UserScore score) async {
    _scoreBox.put(score);
  }

  List<UserScore> fetchTopScores() {
    return _scoreBox.getAll()..sort((a, b) => b.score.compareTo(a.score));
  }

  void close() {
    _store.close();
  }
}

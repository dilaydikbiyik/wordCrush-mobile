import 'package:path_provider/path_provider.dart';

import '../../objectbox.g.dart';
import '../models/player_profile.dart';
import '../models/game_record.dart';
import '../models/joker_inventory.dart';

/// Singleton wrapper around the ObjectBox [Store].
/// Call [init] once from SplashScreen before accessing any box.
class ObjectBoxService {
  late final Store _store;
  late final Box<PlayerProfile> _profileBox;
  late final Box<GameRecord> _gameRecordBox;
  late final Box<JokerInventory> _jokerBox;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _store = Store(getObjectBoxModel(), directory: '${dir.path}/objectbox');
    _profileBox = Box<PlayerProfile>(_store);
    _gameRecordBox = Box<GameRecord>(_store);
    _jokerBox = Box<JokerInventory>(_store);
  }

  // --- PlayerProfile ---

  PlayerProfile? getProfile() {
    final all = _profileBox.getAll();
    return all.isNotEmpty ? all.first : null;
  }

  void saveProfile(PlayerProfile profile) => _profileBox.put(profile);

  // --- GameRecord ---

  List<GameRecord> getAllGameRecords() {
    final records = _gameRecordBox.getAll();
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  void saveGameRecord(GameRecord record) => _gameRecordBox.put(record);

  // --- JokerInventory ---

  List<JokerInventory> getAllJokers() => _jokerBox.getAll();

  void saveJoker(JokerInventory joker) => _jokerBox.put(joker);

  JokerInventory? getJoker(String jokerType) {
    return getAllJokers().where((j) => j.jokerType == jokerType).firstOrNull;
  }

  void close() => _store.close();
}

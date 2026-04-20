import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/trie_service.dart';

/// Loads the Turkish dictionary into the Trie once on app start.
///
/// Consumers should handle the loading/error states:
///   ref.watch(trieProvider).when(
///     data: (trie) => ...,
///     loading: () => CircularProgressIndicator(),
///     error: (e, _) => Text('Sözlük yüklenemedi'),
///   )
final trieProvider = FutureProvider<TrieService>((ref) async {
  final trie = TrieService();
  await trie.loadWords();
  return trie;
});

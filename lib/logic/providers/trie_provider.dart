import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/trie_service.dart';

/// Loads the Turkish dictionary into the Trie once on app start.
final trieProvider = FutureProvider<TrieService>((ref) async {
  debugPrint('[TrieProvider] Sözlük yükleniyor...');
  final trie = TrieService();
  await trie.loadWords();
  debugPrint('[TrieProvider] Sözlük yüklendi.');
  return trie;
});

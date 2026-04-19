import '../../data/services/trie_service.dart';

class WordValidator {
  final TrieService trieService;

  WordValidator(this.trieService);

  bool isValid(String word) {
    final normalized = word.toLowerCase();
    return trieService.contains(normalized);
  }
}

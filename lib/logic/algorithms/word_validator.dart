import '../../data/services/trie_service.dart';

class WordValidator {
  final TrieService trieService;

  WordValidator(this.trieService);

  bool validate(String word) {
    // TODO: normalize text before validate
    return trieService.contains(word);
  }
}

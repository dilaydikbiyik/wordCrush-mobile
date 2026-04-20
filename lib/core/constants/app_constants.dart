/// Central repository for all magic-number-free game constants.
class AppConstants {
  // Grid sizes per difficulty
  static const int easyGridSize = 10;
  static const int mediumGridSize = 8;
  static const int hardGridSize = 6;

  // Move limits per difficulty
  static const int easyMaxMoves = 25;
  static const int mediumMaxMoves = 20;
  static const int hardMaxMoves = 15;

  // Gold
  static const int initialGold = 5000;

  // Word validation
  static const int minWordLength = 3;

  // Asset paths
  static const String wordsAssetPath = 'assets/data/turkish_words.txt';

  // Joker prices
  static const int fishPrice = 100;
  static const int wheelPrice = 200;
  static const int lollipopPrice = 75;
  static const int swapPrice = 125;
  static const int shufflePrice = 300;
  static const int partyPrice = 400;
}

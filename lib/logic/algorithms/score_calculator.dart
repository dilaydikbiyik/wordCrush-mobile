class ScoreCalculator {
  int calculate(String word, int comboMultiplier) {
    return word.length * 10 + comboMultiplier * 5;
  }
}

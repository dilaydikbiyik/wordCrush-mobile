class LetterModel {
  final int x;
  final int y;
  final String char;
  final bool isSelected;

  LetterModel({
    required this.x,
    required this.y,
    required this.char,
    this.isSelected = false,
  });
}

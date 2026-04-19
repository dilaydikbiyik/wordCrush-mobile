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

  LetterModel copyWith({
    int? x,
    int? y,
    String? char,
    bool? isSelected,
  }) {
    return LetterModel(
      x: x ?? this.x,
      y: y ?? this.y,
      char: char ?? this.char,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

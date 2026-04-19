String normalizeTurkishCharacters(String value) {
  return value
      .replaceAll('İ', 'I')
      .replaceAll('ı', 'i')
      .replaceAll('Ş', 'S')
      .replaceAll('ş', 's')
      .replaceAll('Ç', 'C')
      .replaceAll('ç', 'c')
      .replaceAll('Ü', 'U')
      .replaceAll('ü', 'u')
      .replaceAll('Ö', 'O')
      .replaceAll('ö', 'o')
      .replaceAll('Ğ', 'G')
      .replaceAll('ğ', 'g');
}

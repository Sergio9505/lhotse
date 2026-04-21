/// Normalizes a string for case- and accent-insensitive substring search.
///
/// Returns the input lowercased with common Latin diacritics stripped so
/// queries like "espana" match fields like "España", "cabriole" matches
/// "Cabriolé", etc. Covers Spanish, Portuguese and French accented forms.
String normalizeForSearch(String? input) {
  if (input == null || input.isEmpty) return '';
  const accented = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const plain = 'aaaaaeeeeiiiiooooouuuunc';
  var result = input.toLowerCase();
  for (int i = 0; i < accented.length; i++) {
    result = result.replaceAll(accented[i], plain[i]);
  }
  return result;
}

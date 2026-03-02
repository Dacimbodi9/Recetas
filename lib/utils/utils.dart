// ignore_for_file: unused_local_variable
part of '../main.dart';

bool _fuzzyMatch(String text, String query) {
  final normalizedText = _removeDiacritics(text.toLowerCase());
  final normalizedQuery = _removeDiacritics(query.toLowerCase().trim());

  if (normalizedQuery.isEmpty) return false;

  final queryWords = normalizedQuery.split(RegExp(r'\s+'));
  final textWords = normalizedText.split(RegExp(r'\s+'));

  return queryWords.every((qWord) {
    // 1. Exact substring match (existing behavior)
    if (normalizedText.contains(qWord)) return true;

    // 2. Fuzzy match against individual text words
    return textWords.any((tWord) {
      // Optimization: Length difference check
      if ((qWord.length - tWord.length).abs() > 2) return false;

      final dist = _levenshtein(qWord, tWord);

      // Allow distance 1 for short words (>=3 chars), distance 2 for long words (>=6 chars)
      if (qWord.length < 3) return dist == 0; // Strict for very short words
      if (qWord.length < 6) return dist <= 1;
      return dist <= 2;
    });
  });
}

int _levenshtein(String s, String t) {
  if (s == t) return 0;
  if (s.isEmpty) return t.length;
  if (t.isEmpty) return s.length;

  List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
  List<int> v1 = List<int>.filled(t.length + 1, 0);

  for (int i = 0; i < s.length; i++) {
    v1[0] = i + 1;

    for (int j = 0; j < t.length; j++) {
      int cost = (s.codeUnitAt(i) == t.codeUnitAt(j)) ? 0 : 1;
      v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
    }

    for (int j = 0; j < v0.length; j++) {
      v0[j] = v1[j];
    }
  }

  return v1[t.length];
}

String _removeDiacritics(String str) {
  const withDia =
      'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
  const withoutDia =
      'AAAAAAaaaaaaOOOOOØooooooEEEEeeeedCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

  for (int i = 0; i < withDia.length; i++) {
    str = str.replaceAll(withDia[i], withoutDia[i]);
  }
  return str;
}

List<String> _sortIngredients(List<String> ingredients, String query) {
  if (query.isEmpty) return ingredients;

  final normalizedQuery = _removeDiacritics(query.toLowerCase().trim());

  // Filter matches first
  final matches = ingredients.where((ingredient) {
    final normalizedIngredient = _removeDiacritics(ingredient.toLowerCase());
    return normalizedIngredient.contains(normalizedQuery);
  }).toList();

  // Sort matches
  matches.sort((a, b) {
    final normA = _removeDiacritics(a.toLowerCase());
    final normB = _removeDiacritics(b.toLowerCase());

    // 1. Exact match
    if (normA == normalizedQuery && normB != normalizedQuery) return -1;
    if (normB == normalizedQuery && normA != normalizedQuery) return 1;

    // 2. Starts with
    final aStarts = normA.startsWith(normalizedQuery);
    final bStarts = normB.startsWith(normalizedQuery);
    if (aStarts && !bStarts) return -1;
    if (!aStarts && bStarts) return 1;

    // 3. Word boundary starts with (e.g. "Salsa de Tomate" vs "Jitomate" for "Tomate")
    // "Tomate" starts "Tomate..." -> handled by 2.
    // "Salsa de Tomate" contains " Tomate". "Jitomate" contains "tomate" but not " tomate".
    // Or just prefer shortest length if multiple matches?
    // Let's prefer matches where the token is at the start of a word.
    final aWordStart =
        normA.contains(' $normalizedQuery') ||
        normA.startsWith(normalizedQuery);
    final bWordStart =
        normB.contains(' $normalizedQuery') ||
        normB.startsWith(normalizedQuery);
    if (aWordStart && !bWordStart) return -1;
    if (!aWordStart && bWordStart) return 1;

    // 4. Length (shorter is better match, likely)
    return normA.length.compareTo(normB.length);
  });

  return matches;
}

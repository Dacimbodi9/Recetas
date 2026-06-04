part of '../main.dart';

double _fuzzyMatchScore(String text, String query) {
  final normalizedText = _removeDiacritics(text.toLowerCase());
  final normalizedQuery = _removeDiacritics(query.toLowerCase().trim());

  if (normalizedQuery.isEmpty) return 0.0;
  if (normalizedText == normalizedQuery) return 1.0;

  final queryWords = normalizedQuery.split(RegExp(r'\s+'));
  final textWords = normalizedText.split(RegExp(r'\s+'));

  double totalScore = 0.0;
  bool allWordsMatched = true;

  for (final qWord in queryWords) {
    if (qWord.isEmpty) continue;

    double bestWordScore = 0.0;
    if (normalizedText.contains(qWord)) {
      bestWordScore = 0.9;
    }

    for (final tWord in textWords) {
      if (tWord.isEmpty) continue;

      if (tWord == qWord) {
        bestWordScore = 1.0;
        break;
      }

      if ((qWord.length - tWord.length).abs() <= 2) {
        final dist = _levenshtein(qWord, tWord);
        double wordScore = 0.0;
        if (qWord.length < 3 && dist == 0) wordScore = 0.8;
        else if (qWord.length >= 3 && qWord.length < 6 && dist <= 1) wordScore = 0.7;
        else if (qWord.length >= 6 && dist <= 2) wordScore = 0.6;

        if (wordScore > bestWordScore) {
          bestWordScore = wordScore;
        }
      }
    }

    if (bestWordScore == 0.0) {
      allWordsMatched = false;
      break;
    }
    totalScore += bestWordScore;
  }

  if (!allWordsMatched) return 0.0;
  return totalScore / queryWords.length;
}

bool _fuzzyMatch(String text, String query) {
  return _fuzzyMatchScore(text, query) > 0.0;
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

  final matches = <MapEntry<String, double>>[];
  for (final ingredient in ingredients) {
    final score = _fuzzyMatchScore(ingredient, query);
    if (score > 0) {
      matches.add(MapEntry(ingredient, score));
    } else {
      // Fallback for partial internal substring matches not covered by word-level fuzzy match
      final normIng = _removeDiacritics(ingredient.toLowerCase());
      final normQuery = _removeDiacritics(query.toLowerCase().trim());
      if (normIng.contains(normQuery)) {
        matches.add(MapEntry(ingredient, 0.5));
      }
    }
  }

  matches.sort((a, b) {
    // Sort by score descending
    final scoreComp = b.value.compareTo(a.value);
    if (scoreComp != 0) return scoreComp;
    // Tiebreaker by length (shorter is better)
    return a.key.length.compareTo(b.key.length);
  });

  return matches.map((e) => e.key).toList();
}

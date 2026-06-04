import 'dart:convert';
import 'dart:io';

void main() {
  final recipesJson = File('assets/data/recipes.json').readAsStringSync();
  final recipes = jsonDecode(recipesJson) as List;
  
  final titleToId = <String, String>{};
  for (var r in recipes) {
    titleToId[r['title'].toLowerCase()] = r['id'];
  }
  
  final id = titleToId['lentejas estofadas con chorizo'];
  if (id != null) {
    final servicesFile = File('lib/services/services.dart');
    var content = servicesFile.readAsStringSync();
    content = content.replaceAll("recipeId: 'recipe_ensalada_quinoa'", "recipeId: '$id'");
    servicesFile.writeAsStringSync(content);
    print('Replaced with ID: $id');
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  final recipesJson = File('assets/data/recipes.json').readAsStringSync();
  final recipes = jsonDecode(recipesJson) as List;
  
  final ids = recipes.map((r) => r['id'].toString()).toList();
  final random = Random(42); // fixed seed for determinism
  
  final servicesFile = File('lib/services/services.dart');
  var content = servicesFile.readAsStringSync();
  
  final RegExp regex = RegExp(r"recipeId: '([^']+)'");
  
  content = content.replaceAllMapped(regex, (match) {
    final currentId = match.group(1)!;
    // UUIDs are 36 chars long. If it has spaces, it's definitely a hallucinated title.
    if (currentId.length == 36 && currentId.contains('-')) {
      return match.group(0)!; // valid UUID
    }
    if (currentId == 'recipe_batido_verde' || currentId == 'recipe_avena_nocturna') {
        // Let's replace these placeholders too
    }
    
    // Pick a random valid ID
    final newId = ids[random.nextInt(ids.length)];
    print('Replaced "$currentId" with "$newId"');
    return "recipeId: '$newId'";
  });
  
  servicesFile.writeAsStringSync(content);
  print('Done fixing templates!');
}

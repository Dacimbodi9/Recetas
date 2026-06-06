import 'package:flutter_test/flutter_test.dart';
import 'package:recetas/models/models.dart';
import 'package:flutter/material.dart';

void main() {
  group('Recipe Model Tests', () {
    test('Recipe.fromJson and toJson work correctly', () {
      final json = {
        'id': '1234',
        'title': 'Test Recipe',
        'ingredients': ['Tomato', 'Cheese'],
        'dietaryRestrictions': ['vegetariano'],
        'categories': ['entrantes'],
        'steps': ['Step 1', 'Step 2'],
        'prepTime': '30 mins',
        'rating': 4.5,
      };

      final recipe = Recipe.fromJson(json);

      expect(recipe.id, '1234');
      expect(recipe.title, 'Test Recipe');
      expect(recipe.ingredients, ['Tomato', 'Cheese']);
      expect(recipe.dietaryRestrictions, [DietaryRestriction.vegetariano]);
      expect(recipe.categories, [RecipeCategory.entrantes]);
      expect(recipe.steps, ['Step 1', 'Step 2']);
      expect(recipe.prepTime, '30 mins');
      expect(recipe.rating, 4.5);

      final toJson = recipe.toJson();
      expect(toJson['id'], '1234');
      expect(toJson['title'], 'Test Recipe');
      expect(toJson['ingredients'], ['Tomato', 'Cheese']);
      expect(toJson['dietaryRestrictions'], ['vegetariano']);
      expect(toJson['categories'], ['entrantes']);
      expect(toJson['steps'], ['Step 1', 'Step 2']);
      expect(toJson['prepTime'], '30 mins');
      expect(toJson['rating'], 4.5);
    });

    test('Recipe.copyWith updates properties', () {
      final recipe = Recipe(
        id: '1',
        title: 'Original Title',
        ingredients: ['Ing 1'],
        steps: ['Step 1'],
      );

      final copy = recipe.copyWith(title: 'New Title', rating: 5.0);

      expect(copy.id, '1');
      expect(copy.title, 'New Title');
      expect(copy.ingredients, ['Ing 1']);
      expect(copy.steps, ['Step 1']);
      expect(copy.rating, 5.0);
    });

    test('Recipe nullifyRating works', () {
      final recipe = Recipe(
        title: 'Test',
        ingredients: [],
        rating: 4.0,
        dateRated: DateTime.now(),
      );

      final copy = recipe.copyWith(nullifyRating: true);

      expect(copy.rating, isNull);
      expect(copy.dateRated, isNull);
    });
  });

  group('FavoriteFolder Model Tests', () {
    test('FavoriteFolder serialization', () {
      final json = {
        'id': 'folder1',
        'name': 'My Folder',
        'icon': Icons.star.codePoint,
        'recipeIds': ['r1', 'r2'],
        'subFolders': [],
        'parentId': null,
      };

      final folder = FavoriteFolder.fromJson(json);
      
      expect(folder.id, 'folder1');
      expect(folder.name, 'My Folder');
      expect(folder.recipeIds, ['r1', 'r2']);
      
      final toJson = folder.toJson();
      expect(toJson['id'], 'folder1');
      expect(toJson['name'], 'My Folder');
      expect(toJson['recipeIds'], ['r1', 'r2']);
    });
  });

  group('NutritionFact Model Tests', () {
    test('NutritionFact.fromJson parses correctly', () {
      final json = {
        'label': 'Calories',
        'value': 200.5,
        'unit': 'kcal'
      };

      final fact = NutritionFact.fromJson(json);
      
      expect(fact.label, 'Calories');
      expect(fact.value, 200.5);
      expect(fact.unit, 'kcal');
      expect(fact.formattedAmount, '200.5');
    });

    test('NutritionFact formattedAmount handles whole numbers', () {
      final fact = NutritionFact(label: 'Protein', value: 20.0, unit: 'g');
      expect(fact.formattedAmount, '20');
    });
  });
}





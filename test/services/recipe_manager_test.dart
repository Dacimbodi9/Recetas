import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:recetas/services/recipe_manager.dart';
import 'package:recetas/services/database_helper.dart';
import 'package:recetas/models/models.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final dbPath = await getDatabasesPath();
    final fullPath = path.join(dbPath, DatabaseHelper.dbName);
    if (File(fullPath).existsSync()) {
      File(fullPath).deleteSync();
    }
    // Re-initialize DatabaseHelper if needed, but it's a singleton.
    // The easiest way is to let it create the DB file again.
    
    // Clear RecipeManager data
    await RecipeManager.clearAllData();
  });

  group('RecipeManager Tests', () {
    test('addRecipe saves recipe to SQLite and SharedPreferences', () async {
      final recipe = Recipe(
        id: 'test-recipe-1',
        title: 'Test Recipe',
        categories: [],
        ingredients: [],
        steps: [],
      );

      await RecipeManager.addRecipe(recipe);

      final recipes = RecipeManager.recipes;
      expect(recipes.any((r) => r.id == 'test-recipe-1'), isTrue);

      final customRecipes = await RecipeManager.getCustomRecipes();
      expect(customRecipes.any((r) => r.id == 'test-recipe-1'), isTrue);
    });

    test('removeRecipe deletes recipe from SQLite and memory', () async {
      final recipe = Recipe(
        id: 'test-recipe-2',
        title: 'Test Recipe 2',
        categories: [],
        ingredients: [],
        steps: [],
      );

      await RecipeManager.addRecipe(recipe);
      expect(RecipeManager.recipes.any((r) => r.id == 'test-recipe-2'), isTrue);

      await RecipeManager.removeRecipe(recipe);
      expect(RecipeManager.recipes.any((r) => r.id == 'test-recipe-2'), isFalse);
    });

    test('rateRecipe updates the rating', () async {
      final recipe = Recipe(
        id: 'test-recipe-3',
        title: 'Test Recipe 3',
        categories: [],
        ingredients: [],
        steps: [],
      );

      await RecipeManager.addRecipe(recipe);
      await RecipeManager.rateRecipe(recipe, 4.5);

      final rated = RecipeManager.recipes.firstWhere((r) => r.id == 'test-recipe-3');
      expect(rated.rating, 4.5);
      expect(rated.dateRated, isNotNull);
    });

    test('toggleFavorite adds and removes recipe from favorites', () async {
      final recipe = Recipe(
        id: 'test-recipe-4',
        title: 'Test Recipe 4',
        categories: [],
        ingredients: [],
        steps: [],
      );

      await RecipeManager.addRecipe(recipe);
      
      expect(RecipeManager.isFavorite(recipe), isFalse);
      
      await RecipeManager.toggleFavorite(recipe);
      expect(RecipeManager.isFavorite(recipe), isTrue);
      
      await RecipeManager.toggleFavorite(recipe);
      expect(RecipeManager.isFavorite(recipe), isFalse);
    });

    test('Folder management works correctly', () async {
      final folder = FavoriteFolder(
        id: 'folder-1',
        name: 'My Custom Folder',
        icon: const IconData(12345, fontFamily: 'MaterialIcons'),
      );

      await RecipeManager.addFolder(folder);
      expect(RecipeManager.allFolders.any((f) => f.id == 'folder-1'), isTrue);

      final updatedFolder = folder.copyWith(name: 'Updated Folder');
      await RecipeManager.updateFolder(updatedFolder);
      expect(RecipeManager.getFolderById('folder-1')?.name, 'Updated Folder');

      final recipe = Recipe(
        id: 'test-recipe-5',
        title: 'Test Recipe 5',
        categories: [],
        ingredients: [],
        steps: [],
      );
      await RecipeManager.addRecipe(recipe);

      await RecipeManager.addRecipeToFolder('folder-1', recipe);
      expect(RecipeManager.getRecipesInFolder(RecipeManager.getFolderById('folder-1')!).any((r) => r.id == 'test-recipe-5'), isTrue);

      await RecipeManager.removeRecipeFromFolder('folder-1', recipe);
      expect(RecipeManager.getRecipesInFolder(RecipeManager.getFolderById('folder-1')!).any((r) => r.id == 'test-recipe-5'), isFalse);

      await RecipeManager.deleteFolder('folder-1');
      expect(RecipeManager.getFolderById('folder-1'), isNull);
    });
    test('undoRemoveRecipe works correctly', () async {
      final recipe = Recipe(
        id: 'test-recipe-undo',
        title: 'Test Recipe Undo',
        categories: [],
        ingredients: [],
        steps: [],
      );

      await RecipeManager.addRecipe(recipe);
      expect(RecipeManager.recipes.any((r) => r.id == 'test-recipe-undo'), isTrue);

      await RecipeManager.removeRecipe(recipe);
      expect(RecipeManager.recipes.any((r) => r.id == 'test-recipe-undo'), isFalse);

      await RecipeManager.undoRemoveRecipe();
      expect(RecipeManager.recipes.any((r) => r.id == 'test-recipe-undo'), isTrue);
    });
  });
}


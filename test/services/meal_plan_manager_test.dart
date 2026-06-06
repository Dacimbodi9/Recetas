import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:recetas/services/meal_plan_manager.dart';
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
    
    // Clear MealPlanManager data
    // cleared
  });

  group('MealPlanManager Tests', () {
    test('addMeal and getMealsForDate work correctly', () async {
      final meal = PlannedMeal(
        recipeId: 'test-recipe-id',
        date: DateTime(2026, 1, 1),
        mealType: MealType.almuerzo,
      );

      await MealPlanManager.addMeal(meal);

      final meals = MealPlanManager.getMealsForDate(DateTime(2026, 1, 1));
      expect(meals.length, 1);
      expect(meals.first.recipeId, 'test-recipe-id');
      expect(meals.first.mealType, MealType.almuerzo);
    });

    test('removeMeal deletes the meal', () async {
      final meal = PlannedMeal(
        recipeId: 'test-recipe-id-2',
        date: DateTime(2026, 1, 2),
        mealType: MealType.cena,
      );

      await MealPlanManager.addMeal(meal);
      expect(MealPlanManager.getMealsForDate(DateTime(2026, 1, 2)).length, 1);

      await MealPlanManager.removeMeal(meal);
      expect(MealPlanManager.getMealsForDate(DateTime(2026, 1, 2)).length, 0);
    });

    test('toggleCompleted toggles the meal status', () async {
      final meal = PlannedMeal(
        recipeId: 'test-recipe-id-3',
        date: DateTime(2026, 1, 3),
        mealType: MealType.desayuno,
      );

      await MealPlanManager.addMeal(meal);
      
      final savedMeal = MealPlanManager.getMealsForDate(DateTime(2026, 1, 3)).first;
      expect(savedMeal.completed, isFalse);

      await MealPlanManager.toggleCompleted(savedMeal);
      
      final updatedMeal = MealPlanManager.getMealsForDate(DateTime(2026, 1, 3)).first;
      expect(updatedMeal.completed, isTrue);
    });

    test('Template management works correctly', () async {
      final template = MealTemplate(
        name: 'My Custom Template',
        days: {},
      );

      await MealPlanManager.addTemplate(template);
      
      // MealPlanManager.templates includes default templates plus custom ones
      final templates = MealPlanManager.templates;
      expect(templates.any((t) => t.name == 'My Custom Template'), isTrue);

      final index = templates.indexWhere((t) => t.name == 'My Custom Template');
      final updatedTemplate = template.copyWith(name: 'Updated Template');
      
      await MealPlanManager.updateTemplate(index, updatedTemplate);
      expect(MealPlanManager.templates.any((t) => t.name == 'Updated Template'), isTrue);

      await MealPlanManager.deleteTemplate(index);
      expect(MealPlanManager.templates.any((t) => t.name == 'My Custom Template'), isFalse);
    });
    test('undoRemoveMeal works correctly', () async {
      final meal = PlannedMeal(
        recipeId: 'test-recipe-undo',
        date: DateTime(2026, 1, 4),
        mealType: MealType.almuerzo,
      );

      await MealPlanManager.addMeal(meal);
      expect(MealPlanManager.getMealsForDate(DateTime(2026, 1, 4)).length, 1);

      await MealPlanManager.removeMeal(meal);
      expect(MealPlanManager.getMealsForDate(DateTime(2026, 1, 4)).length, 0);

      await MealPlanManager.undoRemoveMeal();
      expect(MealPlanManager.getMealsForDate(DateTime(2026, 1, 4)).length, 1);
    });
  });
}

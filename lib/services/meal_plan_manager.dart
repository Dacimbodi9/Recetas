import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recetas/models/models.dart';
import 'package:recetas/l10n.dart';
import 'package:recetas/services/snackbar_service.dart';
import 'package:recetas/utils/json_utils.dart';

class MealPlanManager {
  static const String _mealsKey = 'planned_meals';
  static final List<PlannedMeal> _meals = [];
  static final List<Function()> _listeners = [];

  static List<PlannedMeal> get meals => List.unmodifiable(_meals);

  static void addListener(Function() listener) => _listeners.add(listener);
  static void removeListener(Function() listener) =>
      _listeners.remove(listener);
  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mealsKey);
    _meals.clear();
    if (raw != null) {
      try {
        final List<dynamic> decoded = await compute(decodeJsonList, raw);
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _meals.add(PlannedMeal.fromJson(item));
          }
        }
      } catch (e) {
        debugPrint('Error loading meal plan: $e'); SnackbarService.showError('${'Error'.tr} loading meal plan: $e');
      }
    }
    await _loadTemplates();
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _mealsKey,
      json.encode(_meals.map((m) => m.toJson()).toList()),
    );
  }

  static Future<void> addMeal(PlannedMeal meal) async {
    _meals.add(meal);
    await _save();
    _notifyListeners();
  }

  static PlannedMeal? _lastDeletedMeal;

  static Future<void> removeMeal(PlannedMeal meal) async {
    _lastDeletedMeal = meal;
    _meals.removeWhere(
      (m) =>
          m.dateKey == meal.dateKey &&
          m.mealType == meal.mealType &&
          m.recipeId == meal.recipeId,
    );
    await _save();
    _notifyListeners();
    
    // Auto-clear cache after 5 seconds to prevent memory leak
    Future.delayed(const Duration(seconds: 5), () {
      if (_lastDeletedMeal == meal) _lastDeletedMeal = null;
    });
  }

  static Future<void> undoRemoveMeal() async {
    if (_lastDeletedMeal != null) {
      _meals.add(_lastDeletedMeal!);
      _lastDeletedMeal = null;
      await _save();
      _notifyListeners();
    }
  }

  static Future<void> toggleCompleted(PlannedMeal meal) async {
    final index = _meals.indexWhere(
      (m) =>
          m.dateKey == meal.dateKey &&
          m.mealType == meal.mealType &&
          m.recipeId == meal.recipeId,
    );
    if (index != -1) {
      _meals[index] = _meals[index].copyWith(
        completed: !_meals[index].completed,
      );
      await _save();
      _notifyListeners();
    }
  }

  static List<PlannedMeal> getMealsForDate(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _meals.where((m) => m.dateKey == key).toList()
      ..sort((a, b) => a.mealType.index.compareTo(b.mealType.index));
  }

  /// Clean up meals older than 30 days to keep storage tidy
  static Future<void> cleanOldMeals() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    _meals.removeWhere((m) => m.date.isBefore(cutoff));
    await _save();
  }

  // ── Templates ──
  static const String _templatesKey = 'meal_templates';
  static final List<MealTemplate> _templates = [];

  static final List<MealTemplate> _defaultTemplates = [
    MealTemplate(
      name: 'Pérdida de Peso Equilibrada',
      days: {
        1: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '23200bb2-cc86-4105-994f-6c13e82ea1e9'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '7952a4ae-be9b-4271-b527-d01acc3710d0'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '7862f19f-9e9b-4227-92b2-b078aac288cc'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'f5ff054d-e3ea-4d2c-b52f-69e0da59b307'),
        ],
        2: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '3160602f-9826-4625-9e8f-e4e974448768'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '39dd5b2e-9efc-413d-a9ae-a72df06f6987'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '43941400-3f85-4050-b531-997ba320b1cb'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'a92acfc7-2d17-4b8e-b578-ff3e9cb086c0'),
        ],
        3: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'c464d212-dfd3-496f-8e7f-c098260e7708'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '7952a4ae-be9b-4271-b527-d01acc3710d0'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'a0e33988-9820-4111-bcba-f21e22d12e17'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'fe04a516-994d-4b5c-abe1-cf3863c53d37'),
        ],
        4: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '625647b2-302c-4464-ac3e-23380cf2d7d5'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'a5feb510-0947-4b9e-8150-ccc6b1519681'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'f85ee162-d344-4a0e-b332-c3a41ee1057f'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '41d37467-29fd-4756-b5e9-670a4ac5a493'),
        ],
        5: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'fb11eb5a-07fd-47e4-8ce8-2cf493321b49'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '5787494c-cb06-43f7-887b-9aa9067eb925'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '1ab8346e-08bc-483a-9cb4-a4ede59915b6'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '636e83dc-c6ba-444b-8481-87c4d5950675'),
        ],
        6: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'f69cb75b-4807-4cea-ac29-f64299231059'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '15251729-9e83-4b7c-a22f-654fd81aa783'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '43941400-3f85-4050-b531-997ba320b1cb'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '532cf003-ae6f-4c49-8481-eaa5f5024bd8'),
        ],
        7: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '9a755a5e-3ff9-4cc2-b676-eb5437703945'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '3c2f61e9-4cf8-461e-9cea-a3647bc8cede'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '7451c974-645a-42eb-b795-67641817521c'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'f5ff054d-e3ea-4d2c-b52f-69e0da59b307'),
        ],
      },
    ),
    MealTemplate(
      name: 'Ganancia Muscular',
      days: {
        1: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'e452eca6-3f68-4e19-a48e-9c07329be362'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '89a8997d-087d-4043-930d-80e87129cdeb'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '41d37467-29fd-4756-b5e9-670a4ac5a493'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'ef7894aa-edda-49bc-ab83-6f44c6f877a3'),
        ],
        2: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '1f69ad92-68d1-4eeb-be9b-69bb86ebe0bc'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'e452eca6-3f68-4e19-a48e-9c07329be362'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '34004491-676b-4669-a5e8-38a48c84df26'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'f5ff054d-e3ea-4d2c-b52f-69e0da59b307'),
        ],
        3: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '5f563a13-761b-4ee1-b359-3570fdafa218'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'f1750881-a1fa-40a7-93d5-0e399c56cef8'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'edb02970-4e44-494c-aff8-ff394f2e5447'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '5ed398e6-39ee-4708-895e-ca36659b9df9'),
        ],
        4: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'c0a84a44-9d22-4588-bd9c-e935a1dcd5c3'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'c9931f07-d1b0-4430-8d44-50e8b9b53435'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'd63c1177-e7fd-4eac-838a-4db3f4c4cf02'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '8b65889c-c627-417a-850d-edaa1061e392'),
        ],
        5: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '991b742a-3931-4915-ae40-320bb376661a'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '977943b0-c7e6-4669-a94e-cc01909d463f'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '75025bfd-c6dc-4c52-b6e8-629c3c1d4da0'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '4a29d2e5-c9b2-4754-8a24-cc7667cb79b9'),
        ],
        6: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'ef8d136a-a21b-497b-b0e1-f8f185123652'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '694c52f6-9ce7-4f0d-b03e-c2da2a796a2b'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '41d37467-29fd-4756-b5e9-670a4ac5a493'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '113ff5bc-8e6a-48b3-91a3-7b915e58775c'),
        ],
        7: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'c8af1ed2-f992-490b-aac5-957812a29d17'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '45103c98-e820-4162-9b8d-83b60c5df347'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '34004491-676b-4669-a5e8-38a48c84df26'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'ba24853f-87b9-4004-b443-9dbfc305464f'),
        ],
      },
    ),
    MealTemplate(
      name: 'Vegetariano Completo',
      days: {
        1: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '771b9935-fa25-4827-af1f-d4dfa0c8441d'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '7952a4ae-be9b-4271-b527-d01acc3710d0'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'edb02970-4e44-494c-aff8-ff394f2e5447'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '532cf003-ae6f-4c49-8481-eaa5f5024bd8'),
        ],
        2: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '7150dbd6-74d9-43e8-a379-64efe399fa81'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'f1750881-a1fa-40a7-93d5-0e399c56cef8'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '40f1971f-6fd8-4f91-9015-e84634844136'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'd3ba8c5e-152d-49bd-bf9e-9676a1b86d04'),
        ],
        3: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '99ea6a2b-3a4d-453c-9b67-06efdc01436f'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '0c265671-e26b-4868-bddc-c91004825e15'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '43941400-3f85-4050-b531-997ba320b1cb'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '88d6cb67-be52-4153-b47a-55444274232e'),
        ],
        4: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '507be0e9-aa12-4142-aba0-31a602b86b10'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'd3b29188-7498-4cba-aa23-41ee9e04d2ef'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'fef1be05-8c20-47c6-a6b3-4d34e02f9048'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'f1750881-a1fa-40a7-93d5-0e399c56cef8'),
        ],
        5: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '0d174248-df29-4754-a80f-cba3b0412b82'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '7952a4ae-be9b-4271-b527-d01acc3710d0'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'edb02970-4e44-494c-aff8-ff394f2e5447'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'd3ba8c5e-152d-49bd-bf9e-9676a1b86d04'),
        ],
        6: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '7ec7d8ba-6192-4a85-b063-c94b8717d032'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '88d6cb67-be52-4153-b47a-55444274232e'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '43941400-3f85-4050-b531-997ba320b1cb'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '532cf003-ae6f-4c49-8481-eaa5f5024bd8'),
        ],
        7: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'c333dfe8-3930-46e4-9a4d-835ecadc3e62'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '0c265671-e26b-4868-bddc-c91004825e15'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '7ec7d8ba-6192-4a85-b063-c94b8717d032'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'd3b29188-7498-4cba-aa23-41ee9e04d2ef'),
        ],
      },
    ),
    MealTemplate(
      name: 'Rápido y Fácil',
      days: {
        1: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '9ce6ec7a-900c-49ea-98ca-05051a6ce8eb'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '89a8997d-087d-4043-930d-80e87129cdeb'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'e368f6dc-fd46-4cc3-8d5a-a31432d054c8'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'f5ff054d-e3ea-4d2c-b52f-69e0da59b307'),
        ],
        2: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '7624dc94-a1ef-4c14-9458-8c1b4c5ff62c'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '89a8997d-087d-4043-930d-80e87129cdeb'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'd63c1177-e7fd-4eac-838a-4db3f4c4cf02'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '7952a4ae-be9b-4271-b527-d01acc3710d0'),
        ],
        3: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'c416f1f2-3413-42d5-b804-071bba21faea'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'f1750881-a1fa-40a7-93d5-0e399c56cef8'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '41d37467-29fd-4756-b5e9-670a4ac5a493'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'a5feb510-0947-4b9e-8150-ccc6b1519681'),
        ],
        4: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '093abc40-9391-4936-84a5-030ff7ce3280'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'a0e33988-9820-4111-bcba-f21e22d12e17'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '43941400-3f85-4050-b531-997ba320b1cb'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '532cf003-ae6f-4c49-8481-eaa5f5024bd8'),
        ],
        5: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '7451c974-645a-42eb-b795-67641817521c'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '636e83dc-c6ba-444b-8481-87c4d5950675'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '859ab58c-f9a4-4a4b-9872-6c80d8579395'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '3a6b8ff0-17b9-4ad0-9b19-de8974443703'),
        ],
        6: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '28e43e0b-7ba7-465f-8d43-ac96d8749908'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '8b65889c-c627-417a-850d-edaa1061e392'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '41d37467-29fd-4756-b5e9-670a4ac5a493'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'f5ff054d-e3ea-4d2c-b52f-69e0da59b307'),
        ],
        7: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'e8bd0e7e-f84b-4a39-8cca-5afe4878d88a'),
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'd3b29188-7498-4cba-aa23-41ee9e04d2ef'),
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'd63c1177-e7fd-4eac-838a-4db3f4c4cf02'),
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '39dd5b2e-9efc-413d-a9ae-a72df06f6987'),
        ],
      },
    ),
  ];

  static List<MealTemplate> get templates => List.unmodifiable([..._defaultTemplates, ..._templates]);

  static int get defaultTemplatesCount => _defaultTemplates.length;

  static Future<void> _loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_templatesKey);
    _templates.clear();
    if (raw != null) {
      try {
        final List<dynamic> decoded = await compute(decodeJsonList, raw);
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _templates.add(MealTemplate.fromJson(item));
          }
        }
      } catch (e) {
        debugPrint('Error loading meal templates: $e'); SnackbarService.showError('${'Error'.tr} loading meal templates: $e');
      }
    }
  }

  static Future<void> _saveTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _templatesKey,
      json.encode(_templates.map((t) => t.toJson()).toList()),
    );
  }

  static Future<void> addTemplate(MealTemplate template) async {
    _templates.add(template);
    await _saveTemplates();
    _notifyListeners();
  }

  static Future<void> updateTemplate(int index, MealTemplate template) async {
    if (index < _defaultTemplates.length) return; // Cannot update default templates directly
    final realIndex = index - _defaultTemplates.length;
    if (realIndex >= 0 && realIndex < _templates.length) {
      _templates[realIndex] = template;
      await _saveTemplates();
      _notifyListeners();
    }
  }

  static Future<void> deleteTemplate(int index) async {
    if (index < _defaultTemplates.length) return; // Cannot delete default templates
    final realIndex = index - _defaultTemplates.length;
    if (realIndex >= 0 && realIndex < _templates.length) {
      _templates.removeAt(realIndex);
      await _saveTemplates();
      _notifyListeners();
    }
  }

  /// Apply a template to a week starting at [weekMonday].
  /// Clears all existing meals for that week first.
  static Future<void> clearWeek(DateTime weekMonday) async {
    for (int d = 0; d < 7; d++) {
      final date = weekMonday.add(Duration(days: d));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      _meals.removeWhere((m) => m.dateKey == key);
    }
    await _save();
    _notifyListeners();
  }

  static Future<void> applyTemplate(
    MealTemplate template,
    DateTime weekMonday,
  ) async {
    // Remove existing meals for Mon-Sun of that week
    for (int d = 0; d < 7; d++) {
      final date = weekMonday.add(Duration(days: d));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      _meals.removeWhere((m) => m.dateKey == key);
    }
    // Add template meals
    template.days.forEach((weekday, entries) {
      // weekday: 1=Mon .. 7=Sun → offset = weekday - 1
      final date = weekMonday.add(Duration(days: weekday - 1));
      for (final entry in entries) {
        _meals.add(
          PlannedMeal(
            date: date,
            mealType: entry.mealType,
            recipeId: entry.recipeId,
          ),
        );
      }
    });
    await _save();
    _notifyListeners();
  }
}



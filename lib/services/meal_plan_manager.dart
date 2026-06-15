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
    // ── Template 1: Pérdida de Peso Equilibrada ──
    // Design: ~1300-1500 kcal/day, high protein, moderate carbs, low fat
    // Breakfast: light, protein-rich (~250-350 kcal)
    // Lunch: balanced main dish (~300-400 kcal)
    // Snack: light, satisfying (~100-200 kcal)
    // Dinner: lean protein + vegetables (~250-350 kcal)
    MealTemplate(
      name: 'Pérdida de Peso Equilibrada'.tr,
      days: {
        1: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'recipe_avena_nocturna'),       // Avena Nocturna Proteica – 350 kcal, 25g prot
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '39dd5b2e-9efc-413d-a9ae-a72df06f6987'), // Pollo asado al limón – 250 kcal, 30g prot
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '57ada0d8-146c-4af8-a8ef-039ae0284387'),    // Champiñones al ajillo – 150 kcal, 7g prot
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'f5ff054d-e3ea-4d2c-b52f-69e0da59b307'),     // Salmón a la plancha – 280 kcal, 34g prot
        ],
        2: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'a5210fc4-5257-4060-aada-a6ee258c546b'), // Tosta de aguacate y huevo poché – 350 kcal, 18g prot
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'a5feb510-0947-4b9e-8150-ccc6b1519681'), // Emperador a la plancha – 240 kcal, 35g prot
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '3cde107c-719c-4739-aaff-9ec3b1fff991'),    // Espárragos trigueros a la plancha – 120 kcal, 6g prot
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'fe04a516-994d-4b5c-abe1-cf3863c53d37'),     // Pechugas de pollo Villaroy – 240 kcal, 35g prot
        ],
        3: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '8d860c45-1df3-4cb9-99de-25c55e01bf78'), // Shakshuka – 300 kcal, 18g prot
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'cbe9f2ae-b40a-4f38-a0b3-f2cca23a4251'), // Ensalada de garbanzos y espinacas – 300 kcal, 15g prot
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'f6d8c827-63fe-4301-839b-66e4dbd5a5f0'),    // Carpaccio de calabacín y parmesano – 150 kcal, 8g prot
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '636e83dc-c6ba-444b-8481-87c4d5950675'),     // Sepia a la plancha con alioli – 250 kcal, 35g prot
        ],
        4: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '16de268f-6fbf-43f9-b239-084df38e12c8'), // Huevos fritos con pisto – 250 kcal, 18g prot
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '3bc8d6b0-3ac5-4734-aaeb-6d256429ec5d'), // Ensalada mixta con atún – 250 kcal, 20g prot
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '1d9bc6b6-a5e1-47c3-973e-15bfc3622be9'),    // Edamame con sal – 189 kcal, 17g prot
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'e2b04513-e1ac-4bb5-95f4-7fb55146efcc'),     // Tortilla de calabacín – 250 kcal, 18g prot
        ],
        5: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'af84cb2a-8f9e-4a77-9121-8dfed0881033'), // Huevos benedictinos – 400 kcal, 18g prot
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '5787494c-cb06-43f7-887b-9aa9067eb925'), // Ternera a la jardinera – 350 kcal, 30g prot
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '093abc40-9391-4936-84a5-030ff7ce3280'),    // Setas a la plancha con perejil – 150 kcal, 5g prot
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '25b939a6-ac1d-4867-8142-84d4284864c2'),     // Ensalada de espinacas, fresas y queso – 250 kcal, 18g prot
        ],
        6: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '0722228b-745a-45dc-ac23-de852165138a'), // Huevos escoceses – 300 kcal, 15g prot
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '15251729-9e83-4b7c-a22f-654fd81aa783'), // Conejo al ajillo – 280 kcal, 35g prot
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'fba2b451-7334-4488-845f-6a907bfee232'),    // Dips de verduras con salsa de yogur – 150 kcal, 8g prot
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '532cf003-ae6f-4c49-8481-eaa5f5024bd8'),     // Tortilla de patatas con cebolla – 300 kcal, 15g prot
        ],
        7: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'recipe_batido_verde'),                  // Batido Verde Detox – 120 kcal, 2g prot
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '3c2f61e9-4cf8-461e-9cea-a3647bc8cede'), // Pollo al chilindrón – 350 kcal, 40g prot
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '9738f9a2-3c18-4d27-991a-a6860da12097'),    // Tzatziki – 150 kcal, 8g prot
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'f5ff054d-e3ea-4d2c-b52f-69e0da59b307'),     // Salmón a la plancha – 280 kcal, 34g prot
        ],
      },
    ),
    // ── Template 2: Ganancia Muscular ──
    // Design: ~2200-2500 kcal/day, very high protein (≥130g/day)
    // Breakfast: calorie-dense, protein-rich (~400-500 kcal)
    // Lunch: large, high-protein main (~450-600 kcal)
    // Snack: protein-rich (~250-350 kcal)
    // Dinner: high-protein main (~350-500 kcal)
    MealTemplate(
      name: 'Ganancia Muscular'.tr,
      days: {
        1: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '9ce6ec7a-900c-49ea-98ca-05051a6ce8eb'), // Huevos rancheros – 450 kcal, 20g prot
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '694c52f6-9ce7-4f0d-b03e-c2da2a796a2b'), // Cocido madrileño – 600 kcal, 45g prot
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '34004491-676b-4669-a5e8-38a48c84df26'),    // Croquetas de jamón serrano – 250 kcal, 18g prot
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'ef7894aa-edda-49bc-ab83-6f44c6f877a3'),     // Estofado de ternera con patatas – 350 kcal, 25g prot
        ],
        2: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'recipe_avena_nocturna'),                // Avena Nocturna Proteica – 350 kcal, 25g prot
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '4a29d2e5-c9b2-4754-8a24-cc7667cb79b9'), // Solomillo de cerdo al roquefort – 450 kcal, 35g prot
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '75025bfd-c6dc-4c52-b6e8-629c3c1d4da0'),    // Empanadillas de atún y tomate – 350 kcal, 20g prot
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '113ff5bc-8e6a-48b3-91a3-7b915e58775c'),     // Pollo al curry con leche de coco – 350 kcal, 28g prot
        ],
        3: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'af84cb2a-8f9e-4a77-9121-8dfed0881033'), // Huevos benedictinos – 400 kcal, 18g prot
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'c9931f07-d1b0-4430-8d44-50e8b9b53435'), // Lasaña de carne (boloñesa) – 450 kcal, 25g prot
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'edb02970-4e44-494c-aff8-ff394f2e5447'),    // Patatas bravas – 350 kcal, 10g prot
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'ba24853f-87b9-4004-b443-9dbfc305464f'),     // Costillas de cerdo a la barbacoa – 350 kcal, 25g prot
        ],
        4: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '863eefa7-2a0e-404b-b8e2-723f6cc4a6d6'), // Huevos fritos con patatas y pimientos – 350 kcal, 18g prot
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'b678c5e9-e77a-49d9-86a6-fd9433c69338'), // Pollo al horno con patatas – 450 kcal, 30g prot
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'd63c1177-e7fd-4eac-838a-4db3f4c4cf02'),    // Tabla de quesos y embutidos – 350 kcal, 20g prot
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '8b65889c-c627-417a-850d-edaa1061e392'),     // Hamburguesa casera completa – 350 kcal, 25g prot
        ],
        5: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '771b9935-fa25-4827-af1f-d4dfa0c8441d'), // Sandwich vegetal con huevo – 450 kcal, 20g prot
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '977943b0-c7e6-4669-a94e-cc01909d463f'), // Espaguetis a la carbonara – 500 kcal, 20g prot
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'f8f13aa8-f0a1-4711-b436-e8bb1a4b72b8'),    // Hummus clásico con crudités – 350 kcal, 18g prot
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '3c2f61e9-4cf8-461e-9cea-a3647bc8cede'),     // Pollo al chilindrón – 350 kcal, 40g prot
        ],
        6: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'a5210fc4-5257-4060-aada-a6ee258c546b'), // Tosta de aguacate y huevo poché – 350 kcal, 18g prot
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '89a8997d-087d-4043-930d-80e87129cdeb'), // Fajitas de pollo con pimientos – 350 kcal, 25g prot
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '41d37467-29fd-4756-b5e9-670a4ac5a493'),    // Huevos rellenos de atún – 250 kcal, 18g prot
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '5ed398e6-39ee-4708-895e-ca36659b9df9'),     // Chuletas de cordero a la brasa – 250 kcal, 30g prot
        ],
        7: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'd3b29188-7498-4cba-aa23-41ee9e04d2ef'), // Arroz a la cubana con huevo frito – 350 kcal, 18g prot
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '45103c98-e820-4162-9b8d-83b60c5df347'), // Fideuá de marisco – 350 kcal, 20g prot
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'ef8d136a-a21b-497b-b0e1-f8f185123652'),    // Empanadas criollas (carne) – 350 kcal, 18g prot
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'f5ff054d-e3ea-4d2c-b52f-69e0da59b307'),     // Salmón a la plancha – 280 kcal, 34g prot
        ],
      },
    ),
    // ── Template 3: Vegetariano Completo ──
    // Design: 100% vegetarian (verified via dietaryRestrictions), nutritionally complete
    // Ensures adequate protein through legumes, eggs, dairy, and plant sources
    // Variety of cuisines and cooking methods throughout the week
    MealTemplate(
      name: 'Vegetariano Completo'.tr,
      days: {
        1: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'recipe_avena_nocturna'),                // Avena Nocturna Proteica – 350 kcal, 25g prot
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '532cf003-ae6f-4c49-8481-eaa5f5024bd8'), // Tortilla de patatas con cebolla – 300 kcal, 15g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '57ada0d8-146c-4af8-a8ef-039ae0284387'),    // Champiñones al ajillo – 150 kcal, 7g prot (vegetariano+vegano)
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'd3ba8c5e-152d-49bd-bf9e-9676a1b86d04'),     // Pisto manchego con huevo frito – 350 kcal, 18g prot (vegetariano)
        ],
        2: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '8d860c45-1df3-4cb9-99de-25c55e01bf78'), // Shakshuka – 300 kcal, 18g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'f1750881-a1fa-40a7-93d5-0e399c56cef8'), // Macarrones con tomate y queso – 450 kcal, 18g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '1d9bc6b6-a5e1-47c3-973e-15bfc3622be9'),    // Edamame con sal – 189 kcal, 17g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '0c265671-e26b-4868-bddc-c91004825e15'),     // Risotto de setas y parmesano – 350 kcal, 12g prot (vegetariano)
        ],
        3: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '16de268f-6fbf-43f9-b239-084df38e12c8'), // Huevos fritos con pisto – 250 kcal, 18g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'ba46b513-5438-4d8c-8e76-5fb4c8bfbdc1'), // Alubias pintas con arroz – 350 kcal, 18g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'fba2b451-7334-4488-845f-6a907bfee232'),    // Dips de verduras con salsa de yogur – 150 kcal, 8g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '88d6cb67-be52-4153-b47a-55444274232e'),     // Pizza casera margarita – 300 kcal, 15g prot (vegetariano)
        ],
        4: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'a5210fc4-5257-4060-aada-a6ee258c546b'), // Tosta de aguacate y huevo poché – 350 kcal, 18g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'd3b29188-7498-4cba-aa23-41ee9e04d2ef'), // Arroz a la cubana con huevo frito – 350 kcal, 18g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '2acd84bf-0fff-4010-948e-4be4a2d8dafd'),    // Champiñones portobello gratinados – 250 kcal, 12g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '19c26f61-5bfb-4676-80f8-733f10ff03c7'),     // Canelones de espinacas y ricota – 350 kcal, 18g prot (vegetariano)
        ],
        5: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '863eefa7-2a0e-404b-b8e2-723f6cc4a6d6'), // Huevos fritos con patatas y pimientos – 350 kcal, 18g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'dc066a48-aa9f-4b2e-83c8-c3453866348c'), // Ensalada de lentejas y queso feta – 350 kcal, 20g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'ed704d1f-d994-4b4d-80bc-7627f194d71f'),    // Spanakopita – 300 kcal, 15g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'e2b04513-e1ac-4bb5-95f4-7fb55146efcc'),     // Tortilla de calabacín – 250 kcal, 18g prot (vegetariano)
        ],
        6: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'a8ba6082-d20e-4885-8041-3f178b6fa9b1'), // Crepes de espinacas y queso – 300 kcal, 15g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'a07e1024-def3-41ac-ac38-3bd60f90d136'), // Chili sin carne (Vegetariano) – 300 kcal, 12g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'ab052372-10c2-44a5-b00a-af1a6ec224ea'),    // Edamame picante – 200 kcal, 17g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '1d61f5e7-0993-48a1-b756-b25fa68103d4'),     // Tortilla de espinacas – 250 kcal, 18g prot (vegetariano)
        ],
        7: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '9ce6ec7a-900c-49ea-98ca-05051a6ce8eb'), // Huevos rancheros – 450 kcal, 20g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '8102b127-0629-4479-9d69-76cb9448217c'), // Lasaña de verduras – 350 kcal, 18g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '9b5ac744-5811-4fc0-b0ec-9323e7e7cac2'),    // Tartar de tomate y aguacate – 300 kcal, 15g prot (vegetariano)
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'b2f0a2ac-c6bf-4b03-9294-6f2cb5ebc531'),     // Ensalada de garbanzos con comino – 350 kcal, 18g prot (vegetariano)
        ],
      },
    ),
    // ── Template 4: Rápido y Fácil ──
    // Design: All recipes ≤30 min prep time, simple cooking methods
    // Focused on convenience without sacrificing nutrition
    MealTemplate(
      name: 'Rápido y Fácil'.tr,
      days: {
        1: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'recipe_avena_nocturna'),                // Avena Nocturna Proteica – 5 min
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '89a8997d-087d-4043-930d-80e87129cdeb'), // Fajitas de pollo – 30 min
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '9738f9a2-3c18-4d27-991a-a6860da12097'),    // Tzatziki – 20 min
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'f5ff054d-e3ea-4d2c-b52f-69e0da59b307'),     // Salmón a la plancha – 15 min
        ],
        2: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'a5210fc4-5257-4060-aada-a6ee258c546b'), // Tosta de aguacate y huevo poché – 15 min
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'f1750881-a1fa-40a7-93d5-0e399c56cef8'), // Macarrones con tomate y queso – 30 min
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '093abc40-9391-4936-84a5-030ff7ce3280'),    // Setas a la plancha – 20 min
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'cf1d913c-5a77-4456-b7f1-ae007c5faeff'),     // Huevos rotos con jamón – 15 min
        ],
        3: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '8d860c45-1df3-4cb9-99de-25c55e01bf78'), // Shakshuka – 30 min
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '25b939a6-ac1d-4867-8142-84d4284864c2'), // Ensalada de espinacas, fresas y queso – 15 min
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '57ada0d8-146c-4af8-a8ef-039ae0284387'),    // Champiñones al ajillo – 30 min
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'a5feb510-0947-4b9e-8150-ccc6b1519681'),     // Emperador a la plancha – 20 min
        ],
        4: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '0722228b-745a-45dc-ac23-de852165138a'), // Huevos escoceses – 15 min
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'd3b29188-7498-4cba-aa23-41ee9e04d2ef'), // Arroz a la cubana – 30 min
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '3cde107c-719c-4739-aaff-9ec3b1fff991'),    // Espárragos a la plancha – 15 min
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '5ed398e6-39ee-4708-895e-ca36659b9df9'),     // Chuletas de cordero – 20 min
        ],
        5: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: 'recipe_batido_verde'),                  // Batido Verde Detox – 5 min
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: 'd3ba8c5e-152d-49bd-bf9e-9676a1b86d04'), // Pisto manchego con huevo – 30 min
          const TemplateMealEntry(mealType: MealType.snack, recipeId: '1f69ad92-68d1-4eeb-be9b-69bb86ebe0bc'),    // Bastones de boniato al horno – 25 min
          const TemplateMealEntry(mealType: MealType.cena, recipeId: 'fe04a516-994d-4b5c-abe1-cf3863c53d37'),     // Pechugas de pollo Villaroy – 30 min
        ],
        6: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '16de268f-6fbf-43f9-b239-084df38e12c8'), // Huevos fritos con pisto – 30 min
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '43941400-3f85-4050-b531-997ba320b1cb'), // Salmorejo cordobés – 20 min
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'f6d8c827-63fe-4301-839b-66e4dbd5a5f0'),    // Carpaccio de calabacín – 15 min
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '532cf003-ae6f-4c49-8481-eaa5f5024bd8'),     // Tortilla de patatas – 30 min (prep 15)
        ],
        7: [
          const TemplateMealEntry(mealType: MealType.desayuno, recipeId: '863eefa7-2a0e-404b-b8e2-723f6cc4a6d6'), // Huevos fritos con patatas y pimientos – 30 min
          const TemplateMealEntry(mealType: MealType.almuerzo, recipeId: '39dd5b2e-9efc-413d-a9ae-a72df06f6987'), // Pollo asado al limón – 30 min (can prep faster)
          const TemplateMealEntry(mealType: MealType.snack, recipeId: 'edb02970-4e44-494c-aff8-ff394f2e5447'),    // Patatas bravas – 30 min
          const TemplateMealEntry(mealType: MealType.cena, recipeId: '636e83dc-c6ba-444b-8481-87c4d5950675'),     // Sepia a la plancha – 30 min
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



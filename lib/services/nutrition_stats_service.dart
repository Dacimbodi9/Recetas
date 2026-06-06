import 'package:recetas/l10n.dart';
import 'package:recetas/models/models.dart';
import 'package:recetas/services/settings_manager.dart';
import 'package:recetas/services/recipe_manager.dart';
import 'package:recetas/services/meal_plan_manager.dart';

class NutritionStatsService {
  /// Get completed meals for a specific date
  static List<PlannedMeal> _getCompletedMealsForDate(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return MealPlanManager.meals.where((m) => m.dateKey == key && m.completed).toList();
  }

  /// Get completed meals for a date range (inclusive)
  static List<PlannedMeal> _getCompletedMealsForRange(DateTime start, DateTime end) {
    final meals = <PlannedMeal>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(endDate)) {
      meals.addAll(_getCompletedMealsForDate(current));
      current = current.add(const Duration(days: 1));
    }
    return meals;
  }

  /// Look up a Recipe by its ID
  static Recipe? _findRecipe(String recipeId) {
    return RecipeManager.recipes.where((r) => r.id == recipeId || r.title == recipeId).firstOrNull;
  }

  /// Sum nutrition facts from a list of meals
  static Map<String, double> _sumNutrition(List<PlannedMeal> meals) {
    final totals = <String, double>{};
    for (final meal in meals) {
      final recipe = _findRecipe(meal.recipeId);
      if (recipe == null) continue;
      for (final fact in recipe.nutritionFacts) {
        final key = fact.label.toLowerCase();
        totals[key] = (totals[key] ?? 0) + fact.value;
      }
    }
    return totals;
  }

  /// Get total nutrition for a specific date from completed meals
  static Map<String, double> getNutritionForDate(DateTime date) {
    return _sumNutrition(_getCompletedMealsForDate(date));
  }

  /// Get nutrition aggregated over a date range
  static Map<String, double> getNutritionForDateRange(DateTime start, DateTime end) {
    return _sumNutrition(_getCompletedMealsForRange(start, end));
  }

  /// Get daily nutrition values for each day in a range (for bar charts)
  static List<Map<String, double>> getDailyNutritionList(DateTime start, DateTime end) {
    final result = <Map<String, double>>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(endDate)) {
      result.add(getNutritionForDate(current));
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  /// Get weekly averages for the last 4 weeks (for monthly chart)
  static List<Map<String, double>> getWeeklyAverages() {
    final result = <Map<String, double>>[];
    final now = DateTime.now();
    for (int week = 3; week >= 0; week--) {
      final weekEnd = DateTime(now.year, now.month, now.day).subtract(Duration(days: week * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      final weekData = getNutritionForDateRange(weekStart, weekEnd);
      // Average per day
      final avg = <String, double>{};
      for (final entry in weekData.entries) {
        avg[entry.key] = entry.value / 7;
      }
      result.add(avg);
    }
    return result;
  }

  /// Get monthly averages for the last 12 months (for yearly chart)
  static List<Map<String, double>> getMonthlyAverages() {
    final result = <Map<String, double>>[];
    final now = DateTime.now();
    for (int month = 11; month >= 0; month--) {
      final m = DateTime(now.year, now.month - month, 1);
      final mEnd = DateTime(m.year, m.month + 1, 0); // Last day of month
      final monthData = getNutritionForDateRange(m, mEnd);
      final daysInMonth = mEnd.day;
      final avg = <String, double>{};
      for (final entry in monthData.entries) {
        avg[entry.key] = entry.value / daysInMonth;
      }
      result.add(avg);
    }
    return result;
  }

  /// Get macro distribution as percentages for a date
  static Map<String, double> getMacroDistribution(DateTime date) {
    final nutrition = getNutritionForDate(date);
    final protein = nutrition['proteína'] ?? nutrition['proteínas'] ?? nutrition['proteins'] ?? nutrition['protein'] ?? 0;
    final carbs = nutrition['carbohidratos'] ?? nutrition['carbohydrates'] ?? nutrition['carbs'] ?? 0;
    final fat = nutrition['grasas'] ?? nutrition['fats'] ?? nutrition['fat'] ?? 0;
    
    // Convert to calories: protein 4cal/g, carbs 4cal/g, fat 9cal/g
    final proteinCal = protein * 4;
    final carbsCal = carbs * 4;
    final fatCal = fat * 9;
    final total = proteinCal + carbsCal + fatCal;
    
    if (total == 0) return {'proteínas': 0, 'carbohidratos': 0, 'grasas': 0};
    
    return {
      'proteínas': (proteinCal / total) * 100,
      'carbohidratos': (carbsCal / total) * 100,
      'grasas': (fatCal / total) * 100,
    };
  }

  /// Get most consumed recipes in last N days
  static List<MapEntry<Recipe, int>> getMostConsumedRecipes(int days) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
    final meals = _getCompletedMealsForRange(start, DateTime(now.year, now.month, now.day));
    
    final counts = <String, int>{};
    for (final meal in meals) {
      counts[meal.recipeId] = (counts[meal.recipeId] ?? 0) + 1;
    }
    
    final result = <MapEntry<Recipe, int>>[];
    for (final entry in counts.entries) {
      final recipe = _findRecipe(entry.key);
      if (recipe != null) {
        result.add(MapEntry(recipe, entry.value));
      }
    }
    
    result.sort((a, b) => b.value.compareTo(a.value));
    return result.take(5).toList();
  }

  /// Get consecutive streak days (days with at least one completed meal)
  static int getStreakDays() {
    final now = DateTime.now();
    var current = DateTime(now.year, now.month, now.day);
    int streak = 0;
    
    while (true) {
      final meals = _getCompletedMealsForDate(current);
      if (meals.isEmpty) break;
      streak++;
      current = current.subtract(const Duration(days: 1));
    }
    
    return streak;
  }

  /// Get category distribution for last N days
  static Map<RecipeCategory, int> getCategoryDistribution(int days) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
    final meals = _getCompletedMealsForRange(start, DateTime(now.year, now.month, now.day));
    
    final counts = <RecipeCategory, int>{};
    for (final meal in meals) {
      final recipe = _findRecipe(meal.recipeId);
      if (recipe != null) {
        for (final cat in recipe.categories) {
          counts[cat] = (counts[cat] ?? 0) + 1;
        }
      }
    }
    
    return counts;
  }

  /// Calculate BMI from user profile
  static double? calculateBMI() {
    final weight = SettingsManager.userWeight.value;
    final height = SettingsManager.userHeight.value;
    if (weight == null || height == null || height == 0) return null;
    return weight / ((height / 100) * (height / 100));
  }

  /// Get BMI category label
  static String? getBMICategory() {
    final bmi = calculateBMI();
    if (bmi == null) return null;
    if (bmi < 18.5) return 'Bajo peso'.tr;
    if (bmi < 25) return 'Normal'.tr;
    if (bmi < 30) return 'Sobrepeso'.tr;
    return 'Obesidad'.tr;
  }

  /// Calculate BMR using Mifflin-St Jeor equation
  static double? calculateBMR() {
    final weight = SettingsManager.userWeight.value;
    final height = SettingsManager.userHeight.value;
    final age = SettingsManager.userAge.value;
    final sex = SettingsManager.userSex.value;
    if (weight == null || height == null || age == null || sex == null) return null;
    
    // Mifflin-St Jeor: 10×weight(kg) + 6.25×height(cm) − 5×age + constant
    final base = 10 * weight + 6.25 * height - 5 * age;
    return sex == 'male' ? base + 5 : base - 161;
  }

  static double? calculateTDEE() {
    final bmr = calculateBMR();
    if (bmr == null) return null;
    final activityMultiplier = SettingsManager.userActivityLevel.value ?? 1.55;
    return bmr * activityMultiplier;
  }

  /// Get daily calorie goal based on TDEE, or null if no profile
  static double? getDailyCalorieGoal() {
    return calculateTDEE();
  }

  /// Get the total number of completed meals across all time
  static int getTotalCompletedMeals() {
    return MealPlanManager.meals.where((m) => m.completed).length;
  }

  /// Get details of completed meals for a date with recipe info
  static List<MapEntry<PlannedMeal, Recipe>> getCompletedMealDetails(DateTime date) {
    final meals = _getCompletedMealsForDate(date);
    final result = <MapEntry<PlannedMeal, Recipe>>[];
    for (final meal in meals) {
      final recipe = _findRecipe(meal.recipeId);
      if (recipe != null) {
        result.add(MapEntry(meal, recipe));
      }
    }
    return result;
  }
}



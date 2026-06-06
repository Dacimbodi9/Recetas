import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recetas/models/models.dart';
import 'package:recetas/l10n.dart';
import 'package:recetas/services/settings_manager.dart';
import 'package:recetas/services/snackbar_service.dart';
import 'package:recetas/utils/json_utils.dart';

class RecipeManager {
  static const String _storageKey = 'saved_recipes';
  static const String _favoritesKey = 'favorite_recipes';
  static const String _foldersKey = 'favorite_folders';
  static const String _customMappingsKey = 'custom_ingredient_mappings';
  static const String _customImagesKey = 'custom_recipe_images';

  static final List<IconData> availableFolderIcons = [
    CupertinoIcons.folder,
    CupertinoIcons.book,
    CupertinoIcons.star,
    CupertinoIcons.bookmark,
    CupertinoIcons.flame,
    CupertinoIcons.tag,
    CupertinoIcons.collections,
    CupertinoIcons.clock,
    Icons.restaurant,
    Icons.restaurant_menu,
    Icons.cake,
    Icons.fastfood,
    Icons.local_pizza,
    Icons.local_cafe,
    Icons.local_bar,
    Icons.set_meal,
    Icons.soup_kitchen,
    Icons.rice_bowl,
    Icons.icecream,
    Icons.bakery_dining,
    Icons.breakfast_dining,
    Icons.egg_alt,
    Icons.kitchen,
    Icons.eco,
  ];

  static final List<Recipe> _defaultRecipes = [];
  static final List<Recipe> _recipes = [];
  static final List<Function()> _listeners = [];
  static Set<String> _favoriteIds = {};
  static List<FavoriteFolder> _folders = [];
  static Map<String, String> _customImages = {};
  static Map<String, IngredientCategory> _customMappings = {};

  static Set<String> get allCustomDietaryTags {
    final tags = <String>{};
    for (final recipe in _recipes) {
      tags.addAll(recipe.customDietaryTags);
    }
    return tags;
  }

  static IngredientCategory? getCategoryForIngredient(String ingredient) =>
      _customMappings[ingredient.toLowerCase()];

  static String? getCustomImage(String recipeTitle) =>
      _customImages[recipeTitle];

  static Future<void> setCustomImage(String recipeTitle, String path) async {
    _customImages[recipeTitle] = path;
    await _saveCustomImages();
    _notifyListeners();
  }

  static Future<void> _saveCustomImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customImagesKey, json.encode(_customImages));
    } catch (e) {
      debugPrint('Error saving custom images: $e'); SnackbarService.showError('${'Error'.tr} saving custom images: $e');
    }
  }

  static Future<void> addCustomMapping(
    String ingredient,
    IngredientCategory category,
  ) async {
    _customMappings[ingredient.toLowerCase()] = category;
    await _saveCustomMappings();
    _notifyListeners();
  }

  static Future<void> _saveCustomMappings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _customMappings.map((k, v) => MapEntry(k, v.index));
      await prefs.setString(_customMappingsKey, json.encode(map));
    } catch (e) {
      debugPrint('Error saving custom mappings: $e'); SnackbarService.showError('${'Error'.tr} saving custom mappings: $e');
    }
  }

  static List<Recipe> get recipes {
    final defaultTitles = _defaultRecipes.map((r) => r.title).toSet();

    if (!SettingsManager.showDefaultRecipes.value) {
      return _recipes.where((r) {
        final isTitleDefault = defaultTitles.contains(r.title);
        if (!isTitleDefault) return true;
        return !isDefaultRecipe(r) || isFavorite(r);
      }).toList();
    }

    final userTitles = _recipes.map((r) => r.title).toSet();
    final nonOverriddenDefaults = _defaultRecipes.where(
      (r) => !userTitles.contains(r.title),
    );
    final allRecipes = [...nonOverriddenDefaults, ..._recipes];

    if (SettingsManager.hideIncompatibleRecipes.value) {
      return allRecipes.where((r) => isRecipeCompatible(r)).toList();
    }

    return allRecipes;
  }

  static Recipe? getRecipeById(String id) {
    return [..._defaultRecipes, ..._recipes].where((r) => r.id == id).firstOrNull;
  }

  static bool isRecipeCompatible(Recipe recipe) {
    if (SettingsManager.dietaryDefaults.value.isEmpty &&
        SettingsManager.customDietaryDefaults.value.isEmpty) {
      return true;
    }

    final isDefault = isDefaultRecipe(recipe);
    final applyToDefaults = SettingsManager.applyDietaryToDefaults.value;

    if (isDefault && !applyToDefaults) return true;

    final permanentFilters = SettingsManager.dietaryDefaults.value;
    final customPermanentFilters = SettingsManager.customDietaryDefaults.value;

    final standardCompatible =
        permanentFilters.isEmpty ||
        permanentFilters.every((f) => recipe.dietaryRestrictions.contains(f));

    final customCompatible =
        customPermanentFilters.isEmpty ||
        customPermanentFilters.every(
          (t) => recipe.customDietaryTags.contains(t),
        );

    return standardCompatible && customCompatible;
  }

  static List<String>? _cachedIngredients;
  static int _lastRecipeCount = 0;

  static List<String> get allIngredients {
    final currentCount = recipes.length;
    if (_cachedIngredients != null && _lastRecipeCount == currentCount) {
      return _cachedIngredients!;
    }

    final Set<String> ingredients = {};
    for (final recipe in recipes) {
      for (final ingredient in recipe.ingredients) {
        final normalized = ingredient.trim().toLowerCase();
        if (normalized.isNotEmpty) {
          ingredients.add(normalized);
        }
      }
    }
    _cachedIngredients = ingredients.toList()..sort();
    _lastRecipeCount = currentCount;
    return _cachedIngredients!;
  }

  static bool isDefaultRecipe(Recipe recipe) {
    final isDirectDefault = _defaultRecipes.contains(recipe);
    if (isDirectDefault) return true;

    final defaultMatch = _defaultRecipes
        .where((r) => r.id == recipe.id)
        .firstOrNull;
    if (defaultMatch == null) return false;

    final bool contentMatches =
        listEquals(recipe.ingredients, defaultMatch.ingredients) &&
        listEquals(recipe.steps, defaultMatch.steps) &&
        listEquals(
          recipe.detailedIngredients.map((e) => e.toJson().toString()).toList(),
          defaultMatch.detailedIngredients
              .map((e) => e.toJson().toString())
              .toList(),
        ) &&
        listEquals(recipe.categories, defaultMatch.categories) &&
        listEquals(
          recipe.dietaryRestrictions,
          defaultMatch.dietaryRestrictions,
        ) &&
        recipe.imagePath == defaultMatch.imagePath &&
        recipe.prepTime == defaultMatch.prepTime;

    return contentMatches;
  }

  static Future<void> loadDefaultRecipes() async {
    try {
      final isEnglish = SettingsManager.language.value == 'en';
      final String jsonString = await rootBundle.loadString(
        isEnglish ? 'assets/data/recipes_en.json' : 'assets/data/recipes.json',
      );
      final List<dynamic> jsonData = await compute(decodeJsonList, jsonString);

      _defaultRecipes.clear();
      for (final item in jsonData) {
        if (item is Map<String, dynamic>) {
          try {
            _defaultRecipes.add(Recipe.fromJson(item));
          } catch (e) {
            debugPrint(
              'Error loading recipe "${item['title'] ?? 'unknown'}": $e',
            );
          }
        }
      }
      _notifyListeners();
    } catch (e) {
      debugPrint('Error loading default recipes from JSON: $e'); SnackbarService.showError('${'Error'.tr} loading default recipes from JSON: $e');
      _defaultRecipes.clear();
    }
  }

  static Future<void> addRecipe(Recipe recipe) async {
    final index = _recipes.indexWhere((r) => r.id == recipe.id);
    if (index != -1) {
      _recipes[index] = recipe;
    } else {
      _recipes.add(recipe);
    }
    await _saveRecipes();
    _notifyListeners();
  }

  static Recipe? _lastDeletedRecipe;

  static Future<void> removeRecipe(Recipe recipe) async {
    _lastDeletedRecipe = recipe;
    _recipes.removeWhere((r) => r.id == recipe.id);
    await _saveRecipes();
    _notifyListeners();
    
    // Auto-clear cache after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (_lastDeletedRecipe?.id == recipe.id) _lastDeletedRecipe = null;
    });
  }

  static Future<void> undoRemoveRecipe() async {
    if (_lastDeletedRecipe != null) {
      _recipes.add(_lastDeletedRecipe!);
      _lastDeletedRecipe = null;
      await _saveRecipes();
      _notifyListeners();
    }
  }

  static Future<void> loadRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recipesJson = prefs.getStringList(_storageKey) ?? [];

      _recipes.clear();
      for (final recipeJson in recipesJson) {
        final recipeMap = json.decode(recipeJson) as Map<String, dynamic>;
        _recipes.add(Recipe.fromJson(recipeMap));
      }

      final favoriteIdsList = prefs.getStringList(_favoritesKey) ?? [];
      _favoriteIds = favoriteIdsList.toSet();

      final foldersJson = prefs.getString(_foldersKey);
      if (foldersJson != null) {
        try {
          final foldersList = json.decode(foldersJson) as List;
          _folders = foldersList
              .map((f) => FavoriteFolder.fromJson(f as Map<String, dynamic>))
              .toList();
        } catch (e) {
          debugPrint('Error loading folders: $e'); SnackbarService.showError('${'Error'.tr} loading folders: $e');
          _folders = [];
        }
      } else {
        _folders = [];
      }

      final mappingsJson = prefs.getString(_customMappingsKey);
      if (mappingsJson != null) {
        try {
          final Map<String, dynamic> decoded = json.decode(mappingsJson);
          _customMappings = decoded.map(
            (k, v) => MapEntry(k, IngredientCategory.values[v as int]),
          );
        } catch (e) {
          debugPrint('Error loading custom mappings: $e'); SnackbarService.showError('${'Error'.tr} loading custom mappings: $e');
          _customMappings = {};
        }
      }

      final imagesJson = prefs.getString(_customImagesKey);
      if (imagesJson != null) {
        try {
          final Map<String, dynamic> decoded = json.decode(imagesJson);
          _customImages = decoded.map((k, v) => MapEntry(k, v as String));
        } catch (e) {
          debugPrint('Error loading custom images: $e'); SnackbarService.showError('${'Error'.tr} loading custom images: $e');
          _customImages = {};
        }
      }

      _notifyListeners();
    } catch (e) {
      debugPrint('Error loading recipes: $e'); SnackbarService.showError('${'Error'.tr} loading recipes: $e');
    }
  }

  static bool isFavorite(Recipe recipe) => _favoriteIds.contains(recipe.id);

  static Future<void> toggleFavorite(Recipe recipe) async {
    if (_favoriteIds.contains(recipe.id)) {
      _favoriteIds.remove(recipe.id);
    } else {
      _favoriteIds.add(recipe.id);
    }
    await _saveFavorites();
    _notifyListeners();
  }

  static List<Recipe> get favoriteRecipes =>
      recipes.where((recipe) => _favoriteIds.contains(recipe.id)).toList();

  static Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, _favoriteIds.toList());
    } catch (e) {
      debugPrint('Error saving favorites: $e'); SnackbarService.showError('${'Error'.tr} saving favorites: $e');
    }
  }

  static List<FavoriteFolder> get rootFolders =>
      _folders.where((f) => f.parentId == null).toList();

  static Future<void> rateRecipe(Recipe recipe, double rating) async {
    final updatedRecipe = recipe.copyWith(
      rating: rating,
      dateRated: DateTime.now(),
    );

    final index = _recipes.indexWhere((r) => r.id == recipe.id);
    if (index != -1) {
      _recipes[index] = updatedRecipe;
    } else {
      _recipes.add(updatedRecipe);
    }

    await _saveRecipes();
    _notifyListeners();
  }

  static List<Recipe> get ratedRecipes {
    final rated = _recipes
        .where((r) => r.rating != null && r.rating! > 0)
        .toList();
    if (!SettingsManager.showDefaultRecipes.value) {
      return rated.where((r) => !isDefaultRecipe(r)).toList();
    }
    return rated;
  }

  static List<FavoriteFolder> get allFolders => List.unmodifiable(_folders);

  static FavoriteFolder? getFolderById(String id) {
    try {
      return _folders.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<FavoriteFolder> getSubFolders(String parentId) =>
      _folders.where((f) => f.parentId == parentId).toList();

  static List<FavoriteFolder> getSubFoldersRecursive(String folderId) {
    final subFolders = getSubFolders(folderId);
    final result = <FavoriteFolder>[...subFolders];
    for (final subFolder in subFolders) {
      result.addAll(getSubFoldersRecursive(subFolder.id));
    }
    return result;
  }

  static List<Recipe> getRecipesInFolder(FavoriteFolder folder) =>
      recipes.where((r) => folder.recipeIds.contains(r.id)).toList();

  static List<Recipe> getRecipesInFolderRecursive(String folderId) {
    final folder = getFolderById(folderId);
    if (folder == null) return [];
    final result = <Recipe>[...getRecipesInFolder(folder)];
    final subFolders = getSubFolders(folderId);
    for (final subFolder in subFolders) {
      result.addAll(getRecipesInFolderRecursive(subFolder.id));
    }
    return result.toSet().toList();
  }

  static Future<void> addFolder(FavoriteFolder folder) async {
    _folders.add(folder);
    await _saveFolders();
    _notifyListeners();
  }

  static Future<void> updateFolder(FavoriteFolder folder) async {
    final index = _folders.indexWhere((f) => f.id == folder.id);
    if (index != -1) {
      _folders[index] = folder;
      await _saveFolders();
      _notifyListeners();
    }
  }

  static Future<void> deleteFolder(String folderId) async {
    _removeFolderRecursive(folderId);
    await _saveFolders();
    _notifyListeners();
  }

  static void _removeFolderRecursive(String folderId) {
    final subFolders = _folders.where((f) => f.parentId == folderId).toList();
    for (final subFolder in subFolders) {
      _removeFolderRecursive(subFolder.id);
    }
    _folders.removeWhere((f) => f.id == folderId);
  }

  static Future<void> addRecipeToFolder(String folderId, Recipe recipe) async {
    final folder = getFolderById(folderId);
    if (folder != null && !folder.recipeIds.contains(recipe.id)) {
      final updatedFolder = folder.copyWith(
        recipeIds: [...folder.recipeIds, recipe.id],
      );
      await updateFolder(updatedFolder);
    }
  }

  static Future<void> removeRecipeFromFolder(
    String folderId,
    Recipe recipe,
  ) async {
    final folder = getFolderById(folderId);
    if (folder != null && folder.recipeIds.contains(recipe.id)) {
      final updatedFolder = folder.copyWith(
        recipeIds: folder.recipeIds.where((t) => t != recipe.id).toList(),
      );
      await updateFolder(updatedFolder);
    }
  }

  static Future<void> _saveFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final foldersJson = json.encode(_folders.map((f) => f.toJson()).toList());
      await prefs.setString(_foldersKey, foldersJson);
    } catch (e) {
      debugPrint('Error saving folders: $e'); SnackbarService.showError('${'Error'.tr} saving folders: $e');
    }
  }

  static Future<List<Recipe>> getCustomRecipes() async {
    final defaultIds = _defaultRecipes.map((r) => r.id).toSet();
    return _recipes.where((r) => !defaultIds.contains(r.id)).toList();
  }

  static Future<void> clearAllData() async {
    _recipes.clear();
    _folders.clear();
    _favoriteIds.clear();
    _customMappings.clear();
    _customImages.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_favoritesKey);
    await prefs.remove(_foldersKey);
    await prefs.remove(_customMappingsKey);
    await prefs.remove(_customImagesKey);

    _notifyListeners();
  }

  static Future<void> _saveRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recipesJson = _recipes.map((r) => json.encode(r.toJson())).toList();
      await prefs.setStringList(_storageKey, recipesJson);
    } catch (e) {
      debugPrint('Error saving recipes: $e'); SnackbarService.showError('${'Error'.tr} saving recipes: $e');
    }
  }

  static final ValueNotifier<int> listenable = ValueNotifier<int>(0);
  static void addListener(Function() listener) {
    _listeners.add(listener);
    listenable.addListener(listener);
  }
  static void removeListener(Function() listener) {
    _listeners.remove(listener);
    listenable.removeListener(listener);
  }
  static void notifyListeners() => _notifyListeners();

  static void _notifyListeners() {
    _cachedIngredients = null;
    _lastRecipeCount = 0;
    listenable.value++;
    for (final listener in List.from(_listeners)) {
      listener();
    }
  }
}


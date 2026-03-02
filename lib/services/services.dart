// ignore_for_file: unused_local_variable
// ignore_for_file: use_build_context_synchronously
// ignore_for_file: deprecated_member_use
// ignore_for_file: constant_identifier_names
// ignore_for_file: avoid_print
part of '../main.dart';

class SettingsManager {
  static final ValueNotifier<bool> isDarkMode = ValueNotifier(true);
  static final ValueNotifier<bool> showDefaultRecipes = ValueNotifier(false);
  static final ValueNotifier<bool> preventSleep = ValueNotifier(false);
  static final ValueNotifier<int> startScreenIndex = ValueNotifier(
    0,
  ); // 0: Search, 1: Favorites
  static final ValueNotifier<Set<DietaryRestriction>> dietaryDefaults =
      ValueNotifier({});

  static final ValueNotifier<Set<String>> customDietaryDefaults = ValueNotifier(
    {},
  );
  static final ValueNotifier<bool> hasSeenOnboarding = ValueNotifier(false);
  static final ValueNotifier<String> language = ValueNotifier('es');

  static const _themeKey = 'is_dark_mode';
  static const _languageKey = 'app_language';
  static const _defaultsKey = 'show_default_recipes';
  static const _preventSleepKey = 'prevent_sleep';
  static const _startScreenKey = 'start_screen_index';
  static const _dietaryDefaultsKey = 'dietary_defaults';

  static const _customDietaryDefaultsKey = 'custom_dietary_defaults';
  static const _onboardingKey = 'has_seen_onboarding';

  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Check system brightness if no preference is saved
    final systemBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    isDarkMode.value =
        prefs.getBool(_themeKey) ?? (systemBrightness == Brightness.dark);
    showDefaultRecipes.value = prefs.getBool(_defaultsKey) ?? true;

    preventSleep.value = prefs.getBool(_preventSleepKey) ?? false;
    if (preventSleep.value) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }

    startScreenIndex.value = prefs.getInt(_startScreenKey) ?? 0;

    final dietaryList = prefs.getStringList(_dietaryDefaultsKey) ?? [];
    dietaryDefaults.value = dietaryList
        .map(
          (e) => DietaryRestriction.values.firstWhere(
            (r) => r.name == e,
            orElse: () => DietaryRestriction.vegetariano,
          ),
        )
        .toSet();

    final customDietaryList =
        prefs.getStringList(_customDietaryDefaultsKey) ?? [];
    customDietaryDefaults.value = customDietaryList.toSet();

    applyDietaryToDefaults.value = prefs.getBool(_applyToDefaultsKey) ?? false;
    hideIncompatibleRecipes.value =
        prefs.getBool(_hideIncompatibleKey) ?? false;
    hasSeenOnboarding.value = prefs.getBool(_onboardingKey) ?? false;
    final deviceLocale = Platform.localeName;
    final defaultLang = deviceLocale.startsWith('es') ? 'es' : 'en';
    language.value = prefs.getString(_languageKey) ?? defaultLang;
    AppLocalization.instance.setLanguage(language.value);
  }

  static Future<void> setLanguage(String lang) async {
    AppLocalization.instance.setLanguage(lang);
    language.value = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, lang);
    await RecipeManager.loadDefaultRecipes();
    RecipeManager.notifyListeners();
  }

  static Future<void> completeOnboarding() async {
    hasSeenOnboarding.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  static Future<void> setDarkMode(bool value) async {
    isDarkMode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
  }

  static Future<void> setStartScreenIndex(int index) async {
    startScreenIndex.value = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_startScreenKey, index);
  }

  static Future<void> setPreventSleep(bool value) async {
    preventSleep.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preventSleepKey, value);
    if (value) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  static Future<void> toggleDietaryDefault(
    DietaryRestriction restriction,
  ) async {
    final current = Set<DietaryRestriction>.from(dietaryDefaults.value);
    if (current.contains(restriction)) {
      current.remove(restriction);
    } else {
      current.add(restriction);
    }
    dietaryDefaults.value = current;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _dietaryDefaultsKey,
      current.map((e) => e.name).toList(),
    );
    RecipeManager.notifyListeners();
  }

  static Future<void> toggleCustomDietaryDefault(String tag) async {
    final current = Set<String>.from(customDietaryDefaults.value);
    if (current.contains(tag)) {
      current.remove(tag);
    } else {
      current.add(tag);
    }
    customDietaryDefaults.value = current;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customDietaryDefaultsKey, current.toList());
    RecipeManager.notifyListeners();
  }

  static Future<void> setShowDefaults(bool value) async {
    showDefaultRecipes.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_defaultsKey, value);
    // Notify RecipeManager listeners to refresh the list
    RecipeManager.notifyListeners();
  }

  static final ValueNotifier<bool> applyDietaryToDefaults = ValueNotifier(
    false,
  );
  static const _applyToDefaultsKey = 'apply_dietary_to_defaults';

  static Future<void> setApplyDietaryToDefaults(bool value) async {
    applyDietaryToDefaults.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_applyToDefaultsKey, value);
    // Notify to refresh UI (RecipeCards might need rebuild or just ValueListenableBuilder)
    // Since RecipeCard reads this ValueNotifier in build, we might need to trigger rebuild.
    // However, RecipeCard isn't listening to it directly yet.
    // Best way is to rely on setState at page level or wrap RecipeCard content in ValueListenableBuilder.
    // For now, let's just save. The UI update depends on how we consume it.
    RecipeManager.notifyListeners();
  }

  static final ValueNotifier<bool> hideIncompatibleRecipes = ValueNotifier(
    false,
  );
  static const _hideIncompatibleKey = 'hide_incompatible_recipes';

  static Future<void> setHideIncompatibleRecipes(bool value) async {
    hideIncompatibleRecipes.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideIncompatibleKey, value);
    // Notify to refresh recipe list immediately
    RecipeManager.notifyListeners();
  }

  // Data Management
  static Future<void> exportRecipes(BuildContext context) async {
    try {
      final recipes = await RecipeManager.getCustomRecipes();
      if (recipes.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No hay recetas para exportar'.tr)),
          );
        }
        return;
      }

      // Ask user choice
      final choice = await showModalBottomSheet<String>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Compartir'.tr),
                  onTap: () => Navigator.pop(context, 'share'),
                ),
                ListTile(
                  leading: Icon(Icons.save),
                  title: Text('Guardar en dispositivo'.tr),
                  onTap: () => Navigator.pop(context, 'save'),
                ),
              ],
            ),
          );
        },
      );

      if (choice == null) return;

      final jsonStr = jsonEncode(recipes.map((r) => r.toJson()).toList());

      if (choice == 'share') {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/recetas_backup.json');
        await file.writeAsString(jsonStr);

        final result = await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Copia de seguridad de Mis Recetas');

        if (result.status == ShareResultStatus.success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Copia de seguridad compartida'.tr)),
            );
          }
        }
      } else if (choice == 'save') {
        final bytes = Uint8List.fromList(utf8.encode(jsonStr));
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar copia de seguridad',
          fileName: 'recetas_backup.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: bytes,
        );

        // On Android/iOS with bytes provided, saveFile handles the write.
        // It returns the path if successful (or null if cancelled/failed).
        if (outputFile != null) {
          // We don't need to write again if the plugin took bytes, usually.
          // However, to be safe and consistent with desktop behavior where we might get a path:
          // The error specifically asked for bytes on Android/iOS, implying it needs them to write.
          // So we assume if we get here, it's done or we have a path.
          // But if we passed bytes, we shouldn't write to outputFile again blindly unless we know it's just a path picker.
          // Given the error, I trust the plugin used the bytes.
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Recetas guardadas exitosamente'.tr)),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
      }
    }
  }

  static Future<void> importRecipes(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonStr = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonStr);

        int importedCount = 0;
        int skippedCount = 0;

        // Find or create "Importados" folder
        String? importFolderId;
        try {
          final existing = RecipeManager.allFolders
              .where((f) => f.name == 'Importados')
              .firstOrNull;

          if (existing != null) {
            importFolderId = existing.id;
          } else {
            // Create New
            final newId = DateTime.now().millisecondsSinceEpoch.toString();
            final newFolder = FavoriteFolder(
              id: newId,
              name: 'Importados',
              icon: Icons.drive_file_move,
              recipeTitles: [],
            );
            await RecipeManager.addFolder(newFolder);
            importFolderId = newId;
          }
        } catch (e) {
          print('Error handling Importados folder: $e');
        }

        for (var item in jsonList) {
          try {
            final recipe = Recipe.fromJson(item);
            // Check if exists to avoid duplicates (simple check by title)
            if (!RecipeManager.recipes.any((r) => r.title == recipe.title)) {
              await RecipeManager.addRecipe(recipe);

              // Add to Importados folder
              if (importFolderId != null) {
                await RecipeManager.addRecipeToFolder(importFolderId, recipe);
              }

              // Ensure it is marked as a favorite
              if (!RecipeManager.isFavorite(recipe)) {
                await RecipeManager.toggleFavorite(recipe);
              }

              importedCount++;
            } else {
              skippedCount++;
            }
          } catch (e) {
            print('Skipping invalid recipe during import: $e');
          }
        }

        // Ensure UI updates
        RecipeManager.notifyListeners();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Importado: $importedCount. Omitido (duplicado): $skippedCount',
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al importar: $e')));
      }
    }
  }

  static Future<void> clearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Borrar TODOS los datos'.tr),
        content: Text(
          'Esta acción eliminará todas tus recetas personalizadas y carpetas. No se puede deshacer. ¿Estás seguro?'
              .tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Borrar todo'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await RecipeManager.clearAllData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Datos eliminados correctamente'.tr)),
        );
      }
    }
  }
}

// Dietary restriction enum
class RecipeManager {
  static const String _storageKey = 'saved_recipes';
  static const String _favoritesKey = 'favorite_recipes';
  static const String _foldersKey = 'favorite_folders';

  static const String _customMappingsKey = 'custom_ingredient_mappings';
  static const String _customImagesKey = 'custom_recipe_images';

  static const List<IconData> availableFolderIcons = [
    CupertinoIcons.folder,
    CupertinoIcons.folder_fill,
    CupertinoIcons.book,
    CupertinoIcons.book_fill,
    CupertinoIcons.star,
    CupertinoIcons.star_fill,
    CupertinoIcons.heart,
    CupertinoIcons.heart_fill,
    CupertinoIcons.flame,
    CupertinoIcons.flame_fill,
    Icons.cake,
    Icons.cake_outlined,
    Icons.restaurant,
    Icons.restaurant_menu,
    CupertinoIcons.bell,
    CupertinoIcons.bell_fill,
    CupertinoIcons.tag,
    CupertinoIcons.tag_fill,
    CupertinoIcons.collections,
    Icons.collections_bookmark,
  ];

  static final List<Recipe> _defaultRecipes = [];
  static final List<Recipe> _recipes = [];
  static final List<Function()> _listeners = [];
  static Set<String> _favoriteTitles = {};
  static List<FavoriteFolder> _folders = [];
  static Map<String, String> _customImages = {};
  static Map<String, IngredientCategory> _customMappings = {};

  // Get all unique custom dietary tags from all recipes
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
      print('Error saving custom images: $e');
    }
  }

  static Future<void> addCustomMapping(
    String ingredient,
    IngredientCategory category,
  ) async {
    _customMappings[ingredient.toLowerCase()] = category;
    await _saveCustomMappings();
    // We don't necessarily need to notify listeners here if the caller does,
    // but doing so ensures the ingredients list refreshes.
    _notifyListeners();
  }

  static Future<void> _saveCustomMappings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _customMappings.map((k, v) => MapEntry(k, v.index));
      await prefs.setString(_customMappingsKey, json.encode(map));
    } catch (e) {
      print('Error saving custom mappings: $e');
    }
  }

  // Get all recipes (default + saved)
  static List<Recipe> get recipes {
    final defaultTitles = _defaultRecipes.map((r) => r.title).toSet();

    // If show defaults is off, just show user recipes (excluding rated defaults)
    // If show defaults is off, show user recipes, BUT include modified defaults (overrides)
    if (!SettingsManager.showDefaultRecipes.value) {
      return _recipes.where((r) {
        final isTitleDefault = defaultTitles.contains(r.title);
        if (!isTitleDefault) return true; // It's a purely custom recipe
        // It has a default title. Keep it ONLY if it is modified (i.e., not just a default copy).
        return !isDefaultRecipe(r);
      }).toList();
    }

    // If show defaults is on:
    // Show user recipes (which might be overrides of defaults)
    // PLUS default recipes that exist in _defaultRecipes BUT NOT in _recipes (by title)
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

  // Check compatibility based on permanent filters
  static bool isRecipeCompatible(Recipe recipe) {
    if (SettingsManager.dietaryDefaults.value.isEmpty &&
        SettingsManager.customDietaryDefaults.value.isEmpty) {
      return true;
    }

    final isDefault = isDefaultRecipe(recipe);
    final isPersonalized = !isDefault;
    final applyToDefaults = SettingsManager.applyDietaryToDefaults.value;

    // Only check if it's a personalized recipe OR if we are forcing checks on defaults
    final shouldCheck = isPersonalized || applyToDefaults;
    if (!shouldCheck) return true;

    final permanentFilters = SettingsManager.dietaryDefaults.value;
    final customPermanentFilters = SettingsManager.customDietaryDefaults.value;

    // Check standard restrictions
    final standardMatch =
        permanentFilters.isEmpty ||
        permanentFilters.every(
          (filter) => recipe.dietaryRestrictions.contains(filter),
        );

    // Check custom tags
    // Note: custom tags are stored as strings. Standard restrictions check against enum names or values?
    // In _RecipeCard we did: allPermanentFilters.every((restriction) => recipe.dietaryRestrictions.contains(restriction) || !recipe.customDietaryTags.contains(restriction));
    // Wait, the logic in RecipeCard was:
    // final allPermanentFilters = {...permanentFilters, ...customPermanentFilters};
    // allPermanentFilters.every((restriction) => recipe.dietaryRestrictions.contains(restriction) || recipe.customDietaryTags.contains(restriction));

    // Let's replicate strict logic:
    // 1. Standard filters must be in recipe.dietaryRestrictions
    // 2. Custom filters must be in recipe.customDietaryTags

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

  // Cache for ingredients to improve performance
  static List<String>? _cachedIngredients;
  static int _lastRecipeCount = 0;

  // Get all unique ingredients from all recipes
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

  // Check if a recipe is a default recipe
  static bool isDefaultRecipe(Recipe recipe) {
    // It is default if it comes from _defaultRecipes AND matches logic?
    // Actually simpler: check if it is in _defaultRecipes list by reference or title?
    // Since we create copies, reference check might fail.
    // A recipe is "default" origin if title is in _defaultRecipes.
    // But isPersonalized check usually implies created by user.
    // Let's keep logic simple: strict check or title check?
    // Existing code uses _defaultRecipes.contains(recipe).
    // A recipe is treated as default if it's in the default list, OR if it's an override
    // that has the same content as a default recipe (ignoring rating/date).
    final isDirectDefault = _defaultRecipes.contains(recipe);
    if (isDirectDefault) return true;

    final defaultMatch = _defaultRecipes
        .where((r) => r.title == recipe.title)
        .firstOrNull;
    if (defaultMatch == null) return false;

    // It matches a default title. Check if content (ingredients/steps) is modified.
    // If content matches, we treat it as "Default" (e.g. just rated).
    // If content differs, we treat it as "Personalized".
    // We compare JSON representation minus rating/date for simplicity, or key fields.
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

  // Load default recipes from JSON asset
  static Future<void> loadDefaultRecipes() async {
    try {
      final isEnglish = SettingsManager.language.value == 'en';
      final String jsonString = await rootBundle.loadString(
        isEnglish ? 'assets/data/recipes_en.json' : 'assets/data/recipes.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      _defaultRecipes.clear();
      int loadedCount = 0;
      for (final item in jsonData) {
        if (item is Map<String, dynamic>) {
          try {
            _defaultRecipes.add(Recipe.fromJson(item));
            loadedCount++;
          } catch (e, stackTrace) {
            print('Error loading recipe "${item['title'] ?? 'unknown'}": $e');
            print('Stack trace: $stackTrace');
          }
        }
      }
      print('Loaded $loadedCount recipes from JSON');
      _notifyListeners();
    } catch (e, stackTrace) {
      print('Error loading default recipes from JSON: $e');
      print('Stack trace: $stackTrace');
      // If file doesn't exist or has errors, use empty list
      _defaultRecipes.clear();
    }
  }

  // Add or update a recipe
  static Future<void> addRecipe(Recipe recipe) async {
    final index = _recipes.indexWhere((r) => r.title == recipe.title);
    if (index != -1) {
      _recipes[index] = recipe;
    } else {
      _recipes.add(recipe);
    }
    await _saveRecipes();
    _notifyListeners();
  }

  // Remove a recipe
  static Future<void> removeRecipe(Recipe recipe) async {
    _recipes.removeWhere((r) => r.title == recipe.title);
    await _saveRecipes();
    _notifyListeners();
  }

  // Load saved recipes from storage
  static Future<void> loadRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recipesJson = prefs.getStringList(_storageKey) ?? [];

      _recipes.clear();
      for (final recipeJson in recipesJson) {
        final recipeMap = json.decode(recipeJson) as Map<String, dynamic>;
        _recipes.add(Recipe.fromJson(recipeMap));
      }

      // Load favorites
      final favoriteTitlesList = prefs.getStringList(_favoritesKey) ?? [];
      _favoriteTitles = favoriteTitlesList.toSet();

      // Load folders
      final foldersJson = prefs.getString(_foldersKey);
      if (foldersJson != null) {
        try {
          final foldersList = json.decode(foldersJson) as List;
          _folders = foldersList
              .map((f) => FavoriteFolder.fromJson(f as Map<String, dynamic>))
              .toList();
        } catch (e) {
          print('Error loading folders: $e');
          _folders = [];
        }
      } else {
        _folders = [];
      }

      // Load custom mappings
      final mappingsJson = prefs.getString(_customMappingsKey);
      if (mappingsJson != null) {
        try {
          final Map<String, dynamic> decoded = json.decode(mappingsJson);
          _customMappings = decoded.map(
            (k, v) => MapEntry(k, IngredientCategory.values[v as int]),
          );
        } catch (e) {
          print('Error loading custom mappings: $e');
          _customMappings = {};
        }
      }

      // Load custom images
      final imagesJson = prefs.getString(_customImagesKey);
      if (imagesJson != null) {
        try {
          final Map<String, dynamic> decoded = json.decode(imagesJson);
          _customImages = decoded.map((k, v) => MapEntry(k, v as String));
        } catch (e) {
          print('Error loading custom images: $e');
          _customImages = {};
        }
      }

      _notifyListeners();
    } catch (e) {
      print('Error loading recipes: $e');
    }
  }

  // Check if a recipe is favorited
  static bool isFavorite(Recipe recipe) {
    return _favoriteTitles.contains(recipe.title);
  }

  // Toggle favorite status
  static Future<void> toggleFavorite(Recipe recipe) async {
    if (_favoriteTitles.contains(recipe.title)) {
      _favoriteTitles.remove(recipe.title);
    } else {
      _favoriteTitles.add(recipe.title);
    }
    await _saveFavorites();
    _notifyListeners();
  }

  // Get favorite recipes
  static List<Recipe> get favoriteRecipes {
    return recipes
        .where((recipe) => _favoriteTitles.contains(recipe.title))
        .toList();
  }

  // Save favorites to storage
  static Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, _favoriteTitles.toList());
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  // Get root folders (folders without parent)
  static List<FavoriteFolder> get rootFolders {
    return _folders.where((f) => f.parentId == null).toList();
  }

  // Get all folders
  // Rate a recipe
  static Future<void> rateRecipe(Recipe recipe, double rating) async {
    final updatedRecipe = Recipe(
      title: recipe.title,
      ingredients: recipe.ingredients,
      nutritionFacts: recipe.nutritionFacts,
      steps: recipe.steps,
      imagePath: recipe.imagePath,
      categories: recipe.categories,
      dietaryRestrictions: recipe.dietaryRestrictions,
      prepTime: recipe.prepTime,
      detailedIngredients: recipe.detailedIngredients,
      rating: rating,
      dateRated: DateTime.now(),
    );

    final index = _recipes.indexWhere((r) => r.title == recipe.title);
    if (index != -1) {
      // Update existing user recipe
      _recipes[index] = updatedRecipe;
    } else {
      // Add new override for default recipe (or new user recipe)
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

  // Get folder by id
  static FavoriteFolder? getFolderById(String id) {
    try {
      return _folders.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get subfolders of a folder
  static List<FavoriteFolder> getSubFolders(String parentId) {
    return _folders.where((f) => f.parentId == parentId).toList();
  }

  // Get subfolders recursive
  static List<FavoriteFolder> getSubFoldersRecursive(String folderId) {
    final subFolders = getSubFolders(folderId);
    final result = <FavoriteFolder>[
      ...subFolders,
    ]; // Start with direct children

    for (final subFolder in subFolders) {
      result.addAll(getSubFoldersRecursive(subFolder.id));
    }

    return result;
  }

  // Get recipes in a folder
  static List<Recipe> getRecipesInFolder(FavoriteFolder folder) {
    return recipes.where((r) => folder.recipeTitles.contains(r.title)).toList();
  }

  // Get recipes in a folder (recursive)
  static List<Recipe> getRecipesInFolderRecursive(String folderId) {
    final folder = getFolderById(folderId);
    if (folder == null) return [];

    final result = <Recipe>[];

    // Add recipes from current folder
    result.addAll(getRecipesInFolder(folder));

    // Process subfolders
    final subFolders = getSubFolders(folderId);
    for (final subFolder in subFolders) {
      result.addAll(getRecipesInFolderRecursive(subFolder.id));
    }

    // Remove duplicates just in case
    return result.toSet().toList();
  }

  // Add folder
  static Future<void> addFolder(FavoriteFolder folder) async {
    _folders.add(folder);
    await _saveFolders();
    _notifyListeners();
  }

  // Update folder
  static Future<void> updateFolder(FavoriteFolder folder) async {
    final index = _folders.indexWhere((f) => f.id == folder.id);
    if (index != -1) {
      _folders[index] = folder;
      await _saveFolders();
      _notifyListeners();
    }
  }

  // Delete folder
  static Future<void> deleteFolder(String folderId) async {
    // Remove folder and all its subfolders recursively
    _removeFolderRecursive(folderId);
    await _saveFolders();
    _notifyListeners();
  }

  static void _removeFolderRecursive(String folderId) {
    // Remove all subfolders first
    final subFolders = _folders.where((f) => f.parentId == folderId).toList();
    for (final subFolder in subFolders) {
      _removeFolderRecursive(subFolder.id);
    }
    // Remove the folder itself
    _folders.removeWhere((f) => f.id == folderId);
  }

  // Add recipe to folder
  static Future<void> addRecipeToFolder(String folderId, Recipe recipe) async {
    final folder = getFolderById(folderId);
    if (folder != null && !folder.recipeTitles.contains(recipe.title)) {
      final updatedFolder = folder.copyWith(
        recipeTitles: [...folder.recipeTitles, recipe.title],
      );
      await updateFolder(updatedFolder);
    }
  }

  // Remove recipe from folder
  static Future<void> removeRecipeFromFolder(
    String folderId,
    Recipe recipe,
  ) async {
    final folder = getFolderById(folderId);
    if (folder != null && folder.recipeTitles.contains(recipe.title)) {
      final updatedFolder = folder.copyWith(
        recipeTitles: folder.recipeTitles
            .where((t) => t != recipe.title)
            .toList(),
      );
      await updateFolder(updatedFolder);
    }
  }

  // Save folders to storage
  static Future<void> _saveFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final foldersJson = json.encode(_folders.map((f) => f.toJson()).toList());
      await prefs.setString(_foldersKey, foldersJson);
    } catch (e) {
      print('Error saving folders: $e');
    }
  }

  // Save recipes to storage
  // Get custom recipes only
  static Future<List<Recipe>> getCustomRecipes() async {
    final defaultTitles = _defaultRecipes.map((r) => r.title).toSet();
    return _recipes
        .where((r) => !defaultTitles.contains(r.title))
        .toList(); // returns only non-default recipes as _recipes stores user added content
  }

  // Clear all user data
  static Future<void> clearAllData() async {
    _recipes.clear();
    _folders.clear();
    _favoriteTitles.clear();
    _customMappings.clear();
    _customImages.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_favoritesKey);
    await prefs.remove(_foldersKey);
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
      print('Error saving recipes: $e');
    }
  }

  // Add listener for recipe changes
  static void addListener(Function() listener) {
    _listeners.add(listener);
  }

  // Remove listener
  static void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  // Notify all listeners
  static void notifyListeners() {
    _notifyListeners();
  }

  static void _notifyListeners() {
    // Invalidate cache when recipes change
    _cachedIngredients = null;
    _lastRecipeCount = 0;

    for (final listener in _listeners) {
      listener();
    }
  }
}

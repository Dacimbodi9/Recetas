// ignore_for_file: unused_local_variable
// ignore_for_file: use_build_context_synchronously
// ignore_for_file: deprecated_member_use
// ignore_for_file: constant_identifier_names
// ignore_for_file: avoid_print
part of '../main.dart';

class SettingsManager {
  static final ValueNotifier<String> userName = ValueNotifier('Chef');
  static final ValueNotifier<String?> userPhotoPath = ValueNotifier(null);
  static final ValueNotifier<bool> showProfileStats = ValueNotifier(true);
  static final ValueNotifier<bool> isDarkMode = ValueNotifier(true);
  static final ValueNotifier<bool> showDefaultRecipes = ValueNotifier(false);
  static final ValueNotifier<bool> preventSleep = ValueNotifier(false);
  static final ValueNotifier<int> startScreenIndex = ValueNotifier(0);
  static final ValueNotifier<Set<DietaryRestriction>> dietaryDefaults = ValueNotifier({});
  static final ValueNotifier<Set<String>> customDietaryDefaults = ValueNotifier({});
  static final ValueNotifier<bool> hasSeenOnboarding = ValueNotifier(false);
  static final ValueNotifier<String> language = ValueNotifier('es');
  static final ValueNotifier<String> aiApiKey = ValueNotifier('');
  static final ValueNotifier<String> aiApiEndpoint = ValueNotifier('https://api.openai.com/v1/chat/completions');
  static final ValueNotifier<String> aiProvider = ValueNotifier('gemini');

  static const _themeKey = 'is_dark_mode';
  static const _languageKey = 'app_language';
  static const _defaultsKey = 'show_default_recipes';
  static const _preventSleepKey = 'prevent_sleep';
  static const _startScreenKey = 'start_screen_index';
  static const _dietaryDefaultsKey = 'dietary_defaults';
  static const _userNameKey = 'user_name';
  static const _userPhotoKey = 'user_photo_path';
  static const _showStatsKey = 'show_profile_stats';

  static const _customDietaryDefaultsKey = 'custom_dietary_defaults';
  static const _onboardingKey = 'has_seen_onboarding';
  static const _aiApiKeyPref = 'ai_api_key';
  static const _aiApiEndpointPref = 'ai_api_endpoint';
  static const _aiProviderPref = 'ai_provider';

  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    isDarkMode.value = prefs.getBool(_themeKey) ?? (systemBrightness == Brightness.dark);
    showDefaultRecipes.value = prefs.getBool(_defaultsKey) ?? true;
    showProfileStats.value = prefs.getBool(_showStatsKey) ?? true;
    preventSleep.value = prefs.getBool(_preventSleepKey) ?? false;
    if (preventSleep.value) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
    startScreenIndex.value = prefs.getInt(_startScreenKey) ?? 0;
    final dietaryList = prefs.getStringList(_dietaryDefaultsKey) ?? [];
    dietaryDefaults.value = dietaryList.map((e) => DietaryRestriction.values.firstWhere((r) => r.name == e, orElse: () => DietaryRestriction.vegetariano)).toSet();
    final customDietaryList = prefs.getStringList(_customDietaryDefaultsKey) ?? [];
    customDietaryDefaults.value = customDietaryList.toSet();
    applyDietaryToDefaults.value = prefs.getBool(_applyToDefaultsKey) ?? false;
    hideIncompatibleRecipes.value = prefs.getBool(_hideIncompatibleKey) ?? false;
    hasSeenOnboarding.value = prefs.getBool(_onboardingKey) ?? false;
    aiApiKey.value = prefs.getString(_aiApiKeyPref) ?? '';
    aiApiEndpoint.value = prefs.getString(_aiApiEndpointPref) ?? 'https://api.openai.com/v1/chat/completions';
    aiProvider.value = prefs.getString(_aiProviderPref) ?? 'gemini';
    userName.value = prefs.getString(_userNameKey) ?? 'Chef';
    userPhotoPath.value = prefs.getString(_userPhotoKey);
    final deviceLocale = Platform.localeName;
    final defaultLang = deviceLocale.startsWith('es') ? 'es' : 'en';
    language.value = prefs.getString(_languageKey) ?? defaultLang;
    AppLocalization.instance.setLanguage(language.value);
  }

  static Future<void> setUserName(String name) async {
    userName.value = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  static Future<void> setUserPhotoPath(String? path) async {
    userPhotoPath.value = path;
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_userPhotoKey);
    } else {
      await prefs.setString(_userPhotoKey, path);
    }
  }

  static Future<void> setAiApiKey(String key) async {
    aiApiKey.value = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiApiKeyPref, key);
  }

  static Future<void> setAiApiEndpoint(String endpoint) async {
    aiApiEndpoint.value = endpoint;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiApiEndpointPref, endpoint);
  }

  static Future<void> setAiProvider(String provider) async {
    aiProvider.value = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiProviderPref, provider);
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

  static Future<void> setShowProfileStats(bool value) async {
    showProfileStats.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showStatsKey, value);
  }

  static Future<void> toggleDietaryDefault(DietaryRestriction restriction) async {
    final current = Set<DietaryRestriction>.from(dietaryDefaults.value);
    if (current.contains(restriction)) {
      current.remove(restriction);
    } else {
      current.add(restriction);
    }
    dietaryDefaults.value = current;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_dietaryDefaultsKey, current.map((e) => e.name).toList());
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
    RecipeManager.notifyListeners();
  }

  static final ValueNotifier<bool> applyDietaryToDefaults = ValueNotifier(false);
  static const _applyToDefaultsKey = 'apply_dietary_to_defaults';

  static Future<void> setApplyDietaryToDefaults(bool value) async {
    applyDietaryToDefaults.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_applyToDefaultsKey, value);
    RecipeManager.notifyListeners();
  }

  static final ValueNotifier<bool> hideIncompatibleRecipes = ValueNotifier(false);
  static const _hideIncompatibleKey = 'hide_incompatible_recipes';

  static Future<void> setHideIncompatibleRecipes(bool value) async {
    hideIncompatibleRecipes.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideIncompatibleKey, value);
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
                  leading: const Icon(Icons.share),
                  title: Text('Compartir'.tr),
                  onTap: () => Navigator.pop(context, 'share'),
                ),
                ListTile(
                  leading: const Icon(Icons.save),
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

        if (outputFile != null) {
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

        // Find or create \"Importados\" folder
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
            if (!RecipeManager.recipes.any((r) => r.title == recipe.title)) {
              await RecipeManager.addRecipe(recipe);

              if (importFolderId != null) {
                await RecipeManager.addRecipeToFolder(importFolderId, recipe);
              }

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

        RecipeManager.notifyListeners();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Importado: $importedCount. Omitido (duplicado): $skippedCount',
              ),
              duration: const Duration(seconds: 4),
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

class RecipeManager {
  static const String _storageKey = 'saved_recipes';
  static const String _favoritesKey = 'favorite_recipes';
  static const String _foldersKey = 'favorite_folders';
  static const String _customMappingsKey = 'custom_ingredient_mappings';
  static const String _customImagesKey = 'custom_recipe_images';

  static const List<IconData> availableFolderIcons = [
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
  static Set<String> _favoriteTitles = {};
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

  static String? getCustomImage(String recipeTitle) => _customImages[recipeTitle];

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

  static Future<void> addCustomMapping(String ingredient, IngredientCategory category) async {
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
      print('Error saving custom mappings: $e');
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
    final nonOverriddenDefaults = _defaultRecipes.where((r) => !userTitles.contains(r.title));
    final allRecipes = [...nonOverriddenDefaults, ..._recipes];

    if (SettingsManager.hideIncompatibleRecipes.value) {
      return allRecipes.where((r) => isRecipeCompatible(r)).toList();
    }

    return allRecipes;
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

    final standardCompatible = permanentFilters.isEmpty ||
        permanentFilters.every((f) => recipe.dietaryRestrictions.contains(f));

    final customCompatible = customPermanentFilters.isEmpty ||
        customPermanentFilters.every((t) => recipe.customDietaryTags.contains(t));

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

    final defaultMatch = _defaultRecipes.where((r) => r.title == recipe.title).firstOrNull;
    if (defaultMatch == null) return false;

    final bool contentMatches = listEquals(recipe.ingredients, defaultMatch.ingredients) &&
        listEquals(recipe.steps, defaultMatch.steps) &&
        listEquals(
          recipe.detailedIngredients.map((e) => e.toJson().toString()).toList(),
          defaultMatch.detailedIngredients.map((e) => e.toJson().toString()).toList(),
        ) &&
        listEquals(recipe.categories, defaultMatch.categories) &&
        listEquals(recipe.dietaryRestrictions, defaultMatch.dietaryRestrictions) &&
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
      final List<dynamic> jsonData = json.decode(jsonString);

      _defaultRecipes.clear();
      for (final item in jsonData) {
        if (item is Map<String, dynamic>) {
          try {
            _defaultRecipes.add(Recipe.fromJson(item));
          } catch (e) {
            print('Error loading recipe \"${item['title'] ?? 'unknown'}\": $e');
          }
        }
      }
      _notifyListeners();
    } catch (e) {
      print('Error loading default recipes from JSON: $e');
      _defaultRecipes.clear();
    }
  }

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

  static Future<void> removeRecipe(Recipe recipe) async {
    _recipes.removeWhere((r) => r.title == recipe.title);
    await _saveRecipes();
    _notifyListeners();
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

      final favoriteTitlesList = prefs.getStringList(_favoritesKey) ?? [];
      _favoriteTitles = favoriteTitlesList.toSet();

      final foldersJson = prefs.getString(_foldersKey);
      if (foldersJson != null) {
        try {
          final foldersList = json.decode(foldersJson) as List;
          _folders = foldersList.map((f) => FavoriteFolder.fromJson(f as Map<String, dynamic>)).toList();
        } catch (e) {
          print('Error loading folders: $e');
          _folders = [];
        }
      } else {
        _folders = [];
      }

      final mappingsJson = prefs.getString(_customMappingsKey);
      if (mappingsJson != null) {
        try {
          final Map<String, dynamic> decoded = json.decode(mappingsJson);
          _customMappings = decoded.map((k, v) => MapEntry(k, IngredientCategory.values[v as int]));
        } catch (e) {
          print('Error loading custom mappings: $e');
          _customMappings = {};
        }
      }

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

  static bool isFavorite(Recipe recipe) => _favoriteTitles.contains(recipe.title);

  static Future<void> toggleFavorite(Recipe recipe) async {
    if (_favoriteTitles.contains(recipe.title)) {
      _favoriteTitles.remove(recipe.title);
    } else {
      _favoriteTitles.add(recipe.title);
    }
    await _saveFavorites();
    _notifyListeners();
  }

  static List<Recipe> get favoriteRecipes => recipes.where((recipe) => _favoriteTitles.contains(recipe.title)).toList();

  static Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, _favoriteTitles.toList());
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  static List<FavoriteFolder> get rootFolders => _folders.where((f) => f.parentId == null).toList();

  static Future<void> rateRecipe(Recipe recipe, double rating) async {
    final updatedRecipe = recipe.copyWith(
      rating: rating,
      dateRated: DateTime.now(),
    );

    final index = _recipes.indexWhere((r) => r.title == recipe.title);
    if (index != -1) {
      _recipes[index] = updatedRecipe;
    } else {
      _recipes.add(updatedRecipe);
    }

    await _saveRecipes();
    _notifyListeners();
  }

  static List<Recipe> get ratedRecipes {
    final rated = _recipes.where((r) => r.rating != null && r.rating! > 0).toList();
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

  static List<FavoriteFolder> getSubFolders(String parentId) => _folders.where((f) => f.parentId == parentId).toList();

  static List<FavoriteFolder> getSubFoldersRecursive(String folderId) {
    final subFolders = getSubFolders(folderId);
    final result = <FavoriteFolder>[...subFolders];
    for (final subFolder in subFolders) {
      result.addAll(getSubFoldersRecursive(subFolder.id));
    }
    return result;
  }

  static List<Recipe> getRecipesInFolder(FavoriteFolder folder) => recipes.where((r) => folder.recipeTitles.contains(r.title)).toList();

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
    if (folder != null && !folder.recipeTitles.contains(recipe.title)) {
      final updatedFolder = folder.copyWith(recipeTitles: [...folder.recipeTitles, recipe.title]);
      await updateFolder(updatedFolder);
    }
  }

  static Future<void> removeRecipeFromFolder(String folderId, Recipe recipe) async {
    final folder = getFolderById(folderId);
    if (folder != null && folder.recipeTitles.contains(recipe.title)) {
      final updatedFolder = folder.copyWith(recipeTitles: folder.recipeTitles.where((t) => t != recipe.title).toList());
      await updateFolder(updatedFolder);
    }
  }

  static Future<void> _saveFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final foldersJson = json.encode(_folders.map((f) => f.toJson()).toList());
      await prefs.setString(_foldersKey, foldersJson);
    } catch (e) {
      print('Error saving folders: $e');
    }
  }

  static Future<List<Recipe>> getCustomRecipes() async {
    final defaultTitles = _defaultRecipes.map((r) => r.title).toSet();
    return _recipes.where((r) => !defaultTitles.contains(r.title)).toList();
  }

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

  static void addListener(Function() listener) => _listeners.add(listener);
  static void removeListener(Function() listener) => _listeners.remove(listener);
  static void notifyListeners() => _notifyListeners();

  static void _notifyListeners() {
    _cachedIngredients = null;
    _lastRecipeCount = 0;
    for (final listener in _listeners) {
      listener();
    }
  }
}

class DeepLinkHandler {
  DeepLinkHandler._();
  static final DeepLinkHandler instance = DeepLinkHandler._();

  static const _channel = MethodChannel('com.daniel.recetas/file_reader');
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  void init() {
    _appLinks = AppLinks();
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
    _sub = _appLinks.uriLinkStream.listen(_handleDeepLink);
    _checkInitialFileIntent();
  }

  void dispose() => _sub?.cancel();

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'recetas' || uri.host != 'recipe') return;
    final segments = uri.pathSegments;
    if (segments.isEmpty) return;
    final encodedData = segments.first;
    final recipe = Recipe.fromShareableData(encodedData);
    if (recipe != null) {
      Future.delayed(const Duration(milliseconds: 500), () => _showImportDialog(recipe));
    }
  }

  Future<void> _checkInitialFileIntent() async {
    try {
      final uriString = await _channel.invokeMethod<String>('getIntentData');
      if (uriString != null) await _handleFileUri(uriString);
    } catch (e) {
      print('Error checking initial file intent: $e');
    }
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewFileIntent') {
        final uriString = call.arguments as String?;
        if (uriString != null) await _handleFileUri(uriString);
      }
    });
  }

  Future<void> _handleFileUri(String uriString) async {
    if (uriString.startsWith('recetas://')) return;
    try {
      String? content;
      if (uriString.startsWith('content://')) {
        content = await _channel.invokeMethod<String>('readContentUri', {'uri': uriString});
      } else if (uriString.startsWith('file://')) {
        final path = Uri.parse(uriString).toFilePath();
        content = await File(path).readAsString();
      }
      if (content != null) {
        final recipe = Recipe.fromShareableData(content.trim());
        if (recipe != null) {
          Future.delayed(const Duration(milliseconds: 500), () => _showImportDialog(recipe));
        }
      }
    } catch (e) {
      print('Error handling file URI: $e');
    }
  }

  void _showImportDialog(Recipe recipe) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final exists = RecipeManager.recipes.any((r) => r.title == recipe.title);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Receta compartida detectada'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'¿Quieres importar la receta'.tr} "${recipe.title}"?'),
            if (exists) ...[
              const SizedBox(height: 12),
              Text(
                'Nota: Ya tienes una receta con este nombre.'.tr,
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'.tr),
          ),
          FilledButton(
            onPressed: () async {
              await RecipeManager.addRecipe(recipe);
              if (!RecipeManager.isFavorite(recipe)) {
                await RecipeManager.toggleFavorite(recipe);
              }
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Receta importada correctamente'.tr)),
                );
              }
            },
            child: Text('Importar'.tr),
          ),
        ],
      ),
    );
  }
}

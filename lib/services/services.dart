part of '../main.dart';

class SettingsManager {
  static final ValueNotifier<String> userName = ValueNotifier('Chef');
  static final ValueNotifier<String?> userPhotoPath = ValueNotifier(null);
  static final ValueNotifier<bool> isDarkMode = ValueNotifier(true);
  static final ValueNotifier<bool> showDefaultRecipes = ValueNotifier(false);
  static final ValueNotifier<bool> preventSleep = ValueNotifier(false);
  static final ValueNotifier<String> startScreenFeature = ValueNotifier(
    'profile',
  );
  static final ValueNotifier<Set<DietaryRestriction>> dietaryDefaults =
      ValueNotifier({});
  static final ValueNotifier<Set<String>> customDietaryDefaults = ValueNotifier(
    {},
  );
  static final ValueNotifier<bool> hasSeenOnboarding = ValueNotifier(false);
  static final ValueNotifier<String> language = ValueNotifier('es');
  static final ValueNotifier<String> aiApiKey = ValueNotifier('');
  static final ValueNotifier<String> aiApiEndpoint = ValueNotifier(
    'https://api.openai.com/v1/chat/completions',
  );
  static final ValueNotifier<String> aiProvider = ValueNotifier('gemini');
  static final ValueNotifier<List<String>> bottomMenuFeatures = ValueNotifier([
    'search',
    'saved',
  ]);
  static final ValueNotifier<double?> userWeight = ValueNotifier(null);
  static final ValueNotifier<double?> userHeight = ValueNotifier(null);
  static final ValueNotifier<int?> userAge = ValueNotifier(null);
  static final ValueNotifier<String?> userSex = ValueNotifier(null);
  static final ValueNotifier<double?> userActivityLevel = ValueNotifier(null);
  static final ValueNotifier<bool> showTodayMealsInHome = ValueNotifier(false);
  static const _themeKey = 'is_dark_mode';
  static const _languageKey = 'app_language';
  static const _defaultsKey = 'show_default_recipes';
  static const _preventSleepKey = 'prevent_sleep';
  static const _startScreenFeatureKey = 'start_screen_feature';
  static const _dietaryDefaultsKey = 'dietary_defaults';
  static const _userNameKey = 'user_name';
  static const _userPhotoKey = 'user_photo_path';

  static const _customDietaryDefaultsKey = 'custom_dietary_defaults';
  static const _onboardingKey = 'has_seen_onboarding';
  static const _aiApiKeyPref = 'ai_api_key';
  static const _aiApiEndpointPref = 'ai_api_endpoint';
  static const _aiProviderPref = 'ai_provider';
  static const _bottomMenuFeaturesKey = 'bottom_menu_features';
  static const _userWeightKey = 'user_weight';
  static const _userHeightKey = 'user_height';
  static const _userAgeKey = 'user_age';
  static const _userSexKey = 'user_sex';
  static const _userActivityLevelKey = 'user_activity_level';
  static const _showTodayMealsInHomeKey = 'show_today_meals_in_home';

  static List<Map<String, dynamic>> get availableFeatures => [
    {
      'id': 'search',
      'title': 'Búsqueda'.tr,
      'subtitle': 'Busca recetas e ingredientes'.tr,
      'icon': CupertinoIcons.search,
    },
    {
      'id': 'saved',
      'title': 'Guardados'.tr,
      'subtitle': 'Tus recetas guardadas y favoritas'.tr,
      'icon': CupertinoIcons.book,
    },
    {
      'id': 'mealPlanner',
      'title': 'Planificador'.tr,
      'subtitle': 'Organiza tus comidas de la semana'.tr,
      'icon': Icons.calendar_month_outlined,
    },
    {
      'id': 'shoppingList',
      'title': 'Lista de Compra'.tr,
      'subtitle': 'Lista de compra automática'.tr,
      'icon': Icons.shopping_cart_outlined,
    },
    {
      'id': 'stats',
      'title': 'Estadísticas'.tr,
      'subtitle': 'Tus estadísticas nutricionales'.tr,
      'icon': Icons.bar_chart_rounded,
    },
  ];

  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
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
    startScreenFeature.value =
        prefs.getString(_startScreenFeatureKey) ?? 'profile';
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
    aiApiKey.value = prefs.getString(_aiApiKeyPref) ?? '';
    aiApiEndpoint.value =
        prefs.getString(_aiApiEndpointPref) ??
        'https://api.openai.com/v1/chat/completions';
    aiProvider.value = prefs.getString(_aiProviderPref) ?? 'gemini';
    userName.value = prefs.getString(_userNameKey) ?? 'Chef';
    userPhotoPath.value = prefs.getString(_userPhotoKey);
    bottomMenuFeatures.value =
        prefs.getStringList(_bottomMenuFeaturesKey) ?? ['search', 'saved'];
    final deviceLocale = Platform.localeName;
    final defaultLang = deviceLocale.startsWith('es') ? 'es' : 'en';
    language.value = prefs.getString(_languageKey) ?? defaultLang;
    AppLocalization.instance.setLanguage(language.value);

    final savedWeight = prefs.getDouble(_userWeightKey);
    userWeight.value = savedWeight;
    final savedHeight = prefs.getDouble(_userHeightKey);
    userHeight.value = savedHeight;
    final savedAge = prefs.getInt(_userAgeKey);
    userAge.value = savedAge;
    userSex.value = prefs.getString(_userSexKey);
    userActivityLevel.value = prefs.getDouble(_userActivityLevelKey);
    showTodayMealsInHome.value = prefs.getBool(_showTodayMealsInHomeKey) ?? false;
  }

  static Future<void> setUserName(String name) async {
    userName.value = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  static Future<void> setUserActivityLevel(double? level) async {
    userActivityLevel.value = level;
    final prefs = await SharedPreferences.getInstance();
    if (level == null) {
      await prefs.remove(_userActivityLevelKey);
    } else {
      await prefs.setDouble(_userActivityLevelKey, level);
    }
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

  static Future<void> setUserWeight(double? weight) async {
    userWeight.value = weight;
    final prefs = await SharedPreferences.getInstance();
    if (weight == null) {
      await prefs.remove(_userWeightKey);
    } else {
      await prefs.setDouble(_userWeightKey, weight);
    }
  }

  static Future<void> setShowTodayMealsInHome(bool show) async {
    showTodayMealsInHome.value = show;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showTodayMealsInHomeKey, show);
  }

  static Future<void> setUserHeight(double? height) async {
    userHeight.value = height;
    final prefs = await SharedPreferences.getInstance();
    if (height == null) {
      await prefs.remove(_userHeightKey);
    } else {
      await prefs.setDouble(_userHeightKey, height);
    }
  }

  static Future<void> setUserAge(int? age) async {
    userAge.value = age;
    final prefs = await SharedPreferences.getInstance();
    if (age == null) {
      await prefs.remove(_userAgeKey);
    } else {
      await prefs.setInt(_userAgeKey, age);
    }
  }

  static Future<void> setUserSex(String? sex) async {
    userSex.value = sex;
    final prefs = await SharedPreferences.getInstance();
    if (sex == null) {
      await prefs.remove(_userSexKey);
    } else {
      await prefs.setString(_userSexKey, sex);
    }
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

  static Future<void> setBottomMenuFeatures(List<String> features) async {
    bottomMenuFeatures.value = features;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_bottomMenuFeaturesKey, features);
    if (startScreenFeature.value != 'profile' &&
        !features.contains(startScreenFeature.value)) {
      await setStartScreenFeature('profile');
    }
  }

  static Future<void> setDarkMode(bool value) async {
    isDarkMode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
  }

  static Future<void> setStartScreenFeature(String feature) async {
    startScreenFeature.value = feature;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_startScreenFeatureKey, feature);
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
      if (!context.mounted) return;
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

        final result = await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Copia de seguridad de Guardados',
          ),
        );

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
              recipeIds: [],
            );
            await RecipeManager.addFolder(newFolder);
            importFolderId = newId;
          }
        } catch (e) {
          debugPrint('Error handling Importados folder: $e');
        }

        for (var item in jsonList) {
          try {
            final recipe = Recipe.fromJson(item);
            if (!RecipeManager.recipes.any((r) => r.id == recipe.id)) {
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
            debugPrint('Skipping invalid recipe during import: $e');
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
      debugPrint('Error saving custom images: $e');
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
      debugPrint('Error saving custom mappings: $e');
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
      final List<dynamic> jsonData = json.decode(jsonString);

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
      debugPrint('Error loading default recipes from JSON: $e');
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

  static Future<void> removeRecipe(Recipe recipe) async {
    _recipes.removeWhere((r) => r.id == recipe.id);
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
          debugPrint('Error loading folders: $e');
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
          debugPrint('Error loading custom mappings: $e');
          _customMappings = {};
        }
      }

      final imagesJson = prefs.getString(_customImagesKey);
      if (imagesJson != null) {
        try {
          final Map<String, dynamic> decoded = json.decode(imagesJson);
          _customImages = decoded.map((k, v) => MapEntry(k, v as String));
        } catch (e) {
          debugPrint('Error loading custom images: $e');
          _customImages = {};
        }
      }

      _notifyListeners();
    } catch (e) {
      debugPrint('Error loading recipes: $e');
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
      debugPrint('Error saving favorites: $e');
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
      debugPrint('Error saving folders: $e');
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
      debugPrint('Error saving recipes: $e');
    }
  }

  static void addListener(Function() listener) => _listeners.add(listener);
  static void removeListener(Function() listener) =>
      _listeners.remove(listener);
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
      Future.delayed(
        const Duration(milliseconds: 500),
        () => _showImportDialog(recipe),
      );
    }
  }

  Future<void> _checkInitialFileIntent() async {
    try {
      final uriString = await _channel.invokeMethod<String>('getIntentData');
      if (uriString != null) await _handleFileUri(uriString);
    } catch (e) {
      debugPrint('Error checking initial file intent: $e');
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
        content = await _channel.invokeMethod<String>('readContentUri', {
          'uri': uriString,
        });
      } else if (uriString.startsWith('file://')) {
        final path = Uri.parse(uriString).toFilePath();
        content = await File(path).readAsString();
      }
      if (content != null) {
        final recipe = Recipe.fromShareableData(content.trim());
        if (recipe != null) {
          Future.delayed(
            const Duration(milliseconds: 500),
            () => _showImportDialog(recipe),
          );
        }
      }
    } catch (e) {
      debugPrint('Error handling file URI: $e');
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
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
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
        final List<dynamic> decoded = json.decode(raw);
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _meals.add(PlannedMeal.fromJson(item));
          }
        }
      } catch (e) {
        debugPrint('Error loading meal plan: $e');
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

  static Future<void> removeMeal(PlannedMeal meal) async {
    _meals.removeWhere(
      (m) =>
          m.dateKey == meal.dateKey &&
          m.mealType == meal.mealType &&
          m.recipeId == meal.recipeId,
    );
    await _save();
    _notifyListeners();
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
        final List<dynamic> decoded = json.decode(raw);
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _templates.add(MealTemplate.fromJson(item));
          }
        }
      } catch (e) {
        debugPrint('Error loading meal templates: $e');
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

/// Manages a shopping list derived from planned meals + manual items.
class ShoppingListManager {
  static const String _checkedKey = 'shopping_checked_items';
  static const String _manualKey = 'shopping_manual_items';
  static const String _daysAheadKey = 'shopping_days_ahead';
  static const String _boughtUntilKey = 'shopping_bought_until';

  static Set<String> _checkedItems = {};
  static List<Map<String, String>> _manualItems = [];
  static Map<String, DateTime> _boughtUntil = {};
  static int _daysAhead = 7;
  static final List<Function()> _listeners = [];

  static int get daysAhead => _daysAhead;
  static Set<String> get checkedItems => Set.unmodifiable(_checkedItems);
  static List<Map<String, String>> get manualItems =>
      List.unmodifiable(_manualItems);

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

    // Checked items
    final checkedList = prefs.getStringList(_checkedKey) ?? [];
    _checkedItems = checkedList.toSet();

    // Manual items
    final manualRaw = prefs.getString(_manualKey);
    _manualItems = [];
    if (manualRaw != null) {
      try {
        final List<dynamic> decoded = json.decode(manualRaw);
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _manualItems.add({
              'name': item['name']?.toString() ?? '',
              'quantity': item['quantity']?.toString() ?? '',
              if (item['category'] != null) 'category': item['category'].toString(),
            });
          }
        }
      } catch (e) {
        debugPrint('Error loading manual shopping items: $e');
      }
    }

    // Days ahead
    _daysAhead = prefs.getInt(_daysAheadKey) ?? 7;

    // Bought until
    final boughtStr = prefs.getString(_boughtUntilKey);
    _boughtUntil = {};
    if (boughtStr != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(boughtStr);
        decoded.forEach((key, value) {
          _boughtUntil[key] = DateTime.parse(value.toString());
        });
      } catch (e) {
        debugPrint('Error loading bought until: $e');
      }
    }
  }

  static Future<void> setDaysAhead(int days) async {
    _daysAhead = days;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_daysAheadKey, days);
    _notifyListeners();
  }

  /// Represents a single shopping item with source info.
  /// Returns a list of maps: { name, sources: [ {recipeName, quantity} ] }
  static List<Map<String, dynamic>> generateFromPlanner() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = today.add(Duration(days: _daysAhead));

    final meals = MealPlanManager.meals.where((m) {
      final d = DateTime(m.date.year, m.date.month, m.date.day);
      return !d.isAfter(endDate);
    }).toList();

    // Map: ingredientNameLower → { name (display), sources: [{recipeName, quantity}] }
    final Map<String, Map<String, dynamic>> aggregated = {};

    for (final meal in meals) {
      final mealDate = DateTime(meal.date.year, meal.date.month, meal.date.day);
      final recipe = RecipeManager.recipes
          .where((r) => r.id == meal.recipeId)
          .firstOrNull;
      if (recipe == null) continue;

      // Prefer detailedIngredients for quantity info
      if (recipe.detailedIngredients.isNotEmpty) {
        for (final di in recipe.detailedIngredients) {
          final key = di.name.trim().toLowerCase();
          if (key.isEmpty) continue;
          
          final boughtUntilDate = _boughtUntil[key];
          if (boughtUntilDate != null && !mealDate.isAfter(boughtUntilDate)) {
            continue; // Already bought for this meal's date
          }

          if (!aggregated.containsKey(key)) {
            aggregated[key] = {
              'name': di.name.trim(),
              'category': di.category,
              'sources': <Map<String, String>>[],
            };
          }
          (aggregated[key]!['sources'] as List<Map<String, String>>).add({
            'recipeName': recipe.title,
            'quantity': di.quantity,
          });
        }
      } else {
        for (final ingredient in recipe.ingredients) {
          final key = ingredient.trim().toLowerCase();
          if (key.isEmpty) continue;

          final boughtUntilDate = _boughtUntil[key];
          if (boughtUntilDate != null && !mealDate.isAfter(boughtUntilDate)) {
            continue; // Already bought for this meal's date
          }

          if (!aggregated.containsKey(key)) {
            aggregated[key] = {
              'name': ingredient.trim(),
              'category': null,
              'sources': <Map<String, String>>[],
            };
          }
          (aggregated[key]!['sources'] as List<Map<String, String>>).add({
            'recipeName': recipe.title,
            'quantity': '',
          });
        }
      }
    }

    return aggregated.values.toList();
  }

  static bool isChecked(String itemName) =>
      _checkedItems.contains(itemName.toLowerCase());

  static Future<void> toggleChecked(String itemName) async {
    final key = itemName.toLowerCase();
    if (_checkedItems.contains(key)) {
      _checkedItems.remove(key);
    } else {
      _checkedItems.add(key);
    }
    await _saveChecked();
    _notifyListeners();
  }

  static Future<void> addManualItem(String name, String quantity, [IngredientCategory? category]) async {
    _manualItems.add({
      'name': name, 
      'quantity': quantity,
      if (category != null) 'category': category.name,
    });
    await _saveManual();
    _notifyListeners();
  }

  static Future<void> removeManualItem(int index) async {
    if (index >= 0 && index < _manualItems.length) {
      _manualItems.removeAt(index);
      await _saveManual();
      _notifyListeners();
    }
  }

  /// Called when leaving the shopping list page to permanently archive checked items
  static Future<void> archiveCheckedItems() async {
    if (_checkedItems.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = today.add(Duration(days: _daysAhead));

    bool manualChanged = false;
    for (final key in _checkedItems) {
      // Check if it's a manual item and remove it
      final initialLength = _manualItems.length;
      _manualItems.removeWhere((item) => (item['name'] ?? '').toLowerCase() == key);
      if (_manualItems.length != initialLength) {
        manualChanged = true;
      }
      
      // Update bought until date for planner items
      _boughtUntil[key] = endDate;
    }

    _checkedItems.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_checkedKey, []);
    if (manualChanged) {
      await prefs.setString(_manualKey, json.encode(_manualItems));
    }
    await prefs.setString(_boughtUntilKey, json.encode(
      _boughtUntil.map((k, v) => MapEntry(k, v.toIso8601String()))
    ));
    
    _notifyListeners();
  }

  static Future<void> _saveChecked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_checkedKey, _checkedItems.toList());
  }

  static Future<void> _saveManual() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_manualKey, json.encode(_manualItems));
  }
}

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

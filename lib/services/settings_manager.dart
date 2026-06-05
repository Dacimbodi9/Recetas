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

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:recetas/l10n.dart';
import 'package:recetas/models/models.dart';
import 'package:recetas/services/recipe_manager.dart';
import 'package:recetas/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

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
  static const _autoBackupFrequencyKey = 'auto_backup_frequency';
  static const _lastBackupDateKey = 'last_backup_date';

  static final ValueNotifier<String> autoBackupFrequency = ValueNotifier('off');
  static final ValueNotifier<String?> lastBackupDate = ValueNotifier(null);

  // Theme preferences
  static final ValueNotifier<String> activeThemeId = ValueNotifier('oliva');
  static final ValueNotifier<List<AppThemePreset>> customThemes = ValueNotifier([]);
  static const _activeThemeKey = 'active_theme_id';
  static const _customThemesKey = 'custom_themes';

  // Auto-backup preferences
  static final ValueNotifier<bool> autoBackupSettings = ValueNotifier(true);
  static final ValueNotifier<bool> autoBackupRecipes = ValueNotifier(true);
  static final ValueNotifier<bool> autoBackupMeals = ValueNotifier(true);
  static final ValueNotifier<bool> autoBackupShopping = ValueNotifier(true);

  static const String _autoBackupSettingsKey = 'auto_backup_settings';
  static const String _autoBackupRecipesKey = 'auto_backup_recipes';
  static const String _autoBackupMealsKey = 'auto_backup_meals';
  static const String _autoBackupShoppingKey = 'auto_backup_shopping';

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
    
    // Secure Storage Migration
    const secureStorage = FlutterSecureStorage();
    String? secureApiKey = await secureStorage.read(key: _aiApiKeyPref);
    
    if (secureApiKey == null) {
      // Check if it exists in SharedPreferences (needs migration)
      final legacyKey = prefs.getString(_aiApiKeyPref);
      if (legacyKey != null && legacyKey.isNotEmpty) {
        await secureStorage.write(key: _aiApiKeyPref, value: legacyKey);
        await prefs.remove(_aiApiKeyPref);
        secureApiKey = legacyKey;
      }
    }
    
    aiApiKey.value = secureApiKey ?? '';
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
    autoBackupFrequency.value = prefs.getString(_autoBackupFrequencyKey) ?? 'off';
    lastBackupDate.value = prefs.getString(_lastBackupDateKey);

    autoBackupSettings.value = prefs.getBool(_autoBackupSettingsKey) ?? true;
    autoBackupRecipes.value = prefs.getBool(_autoBackupRecipesKey) ?? true;
    autoBackupMeals.value = prefs.getBool(_autoBackupMealsKey) ?? true;
    autoBackupShopping.value = prefs.getBool(_autoBackupShoppingKey) ?? true;

    // Theme
    activeThemeId.value = prefs.getString(_activeThemeKey) ?? 'oliva';
    final customThemesJson = prefs.getStringList(_customThemesKey) ?? [];
    customThemes.value = customThemesJson
        .map((e) => AppThemePreset.fromJson(jsonDecode(e)))
        .toList();
  }

  static Future<void> setAutoBackupSettings(bool value) async {
    autoBackupSettings.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupSettingsKey, value);
  }

  static Future<void> setAutoBackupRecipes(bool value) async {
    autoBackupRecipes.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupRecipesKey, value);
  }

  static Future<void> setAutoBackupMeals(bool value) async {
    autoBackupMeals.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupMealsKey, value);
  }

  static Future<void> setAutoBackupShopping(bool value) async {
    autoBackupShopping.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupShoppingKey, value);
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
    const secureStorage = FlutterSecureStorage();
    if (key.isEmpty) {
      await secureStorage.delete(key: _aiApiKeyPref);
    } else {
      await secureStorage.write(key: _aiApiKeyPref, value: key);
    }
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

  static Future<void> setAutoBackupFrequency(String frequency) async {
    autoBackupFrequency.value = frequency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_autoBackupFrequencyKey, frequency);
  }

  static Future<void> setLastBackupDate(DateTime date) async {
    final iso = date.toIso8601String();
    lastBackupDate.value = iso;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupDateKey, iso);
  }

  static Future<Map<String, dynamic>> getAllSettingsAsMap() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> data = {};
    for (final key in prefs.getKeys()) {
      data[key] = prefs.get(key);
    }
    const secureStorage = FlutterSecureStorage();
    final secureData = await secureStorage.readAll();
    data['secure_storage'] = secureData;
    return data;
  }

  static Future<void> importSettingsFromMap(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    for (final key in data.keys) {
      if (key == 'secure_storage') continue;
      
      final value = data[key];
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is List) {
        await prefs.setStringList(key, value.map((e) => e.toString()).toList());
      }
    }

    if (data.containsKey('secure_storage')) {
      const secureStorage = FlutterSecureStorage();
      await secureStorage.deleteAll();
      final Map<String, dynamic> secureData = data['secure_storage'];
      for (final key in secureData.keys) {
        await secureStorage.write(key: key, value: secureData[key].toString());
      }
    }

    // Reload settings into memory
    await loadSettings();
  }

  static Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    const secureStorage = FlutterSecureStorage();
    await secureStorage.deleteAll();
    await loadSettings();
  }

  // ── Theme Management ──

  /// Returns the currently active theme preset (default or custom).
  static AppThemePreset get activePreset {
    final id = activeThemeId.value;
    // Check defaults first
    for (final preset in AppTheme.defaultPresets) {
      if (preset.id == id) return preset;
    }
    // Check custom themes
    for (final preset in customThemes.value) {
      if (preset.id == id) return preset;
    }
    // Fallback to Oliva
    return AppTheme.defaultPreset;
  }

  static Future<void> setActiveTheme(String themeId) async {
    activeThemeId.value = themeId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeThemeKey, themeId);
  }

  static Future<void> _saveCustomThemes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = customThemes.value
        .map((t) => jsonEncode(t.toJson()))
        .toList();
    await prefs.setStringList(_customThemesKey, jsonList);
  }

  static Future<void> addCustomTheme(AppThemePreset theme) async {
    customThemes.value = [...customThemes.value, theme];
    await _saveCustomThemes();
  }

  static Future<void> updateCustomTheme(AppThemePreset theme) async {
    customThemes.value = customThemes.value
        .map((t) => t.id == theme.id ? theme : t)
        .toList();
    await _saveCustomThemes();
  }

  static Future<void> deleteCustomTheme(String themeId) async {
    // If this theme is active, switch to default
    if (activeThemeId.value == themeId) {
      await setActiveTheme('oliva');
    }
    customThemes.value = customThemes.value
        .where((t) => t.id != themeId)
        .toList();
    await _saveCustomThemes();
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recetas/services/recipe_manager.dart';
import 'package:recetas/services/meal_plan_manager.dart';
import 'package:recetas/services/shopping_list_manager.dart';
import 'package:recetas/services/settings_manager.dart';

class DataManagementService {
  /// Exports user data based on selections
  static Future<Map<String, dynamic>> exportData({
    bool exportSettings = true,
    bool exportRecipes = true,
    bool exportMeals = true,
    bool exportShopping = true,
  }) async {
    final data = <String, dynamic>{};
    final prefs = await SharedPreferences.getInstance();

    final recipeKeys = {
      'saved_recipes',
      'favorite_recipes',
      'favorite_folders',
      'custom_ingredient_mappings',
      'custom_recipe_images',
    };
    final mealKeys = {'planned_meals', 'meal_templates'};
    final shoppingKeys = {
      'shopping_checked_items',
      'shopping_manual_items',
      'shopping_days_ahead',
      'shopping_bought_until',
    };

    for (final key in prefs.getKeys()) {
      bool shouldExport = false;
      if (recipeKeys.contains(key)) {
        shouldExport = exportRecipes;
      } else if (mealKeys.contains(key)) {
        shouldExport = exportMeals;
      } else if (shoppingKeys.contains(key)) {
        shouldExport = exportShopping;
      } else {
        // Assume anything else is settings
        shouldExport = exportSettings;
      }

      if (shouldExport) {
        data[key] = prefs.get(key);
      }
    }

    if (exportSettings) {
      const secureStorage = FlutterSecureStorage();
      data['secure_storage'] = await secureStorage.readAll();
    }

    // Metadata
    data['_version'] = 1;
    data['_timestamp'] = DateTime.now().toIso8601String();

    return data;
  }

  /// Imports and merges data non-destructively
  static Future<void> importAllData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    for (final key in data.keys) {
      if (key == 'secure_storage' || key == '_version' || key == '_timestamp') continue;
      final value = data[key];

      // Merge logic for specific known arrays to prevent wiping existing data
      if (key == 'saved_recipes' && value is List) {
        final existingList = prefs.getStringList(key) ?? [];
        _mergeStringList(existingList, value, (item) => jsonDecode(item)['id']);
        await prefs.setStringList(key, existingList);
        continue;
      }

      if (key == 'favorite_recipes' && value is List) {
        final existingList = prefs.getStringList(key) ?? [];
        final set = existingList.toSet()..addAll(value.map((e) => e.toString()));
        await prefs.setStringList(key, set.toList());
        continue;
      }

      if (key == 'shopping_checked_items' && value is List) {
        final existingList = prefs.getStringList(key) ?? [];
        final set = existingList.toSet()..addAll(value.map((e) => e.toString()));
        await prefs.setStringList(key, set.toList());
        continue;
      }

      if (key == 'favorite_folders' && value is String) {
        await _mergeJsonArrayString(prefs, key, value, 'id');
        continue;
      }

      if (key == 'meal_templates' && value is String) {
        await _mergeJsonArrayString(prefs, key, value, 'id');
        continue;
      }

      if (key == 'planned_meals' && value is String) {
        // Meals don't have a stable ID, we merge by string match
        await _mergeJsonArrayString(prefs, key, value, null);
        continue;
      }

      if (key == 'shopping_manual_items' && value is String) {
        await _mergeJsonArrayString(prefs, key, value, null);
        continue;
      }

      // Default behavior for settings and simple values: Overwrite
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
      final Map<String, dynamic> secureData = Map<String, dynamic>.from(data['secure_storage']);
      for (final key in secureData.keys) {
        await secureStorage.write(key: key, value: secureData[key].toString());
      }
    }

    // Reload all managers to reflect the imported data
    await SettingsManager.loadSettings();
    await RecipeManager.loadRecipes();
    await MealPlanManager.load();
    await ShoppingListManager.load();
  }

  static void _mergeStringList(List<String> existing, List<dynamic> imported, String Function(String) getId) {
    final Map<String, int> indexMap = {};
    for (int i = 0; i < existing.length; i++) {
      try {
        indexMap[getId(existing[i])] = i;
      } catch (_) {}
    }

    for (final item in imported) {
      final strItem = item.toString();
      try {
        final id = getId(strItem);
        if (!indexMap.containsKey(id)) {
          existing.add(strItem);
          indexMap[id] = existing.length - 1;
        }
      } catch (_) {
        existing.add(strItem);
      }
    }
  }

  static Future<void> _mergeJsonArrayString(SharedPreferences prefs, String key, String importedStr, String? idField) async {
    final existingStr = prefs.getString(key);
    final List existingList = existingStr != null ? jsonDecode(existingStr) : [];
    final List importedList = jsonDecode(importedStr);

    if (idField == null) {
      // Append only if not already exact match
      final existingStrings = existingList.map((e) => jsonEncode(e)).toSet();
      for (final item in importedList) {
        if (!existingStrings.contains(jsonEncode(item))) {
          existingList.add(item);
        }
      }
    } else {
      final Map<String, int> indexMap = {};
      for (int i = 0; i < existingList.length; i++) {
        if (existingList[i][idField] != null) {
          indexMap[existingList[i][idField].toString()] = i;
        }
      }

      for (final item in importedList) {
        final id = item[idField]?.toString();
        if (id != null) {
          if (!indexMap.containsKey(id)) {
            existingList.add(item);
            indexMap[id] = existingList.length - 1;
          }
        } else {
          existingList.add(item);
        }
      }
    }

    await prefs.setString(key, jsonEncode(existingList));
  }

  /// Clears all user data across all managers
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    const secureStorage = FlutterSecureStorage();
    await secureStorage.deleteAll();

    // Reload managers so they clear their in-memory states
    await SettingsManager.loadSettings();
    await RecipeManager.loadRecipes();
    await MealPlanManager.load();
    await ShoppingListManager.load();
  }

  /// Returns the directory where backups are stored
  static Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDir.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Runs the auto backup logic if the elapsed time matches the configured frequency
  static Future<void> runAutoBackupIfNeeded() async {
    final freq = SettingsManager.autoBackupFrequency.value;
    if (freq == 'off') return;

    final lastStr = SettingsManager.lastBackupDate.value;
    DateTime? lastDate;
    if (lastStr != null) {
      try {
        lastDate = DateTime.parse(lastStr);
      } catch (_) {}
    }

    final now = DateTime.now();
    bool shouldBackup = false;

    if (lastDate == null) {
      shouldBackup = true;
    } else {
      final diff = now.difference(lastDate);
      if (freq == 'daily' && diff.inDays >= 1) shouldBackup = true;
      if (freq == 'weekly' && diff.inDays >= 7) shouldBackup = true;
      if (freq == 'monthly' && diff.inDays >= 30) shouldBackup = true;
    }

    if (shouldBackup) {
      await _createLocalBackup();
      await SettingsManager.setLastBackupDate(now);
      await _cleanOldBackups();
    }
  }

  /// Creates a local backup file
  static Future<File> _createLocalBackup() async {
    final dir = await _getBackupDirectory();
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final file = File('${dir.path}/backup_$dateStr.json');
    
    final data = await exportData(
      exportSettings: SettingsManager.autoBackupSettings.value,
      exportRecipes: SettingsManager.autoBackupRecipes.value,
      exportMeals: SettingsManager.autoBackupMeals.value,
      exportShopping: SettingsManager.autoBackupShopping.value,
    );
    await file.writeAsString(jsonEncode(data));
    return file;
  }

  /// Gets all available local backups, sorted from newest to oldest
  static Future<List<File>> getAvailableBackups() async {
    final dir = await _getBackupDirectory();
    final List<File> backups = [];
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.json') && entity.path.contains('backup_')) {
          backups.add(entity);
        }
      }
      // Sort descending by last modified
      backups.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    }
    return backups;
  }

  /// Restores data from a specific backup file
  static Future<void> restoreFromBackup(File backupFile) async {
    final content = await backupFile.readAsString();
    final Map<String, dynamic> data = jsonDecode(content);
    await importAllData(data);
  }

  /// Keeps only the 5 most recent backups to save space
  static Future<void> _cleanOldBackups() async {
    final backups = await getAvailableBackups();
    if (backups.length > 5) {
      for (int i = 5; i < backups.length; i++) {
        await backups[i].delete();
      }
    }
  }
}

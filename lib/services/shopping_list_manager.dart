part of '../main.dart';

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

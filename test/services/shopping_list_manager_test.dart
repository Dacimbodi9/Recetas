import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recetas/services/shopping_list_manager.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ShoppingListManager.load();
    // Clear lists via reflection or simply rely on mock values being empty
    // since there is no public clear method. We will just load fresh mock values.
  });

  group('ShoppingListManager Tests', () {
    test('Initial state is empty', () {
      expect(ShoppingListManager.manualItems, isEmpty);
      expect(ShoppingListManager.checkedItems, isEmpty);
      expect(ShoppingListManager.daysAhead, 7);
    });

    test('Add and remove manual items', () async {
      await ShoppingListManager.addManualItem('Milk', '1 gallon');
      expect(ShoppingListManager.manualItems.length, 1);
      expect(ShoppingListManager.manualItems.first['name'], 'Milk');
      expect(ShoppingListManager.manualItems.first['quantity'], '1 gallon');

      await ShoppingListManager.removeManualItem(0);
      expect(ShoppingListManager.manualItems, isEmpty);
    });

    test('Toggle item checked state', () async {
      await ShoppingListManager.addManualItem('Eggs', '12');
      final itemName = 'Eggs';

      expect(ShoppingListManager.isChecked(itemName), isFalse);

      await ShoppingListManager.toggleChecked(itemName);
      expect(ShoppingListManager.isChecked(itemName), isTrue);
      expect(ShoppingListManager.checkedItems.contains(itemName.toLowerCase()), isTrue);

      await ShoppingListManager.toggleChecked(itemName);
      expect(ShoppingListManager.isChecked(itemName), isFalse);
    });

    test('Archive checked items', () async {
      await ShoppingListManager.addManualItem('Bread', '1 loaf');
      await ShoppingListManager.toggleChecked('Bread');
      expect(ShoppingListManager.checkedItems, isNotEmpty);

      await ShoppingListManager.archiveCheckedItems();
      expect(ShoppingListManager.checkedItems, isEmpty);
      // Manual item should be deleted by archiveCheckedItems since it was checked
      expect(ShoppingListManager.manualItems, isEmpty);
    });

    test('Set days ahead', () async {
      await ShoppingListManager.setDaysAhead(14);
      expect(ShoppingListManager.daysAhead, 14);
    });
  });
}

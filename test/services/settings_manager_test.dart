import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:recetas/services/settings_manager.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsManager Tests', () {
    test('showDefaultRecipes toggles and persists', () async {
      await SettingsManager.setShowDefaults(false);
      expect(SettingsManager.showDefaultRecipes.value, false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('show_default_recipes'), false);
    });

    test('darkMode toggles and persists', () async {
      await SettingsManager.setDarkMode(false);
      expect(SettingsManager.isDarkMode.value, false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_dark_mode'), false);
    });

    test('migrates AI API Key from SharedPreferences to Secure Storage', () async {
      // Setup mock legacy data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ai_api_key', 'legacy_api_key');
      
      // Mock secure storage
      FlutterSecureStorage.setMockInitialValues({});
      
      await SettingsManager.loadSettings();
      
      // Should have migrated
      expect(SettingsManager.aiApiKey.value, 'legacy_api_key');
      expect(prefs.getString('ai_api_key'), isNull); // Removed from shared prefs
      
      final secureStorage = const FlutterSecureStorage();
      final migratedKey = await secureStorage.read(key: 'ai_api_key');
      expect(migratedKey, 'legacy_api_key');
    });
  });
}




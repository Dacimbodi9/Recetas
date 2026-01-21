import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
// import 'shopping_list.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsManager.loadSettings();
  await RecipeManager.loadDefaultRecipes();
  await RecipeManager.loadRecipes();
  runApp(const RecetasApp());
}

class SettingsManager {
  static final ValueNotifier<bool> isDarkMode = ValueNotifier(true);
  static final ValueNotifier<bool> showDefaultRecipes = ValueNotifier(false);
  static final ValueNotifier<bool> preventSleep = ValueNotifier(false);
  static final ValueNotifier<int> startScreenIndex = ValueNotifier(0); // 0: Search, 1: Favorites
  static final ValueNotifier<Set<DietaryRestriction>> dietaryDefaults = ValueNotifier({});
  static final ValueNotifier<Set<String>> customDietaryDefaults = ValueNotifier({});

  static const _themeKey = 'is_dark_mode';
  static const _defaultsKey = 'show_default_recipes';
  static const _preventSleepKey = 'prevent_sleep';
  static const _startScreenKey = 'start_screen_index';
  static const _dietaryDefaultsKey = 'dietary_defaults';
  static const _customDietaryDefaultsKey = 'custom_dietary_defaults';

  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Force dark mode (option removed from UI per request), but keep variable in case needed
    isDarkMode.value = true; 
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
        .map((e) => DietaryRestriction.values.firstWhere(
            (r) => r.name == e, orElse: () => DietaryRestriction.vegetariano))
        .toSet();

    final customDietaryList = prefs.getStringList(_customDietaryDefaultsKey) ?? [];
    customDietaryDefaults.value = customDietaryList.toSet();

    applyDietaryToDefaults.value = prefs.getBool(_applyToDefaultsKey) ?? false;
    hideIncompatibleRecipes.value = prefs.getBool(_hideIncompatibleKey) ?? false;
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
    // Notify RecipeManager listeners to refresh the list
    RecipeManager.notifyListeners(); 
  }

  static final ValueNotifier<bool> applyDietaryToDefaults = ValueNotifier(false);
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

  static final ValueNotifier<bool> hideIncompatibleRecipes = ValueNotifier(false);
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay recetas para exportar')));
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
                  title: const Text('Compartir'),
                  onTap: () => Navigator.pop(context, 'share'),
                ),
                ListTile(
                  leading: const Icon(Icons.save),
                  title: const Text('Guardar en dispositivo'),
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
        
        final result = await Share.shareXFiles([XFile(file.path)], text: 'Copia de seguridad de Mis Recetas');
        
        if (result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copia de seguridad compartida')));
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recetas guardadas exitosamente')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
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
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Importado: $importedCount. Omitido (duplicado): $skippedCount'),
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al importar: $e')));
    }
  }

  static Future<void> clearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar TODOS los datos'),
        content: const Text('Esta acción eliminará todas tus recetas personalizadas y carpetas. No se puede deshacer. ¿Estás seguro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Borrar todo')
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await RecipeManager.clearAllData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos eliminados correctamente')));
    }
  }
}

// Dietary restriction enum
enum DietaryRestriction {
  vegetariano,
  vegano,
  sinlactosa,
  singluten,
  sinfrutossecos,
  sinmariscos,
}

extension DietaryRestrictionExtension on DietaryRestriction {
  String get displayName {
    switch (this) {
      case DietaryRestriction.vegetariano:
        return 'Vegetariano';
      case DietaryRestriction.vegano:
        return 'Vegano';
      case DietaryRestriction.sinlactosa:
        return 'Sin lactosa';
      case DietaryRestriction.singluten:
        return 'Sin gluten';
      case DietaryRestriction.sinfrutossecos:
        return 'Sin frutos secos';
      case DietaryRestriction.sinmariscos:
        return 'Sin mariscos';
    }
  }

  String get description {
    switch (this) {
      case DietaryRestriction.vegetariano:
        return 'No contiene carne';
      case DietaryRestriction.vegano:
        return 'No contiene productos animales';
      case DietaryRestriction.sinlactosa:
        return 'Sin lactosa';
      case DietaryRestriction.singluten:
        return 'Sin gluten';
      case DietaryRestriction.sinfrutossecos:
        return 'Sin frutos secos';
      case DietaryRestriction.sinmariscos:
        return 'Sin mariscos';
    }
  }
}

enum RecipeCategory {
  entrantes,
  sopasycremas,
  ensaladas,
  platosprincipales,
  guarniciones,
  postresydulces,
  bebidas,
  otros,
}

extension RecipeCategoryX on RecipeCategory {
  String get displayName {
    switch (this) {
      case RecipeCategory.entrantes:
        return 'Entrantes';
      case RecipeCategory.sopasycremas:
        return 'Sopas y Cremas';
      case RecipeCategory.ensaladas:
        return 'Ensaladas';
      case RecipeCategory.platosprincipales:
        return 'Platos Principales';
      case RecipeCategory.guarniciones:
        return 'Guarniciones';
      case RecipeCategory.postresydulces:
        return 'Postres y Dulces';
      case RecipeCategory.bebidas:
        return 'Bebidas';
      case RecipeCategory.otros:
        return 'Otros';
      
    }
  }

  IconData get icon {
    switch (this) {
      case RecipeCategory.entrantes:
        return Icons.tapas;
      case RecipeCategory.sopasycremas:
        return Icons.soup_kitchen;
      case RecipeCategory.ensaladas:
        return Icons.grass;
      case RecipeCategory.platosprincipales:
        return Icons.dinner_dining;
      case RecipeCategory.guarniciones:
        return Icons.breakfast_dining;
      case RecipeCategory.postresydulces:
        return Icons.bakery_dining;
      case RecipeCategory.bebidas:
        return Icons.local_bar;
      case RecipeCategory.otros:
        return Icons.kitchen;
    }
  }
}

enum IngredientCategory {
  frescosVegetales,
  proteinaAnimal,
  lacteosYHuevos,
  granosYPastas,
  aceitesYGrasas,
  condimentosYEspecias,
  reposteriaYHarinas,
  conservasYVarios,
}

extension IngredientCategoryX on IngredientCategory {
  String get displayName {
    switch (this) {
      case IngredientCategory.frescosVegetales:
        return 'Frescos Vegetales';
      case IngredientCategory.proteinaAnimal:
        return 'Proteína Animal';
      case IngredientCategory.lacteosYHuevos:
        return 'Lácteos y Huevos';
      case IngredientCategory.granosYPastas:
        return 'Granos y Pastas';
      case IngredientCategory.aceitesYGrasas:
        return 'Aceites y Grasas';
      case IngredientCategory.condimentosYEspecias:
        return 'Condimentos y Especias';
      case IngredientCategory.reposteriaYHarinas:
        return 'Repostería y Harinas';
      case IngredientCategory.conservasYVarios:
        return 'Conservas y Varios';
    }
  }

  IconData get icon {
    switch (this) {
      case IngredientCategory.frescosVegetales:
        return Icons.eco;
      case IngredientCategory.proteinaAnimal:
        return Icons.set_meal;
      case IngredientCategory.lacteosYHuevos:
        return Icons.local_drink;
      case IngredientCategory.granosYPastas:
        return Icons.grain;
      case IngredientCategory.aceitesYGrasas:
        return Icons.oil_barrel;
      case IngredientCategory.condimentosYEspecias:
        return Icons.restaurant_menu;
      case IngredientCategory.reposteriaYHarinas:
        return Icons.cake;
      case IngredientCategory.conservasYVarios:
        return Icons.inventory;
    }
  }
}


class RecetasApp extends StatefulWidget {
  const RecetasApp({super.key});

  @override
  State<RecetasApp> createState() => _RecetasAppState();
}

class _RecetasAppState extends State<RecetasApp> {


  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF00CED1);
    


    return ValueListenableBuilder<bool>(
      valueListenable: SettingsManager.isDarkMode,
      builder: (context, isDark, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Recetas',
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData.light(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: seed,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F5F7),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              centerTitle: true,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.black.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            cardTheme: const CardThemeData(
              color: Colors.white,
              elevation: 2,
              shadowColor: Colors.black12,
              margin: EdgeInsets.zero,
            ),
          ),
          darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: seed,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0B0B0F),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              centerTitle: true,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: seed.withOpacity(0.8), width: 1.2),
              ),
            ),
            cardTheme: CardThemeData(
              color: Colors.white.withOpacity(0.05),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(18)),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            chipTheme: ChipThemeData(
              backgroundColor: Colors.white.withOpacity(0.05),
              selectedColor: seed.withOpacity(0.2),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              labelStyle: const TextStyle(color: Colors.white),
              secondaryLabelStyle: const TextStyle(color: Colors.white),
            ),
          ),
          home: ValueListenableBuilder<int>(
            valueListenable: SettingsManager.startScreenIndex,
            builder: (context, index, child) => const MainNavigationPage(),
          ),
        );
      },
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = SettingsManager.startScreenIndex.value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          SearchPage(),
          FavoritesPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(CupertinoIcons.search),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.book),
            label: 'Mis Recetas',
          ),
          /*
          NavigationDestination(
            icon: Icon(CupertinoIcons.calendar),
            label: 'Calendario',
          ),
          */
          NavigationDestination(
            icon: Icon(CupertinoIcons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController(); // For recipes view
  late PageController _pageController;
  int _selectedIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    RecipeManager.addListener(_onRecipesChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    RecipeManager.removeListener(_onRecipesChanged);
    super.dispose();
  }

  void _onRecipesChanged() {
    setState(() {});
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onSegmentChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Segmented Control
          Padding(
            padding: const EdgeInsets.all(16),
            child: _SlidingSegmentedControl(
              controller: _pageController,
              selectedIndex: _selectedIndex,
              onTap: _onSegmentChanged,
              tabs: const ['Ingredientes', 'Recetas'],
            ),
          ),
          
          // PageView for sliding content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                const IngredientSearchPage(),
                _RecetasView(
                  searchController: _searchController,
                  searchQuery: _searchQuery,
                  onSearchChanged: (value) => setState(() => _searchQuery = value),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecipeDialog(context),
        child: const Icon(CupertinoIcons.plus),
      ),
    );
  }

  void _showAddRecipeDialog(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const NewRecipePage(),
      fullscreenDialog: true,
    ),
  );
  }
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  String _searchQuery = '';
  int _selectedIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onSegmentChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Custom Segmented Control
          Padding(
            padding: const EdgeInsets.all(16),
            child: _SlidingSegmentedControl(
              controller: _pageController,
              selectedIndex: _selectedIndex,
              onTap: _onSegmentChanged,
              tabs: const ['Favoritos', 'Valoraciones'],
            ),
          ),
          
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _FavoritosView(
                  searchController: _searchController,
                  searchQuery: _searchQuery,
                  onSearchChanged: (value) => setState(() => _searchQuery = value),
                  showAppBar: false,
                ),
                const RatedRecipesPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class _RecetasView extends StatelessWidget {
  const _RecetasView({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final allRecipes = RecipeManager.recipes;
    final categories = RecipeCategory.values.where((c) => allRecipes.any((r) => r.categories.contains(c))).toList();
    
    // Search for recipes by name
    final searchResults = searchQuery.isEmpty 
        ? <Recipe>[]
        : RecipeManager.recipes.where((recipe) {
            final normalizedTitle = _removeDiacritics(recipe.title.toLowerCase());
            final normalizedQuery = _removeDiacritics(searchQuery.toLowerCase().trim());
            
            if (normalizedQuery.isEmpty) return false;
            
            // Split query into words (tokens)
            final queryWords = normalizedQuery.split(RegExp(r'\s+'));
            
            // Check if ALL words are present in the title
            return queryWords.every((word) => normalizedTitle.contains(word));
          }).toList();

    return Column(
        children: [
          Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar recetas por nombre...',
                prefixIcon: const Icon(CupertinoIcons.search),
              suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.xmark_circle_fill),
                        onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                        },
                      )
                    : IconButton(
                        icon: const Icon(CupertinoIcons.shuffle),
                        tooltip: 'Receta aleatoria',
                        onPressed: () {
                          final allRecipes = RecipeManager.recipes;
                          if (allRecipes.isNotEmpty) {
                            final random = Random();
                            final recipe = allRecipes[random.nextInt(allRecipes.length)];
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RecipeDetailPage(recipe: recipe),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No hay recetas disponibles')),
                            );
                          }
                        },
                      ),
              ),
            ),
          ),
        const SizedBox(height: 8),
          Expanded(
          child: searchQuery.isNotEmpty
                ? searchResults.isEmpty
                    ? const Center(child: Text('No se encontraron recetas'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final recipe = searchResults[index];
                          return _RecipeCard(recipe: recipe, matchCount: 0);
                        },
                      )
              : categories.isEmpty
                  ? const _EmptyStateWidget(
                      icon: Icons.restaurant_menu,
                      title: 'No hay recetas',
                      subtitle: 'Añade tus propias recetas para verlas aquí',
                    )
                  : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final c = categories[index];
                    return Container(
                                  decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.09),
                            Colors.white.withOpacity(0.03),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RecipesByCategoryPage(
                                  category: c,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  c.icon,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  c.displayName,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

String _removeDiacritics(String str) {
  const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
  const withoutDia = 'AAAAAAaaaaaaOOOOOØooooooEEEEeeeedCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

  for (int i = 0; i < withDia.length; i++) {
    str = str.replaceAll(withDia[i], withoutDia[i]);
  }
  return str;
}

List<String> _sortIngredients(List<String> ingredients, String query) {
  if (query.isEmpty) return ingredients;
  
  final normalizedQuery = _removeDiacritics(query.toLowerCase().trim());
  
  // Filter matches first
  final matches = ingredients.where((ingredient) {
    final normalizedIngredient = _removeDiacritics(ingredient.toLowerCase());
    return normalizedIngredient.contains(normalizedQuery);
  }).toList();
  
  // Sort matches
  matches.sort((a, b) {
    final normA = _removeDiacritics(a.toLowerCase());
    final normB = _removeDiacritics(b.toLowerCase());
    
    // 1. Exact match
    if (normA == normalizedQuery && normB != normalizedQuery) return -1;
    if (normB == normalizedQuery && normA != normalizedQuery) return 1;
    
    // 2. Starts with
    final aStarts = normA.startsWith(normalizedQuery);
    final bStarts = normB.startsWith(normalizedQuery);
    if (aStarts && !bStarts) return -1;
    if (!aStarts && bStarts) return 1;
    
    // 3. Word boundary starts with (e.g. "Salsa de Tomate" vs "Jitomate" for "Tomate")
    // "Tomate" starts "Tomate..." -> handled by 2.
    // "Salsa de Tomate" contains " Tomate". "Jitomate" contains "tomate" but not " tomate".
    // Or just prefer shortest length if multiple matches?
    // Let's prefer matches where the token is at the start of a word.
    final aWordStart = normA.contains(' $normalizedQuery') || normA.startsWith(normalizedQuery);
    final bWordStart = normB.contains(' $normalizedQuery') || normB.startsWith(normalizedQuery);
    if (aWordStart && !bWordStart) return -1;
    if (!aWordStart && bWordStart) return 1;

    // 4. Length (shorter is better match, likely)
    return normA.length.compareTo(normB.length);
  });
  
  return matches;
}

class _FavoritosView extends StatefulWidget {
  const _FavoritosView({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    this.showAppBar = true,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final bool showAppBar;

  @override
  State<_FavoritosView> createState() => _FavoritosViewState();
}

class _FavoritosViewState extends State<_FavoritosView> {
  String? _currentFolderId;
  List<String> _folderPath = [];

  @override
  void initState() {
    super.initState();
    RecipeManager.addListener(_onFoldersChanged);
  }

  @override
  void dispose() {
    RecipeManager.removeListener(_onFoldersChanged);
    super.dispose();
  }

  void _onFoldersChanged() {
    setState(() {});
  }

  void _navigateToFolder(String? folderId) {
    setState(() {
      if (folderId == null) {
        _currentFolderId = null;
        _folderPath.clear();
      } else {
        // Add current folder to path before navigating
        if (_currentFolderId != null) {
          _folderPath.add(_currentFolderId!);
        }
        _currentFolderId = folderId;
      }
    });
  }

  void _navigateBack() {
    if (_folderPath.isNotEmpty) {
    setState(() {
        _currentFolderId = _folderPath.removeLast();
      });
    } else {
    setState(() {
        _currentFolderId = null;
        _folderPath.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // ROOT VIEW
    if (_currentFolderId == null) {
      final rootFolders = RecipeManager.rootFolders;
      
      // Determine recipes to show (Global Search vs Root View)
      final List<Recipe> recipesToShow;
      final List<FavoriteFolder> foldersToShow;
      
      if (widget.searchQuery.isNotEmpty) {
        // GLOBAL SEARCH
        recipesToShow = RecipeManager.favoriteRecipes
            .where((r) => r.title.toLowerCase().contains(widget.searchQuery.toLowerCase()))
            .toList();
        foldersToShow = RecipeManager.allFolders
            .where((f) => f.name.toLowerCase().contains(widget.searchQuery.toLowerCase()))
            .toList();
      } else {
        // NORMAL ROOT VIEW
        final allRecipesInFolders = <String>{};
        for (final folder in RecipeManager.allFolders) {
          allRecipesInFolders.addAll(folder.recipeTitles);
        }
        recipesToShow = RecipeManager.favoriteRecipes
            .where((r) => !allRecipesInFolders.contains(r.title))
            .toList();
        foldersToShow = rootFolders;
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.searchController,
                      onChanged: widget.onSearchChanged,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: 'Buscar en favoritos...',
                        prefixIcon: const Icon(CupertinoIcons.search),
                        suffixIcon: widget.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(CupertinoIcons.xmark_circle_fill),
                                onPressed: () {
                                  widget.searchController.clear();
                                  widget.onSearchChanged('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(CupertinoIcons.add),
                      onPressed: () => _showCreateFolderDialog(context, _currentFolderId),
                      tooltip: 'Crear carpeta',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: foldersToShow.isEmpty && recipesToShow.isEmpty
                  ? _EmptyStateWidget(
                      icon: widget.searchQuery.isEmpty ? CupertinoIcons.heart : CupertinoIcons.search,
                      title: widget.searchQuery.isEmpty ? 'No tienes favoritos' : 'Sin resultados',
                      subtitle: widget.searchQuery.isEmpty ? 'Tus recetas guardadas aparecerán aquí' : 'Intenta con otra búsqueda',
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Folders
                        ...foldersToShow.map((folder) => _FolderCard(
                          folder: folder,
                          onTap: () => _navigateToFolder(folder.id),
                          onLongPress: () => _showFolderOptions(context, folder),
                        )),
                        // Recipes
                        ...recipesToShow.map((recipe) => _RecipeCard(
                          recipe: recipe,
                          matchCount: 0,
                          showFolderOptions: true,
                        )),
                      ],
                    ),
            ),
          ],
        );
    } 
    
    // FOLDER VIEW
    else {
      final currentFolder = RecipeManager.getFolderById(_currentFolderId!);
      if (currentFolder == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _navigateBack());
        return const SizedBox.shrink();
      }

      final subFolders = RecipeManager.getSubFolders(_currentFolderId!);
      
      // Local Search Logic
      List<Recipe> recipesToShow;
      List<FavoriteFolder> foldersToShow;
      
      if (widget.searchQuery.isNotEmpty) {
        // RECURSIVE SEARCH
        recipesToShow = RecipeManager.getRecipesInFolderRecursive(_currentFolderId!)
            .where((r) => r.title.toLowerCase().contains(widget.searchQuery.toLowerCase()))
            .toList();
         foldersToShow = RecipeManager.getSubFoldersRecursive(_currentFolderId!)
            .where((f) => f.name.toLowerCase().contains(widget.searchQuery.toLowerCase()))
            .toList();
      } else {
        recipesToShow = RecipeManager.getRecipesInFolder(currentFolder);
        foldersToShow = subFolders;
      }

      return Scaffold(
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Pinned Navigation Header
            SliverAppBar(
              pinned: true,
              leading: IconButton(
                icon: const Icon(CupertinoIcons.chevron_left),
                onPressed: _navigateBack,
              ),
              title: Text(currentFolder.name),
              actions: [
                IconButton(
                  icon: const Icon(CupertinoIcons.add),
                  onPressed: () => _showCreateFolderDialog(context, _currentFolderId),
                  tooltip: 'Crear subcarpeta',
                ),
              ],
            ),
            
            // 2. Floating Search Bar
            SliverAppBar(
              pinned: false,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              titleSpacing: 16,
              toolbarHeight: 72,
              title: TextField(
                    controller: widget.searchController,
                    onChanged: widget.onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Buscar en ${currentFolder.name}...',
                      prefixIcon: const Icon(CupertinoIcons.search),
                      suffixIcon: widget.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(CupertinoIcons.xmark_circle_fill),
                              onPressed: () {
                                widget.searchController.clear();
                                widget.onSearchChanged('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
            ),

            if (foldersToShow.isEmpty && recipesToShow.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    widget.searchQuery.isEmpty
                        ? 'Carpeta vacía'
                        : 'No se encontraron resultados en ${currentFolder.name}',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Folders
                    ...foldersToShow.map((folder) => _FolderCard(
                      folder: folder,
                      onTap: () => _navigateToFolder(folder.id),
                      onLongPress: () => _showFolderOptions(context, folder),
                    )),
                    // Recipes
                    ...recipesToShow.map((recipe) => _RecipeCard(
                      recipe: recipe,
                      matchCount: 0,
                      showFolderOptions: true,
                    )),
                  ]),
                ),
              ),
          ],
        ),
      );
    }
  }

  void _showCreateFolderDialog(BuildContext context, String? parentId) {
    showDialog(
      context: context,
      builder: (context) => _CreateFolderDialog(parentId: parentId),
    );
  }

  void _showFolderOptions(BuildContext context, FavoriteFolder folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FolderOptionsSheet(folder: folder),
    );
  }
}

class NewRecipePage extends StatefulWidget {
  const NewRecipePage({super.key, this.recipeToEdit});

  final Recipe? recipeToEdit;

  @override
  State<NewRecipePage> createState() => _NewRecipePageState();
}

class _NewRecipePageState extends State<NewRecipePage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final TextEditingController _ingredientController = TextEditingController();
  
  // Data
  String? _selectedImagePath;
  String _ingredientQuery = '';
  final List<DetailedIngredient> _detailedIngredients = [];
  final List<String> _steps = [];
  bool _isReorderingSteps = false;
  final Set<RecipeCategory> _selectedCategories = {};
  final Set<DietaryRestriction> _selectedDietaryRestrictions = {};
  final Set<String> _selectedCustomTags = {};
  
  // Nutrition (Simplified for UI, but kept in code)
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.recipeToEdit != null) {
      _loadRecipeData(widget.recipeToEdit!);
    }
  }

  void _loadRecipeData(Recipe recipe) {
    _titleController.text = recipe.title;
    if (recipe.prepTime != null) _prepTimeController.text = recipe.prepTime!;
    
    _detailedIngredients.addAll(recipe.detailedIngredients);
    // If old simple ingredients exist and detailed are empty, try to convert? 
    // For now we rely on detailedIngredients being populated or manual entry.
    
    _steps.addAll(recipe.steps);
    _selectedCategories.addAll(recipe.categories);
    _selectedDietaryRestrictions.addAll(recipe.dietaryRestrictions);
    _selectedCustomTags.addAll(recipe.customDietaryTags);
    
    if (recipe.imagePath != null) _selectedImagePath = recipe.imagePath;

    for (final fact in recipe.nutritionFacts) {
      if (fact.label == 'Calorías') _caloriesController.text = fact.value.toString();
      if (fact.label == 'Proteína') _proteinController.text = fact.value.toString();
      if (fact.label == 'Carbohidratos') _carbsController.text = fact.value.toString();
      if (fact.label == 'Grasas') _fatController.text = fact.value.toString();
    }
  }


  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _prepTimeController.dispose();
    _ingredientController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut
      );
    } else {
      _saveRecipe();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final imageDir = Directory('${appDir.path}/recipe_images');
        if (!await imageDir.exists()) {
          await imageDir.create(recursive: true);
        }
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'recipe_$timestamp.jpg';
        final savedImage = File('${imageDir.path}/$fileName');
        
        await File(image.path).copy(savedImage.path);
        
        setState(() {
          _selectedImagePath = savedImage.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  // --- Logic Helpers ---

  Future<void> _saveRecipe() async {
     if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, escribe un nombre para la receta')),
      );
      return;
    }
    
    // Check if title changed effectively creating a new recipe vs editing
    // If we are editing, we usually want to keep the same identity (title) OR handle rename.
    // For simplicity, if we edit a default recipe, we create a custom override.
    // If we rename, it becomes a new recipe and we might want to delete the old override?
    // Let's assume title is the ID for now.
    
    if (widget.recipeToEdit != null && widget.recipeToEdit!.title != _titleController.text.trim()) {
       // Name changed. If it was a custom recipe, ideally we should remove the old one?
       // But user might want to "Save As". For now act as "Save As" / New Recipe if name differs.
       // However, to support "Edit", if name is same, it updates.
    }
    
    // Normalize Ingredients
    final normalizedIngredients = _detailedIngredients.map((d) => d.name).toList();

    // Nutrition
    List<NutritionFact> nutritionFacts = [];
    void addFact(TextEditingController ctrl, String label, String unit) {
       final txt = ctrl.text.trim().replaceAll(',', '.');
       if (txt.isNotEmpty) {
          final val = double.tryParse(txt);
          if (val != null && val > 0) nutritionFacts.add(NutritionFact(label: label, value: val, unit: unit));
       }
    }
    addFact(_caloriesController, 'Calorías', 'kcal');
    addFact(_proteinController, 'Proteína', 'g');
    addFact(_carbsController, 'Carbohidratos', 'g');
    addFact(_fatController, 'Grasas', 'g');

    final newRecipe = Recipe(
      title: _titleController.text.trim(),
      ingredients: normalizedIngredients,
      detailedIngredients: _detailedIngredients,
      prepTime: _prepTimeController.text.trim().isNotEmpty ? _prepTimeController.text.trim() : null,
      categories: _selectedCategories.toList(),
      dietaryRestrictions: _selectedDietaryRestrictions.toList(),
      customDietaryTags: _selectedCustomTags.toList(),
      imagePath: _selectedImagePath,
      steps: _steps,
      nutritionFacts: nutritionFacts,
    );

    try {
      if (widget.recipeToEdit != null && widget.recipeToEdit!.title != newRecipe.title) {
        await RecipeManager.removeRecipe(widget.recipeToEdit!);
      }
      await RecipeManager.addRecipe(newRecipe);
      
      // If we adjusted a custom recipe (same title), 'addRecipe' overwrites it which is correct.
      // If we edited a default recipe (same title), 'addRecipe' creates the override.
      // Favorites should be preserved if title matches.
      
      if (!RecipeManager.isFavorite(newRecipe) && widget.recipeToEdit == null) {
         // Auto-favorite only NEW recipes, not edits unless strictly desired.
         await RecipeManager.toggleFavorite(newRecipe); 
      }
      
      if (mounted) {
        Navigator.of(context).pop(); // Close wizard
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.recipeToEdit != null ? 'Receta actualizada' : 'Receta creada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar la receta')),
        );
      }
    }
  }

  void _addIngredient(DetailedIngredient ingredient) {
    setState(() {
      _detailedIngredients.add(ingredient);
      _ingredientController.clear();
      _ingredientQuery = '';
    });
  }

  void _removeIngredient(DetailedIngredient ingredient) {
    setState(() {
      _detailedIngredients.remove(ingredient);
    });
  }
  
  void _addStep(String step) {
    if (step.trim().isNotEmpty) {
      setState(() => _steps.add(step.trim()));
    }
  }

  void _editStep(int index, String newText) {
    if (newText.trim().isNotEmpty) {
      setState(() => _steps[index] = newText.trim());
    }
  }

  void _showStepOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.pencil),
              title: const Text('Editar paso'),
              onTap: () {
                Navigator.pop(context);
                final controller = TextEditingController(text: _steps[index]);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Editar paso'),
                    content: TextField(
                      controller: controller,
                      maxLines: 3,
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                      FilledButton(
                        onPressed: () {
                          _editStep(index, controller.text);
                          Navigator.pop(context);
                        },
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (index > 0 && !_isReorderingSteps)
              ListTile(
                leading: const Icon(CupertinoIcons.arrow_up),
                title: const Text('Mover arriba'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    final item = _steps.removeAt(index);
                    _steps.insert(index - 1, item);
                  });
                },
              ),
            if (index < _steps.length - 1 && !_isReorderingSteps)
              ListTile(
                leading: const Icon(CupertinoIcons.arrow_down),
                title: const Text('Mover abajo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    final item = _steps.removeAt(index);
                    _steps.insert(index + 1, item);
                  });
                },
              ),
            ListTile(
              leading: const Icon(CupertinoIcons.trash, color: Colors.redAccent),
              title: const Text('Eliminar paso', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _steps.removeAt(index));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickQuantityDialog(String ingredientName) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cantidad para $ingredientName'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Ej: 200g, 1 un, al gusto...'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Añadir')),
        ],
      ),
    );
  }

  void _showAddStepDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir paso'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Describe el paso...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
               _addStep(controller.text);
               Navigator.pop(context);
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }
  
  void _showAddCustomIngredientDialog() {
      final nameCtrl = TextEditingController();
      final qtyCtrl = TextEditingController();
      IngredientCategory? selectedCat;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Ingrediente nuevo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                const SizedBox(height: 12),
                TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Cantidad (ej: 100g)')),
                 const SizedBox(height: 12),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16),
                   decoration: BoxDecoration(
                     color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                   ),
                   child: DropdownButtonHideUnderline(
                     child: DropdownButton<IngredientCategory>(
                       isExpanded: true,
                       value: selectedCat,
                       hint: Text('Categoría (Opcional)', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                       items: IngredientCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.displayName))).toList(),
                       onChanged: (v) => setState(() => selectedCat = v),
                       icon: const Icon(CupertinoIcons.chevron_down, size: 16),
                       borderRadius: BorderRadius.circular(12),
                       dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                     ),
                   ),
                 ),
              ],
            ),
            actions: [
               TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
               FilledButton(
                 onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isNotEmpty) {
                       if (selectedCat != null) RecipeManager.addCustomMapping(name, selectedCat!);
                       _addIngredient(DetailedIngredient(name: name, quantity: qtyCtrl.text.trim()));
                       Navigator.pop(context);
                    }
                 }, 
                 child: const Text('Añadir')
               ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7), // OLED Black for Dark Mode
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar & Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Close Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(CupertinoIcons.xmark),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  // Center Content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.recipeToEdit != null ? 'EDITAR RECETA' : 'NUEVA RECETA',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_totalSteps, (index) {
                          final isActive = index <= _currentStep;
                          return Container(
                            width: 32,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: isActive ? theme.colorScheme.primary : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe, enforce buttons
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                   _buildStep1Overview(theme),
                   _buildStep2Ingredients(theme),
                   _buildStep3Instructions(theme),
                   _buildStep4Details(theme),
                ],
              ),
            ),
            
            // Bottom Action Bar (Back / Next)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: _prevStep,
                        style: FilledButton.styleFrom(
                           padding: const EdgeInsets.symmetric(vertical: 16),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                              Icon(CupertinoIcons.chevron_left, size: 18),
                              SizedBox(width: 8),
                              Text('Atrás'),
                           ],
                        ),
                      ),
                    ),
                  if (_currentStep > 0)
                     const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _currentStep == _totalSteps - 1 ? _saveRecipe : _nextStep,
                      style: FilledButton.styleFrom(
                           padding: const EdgeInsets.symmetric(vertical: 16),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                         backgroundColor: theme.colorScheme.primary,
                         foregroundColor: Colors.black, // High contrast
                      ),
                      child: Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                            Text(
                              _currentStep == _totalSteps - 1 ? (widget.recipeToEdit != null ? 'Guardar Cambios' : 'Finalizar Receta') : 'Siguiente',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                             if (_currentStep < _totalSteps - 1) ...[
                                const SizedBox(width: 8),
                                const Icon(CupertinoIcons.chevron_right, size: 18),
                             ],
                         ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 1: Basics ---
  Widget _buildStep1Overview(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
           GestureDetector(
             onTap: _pickImage,
             child: Container(
               height: 280,
               width: double.infinity,
               decoration: BoxDecoration(
                 color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                 borderRadius: BorderRadius.circular(24),
                 border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
                 image: _selectedImagePath != null 
                    ? DecorationImage(image: FileImage(File(_selectedImagePath!)), fit: BoxFit.cover)
                    : null,
               ),
               child: _selectedImagePath == null 
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Icon(CupertinoIcons.camera, size: 48, color: theme.colorScheme.primary),
                         const SizedBox(height: 12),
                         Text('Añadir foto', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : null,
             ),
           ),
           const SizedBox(height: 32),
           
           _buildInputSection(
             theme,
             title: 'NOMBRE',
             children: [
               TextField(
                 controller: _titleController,
                 style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                 decoration: const InputDecoration(
                    hintText: 'Nombre de la receta',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                 ),
               ),
             ],
           ),

           _buildInputSection(
             theme,
             title: 'TIEMPO ESTIMADO',
             children: [
               TextField(
                 controller: _prepTimeController,
                 decoration: const InputDecoration(
                    hintText: 'Ej: 30 min',
                    prefixIcon: Icon(CupertinoIcons.clock, size: 20),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                 ),
               ),
             ],
           ),

           _buildInputSection(
              theme,
              title: 'NUTRICIÓN (OPCIONAL)',
              children: [
                 Theme(
                   data: theme.copyWith(
                     splashColor: Colors.transparent,
                     highlightColor: Colors.transparent,
                     hoverColor: Colors.transparent,
                     dividerColor: Colors.transparent, // Ensure no dividers show up unexpectedly
                   ),
                   child: ExpansionTile(
                      title: const Text('Información Nutricional'),
                      leading: const Icon(Icons.analytics_outlined),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.all(16),
                      children: [
                         Row(
                           children: [
                              Expanded(child: _buildCompactNutriInput(theme, _caloriesController, 'Calorías (kcal)')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildCompactNutriInput(theme, _proteinController, 'Proteína (g)')),
                           ],
                         ),
                         const SizedBox(height: 8),
                         Row(
                           children: [
                              Expanded(child: _buildCompactNutriInput(theme, _carbsController, 'Carbohidratos (g)')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildCompactNutriInput(theme, _fatController, 'Grasas (g)')),
                           ],
                         ),
                      ],
                   ),
                 ),
              ],
           ),
        ],
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme, {String? title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8, top: 4),
            child: Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Material(
            color: theme.brightness == Brightness.dark 
                ? Colors.white.withOpacity(0.05) 
                : Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.brightness == Brightness.dark 
                    ? Colors.white.withOpacity(0.1) 
                    : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactNutriInput(ThemeData theme, TextEditingController controller, String label) {
     return TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
           labelText: label,
           isDense: true,
           filled: true,
           fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
     );
  }

  // --- Step 2: Ingredients ---
  Widget _buildStep2Ingredients(ThemeData theme) {
      final allIngredients = RecipeManager.allIngredients;
      final filteredList = _ingredientQuery.isEmpty 
          ? <String>[] 
          : _sortIngredients(allIngredients, _ingredientQuery)
               .where((i) => !_detailedIngredients.any((d) => d.name == i))
               .take(6).toList();

      return Column(
        children: [
           Padding(
             padding: const EdgeInsets.all(24),
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('INGREDIENTES', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                   const SizedBox(height: 12),
                   Row(
                      children: [
                        Expanded(
                          child: TextField(
                             controller: _ingredientController,
                             onChanged: (val) => setState(() => _ingredientQuery = val),
                             textAlignVertical: TextAlignVertical.center,
                             decoration: InputDecoration(
                                hintText: 'Buscar ingredientes...',
                                prefixIcon: const Icon(CupertinoIcons.search),
                                suffixIcon: _ingredientQuery.isNotEmpty
                                   ? IconButton(
                                       icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 20),
                                       onPressed: () {
                                         _ingredientController.clear();
                                         setState(() => _ingredientQuery = '');
                                       },
                                     )
                                   : null,
                             ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                             icon: const Icon(CupertinoIcons.add),
                             onPressed: _showAddCustomIngredientDialog,
                             tooltip: 'Crear nuevo',
                          ),
                        ),
                      ],
                   ),
                   // Search Results
                   if (filteredList.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                         constraints: const BoxConstraints(maxHeight: 180),
                         decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                         ),
                         child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: filteredList.length,
                            separatorBuilder: (_,__) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                               final ing = filteredList[index];
                               return ListTile(
                                  title: Text(ing),
                                  leading: const Icon(CupertinoIcons.add, size: 16),
                                  visualDensity: VisualDensity.compact,
                                  onTap: () async {
                                     final qty = await _pickQuantityDialog(ing);
                                     if (qty != null) {
                                        _addIngredient(DetailedIngredient(name: ing, quantity: qty));
                                     }
                                  },
                               );
                            },
                         ),
                      ),
                   ],
                ],
             ),
           ),
           Expanded(
              child: _detailedIngredients.isEmpty 
                 ? Center(child: Text('Añade los ingredientes necesarios', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)))
                 : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _detailedIngredients.length,
                    itemBuilder: (context, index) {
                       final item = _detailedIngredients[index];
                       return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                             color: theme.colorScheme.surface.withOpacity(0.5),
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
                          ),
                          child: ListTile(
                             title: Row(
                               children: [
                                 Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                 const SizedBox(width: 8),
                                 Text(item.quantity, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
                               ],
                             ),
                             trailing: IconButton(
                                icon: const Icon(CupertinoIcons.trash, size: 18, color: Colors.grey),
                                onPressed: () => _removeIngredient(item),
                             ),
                          ),
                       );
                    },
                   ),
           ),
        ],
      );
  }

  // --- Step 3: Instructions ---
  Widget _buildStep3Instructions(ThemeData theme) {
     return Column(
       children: [
          Padding(
             padding: const EdgeInsets.all(24),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                  Text('PASOS A SEGUIR', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  Row(
                     children: [
                       FilledButton(
                         onPressed: () => setState(() => _isReorderingSteps = !_isReorderingSteps),
                         style: FilledButton.styleFrom(
                           visualDensity: VisualDensity.compact,
                           backgroundColor: _isReorderingSteps ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                           foregroundColor: _isReorderingSteps ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                           minimumSize: const Size(48, 36), // Ensure min height matches standard compact button
                           padding: const EdgeInsets.symmetric(horizontal: 12), // Restore some padding
                         ),
                         child: const Icon(Icons.drag_handle, size: 20),
                       ),
                       const SizedBox(width: 8),
                       FilledButton.icon(
                          onPressed: _showAddStepDialog,
                          icon: const Icon(CupertinoIcons.add),
                          label: const Text('Añadir paso'),
                          style: FilledButton.styleFrom(
                             visualDensity: VisualDensity.compact,
                             backgroundColor: theme.colorScheme.surfaceContainerHighest,
                             foregroundColor: theme.colorScheme.onSurface,
                          ),
                       ),
                     ],
                   ),
               ],
             ),
          ),
          Expanded(
             child: _steps.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Icon(CupertinoIcons.list_bullet, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                         const SizedBox(height: 16),
                         Text('¿Cómo se prepara?', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  )
                : _isReorderingSteps 
                    ? ReorderableListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        onReorder: (oldIndex, newIndex) {
                           setState(() {
                              if (oldIndex < newIndex) newIndex -= 1;
                              final item = _steps.removeAt(oldIndex);
                              _steps.insert(newIndex, item);
                           });
                        },
                        children: [
                           for (int index = 0; index < _steps.length; index++)
                              Container(
                                 key: ValueKey('step_${_steps[index]}_$index'),
                                 margin: const EdgeInsets.only(bottom: 12),
                                 decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
                                 ),
                                 child: ListTile(
                                    leading: const Icon(Icons.drag_indicator, color: Colors.grey),
                                    title: Text(_steps[index]),
                                    trailing: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                 ),
                              )
                        ],
                    )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _steps.length,
                        itemBuilder: (context, index) {
                           return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: theme.colorScheme.surface,
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.05)),
                                ),
                                child: ListTile(
                                   leading: Container(
                                      width: 28, height: 28,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                         color: theme.colorScheme.primary.withOpacity(0.2),
                                         shape: BoxShape.circle,
                                      ),
                                      child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                   ),
                                   title: Text(_steps[index]),
                                   onTap: () => _showStepOptions(context, index),
                                ),
                              ),
                           );
                        },
                    ),
          ),
       ],
     );
  }

  // --- Step 4: Tags & Finish ---
  Widget _buildStep4Details(ThemeData theme) {
      return SingleChildScrollView(
         padding: const EdgeInsets.all(24),
         child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               _buildTagSection(
                  theme: theme, 
                  title: 'CATEGORÍA', 
                  items: RecipeCategory.values, 
                  isSelected: (c) => _selectedCategories.contains(c), 
                  onToggle: (c) {
                     setState(() {
                        if (_selectedCategories.contains(c)) {
                           _selectedCategories.remove(c);
                        } else {
                           _selectedCategories.add(c);
                        }
                     });
                  },
                  getLabel: (c) => c.displayName,
               ),
               const SizedBox(height: 32),
               Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Text('DIETA', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                           TextButton.icon(
                              onPressed: _showAddCustomTagDialog,
                              icon: const Icon(CupertinoIcons.add, size: 16),
                              label: const Text('Añadir etiqueta'),
                              style: TextButton.styleFrom(
                                 visualDensity: VisualDensity.compact,
                                 textStyle: const TextStyle(fontSize: 12),
                              ),
                           ),
                        ],
                     ),
                     const SizedBox(height: 12),
                     Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                           ...DietaryRestriction.values.map((r) {
                              final active = _selectedDietaryRestrictions.contains(r);
                              return FilterChip(
                                 label: Text(r.displayName),
                                 selected: active,
                                 onSelected: (_) => setState(() {
                                    if (active) _selectedDietaryRestrictions.remove(r);
                                    else _selectedDietaryRestrictions.add(r);
                                 }),
                                 backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                 selectedColor: theme.colorScheme.primary.withOpacity(0.3),
                                 checkmarkColor: theme.colorScheme.primary,
                                 side: BorderSide(
                                    color: active ? theme.colorScheme.primary : Colors.transparent,
                                 ),
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              );
                           }),
                           ..._selectedCustomTags.map((tag) {
                              return FilterChip(
                                 label: Text(tag),
                                 selected: true,
                                 onSelected: (_) => setState(() => _selectedCustomTags.remove(tag)),
                                 backgroundColor: theme.colorScheme.primary.withOpacity(0.3),
                                 selectedColor: theme.colorScheme.primary.withOpacity(0.3),
                                 checkmarkColor: theme.colorScheme.primary,
                                 side: BorderSide(color: theme.colorScheme.primary),
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              );
                           }),
                        ],
                     ),
                  ],
               ),
            ],
         ),
      );
  }

  Widget _buildTagSection<T>({
    required ThemeData theme, 
    required String title, 
    required List<T> items, 
    required bool Function(T) isSelected, 
    required Function(T) onToggle,
    required String Function(T) getLabel,
  }) {
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(title, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
           const SizedBox(height: 12),
           Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                 final active = isSelected(item);
                 return FilterChip(
                    label: Text(getLabel(item)),
                    selected: active,
                    onSelected: (_) => onToggle(item),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    selectedColor: theme.colorScheme.primary.withOpacity(0.3),
                    checkmarkColor: theme.colorScheme.primary,
                    side: BorderSide(
                       color: active ? theme.colorScheme.primary : Colors.transparent,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                 );
              }).toList(),
           ),
        ],
     );
  }
  void _showAddCustomTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir etiqueta'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Ej: Keto, Low Carb...'),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final tag = controller.text.trim();
              if (tag.isNotEmpty) {
                setState(() {
                  _selectedCustomTags.add(tag);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }
}

class _AddIngredientDialog extends StatefulWidget {
  const _AddIngredientDialog({required this.onAdd});

  final void Function(String, String, IngredientCategory?) onAdd;

  @override
  State<_AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<_AddIngredientDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  IngredientCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _quantityController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir ingrediente'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Nombre del ingrediente',
              labelText: 'Ingrediente',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantityController,
            decoration: const InputDecoration(
              hintText: 'Ej: 200g',
              labelText: 'Cantidad',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<IngredientCategory>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            isExpanded: true,
            items: IngredientCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Row(
                  children: [
                    Icon(category.icon, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              widget.onAdd(
                _nameController.text.trim(), 
                _quantityController.text.trim(),
                _selectedCategory,
              );
              Navigator.of(context).pop();
            }
          },
          child: const Text('Añadir'),
        ),
      ],
    );
  }
}

class _AddStepDialog extends StatefulWidget {
  const _AddStepDialog({required this.onAdd});

  final void Function(String) onAdd;

  @override
  State<_AddStepDialog> createState() => _AddStepDialogState();
}

class _AddStepDialogState extends State<_AddStepDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir paso'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Describe el paso de la receta',
          labelText: 'Paso',
        ),
        autofocus: true,
        maxLines: 3,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            widget.onAdd(value.trim());
            Navigator.of(context).pop();
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              widget.onAdd(_controller.text.trim());
              Navigator.of(context).pop();
            }
          },
          child: const Text('Añadir'),
        ),
      ],
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.onTap,
    this.onLongPress,
  });

  final FavoriteFolder folder;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipeCount = folder.recipeTitles.length;
    final subFolderCount = RecipeManager.getSubFolders(folder.id).length;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                ),
                child: Icon(
                  folder.icon,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$recipeCount receta${recipeCount != 1 ? 's' : ''} • $subFolderCount subcarpeta${subFolderCount != 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateFolderDialog extends StatefulWidget {
  const _CreateFolderDialog({this.parentId, this.folderToEdit});

  final String? parentId;
  final FavoriteFolder? folderToEdit;

  @override
  State<_CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<_CreateFolderDialog> {
  late final TextEditingController _nameController;
  IconData _selectedIcon = CupertinoIcons.folder;
  
  final List<IconData> _availableIcons = RecipeManager.availableFolderIcons;

  @override
  void initState() {
    super.initState();
    if (widget.folderToEdit != null) {
      _nameController = TextEditingController(text: widget.folderToEdit!.name);
      _selectedIcon = widget.folderToEdit!.icon;
    } else {
      _nameController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveFolder() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un nombre para la carpeta')),
      );
      return;
    }

    if (widget.folderToEdit != null) {
      // Update existing folder
      final updatedFolder = widget.folderToEdit!.copyWith(
        name: _nameController.text.trim(),
        icon: _selectedIcon,
      );
      await RecipeManager.updateFolder(updatedFolder);
    } else {
      // Create new folder
      final newFolder = FavoriteFolder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        parentId: widget.parentId,
      );
      await RecipeManager.addFolder(newFolder);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.folderToEdit != null ? 'Editar carpeta' : 'Crear carpeta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la carpeta',
                hintText: 'Ej: Postres',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 20),
            Text('Seleccionar icono', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableIcons.map((icon) {
                final isSelected = icon == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.3)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.white.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.white70,
                      size: 24,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saveFolder,
          child: Text(widget.folderToEdit != null ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}

class _FolderOptionsSheet extends StatelessWidget {
  const _FolderOptionsSheet({required this.folder});

  final FavoriteFolder folder;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(CupertinoIcons.pencil),
            title: const Text('Editar carpeta'),
            onTap: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => _CreateFolderDialog(folderToEdit: folder),
              );
            },
          ),
          ListTile(
            leading: const Icon(CupertinoIcons.delete, color: Colors.red),
            title: const Text('Eliminar carpeta', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pop();
              _showDeleteConfirmation(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar carpeta'),
        content: Text('¿Estás seguro de que quieres eliminar "${folder.name}"? Esto también eliminará todas las subcarpetas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              await RecipeManager.deleteFolder(folder.id);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _RecipeFolderMenu extends StatelessWidget {
  const _RecipeFolderMenu({required this.recipe});

  final Recipe recipe;

  Future<void> _moveToFolder(BuildContext context, String? folderId) async {
    // Remove from all folders first
    for (final folder in RecipeManager.allFolders) {
      if (folder.recipeTitles.contains(recipe.title)) {
        await RecipeManager.removeRecipeFromFolder(folder.id, recipe);
      }
    }
    
    // Add to selected folder if not null
    if (folderId != null) {
      await RecipeManager.addRecipeToFolder(folderId, recipe);
    }
    
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(folderId == null
              ? 'Receta movida fuera de carpetas'
              : 'Receta movida a carpeta'),
        ),
      );
    }
  }

  List<FavoriteFolder> _getAllFoldersFlat(List<FavoriteFolder> folders) {
    final result = <FavoriteFolder>[];
    for (final folder in folders) {
      result.add(folder);
      final subFolders = RecipeManager.getSubFolders(folder.id);
      if (subFolders.isNotEmpty) {
        result.addAll(_getAllFoldersFlat(subFolders));
      }
    }
    return result;
  }

  String? _getCurrentFolderId() {
    for (final folder in RecipeManager.allFolders) {
      if (folder.recipeTitles.contains(recipe.title)) {
        return folder.id;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allFolders = _getAllFoldersFlat(RecipeManager.rootFolders);
    final currentFolderId = _getCurrentFolderId();
    
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Mover a carpeta',
              style: theme.textTheme.titleLarge,
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(CupertinoIcons.folder),
                  title: const Text('Sin carpeta'),
                  trailing: currentFolderId == null
                      ? const Icon(CupertinoIcons.checkmark, color: Colors.green)
                      : null,
                  onTap: () => _moveToFolder(context, null),
                ),
                const Divider(),
                ...allFolders.map((folder) {
                  final isSelected = currentFolderId == folder.id;
                  return ListTile(
                    leading: Icon(folder.icon),
                    title: Text(folder.name),
                    trailing: isSelected
                        ? const Icon(CupertinoIcons.checkmark, color: Colors.green)
                        : null,
                    onTap: () => _moveToFolder(context, folder.id),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecipesByCategoryPage extends StatefulWidget {
  const RecipesByCategoryPage({super.key, required this.category});

  final RecipeCategory category;

  @override
  State<RecipesByCategoryPage> createState() => _RecipesByCategoryPageState();
}

class _RecipesByCategoryPageState extends State<RecipesByCategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = RecipeManager.recipes.where((r) => r.categories.contains(widget.category)).toList();
    final searchFiltered = filtered.where((recipe) {
      if (_searchQuery.isEmpty) return true;
      return recipe.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.displayName),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
              decoration: InputDecoration(
                hintText: 'Buscar recetas en ${widget.category.displayName}...',
                prefixIcon: const Icon(CupertinoIcons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.xmark_circle_fill),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : IconButton(
                        icon: const Icon(CupertinoIcons.shuffle),
                        tooltip: 'Receta aleatoria',
                        onPressed: () {
                          if (searchFiltered.isNotEmpty) {
                            final random = Random();
                            final recipe = searchFiltered[random.nextInt(searchFiltered.length)];
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RecipeDetailPage(recipe: recipe),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No hay recetas disponibles')),
                            );
                          }
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: searchFiltered.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty 
                              ? 'No hay recetas en esta categoría'
                              : 'No se encontraron recetas con "$_searchQuery"',
                        ),
                      )
                    : ListView.builder(
                        itemCount: searchFiltered.length,
                        itemBuilder: (context, index) {
                          final r = searchFiltered[index];
                          return _RecipeCard(recipe: r, matchCount: 0);
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeCategory {
  const _RecipeCategory({required this.name, required this.icon, required this.matches});

  final String name;
  final IconData icon;
  final bool Function(Recipe) matches;
}

class IngredientSearchPage extends StatefulWidget {
  const IngredientSearchPage({super.key});

  @override
  State<IngredientSearchPage> createState() => _IngredientSearchPageState();
}

class _IngredientSearchPageState extends State<IngredientSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<String> get _allIngredients => _getAllCategoryIngredients();
  
  List<String> _getAllCategoryIngredients() {
    final allIngredientsFromRecipes = RecipeManager.allIngredients;
    final allCategoryIngredients = <String>{};
    
    // Get ingredients from all categories
    for (final category in IngredientCategory.values) {
      final categoryIngredients = _getIngredientsForCategory(category, allIngredientsFromRecipes);
      allCategoryIngredients.addAll(categoryIngredients);
    }
    
    return allCategoryIngredients.toList()..sort();
  }
  final Set<String> _selected = <String>{};
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _add(String ingredient) {
    setState(() {
      _selected.add(ingredient.toLowerCase());
      _query = '';
      _controller.clear();
    });
    _focusNode.requestFocus();
  }

  void _remove(String ingredient) {
    setState(() {
      _selected.remove(ingredient);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Use the smart sort logic
    final filtered = _sortIngredients(_allIngredients, _query)
        .where((i) => !_selected.contains(i))
        .take(12)
        .toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  onSubmitted: (v) {
                    final exact = _allIngredients.firstWhere(
                      (i) => i.toLowerCase() == v.trim().toLowerCase(),
                      orElse: () => '',
                    );
                    if (exact.isNotEmpty) _add(exact);
                  },
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Búsqueda por ingredientes...',
                    prefixIcon: const Icon(CupertinoIcons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(CupertinoIcons.xmark_circle_fill),
                            onPressed: () {
                              setState(() {
                                _query = '';
                                _controller.clear();
                              });
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_selected.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Seleccionados', style: theme.textTheme.titleMedium),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _selected.clear()),
                            child: const Text('Borrar todo'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () => _openResults(context),
                            icon: const Icon(CupertinoIcons.search, size: 18),
                            label: const Text('Buscar'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selected
                        .map((i) => InputChip(
                              label: Text(i),
                              selected: true,
                              onDeleted: () => _remove(i),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_query.isNotEmpty) ...[
                  Text('Sugerencias', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: _allIngredients.isEmpty
                ? const _EmptyStateWidget(
                    icon: CupertinoIcons.search,
                    title: 'No hay ingredientes',
                    subtitle: 'Añade recetas para explorar sus ingredientes',
                  )
                : _query.isEmpty
                ? _PopularIngredientsGrid(
                    all: _allIngredients,
                    onPick: _add,
                    isSelected: (i) => _selected.contains(i),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        leading: const Icon(CupertinoIcons.plus_circled),
                        title: Text(item),
                        onTap: () => _add(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );

  }

  void _openResults(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeResultsPage(
          selectedIngredients: _selected.toList(),
        ),
      ),
    );
  }
}

class _PopularIngredientsGrid extends StatelessWidget {
  const _PopularIngredientsGrid({
    required this.all,
    required this.onPick,
    required this.isSelected,
  });

  final List<String> all;
  final void Function(String) onPick;
  final bool Function(String) isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allIngredients = RecipeManager.allIngredients;
    final categoriesWithIngredients = IngredientCategory.values
        .map((category) {
          final categoryIngredients = _getIngredientsForCategory(category, allIngredients);
        final availableIngredients = categoryIngredients
              .where((ingredient) => !isSelected(ingredient.toLowerCase()))
            .toList();
          return MapEntry(category, availableIngredients);
        })
        .where((entry) => entry.value.isNotEmpty)
        .toList();
    
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: categoriesWithIngredients.length,
      itemBuilder: (context, index) {
        final entry = categoriesWithIngredients[index];
        final category = entry.key;
        
        return Container(
                    decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.09),
                Colors.white.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
                      border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => IngredientsByCategoryPage(
                    category: category,
                    onPick: onPick,
                    isSelected: isSelected,
                  ),
                ),
              );
            },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category.icon,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      category.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class IngredientsByCategoryPage extends StatelessWidget {
  const IngredientsByCategoryPage({
    super.key,
    required this.category,
    required this.onPick,
    required this.isSelected,
  });

  final IngredientCategory category;
  final void Function(String) onPick;
  final bool Function(String) isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allIngredients = RecipeManager.allIngredients;
    final categoryIngredients = _getIngredientsForCategory(category, allIngredients);
    final availableIngredients = categoryIngredients
        .where((ingredient) => !isSelected(ingredient.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(category.displayName),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: availableIngredients.isEmpty
              ? const Center(child: Text('No hay ingredientes disponibles en esta categoría'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.start,
                      children: availableIngredients.map((text) {
                        return Material(
                          color: const Color(0xFF16161C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              onPick(text);
                              Navigator.of(context).pop();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Text(
                                text,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class RecipeResultsPage extends StatefulWidget {
  const RecipeResultsPage({super.key, required this.selectedIngredients});

  final List<String> selectedIngredients;

  @override
  State<RecipeResultsPage> createState() => _RecipeResultsPageState();
}

class _RecipeResultsPageState extends State<RecipeResultsPage> {
  final Set<DietaryRestriction> _selectedFilters = {};
  final Set<String> _selectedCustomFilters = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalIngredients = widget.selectedIngredients.length;
    final List<_ScoredRecipe> results = RecipeManager.recipes
        .map((r) {
          final matches = widget.selectedIngredients
              .where((needle) => r.ingredients.contains(needle.toLowerCase()))
              .length;
          // Get the actual recipe ingredients that matched (to highlight them correctly)
          final matchedRecipeIngredients = r.ingredients
              .where((ingredient) => widget.selectedIngredients.contains(ingredient.toLowerCase()))
              .toList();
          final remainingIngredients = r.ingredients.length - matches;
          return _ScoredRecipe(
            recipe: r, 
            matchCount: matches,
            remainingIngredients: remainingIngredients,
            matchedIngredients: matchedRecipeIngredients,
          );
        })
        .where((sr) => sr.matchCount > 0)
        .where((sr) => _applyDietaryFilters(sr.recipe))
        .toList()
      ..sort((a, b) {
        // Primero ordenar por matchCount (mayor a menor)
        final matchComparison = b.matchCount.compareTo(a.matchCount);
        if (matchComparison != 0) return matchComparison;
        // Si hay empate, ordenar por ingredientes sobrantes (mayor a menor)
        return b.remainingIngredients.compareTo(a.remainingIngredients);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: results.isEmpty
              ? _EmptyState(selectedIngredients: widget.selectedIngredients)
              : ListView(
                  children: [
                    if (_selectedFilters.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          const SizedBox.shrink(),
                          TextButton.icon(
                            onPressed: () => setState(() {
                               _selectedFilters.clear();
                               _selectedCustomFilters.clear();
                            }),
                            icon: const Icon(CupertinoIcons.xmark_circle, size: 16),
                            label: const Text('Limpiar filtros'),
                          ),
                      ],
                    ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ..._selectedFilters
                              .map((filter) => Chip(
                                    label: Text(filter.displayName),
                                    onDeleted: () => setState(() => _selectedFilters.remove(filter)),
                                  )),
                          ..._selectedCustomFilters
                              .map((tag) => Chip(
                                    label: Text(tag),
                                    onDeleted: () => setState(() => _selectedCustomFilters.remove(tag)),
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1), 
                                  )),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    ...results.map(
                      (sr) => _RecipeCard(
                        recipe: sr.recipe,
                        matchCount: sr.matchCount,
                        matchedIngredients: sr.matchedIngredients,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  bool _applyDietaryFilters(Recipe recipe) {
    if (_selectedFilters.isEmpty && _selectedCustomFilters.isEmpty) return true;
    
    final standardMatch = _selectedFilters.isEmpty || 
        _selectedFilters.every((filter) => recipe.dietaryRestrictions.contains(filter));
        
    final customMatch = _selectedCustomFilters.isEmpty || 
        _selectedCustomFilters.every((tag) => recipe.customDietaryTags.contains(tag));
        
    return standardMatch && customMatch;
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _DietaryFilterDialog(
        selectedFilters: _selectedFilters,
        selectedCustomFilters: _selectedCustomFilters,
        onFiltersChanged: (filters, customFilters) {
          setState(() {
            _selectedFilters.clear();
            _selectedFilters.addAll(filters);
            _selectedCustomFilters.clear();
            _selectedCustomFilters.addAll(customFilters);
          });
        },
      ),
    );
  }
}

class _DietaryFilterDialog extends StatefulWidget {
  const _DietaryFilterDialog({
    required this.selectedFilters,
    required this.selectedCustomFilters,
    required this.onFiltersChanged,
  });

  final Set<DietaryRestriction> selectedFilters;
  final Set<String> selectedCustomFilters;
  final void Function(Set<DietaryRestriction>, Set<String>) onFiltersChanged;

  @override
  State<_DietaryFilterDialog> createState() => _DietaryFilterDialogState();
}

class _DietaryFilterDialogState extends State<_DietaryFilterDialog> {
  late Set<DietaryRestriction> _selectedFilters;
  late Set<String> _selectedCustomFilters;

  @override
  void initState() {
    super.initState();
    _selectedFilters = Set.from(widget.selectedFilters);
    _selectedCustomFilters = Set.from(widget.selectedCustomFilters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allCustomTags = RecipeManager.allCustomDietaryTags.toList()..sort();

    return AlertDialog(
      title: const Text('Filtros dietéticos'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Restricciones estándar:',
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DietaryRestriction.values.map((restriction) {
                  final isSelected = _selectedFilters.contains(restriction);
                  return FilterChip(
                    label: Text(restriction.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFilters.add(restriction);
                        } else {
                          _selectedFilters.remove(restriction);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              if (allCustomTags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Etiquetas personalizadas:',
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allCustomTags.map((tag) {
                    final isSelected = _selectedCustomFilters.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCustomFilters.add(tag);
                          } else {
                            _selectedCustomFilters.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            widget.onFiltersChanged(_selectedFilters, _selectedCustomFilters);
            Navigator.of(context).pop();
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.selectedIngredients});

  final List<String> selectedIngredients;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.exclamationmark_circle, size: 42),
          const SizedBox(height: 12),
          const Text(
            'No existen recetas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Se intentó con: ${selectedIngredients.join(', ')}',
            style:
                theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe, 
    required this.matchCount,
    this.matchedIngredients = const [],
    this.showFolderOptions = false,
    this.heroTag,
    this.showRating = false,
  });

  final Recipe recipe;
  final int matchCount;
  final List<String> matchedIngredients;
  final bool showFolderOptions;
  final String? heroTag;
  final bool showRating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPersonalized = !RecipeManager.isDefaultRecipe(recipe);
    
    // Check dietary compatibility using centralized logic
    final isDietaryCompatible = RecipeManager.isRecipeCompatible(recipe);
    
    final customImagePath = RecipeManager.getCustomImage(recipe.title);
    final displayImagePath = customImagePath ?? recipe.imagePath;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecipeDetailPage(
                recipe: recipe,
                heroTag: heroTag,
              ),
            ),
          );
        },
        onLongPress: showFolderOptions && RecipeManager.isFavorite(recipe)
            ? () => _showRecipeFolderMenu(context)
            : isPersonalized
                ? () => _showDeleteDialog(context)
                : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: matchedIngredients.isEmpty ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              _RecipeAvatar(title: recipe.title, imagePath: displayImagePath, heroTag: recipe.title),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: matchedIngredients.isEmpty ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recipe.title, 
                            style: matchedIngredients.isEmpty 
                                ? theme.textTheme.titleMedium 
                                : theme.textTheme.titleLarge,
                          ),
                        ),

                      ],
                    ),
                    if (matchedIngredients.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: recipe.ingredients.map((i) {
                          final isMatch = matchedIngredients.contains(i.toLowerCase());
                          return Chip(
                            label: Text(
                              i,
                              style: TextStyle(
                                fontSize: 12,
                                color: isMatch ? Colors.white : Colors.white.withOpacity(0.6),
                              ),
                            ),
                            backgroundColor: isMatch 
                                ? theme.colorScheme.primary.withOpacity(0.3)
                                : Colors.white.withOpacity(0.05),
                            side: BorderSide(
                              color: isMatch ? theme.colorScheme.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    if (showRating && (recipe.rating ?? 0) > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: _PartialStar(
                                filledPercentage: (recipe.rating! - index).clamp(0.0, 1.0),
                                size: 14,
                              ),
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(
                            recipe.rating!.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
        if (isPersonalized || !isDietaryCompatible)
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isDietaryCompatible)
                  Container(
                    width: 8,
                    height: 8,
                    margin: EdgeInsets.only(left: isPersonalized ? 6 : 0),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                if (isPersonalized)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00CED1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar receta'),
        content: Text('¿Estás seguro de que quieres eliminar "${recipe.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await RecipeManager.removeRecipe(recipe);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Receta "${recipe.title}" eliminada')),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al eliminar la receta')),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showRecipeFolderMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _RecipeFolderMenu(recipe: recipe),
    );
  }
}

class _RecipeAvatar extends StatelessWidget {
  const _RecipeAvatar({required this.title, this.imagePath, this.heroTag});

  final String title;
  final String? imagePath;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.primary.withOpacity(0.2);
    final border = theme.colorScheme.primary.withOpacity(0.35);
    
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: imagePath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: imagePath!.startsWith('assets/')
                  ? (heroTag != null 
                          ? Hero(
                              tag: heroTag ?? title,
                              child: Material(
                                color: Colors.transparent,
                                child: Image.asset(
                                  imagePath!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildFallback(title),
                                ),
                              ),
                            )
                          : Image.asset(
                              imagePath!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildFallback(title),
                            ))
                  : (heroTag != null 
                      ? Hero(
                          tag: heroTag!,
                          child: Material(
                            color: Colors.transparent,
                            child: Image.file(
                              File(imagePath!),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildFallback(title),
                            ),
                          ),
                        )
                      : Image.file(
                          File(imagePath!),
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildFallback(title),
                        )),
            )
          : _buildFallback(title),
    );
  }

  Widget _buildFallback(String title) {
    return Center(
      child: Text(
        title.substring(0, 1).toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }
}

class _NutritionFactCard extends StatelessWidget {
  const _NutritionFactCard({required this.fact});

  final NutritionFact fact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
        return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1D24),
            borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
            children: [
              Text(
            fact.label,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            '${fact.formattedAmount} ${fact.unit}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
    );
  }
}

class RecipeDetailPage extends StatefulWidget {
  const RecipeDetailPage({super.key, required this.recipe, this.heroTag});

  final Recipe recipe;
  final String? heroTag;

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  late PageController _pageController;
  int _selectedIndex = 0;
  bool _isFavorite = false;
  late Recipe _currentRecipe;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentRecipe = widget.recipe;
    _isFavorite = RecipeManager.isFavorite(_currentRecipe);
    RecipeManager.addListener(_onRecipesChanged);
  }
  
  // ... callbacks

  void _onRecipesChanged() {
    setState(() {
      // Find the updated recipe object from the manager to get new rating
      final updatedRecipe = RecipeManager.recipes.cast<Recipe?>().firstWhere(
        (r) => r?.title == _currentRecipe.title,
        orElse: () => null,
      );
      
      if (updatedRecipe != null) {
        _currentRecipe = updatedRecipe;
      }
      
      _isFavorite = RecipeManager.isFavorite(_currentRecipe);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    RecipeManager.removeListener(_onRecipesChanged);
    super.dispose();
  }



  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar receta'),
        content: Text('¿Estás seguro de que quieres eliminar "${_currentRecipe.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                // Remove from favorites first if it's there
                if (RecipeManager.isFavorite(widget.recipe)) {
                  await RecipeManager.toggleFavorite(widget.recipe);
                }
                
                await RecipeManager.removeRecipe(widget.recipe);
                
                if (mounted) {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close page
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Receta "${widget.recipe.title}" eliminada')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al eliminar la receta')),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onSegmentChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _toggleFavorite() async {
    await RecipeManager.toggleFavorite(widget.recipe);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'custom_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      
      await RecipeManager.setCustomImage(widget.recipe.title, localImage.path);
      
      if (mounted) {
        setState(() {}); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen actualizada')),
        );
      }
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valorar receta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Toca una estrella para valorar:'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setDialogState) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StarRating(
                      rating: widget.recipe.rating ?? 0,
                      onRatingChanged: (rating) {
                        RecipeManager.rateRecipe(widget.recipe, rating);
                        setState(() {}); // Update Page UI
                        setDialogState(() {}); // Update Dialog UI
                      },
                      starSize: 36,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (widget.recipe.rating ?? 0).toStringAsFixed(1),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPersonalized = !RecipeManager.isDefaultRecipe(_currentRecipe);
    final customImagePath = RecipeManager.getCustomImage(_currentRecipe.title);
    final displayImagePath = customImagePath ?? _currentRecipe.imagePath;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRecipe.title),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.pencil),
            tooltip: 'Editar receta',
            onPressed: () {
               Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => NewRecipePage(recipeToEdit: _currentRecipe)),
               );
            },
          ),
          if (isPersonalized)
            IconButton(
              icon: const Icon(CupertinoIcons.trash),
              onPressed: _showDeleteDialog,
            ),
          IconButton(
            icon: Icon(
              _isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Column(
          children: [
            Stack(
              children: [
            // Recipe Image
            if (displayImagePath != null)
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 250,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16161C),
                  ),
                  child: displayImagePath.startsWith('assets/')

                      ? Hero(
                          tag: widget.heroTag ?? widget.recipe.title,
                          child: Material(
                            color: Colors.transparent,
                            child: Image.asset(
                              displayImagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                            ),
                          ),
                        )
                      : Hero(
                          tag: widget.heroTag ?? widget.recipe.title,
                          child: Material(
                            color: Colors.transparent,
                            child: Image.file(
                              File(displayImagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                            ),
                          ),
                        ),
                ),
              )
            else
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 250,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16161C),
                  ),
                  child: _buildPlaceholder(),
                ),
              ),
              
            // Floating Prep Time Chip
            if (_currentRecipe.prepTime != null)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.clock, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _currentRecipe.prepTime!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
          


          // Segmented Control
            Padding(
              padding: const EdgeInsets.all(16),
              child: _SlidingSegmentedControl(
                controller: _pageController,
                selectedIndex: _selectedIndex,
                onTap: _onSegmentChanged,
                tabs: const ['Ingredientes', 'Instrucciones', 'Info'],
              ),
            ),
          

          // PageView for sliding content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _IngredientsView(recipe: _currentRecipe),
                _InstructionsView(recipe: _currentRecipe),
                _InfoView(recipe: _currentRecipe),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPlaceholder() {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.photo,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca para añadir foto',
              style: TextStyle(color: Colors.white.withOpacity(0.3)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlidingSegmentedControl extends StatelessWidget {
  const _SlidingSegmentedControl({
    required this.controller,
    required this.selectedIndex,
    required this.onTap,
    required this.tabs,
  });

  final PageController controller;
  final int selectedIndex;
  final Function(int) onTap;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / tabs.length;
          
          return Stack(
            children: [
              // Animated Background Indicator
              AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  // If controller not attached yet (initially), use selectedIndex
                  final double page = controller.hasClients ? (controller.page ?? selectedIndex.toDouble()) : selectedIndex.toDouble();
                  final double left = page * tabWidth;
                  
                  return Positioned(
                    left: left,
                    top: 4,
                    bottom: 4,
                    width: tabWidth,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // Text Labels
              Row(
                children: List.generate(tabs.length, (index) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.translucent, // Ensure tap targets whole area
                      child: Center(
                        child: AnimatedBuilder(
                          animation: controller,
                          builder: (context, child) {
                             final double page = controller.hasClients ? (controller.page ?? selectedIndex.toDouble()) : selectedIndex.toDouble();
                             // Calculate opacity/color based on distance from current page
                             final double distance = (page - index).abs();
                             final bool isSelected = distance < 0.5;
                             
                             return Text(
                              tabs[index],
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IngredientsView extends StatefulWidget {
  const _IngredientsView({required this.recipe});

  final Recipe recipe;

  @override
  State<_IngredientsView> createState() => _IngredientsViewState();
}

class _IngredientsViewState extends State<_IngredientsView> with AutomaticKeepAliveClientMixin {
  final Set<String> _checkedIngredients = {};

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${widget.recipe.ingredients.length} Ingredientes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            if (widget.recipe.detailedIngredients.isNotEmpty)
              ...widget.recipe.detailedIngredients.map((ingredient) {
                final key = ingredient.name;
                final isChecked = _checkedIngredients.contains(key);
                
                return Padding(
                    padding: const EdgeInsets.only(bottom: 8), // Reduced bottom padding slightly as Checkbox has internal padding
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isChecked) {
                            _checkedIngredients.remove(key);
                          } else {
                            _checkedIngredients.add(key);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: 1.1,
                            child: Checkbox(
                              value: isChecked,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _checkedIngredients.add(key);
                                  } else {
                                    _checkedIngredients.remove(key);
                                  }
                                });
                              },
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              activeColor: theme.colorScheme.primary,
                              checkColor: theme.colorScheme.onPrimary,
                              side: BorderSide(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5), width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  decoration: isChecked ? TextDecoration.lineThrough : null,
                                  color: isChecked ? theme.textTheme.bodyLarge?.color?.withOpacity(0.5) : null,
                                ),
                                children: [
                                  TextSpan(
                                      text: ingredient.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (ingredient.quantity.isNotEmpty)
                                    TextSpan(
                                        text: '  ${ingredient.quantity}',
                                        style: TextStyle(
                                            color: theme.textTheme.bodyMedium?.color
                                                ?.withOpacity(isChecked ? 0.3 : 0.7))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
              })
            else
              // Fallback for old simple string list
               ...widget.recipe.ingredients.map((ingredient) {
                final isChecked = _checkedIngredients.contains(ingredient);
                return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                         setState(() {
                          if (isChecked) {
                            _checkedIngredients.remove(ingredient);
                          } else {
                            _checkedIngredients.add(ingredient);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                         crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: 1.1,
                            child: Checkbox(
                              value: isChecked,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _checkedIngredients.add(ingredient);
                                  } else {
                                    _checkedIngredients.remove(ingredient);
                                  }
                                });
                              },
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              activeColor: theme.colorScheme.primary,
                              checkColor: theme.colorScheme.onPrimary,
                               side: BorderSide(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5), width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ingredient,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  decoration: isChecked ? TextDecoration.lineThrough : null,
                                  color: isChecked ? theme.textTheme.bodyLarge?.color?.withOpacity(0.5) : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
               }),
          ],
        ),
      ),
    );
  }
}

class _InstructionsView extends StatelessWidget {
  const _InstructionsView({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...recipe.steps.isNotEmpty
              ? recipe.steps.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final step = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withOpacity(0.5),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$index',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStepText(step, theme),
                            ),
                          ],
                        ),
                      );
                }).toList()
              : [
                    Text(
                      'No hay pasos disponibles para esta receta.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                ],
            
            const SizedBox(height: 32),
            Center(
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  final query = Uri.encodeComponent(recipe.title);
                  final url = Uri.parse('https://www.google.com/search?q=$query');
                  try {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } catch (e) {
                     if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No se pudo abrir el navegador')),
                        );
                     }
                  }
                },
                icon: const Icon(CupertinoIcons.globe),
                label: const Text('Buscar en Internet'),
                style: FilledButton.styleFrom(
                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStepText(String text, ThemeData theme) {
    final colonIndex = text.indexOf(':');
    
    // Bold prefix if it looks like "Paso 1:", "Nota:", etc.
    if (colonIndex > 0 && colonIndex < 20) {
      final prefix = text.substring(0, colonIndex + 1);
      final rest = text.substring(colonIndex + 1);
      
      return Text.rich(
        TextSpan(
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.6, // Increased line height
          ),
          children: [
            TextSpan(
              text: prefix,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: rest),
          ],
        ),
      );
    }

    return Text(
      text,
      style: theme.textTheme.bodyLarge?.copyWith(
        height: 1.6, // Increased line height
      ),
    );
  }
}



class _InfoView extends StatelessWidget {
  const _InfoView({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // Dietary Restrictions
            // Dietary Restrictions
            if (recipe.dietaryRestrictions.isNotEmpty || recipe.customDietaryTags.isNotEmpty) ...[
              Text(
                'Restricciones dietéticas',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...recipe.dietaryRestrictions.map((restriction) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            restriction.displayName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )),
                   ...recipe.customDietaryTags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Nutrition Facts
            if (recipe.nutritionFacts.isNotEmpty) ...[
              Text(
                'Información nutricional',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: recipe.nutritionFacts
                    .map(
                      (fact) => _NutritionFactCard(fact: fact),
                    )
                    .toList(),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Rating Row
            // Rating Row
            _PremiumRatingButton(
              recipe: recipe,
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.photo,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca para añadir foto',
            style: TextStyle(color: Colors.white.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }
}

class DetailedIngredient {
  const DetailedIngredient({
    required this.name,
    required this.quantity,
  });

  final String name;
  final String quantity;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
      };

  factory DetailedIngredient.fromJson(Map<String, dynamic> json) {
    return DetailedIngredient(
      name: json['name'] as String,
      quantity: json['quantity'] as String,
    );
  }
}

class Recipe {
  const Recipe({
    required this.title, 
    required this.ingredients,
    this.dietaryRestrictions = const [],
    this.categories = const [],
    this.imagePath,
    this.steps = const [],
    this.nutritionFacts = const [],
    this.prepTime,
    this.detailedIngredients = const [],
    this.rating,
    this.dateRated,
    this.customDietaryTags = const [],
  });

  final String title;
  final List<String> ingredients;
  final List<DietaryRestriction> dietaryRestrictions;
  final List<String> customDietaryTags;
  final List<RecipeCategory> categories;
  final String? imagePath;
  final List<String> steps;
  final List<NutritionFact> nutritionFacts;
  final String? prepTime;
  final List<DetailedIngredient> detailedIngredients;
  final double? rating;
  final DateTime? dateRated;

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'ingredients': ingredients,
      'dietaryRestrictions': dietaryRestrictions.map((r) => r.name).toList(),
      if (customDietaryTags.isNotEmpty) 'customDietaryTags': customDietaryTags,
      'categories': categories.map((c) => c.name).toList(),
      if (imagePath != null) 'imagePath': imagePath,
      if (steps.isNotEmpty) 'steps': steps,
      if (nutritionFacts.isNotEmpty)
        'nutritionFacts': nutritionFacts.map((fact) => fact.toJson()).toList(),
      if (prepTime != null) 'prepTime': prepTime,
      if (detailedIngredients.isNotEmpty)
        'detailedIngredients': detailedIngredients.map((i) => i.toJson()).toList(),
      if (rating != null) 'rating': rating,
      if (dateRated != null) 'dateRated': dateRated!.toIso8601String(),
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      title: json['title'] as String,
      ingredients: (json['ingredients'] != null)
          ? List<String>.from(json['ingredients'])
          : <String>[],
      dietaryRestrictions: (json['dietaryRestrictions'] != null)
          ? (json['dietaryRestrictions'] as List)
              .map((r) {
                try {
                  return DietaryRestriction.values.firstWhere((e) => e.name == r);
                } catch (e) {
                  return null;
                }
              })
              .whereType<DietaryRestriction>()
              .toList()
          : const [],
      customDietaryTags: (json['customDietaryTags'] != null)
          ? List<String>.from(json['customDietaryTags'])
          : const [],
      categories: _parseCategories(json['categories']),
      imagePath: json['imagePath'] as String?,
      prepTime: json['prepTime'] as String?,
      detailedIngredients: (json['detailedIngredients'] != null)
          ? (json['detailedIngredients'] as List)
              .map((i) => DetailedIngredient.fromJson(i as Map<String, dynamic>))
              .toList()
          : const [],
      steps: (json['steps'] != null)
          ? List<String>.from(json['steps'])
          : const [],
      nutritionFacts: (json['nutritionFacts'] != null)
          ? (json['nutritionFacts'] as List)
              .map((item) => NutritionFact.fromJson(item as Map<String, dynamic>))
              .toList()
          : const [],
      rating: (json['rating'] as num?)?.toDouble(),
      dateRated: json['dateRated'] != null ? DateTime.parse(json['dateRated']) : null,
    );
  }

  static List<RecipeCategory> _parseCategories(dynamic rawCategories) {
    if (rawCategories == null) return [RecipeCategory.otros];
    
    final list = (rawCategories as List)
        .map((c) {
          try {
            final categoryStr = c.toString().toLowerCase().replaceAll(' ', '');
            // First try to match by enum name
            try {
              return RecipeCategory.values.firstWhere((e) => e.name == categoryStr);
            } catch (e) {
              // If not found, try to match by displayName (normalized)
              return RecipeCategory.values.firstWhere((e) => 
                e.displayName.toLowerCase().replaceAll(' ', '') == categoryStr
              );
            }
          } catch (e) {
            return null;
          }
        })
        .whereType<RecipeCategory>()
        .toList();
        
    // CRITICAL: Ensure at least one category exists so it appears in UI
    if (list.isEmpty) {
      return [RecipeCategory.otros];
    }
    
    return list;
  }
}

class NutritionFact {
  const NutritionFact({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final double value;
  final String unit;

  String get formattedAmount {
    final isWhole = value % 1 == 0;
    return value.toStringAsFixed(isWhole ? 0 : 1);
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
        'unit': unit,
      };

  factory NutritionFact.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic raw) {
      if (raw is int) return raw.toDouble();
      if (raw is double) return raw;
      if (raw is String) return double.tryParse(raw) ?? 0;
      return 0;
    }

    return NutritionFact(
      label: json['label'] as String? ?? '',
      value: _toDouble(json['value']),
      unit: json['unit'] as String? ?? 'g',
    );
  }
}

class FavoriteFolder {
  const FavoriteFolder({
    required this.id,
    required this.name,
    required this.icon,
    this.recipeTitles = const [],
    this.subFolders = const [],
    this.parentId,
  });

  final String id;
  final String name;
  final IconData icon;
  final List<String> recipeTitles;
  final List<FavoriteFolder> subFolders;
  final String? parentId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'recipeTitles': recipeTitles,
      'subFolders': subFolders.map((f) => f.toJson()).toList(),
      'parentId': parentId,
    };
  }

  factory FavoriteFolder.fromJson(Map<String, dynamic> json) {
    // Find the matching icon in the available list to avoid dynamic IconData creation
    final int iconCode = json['icon'] as int;
    final IconData icon = RecipeManager.availableFolderIcons.firstWhere(
      (i) => i.codePoint == iconCode,
      orElse: () => CupertinoIcons.folder,
    );

    return FavoriteFolder(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: icon,
      recipeTitles: (json['recipeTitles'] as List?)?.cast<String>() ?? const [],
      subFolders: (json['subFolders'] as List?)
          ?.map((f) => FavoriteFolder.fromJson(f as Map<String, dynamic>))
          .toList() ?? const [],
      parentId: json['parentId'] as String?,
    );
  }

  FavoriteFolder copyWith({
    String? id,
    String? name,
    IconData? icon,
    List<String>? recipeTitles,
    List<FavoriteFolder>? subFolders,
    String? parentId,
  }) {
    return FavoriteFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      recipeTitles: recipeTitles ?? this.recipeTitles,
      subFolders: subFolders ?? this.subFolders,
      parentId: parentId ?? this.parentId,
    );
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

  static IngredientCategory? getCategoryForIngredient(String ingredient) => _customMappings[ingredient.toLowerCase()];
  
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
    final nonOverriddenDefaults = _defaultRecipes.where((r) => !userTitles.contains(r.title));
    
    final allRecipes = [...nonOverriddenDefaults, ..._recipes];

    if (SettingsManager.hideIncompatibleRecipes.value) {
      return allRecipes.where((r) => isRecipeCompatible(r)).toList();
    }
    
    return allRecipes;
  }

  // Check compatibility based on permanent filters
  static bool isRecipeCompatible(Recipe recipe) {
    if (SettingsManager.dietaryDefaults.value.isEmpty && SettingsManager.customDietaryDefaults.value.isEmpty) {
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
    final standardMatch = permanentFilters.isEmpty || 
        permanentFilters.every((filter) => recipe.dietaryRestrictions.contains(filter));

    // Check custom tags
    // Note: custom tags are stored as strings. Standard restrictions check against enum names or values?
    // In _RecipeCard we did: allPermanentFilters.every((restriction) => recipe.dietaryRestrictions.contains(restriction) || !recipe.customDietaryTags.contains(restriction));
    // Wait, the logic in RecipeCard was:
    // final allPermanentFilters = {...permanentFilters, ...customPermanentFilters};
    // allPermanentFilters.every((restriction) => recipe.dietaryRestrictions.contains(restriction) || recipe.customDietaryTags.contains(restriction));
    
    // Let's replicate strict logic:
    // 1. Standard filters must be in recipe.dietaryRestrictions
    // 2. Custom filters must be in recipe.customDietaryTags
    
    final standardCompatible = permanentFilters.isEmpty ||
        permanentFilters.every((f) => recipe.dietaryRestrictions.contains(f));
        
    final customCompatible = customPermanentFilters.isEmpty ||
        customPermanentFilters.every((t) => recipe.customDietaryTags.contains(t));
        
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

    final defaultMatch = _defaultRecipes.where((r) => r.title == recipe.title).firstOrNull;
    if (defaultMatch == null) return false;

    // It matches a default title. Check if content (ingredients/steps) is modified.
    // If content matches, we treat it as "Default" (e.g. just rated).
    // If content differs, we treat it as "Personalized".
    // We compare JSON representation minus rating/date for simplicity, or key fields.
    final bool contentMatches = 
        listEquals(recipe.ingredients, defaultMatch.ingredients) &&
        listEquals(recipe.steps, defaultMatch.steps) &&
        listEquals(recipe.detailedIngredients.map((e)=>e.toJson().toString()).toList(), defaultMatch.detailedIngredients.map((e)=>e.toJson().toString()).toList());
        
    return contentMatches;
  }

  // Load default recipes from JSON asset
  static Future<void> loadDefaultRecipes() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/recipes.json');
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
          _customMappings = decoded.map((k, v) => MapEntry(k, IngredientCategory.values[v as int]));
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
    return recipes.where((recipe) => _favoriteTitles.contains(recipe.title)).toList();
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
    final rated = _recipes.where((r) => r.rating != null && r.rating! > 0).toList();
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
    final result = <FavoriteFolder>[...subFolders]; // Start with direct children
    
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
  static Future<void> removeRecipeFromFolder(String folderId, Recipe recipe) async {
    final folder = getFolderById(folderId);
    if (folder != null && folder.recipeTitles.contains(recipe.title)) {
      final updatedFolder = folder.copyWith(
        recipeTitles: folder.recipeTitles.where((t) => t != recipe.title).toList(),
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
    return _recipes.where((r) => !defaultTitles.contains(r.title)).toList(); // returns only non-default recipes as _recipes stores user added content
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

class _ScoredRecipe {
  const _ScoredRecipe({
    required this.recipe, 
    required this.matchCount,
    required this.remainingIngredients,
    this.matchedIngredients = const [],
  });

  final Recipe recipe;
  final int matchCount;
  final int remainingIngredients;
  final List<String> matchedIngredients;
}

// Helper function to categorize ingredients based on keywords
List<String> _getIngredientsForCategory(IngredientCategory category, List<String> allIngredients) {
  final keywords = <IngredientCategory, List<String>>{
    IngredientCategory.frescosVegetales: [
      'fruta', 'verdura', 'vegetal', 'hortaliza', 'tomate', 'cebolla', 'ajo', 'pimiento',
      'papa', 'patata', 'zanahoria', 'lechuga', 'espinaca', 'brócoli', 'coliflor', 'calabaza',
      'pepino', 'berenjena', 'calabacín', 'puerro', 'apio', 'remolacha', 'rábano',
      'manzana', 'plátano', 'naranja', 'limón', 'fresa', 'uva', 'melón', 'sandía', 'aguacate',
      'champiñón', 'seta', 'hongo', 'espárrago', 'alcachofa', 'endibia', 'rúcula', 'canónigo',
      'perejil', 'cilantro', 'albahaca', 'eneldo', 'menta', 'romero', 'salvia', 'tomillo',
    ],
    IngredientCategory.proteinaAnimal: [
      'pollo', 'ternera', 'cerdo', 'cordero', 'carne', 'res', 'vacuno', 'carnero', 'cabrito',
      'pavo', 'gallina', 'pato', 'conejo', 'liebre', 'venado', 'ciervo', 'jabalí',
      'pescado', 'salmón', 'atún', 'merluza', 'bacalao', 'trucha', 'lubina', 'dorada',
      'lenguado', 'pez', 'sardina', 'anchoa', 'arenque', 'caballa', 'mero', 'pargo',
      'marisco', 'gamba', 'camarón', 'langostino', 'langosta', 'mejillón', 'almeja', 'ostra',
      'vieira', 'calamar', 'pulpo', 'sepia', 'cangrejo', 'centollo', 'nécora', 'percebe',
    ],
    IngredientCategory.lacteosYHuevos: [
      'leche', 'yogur', 'queso', 'mantequilla', 'nata', 'crema', 'requesón', 'cuajada',
      'helado', 'kefir', 'mascarpone', 'provolone', 'gorgonzola', 'roquefort', 'mozzarella',
      'parmesano', 'cheddar', 'ricotta', 'feta', 'manchego', 'gouda', 'emmental', 'brie',
      'huevo',
    ],
    IngredientCategory.granosYPastas: [
      'arroz', 'lenteja', 'garbanzo', 'frijol', 'judía', 'haba', 'guisante', 'arveja', 'soja',
      'pasta', 'espagueti', 'fideos', 'macarrones', 'tallarines', 'canelones', 'lasaña',
      'pan', 'galleta',
    ],
    IngredientCategory.aceitesYGrasas: [
      'aceite', 'oliva', 'girasol', 'manteca', 'margarina', 'grasa',
    ],
    IngredientCategory.condimentosYEspecias: [
      'sal', 'pimienta', 'comino', 'cúrcuma', 'curry', 'paprika', 'pimentón', 'clavo',
      'canela', 'nuez moscada', 'cardamomo', 'jengibre', 'azafrán', 'orégano',
      'tomillo', 'romero', 'laurel', 'estragón', 'hinojo',
      'vinagre', 'mostaza', 'ketchup', 'mayonesa', 'salsa', 'soja', 'worcestershire', 'hoisin',
      'teriyaki', 'tahini', 'miso', 'harissa', 'pesto', 'gochujang',
    ],
    IngredientCategory.reposteriaYHarinas: [
      'harina', 'trigo', 'centeno', 'cebada', 'espelta', 'azúcar', 'miel', 'chocolate', 'cacao',
      'levadura', 'vainilla', 'stevia', 'panela', 'piloncillo', 'melaza', 'sirope',
      'bicarbonato', 'polvo',
    ],
    IngredientCategory.conservasYVarios: [
      'lata', 'atún', 'maíz', 'encurtido', 'aceituna', 'fruto seco', 'nuez', 'almendra',
      'avellana', 'cacahuete', 'pistacho', 'caldo preparado', 'caldo', 'conserva',
    ],
  };

  final categoryKeywords = keywords[category] ?? [];
  return allIngredients.where((ingredient) {
    final lower = ingredient.toLowerCase();
    
    // Check custom mapping first
    final customCat = RecipeManager.getCategoryForIngredient(lower);
    if (customCat != null) {
      return customCat == category;
    }

    return categoryKeywords.any((keyword) => lower.contains(keyword));
  }).toList();
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Ajustes',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          _SettingsSection(
            title: 'GENERAL',
            children: [
              ValueListenableBuilder<int>(
                valueListenable: SettingsManager.startScreenIndex,
                builder: (context, index, child) {
                  return _SettingsTile(
                    title: 'Pantalla predeterminada',
                    subtitle: index == 0 ? 'Buscador' : 'Mis Recetas',
                    trailing: const Icon(CupertinoIcons.chevron_right, size: 20, color: Colors.grey),
                    onTap: () => _showStartScreenDialog(context, index),
                  );
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: SettingsManager.preventSleep,
                builder: (context, prevent, child) {
                  return _SettingsTile(
                    title: 'Mantener pantalla encendida',
                    isSwitch: true,
                    switchValue: prevent,
                    onSwitchChanged: (value) => SettingsManager.setPreventSleep(value),
                    icon: CupertinoIcons.eye,
                  );
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: SettingsManager.showDefaultRecipes,
                builder: (context, showDefaults, child) {
                  return _SettingsTile(
                    title: 'Mostrar Recetas Predeterminadas',
                    isSwitch: true,
                    switchValue: showDefaults,
                    onSwitchChanged: (value) => SettingsManager.setShowDefaults(value),
                    icon: CupertinoIcons.book_fill,
                  );
                },
              ),
              _SettingsTile(
                title: 'Filtros dietéticos permanentes',
                subtitle: 'Excluir siempre recetas incompatibles',
                icon: Icons.no_food,
                trailing: const Icon(CupertinoIcons.chevron_right, size: 20, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const _DietarySettingsPage()),
                  );
                },
                lastItem: true,
              ),
            ],
          ),

          _SettingsSection(
            title: 'DATOS',
            children: [
              _SettingsTile(
                title: 'Exportar recetas',
                icon: CupertinoIcons.share,
                onTap: () => SettingsManager.exportRecipes(context),
              ),
              _SettingsTile(
                title: 'Importar recetas',
                icon: CupertinoIcons.arrow_down_doc,
                onTap: () => SettingsManager.importRecipes(context),
              ),
               _SettingsTile(
                title: 'Borrar todos los datos',
                icon: CupertinoIcons.delete,
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: () => SettingsManager.clearData(context),
                lastItem: true,
              ),
            ],
          ),
          
          _SettingsSection(
            title: 'INFORMACIÓN',
            children: [
               _SettingsTile(
                title: 'Legal',
                subtitle: 'Política de Privacidad y Términos',
                icon: CupertinoIcons.doc_text,
                trailing: const Icon(CupertinoIcons.chevron_right, size: 20, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const _LegalPage()),
                  );
                },
                lastItem: true,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showStartScreenDialog(BuildContext context, int currentIndex) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark 
              ? const Color(0xFF1C1C1E) // iOS Dark Gray
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Elegir pantalla predeterminada',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _SelectionOption(
                      title: 'Buscador',
                      icon: CupertinoIcons.search,
                      isSelected: currentIndex == 0,
                      onTap: () {
                         SettingsManager.setStartScreenIndex(0);
                         Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 12),
                    _SelectionOption(
                      title: 'Mis Recetas',
                      icon: CupertinoIcons.book,
                      isSelected: currentIndex == 1,
                      onTap: () {
                         SettingsManager.setStartScreenIndex(1);
                         Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48), // Bottom spacing
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? activeColor.withOpacity(0.15) 
              : theme.brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? activeColor.withOpacity(0.5)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.black : theme.iconTheme.color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: activeColor, size: 24),
          ],
        ),
      ),
    );
  }
}
class _SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _SettingsSection({
    this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
            child: Text(
              title!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark 
                ? Colors.white.withOpacity(0.05) 
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: theme.brightness == Brightness.light ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? textColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSwitch;
  final bool switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final bool lastItem;

  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.textColor,
    this.trailing,
    this.onTap,
    this.isSwitch = false,
    this.switchValue = false,
    this.onSwitchChanged,
    this.lastItem = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;

    if (isSwitch) {
      return Column(
        children: [
          SwitchListTile(
            title: Text(title, style: TextStyle(color: textColor ?? theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500)),
             subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))) : null,
            value: switchValue,
            onChanged: onSwitchChanged,
            secondary: icon != null ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: effectiveIconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 18),
            ) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            activeColor: theme.colorScheme.primary,
          ),
          if (!lastItem)
            Divider(
              height: 1, 
              indent: 56, 
              color: theme.brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.05) 
                  : Colors.black.withOpacity(0.05)
            ),
        ],
      );
    } else {
      return Column(
        children: [
          ListTile(
            title: Text(title, style: TextStyle(color: textColor ?? theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500)),
            subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))) : null,
            leading: icon != null ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: effectiveIconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 18),
            ) : null,
            trailing: trailing,
            onTap: onTap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          ),
          if (!lastItem)
            Divider(
              height: 1, 
              indent: 56, 
              color: theme.brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.05) 
                  : Colors.black.withOpacity(0.05)
            ),
        ],
      );
    }
  }
}

class _DietarySettingsPage extends StatelessWidget {
  const _DietarySettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Filtros Dietéticos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
             const Padding(
               padding: EdgeInsets.only(bottom: 24),
               child: Text(
                 'Selecciona las restricciones que coincidan con tus preferencias (ej: si eres vegetariano, selecciona "vegetariano"). Añadirá un indicador rojo a las recetas que no cumplen con estas restricciones.',
                 textAlign: TextAlign.center,
                 style: TextStyle(color: Colors.grey),
               ),
             ),
             ValueListenableBuilder<Set<DietaryRestriction>>(
              valueListenable: SettingsManager.dietaryDefaults,
              builder: (context, defaults, child) {
                final restrictions = DietaryRestriction.values.toList();
                
                return _SettingsSection(
                  title: 'RESTRICCIONES',
                  children: List.generate(restrictions.length, (index) {
                    final restriction = restrictions[index];
                    final isSelected = defaults.contains(restriction);
                    return _SettingsTile(
                      title: restriction.displayName,
                      subtitle: restriction.description, // Added description for clarity
                      isSwitch: true,
                      switchValue: isSelected,
                      onSwitchChanged: (_) => SettingsManager.toggleDietaryDefault(restriction),
                      lastItem: index == restrictions.length - 1,
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder<Set<String>>(
              valueListenable: SettingsManager.customDietaryDefaults,
              builder: (context, customDefaults, child) {
                final allCustomTags = RecipeManager.allCustomDietaryTags.toList()..sort();
                if (allCustomTags.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: [
                    _SettingsSection(
                      title: 'ETIQUETAS PERSONALIZADAS',
                      children: List.generate(allCustomTags.length, (index) {
                        final tag = allCustomTags[index];
                        final isSelected = customDefaults.contains(tag);
                        return _SettingsTile(
                          title: tag,
                          isSwitch: true,
                          switchValue: isSelected,
                          onSwitchChanged: (_) => SettingsManager.toggleCustomDietaryDefault(tag),
                          lastItem: index == allCustomTags.length - 1,
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: SettingsManager.applyDietaryToDefaults,
              builder: (context, applyToDefaults, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: SettingsManager.hideIncompatibleRecipes,
                  builder: (context, hideIncompatible, _) {
                    return _SettingsSection(
                      title: 'OPCIONES',
                      children: [
                        _SettingsTile(
                          title: 'Aplicar a recetas predeterminadas',
                          subtitle: 'Mostrar indicador rojo también en recetas incluidas en la app',
                          isSwitch: true,
                          switchValue: applyToDefaults,
                          onSwitchChanged: (value) => SettingsManager.setApplyDietaryToDefaults(value),
                          lastItem: false,
                        ),
                        _SettingsTile(
                          title: 'Ocultar recetas incompatibles',
                          subtitle: 'No mostrar recetas que no cumplan con los filtros',
                          isSwitch: true,
                          switchValue: hideIncompatible,
                          onSwitchChanged: (val) => SettingsManager.setHideIncompatibleRecipes(val),

                          lastItem: true,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


class _StarRating extends StatelessWidget {
  const _StarRating({
    required this.rating,
    required this.onRatingChanged,
    this.starSize = 28,
  });

  final double rating;
  final ValueChanged<double> onRatingChanged;
  final double starSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTapUp: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);
            final double singleStarWidth = starSize; // Roughly the width of one icon
            // However, this approach is tricky with Row.
            // Simplified: Just allow tapping a star to set "X.0". 
            // For precise setting (like 4.1), user usually doesn't tap, they see the result.
            // BUT user ASKED TO RATE IT, which usually implies tapping.
            // If user wants to see 4.1, they likely mean "If I rate it, show exact value".
            // Standard rating widgets snap to 0.5 or 1.0. 
            // Setting a 4.1 manually is hard. 
            // I will implement "precise display" (ShaderMask/ClipRect) and "tap to set int/half".
            
            // Actually, simply tapping the star sets integer rating.
            // To set 4.1 is very hard for user.
            // I will assume they mean "Visual representation" shows exact 4.1 if the data is 4.1.
            onRatingChanged(index + 1.0);
          },
          child: _PartialStar(
            filledPercentage: (rating - index).clamp(0.0, 1.0),
            size: starSize,
          ),
        );
      }),
    );
  }
}

class _PartialStar extends StatelessWidget {
  const _PartialStar({
    required this.filledPercentage,
    required this.size,
  });

  final double filledPercentage;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Icon(
          Icons.star_rounded,
          color: Colors.grey.withOpacity(0.3),
          size: size,
        ),
        if (filledPercentage > 0)
          ClipRect(
            clipper: _StarClipper(filledPercentage),
            child: Icon(
              Icons.star_rounded,
              color: Colors.amber,
              size: size,
            ),
          ),
      ],
    );
  }
}

class _StarClipper extends CustomClipper<Rect> {
  final double percentage;

  _StarClipper(this.percentage);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * percentage, size.height);
  }

  @override
  bool shouldReclip(covariant _StarClipper oldClipper) {
    return oldClipper.percentage != percentage;
  }
}

class RatedRecipesPage extends StatefulWidget {
  const RatedRecipesPage({super.key});

  @override
  State<RatedRecipesPage> createState() => _RatedRecipesPageState();
}

class _RatedRecipesPageState extends State<RatedRecipesPage> {
  String _sortOption = 'recent'; // recent, highest, lowest

  @override
  void initState() {
    super.initState();
    RecipeManager.addListener(_onRecipesChanged);
  }

  @override
  void dispose() {
    RecipeManager.removeListener(_onRecipesChanged);
    super.dispose();
  }

  void _onRecipesChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<Recipe> ratedRecipes = RecipeManager.ratedRecipes;

    // Sort logic
    if (_sortOption == 'highest') {
      ratedRecipes.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    } else if (_sortOption == 'lowest') {
      ratedRecipes.sort((a, b) => (a.rating ?? 0).compareTo(b.rating ?? 0));
    } else {
      // Recent (default)
      ratedRecipes.sort((a, b) {
        if (a.dateRated == null && b.dateRated == null) return 0;
        if (a.dateRated == null) return 1;
        if (b.dateRated == null) return -1;
        return b.dateRated!.compareTo(a.dateRated!);
      });
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ratedRecipes.isEmpty
          ? const _EmptyStateWidget(
              icon: CupertinoIcons.star_slash,
              title: 'Sin valoraciones',
              subtitle: 'Valora recetas para verlas aquí',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                   child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortOption,
                            isDense: true,
                            icon: const Icon(Icons.sort, size: 20),
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface),
                            items: const [
                              DropdownMenuItem(value: 'recent', child: Text('Más recientes')),
                              DropdownMenuItem(value: 'highest', child: Text('Mejor valoradas')),
                              DropdownMenuItem(value: 'lowest', child: Text('Peor valoradas')),
                            ],
                            borderRadius: BorderRadius.circular(16),
                            dropdownColor: theme.colorScheme.surfaceContainerHigh,
                            elevation: 4,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _sortOption = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: ratedRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = ratedRecipes[index];
                      return _RecipeCard(
                          recipe: recipe,
                          matchCount: 0, 
                          heroTag: 'rated_${recipe.title}',
                          showRating: true,
                        );
                    },
                  ),
                ),
              ],
            ),
             

    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalPage extends StatelessWidget {
  const _LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Legal'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Política de Privacidad'),
              Tab(text: 'Términos de Uso'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LegalContent(isPrivacy: true),
            _LegalContent(isPrivacy: false),
          ],
        ),
      ),
    );
  }
}

class _LegalContent extends StatelessWidget {
  const _LegalContent({required this.isPrivacy});

  final bool isPrivacy;

  @override
  Widget build(BuildContext context) {
    final text = isPrivacy 
      ? '''POLÍTICA DE PRIVACIDAD
Última actualización: 10 de enero de 2026

1. Introducción
Esta Política de Privacidad describe cómo Recetas ("nosotros", "nuestro" o "la aplicación"), desarrollada por Daniel Cimbollek Díaz, trata su información.

Estamos comprometidos con la protección de su privacidad. El principio fundamental de "Recetas" es la privacidad desde el diseño: no recopilamos, transmitimos ni almacenamos sus datos personales en servidores externos. La aplicación funciona completamente sin conexión (offline) y todos los datos que usted introduce permanecen localmente en su dispositivo.

2. Recopilación y Uso de Datos
No recopilamos información personal, estadísticas de uso ni datos analíticos.

Datos del Usuario (Recetas y Preferencias): Todas las recetas, ingredientes, configuraciones dietéticas y favoritos creados dentro de la aplicación se almacenan localmente en la memoria interna de su dispositivo (utilizando SharedPreferences y almacenamiento de archivos local). Estos datos nunca se transmiten a nosotros ni a terceros.

Copias de Seguridad Voluntarias: Si decide utilizar la función de "Exportar" o "Copia de seguridad", se generará un archivo JSON. Usted tiene el control total sobre dónde almacenar o con quién compartir este archivo. Nosotros no tenemos acceso a estos archivos.

3. Permisos del Dispositivo
Para proporcionar funcionalidades específicas, la aplicación puede solicitar acceso a ciertos permisos del sistema. Estos permisos se utilizan únicamente para la funcionalidad descrita a continuación:

Cámara y Galería de Fotos: Se utiliza estrictamente para permitirle tomar o seleccionar fotos para adjuntarlas a sus recetas personalizadas. Estas imágenes se guardan localmente en su dispositivo. No visualizamos, procesamos ni subimos sus fotos.

Almacenamiento (Archivos/Medios): Se utiliza para guardar copias de seguridad de recetas (archivos JSON) y para leer archivos que usted seleccione explícitamente para importar recetas.

4. Servicios de Terceros
Esta aplicación no contiene publicidad de terceros (por ejemplo, AdMob), analíticas (por ejemplo, Google Analytics) ni SDKs de rastreo. No requiere conexión a Internet para funcionar.

5. Privacidad del Menor
Nuestra aplicación es segura para el público general, incluidos los niños. No recopilamos a sabiendas información de identificación personal de niños menores de 13 años (ni de ninguna edad), ya que no recopilamos datos en absoluto.

6. Sus Derechos (RGPD / LOPD)
Dado que no almacenamos sus datos en nuestros servidores, no podemos "eliminar" o "exportar" los datos de su cuenta por usted, ya que no tenemos acceso a ellos. Usted conserva la propiedad y el control total de sus datos. Puede eliminar sus datos en cualquier momento mediante:

El uso de la opción "Borrar todo" dentro de la configuración de la aplicación.

La desinstalación de la aplicación, lo cual eliminará todos los datos locales.

7. Enlaces a Otros Sitios
Nuestra aplicación puede contener enlaces a sitios externos que no son operados por nosotros (por ejemplo, al utilizar el botón de "Buscar en Internet"). Si hace clic en un enlace de terceros, será dirigido al sitio de ese tercero. Le recomendamos encarecidamente que revise la Política de Privacidad de cada sitio que visite. No tenemos control ni asumimos responsabilidad por el contenido, las políticas de privacidad o las prácticas de sitios o servicios de terceros.

8. Contacto
Si tiene alguna pregunta sobre esta Política de Privacidad, por favor contáctenos en:

Correo electrónico: recetasaplicacion@gmail.com

Desarrollador: Daniel Cimbollek Díaz

--------------------------------------------------

PRIVACY POLICY
Last updated: January 10, 2026

1. Introduction
This Privacy Policy describes how Recetas ("we", "our", or "us"), developed by Daniel Cimbollek Díaz, handles your information.

We are committed to protecting your privacy. The core principle of "Recetas" is privacy by design: we do not collect, transmit, or store your personal data on any external servers. The application functions entirely offline, and all data you input remains locally on your device.

2. Data Collection and Usage
We do not collect any personal information, usage statistics, or analytics.

User Data (Recipes & Preferences): All recipes, ingredients, dietary settings, and favorites created within the app are stored locally on your device’s internal memory using SharedPreferences and local file storage. This data is never transmitted to us or any third party.

Voluntary Backups: If you choose to use the "Export" or "Backup" feature, a JSON file is generated. You control where this file is stored or shared. We do not have access to these files.

3. Device Permissions
To provide specific features, the app may request access to certain system permissions. These permissions are used solely for the functionality described below:

Camera & Photo Gallery: Used strictly to allow you to take or select photos to attach to your custom recipes. These images are stored locally on your device. We do not view, process, or upload your photos.

Storage (Files/Media): Used to save recipe backups (JSON files) and to read files you explicitly select for importing recipes.

4. Third-Party Services
This application does not contain third-party advertising (e.g., AdMob), analytics (e.g., Google Analytics), or tracking SDKs. It does not require an internet connection to function.

5. Children’s Privacy
Our application is safe for general audiences, including children. We do not knowingly collect personally identifiable information from children under 13 (or any age), as we do not collect data at all.

6. Your Rights (GDPR)
Since we do not store your data on our servers, we cannot "delete" or "export" your account data for you because we do not have it. You retain full ownership and control of your data. You can delete your data at any time by:

Using the "Clear Data" (Borrar todo) option within the app settings.

Uninstalling the application, which will remove all local data.

7. Links to Other Sites
Our Service may contain links to other sites that are not operated by us (e.g., when using the "Search on Internet" button). If you click on a third-party link, you will be directed to that third party's site. We strongly advise you to review the Privacy Policy of every site you visit. We have no control over and assume no responsibility for the content, privacy policies, or practices of any third-party sites or services.

8. Contact Us
If you have any questions about this Privacy Policy, please contact us at:

Email: recetasaplicacion@gmail.com

Developer: Daniel Cimbollek Díaz'''
      : '''TÉRMINOS Y CONDICIONES DE USO
Última actualización: 10 de enero de 2026

1. Aceptación de los Términos
Al descargar o utilizar la aplicación Recetas, usted acepta estar vinculado por estos Términos y Condiciones. Si no está de acuerdo con estos términos, por favor no utilice la aplicación.

2. Licencia de Uso
Daniel Cimbollek Díaz le otorga una licencia personal, no exclusiva, intransferible y revocable para utilizar la aplicación "Recetas" con fines personales y no comerciales.

3. Contenido del Usuario
Propiedad: Usted conserva todos los derechos y la propiedad de las recetas, fotos y textos ("Contenido") que cree o almacene dentro de la aplicación.

Responsabilidad: Usted es el único responsable del Contenido que crea. Dado que la aplicación funciona sin conexión, usted es responsable de realizar copias de seguridad de sus propios datos utilizando las funciones de exportación proporcionadas. No nos hacemos responsables de ninguna pérdida de datos causada por fallos del dispositivo, desinstalación de la aplicación o corrupción de archivos.

4. Renuncia de Responsabilidad sobre el Contenido (IA)
Origen de las Recetas: Usted reconoce que las recetas predeterminadas proporcionadas dentro de la aplicación fueron generadas con la asistencia de Inteligencia Artificial.

Exactitud: Aunque nos esforzamos por ofrecer contenido de calidad, el texto generado por IA puede contener ocasionalmente errores, inexactitudes o "alucinaciones" con respecto a ingredientes, cantidades o instrucciones de cocción.

Responsabilidad del Usuario: Usted acepta utilizar su propio juicio y sentido común al seguir estas recetas. Es su responsabilidad garantizar la seguridad alimentaria, verificar los tiempos/temperaturas de cocción y comprobar posibles alérgenos. Recetas y Daniel Cimbollek Díaz no se hacen responsables de ninguna enfermedad, lesión o fallo culinario resultante del uso de estas recetas.

5. Enlaces Externos
La aplicación puede contener enlaces a sitios web o servicios de terceros (como resultados de búsqueda de Google) que no son propiedad ni están controlados por Recetas. Daniel Cimbollek Díaz no tiene control ni asume responsabilidad por el contenido, las políticas de privacidad o las prácticas de los sitios web o servicios de terceros. Usted reconoce y acepta que Recetas no será responsable, directa o indirectamente, de cualquier daño o pérdida causada por el uso de dicho contenido, bienes o servicios disponibles a través de dichos sitios web.

6. Exención de Garantías
La aplicación se proporciona "TAL CUAL" y "SEGÚN DISPONIBILIDAD", sin garantía de ningún tipo, expresa o implícita. No garantizamos que la aplicación esté libre de errores o que el acceso a la misma sea continuo o ininterrumpido.

7. Propiedad Intelectual
El código fuente, el diseño y la marca "Recetas" son propiedad intelectual de Daniel Cimbollek Díaz.

8. Ley Aplicable
Estos términos se regirán e interpretarán de acuerdo con las leyes de España, sin tener en cuenta sus disposiciones sobre conflictos de leyes.

9. Cambios en los Términos
Nos reservamos el derecho de modificar estos términos en cualquier momento. Le notificaremos cualquier cambio actualizando la fecha de "Última actualización" en la parte superior de este documento. El uso continuado de la aplicación constituye la aceptación de dichos cambios.

10. Contacto
Para cualquier pregunta relacionada con estos Términos, por favor contacte a: recetasaplicacion@gmail.com

--------------------------------------------------

TERMS OF SERVICE
Last updated: January 10, 2026

1. Acceptance of Terms
By downloading or using the Recetas application, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.

2. Use License
Daniel Cimbollek Díaz grants you a personal, non-exclusive, non-transferable, revocable license to use the "Recetas" application for your personal, non-commercial purposes.

3. User Content
Ownership: You retain all rights and ownership of the recipes, photos, and text ("Content") you create or store within the app.

Responsibility: You are solely responsible for the Content you create. Since the app functions offline, you are responsible for backing up your own data using the export features provided. We are not liable for any loss of data caused by device failure, uninstallation, or corruption.

4. Content Disclaimer (AI-Generated Content)
Source of Recipes: You acknowledge that the default recipes provided within the application were generated with the assistance of Artificial Intelligence.

Accuracy: While we strive to provide quality content, AI-generated text may occasionally contain errors, inaccuracies, or "hallucinations" regarding ingredients, quantities, or cooking instructions.

User Responsibility: You agree to use your own judgment and common sense when following these recipes. You are responsible for ensuring food safety, verifying cooking times/temperatures, and checking for potential allergens. Recetas and Daniel Cimbollek Díaz are not liable for any illness, injury, or culinary failure resulting from the use of these recipes.

5. External Links
The application may contain links to third-party web sites or services (such as Google search results) that are not owned or controlled by Recetas. Daniel Cimbollek Díaz has no control over, and assumes no responsibility for, the content, privacy policies, or practices of any third-party web sites or services. You acknowledge and agree that Recetas shall not be responsible or liable, directly or indirectly, for any damage or loss caused or alleged to be caused by or in connection with the use of or reliance on any such content, goods or services available on or through any such web sites.

6. Disclaimer of Warranties
The application is provided "AS IS" and "AS AVAILABLE," without warranty of any kind, express or implied. We do not warrant that the application will be error-free or that access thereto will be continuous or uninterrupted.

7. Intellectual Property
The source code, design, and "Recetas" branding are the intellectual property of Daniel Cimbollek Díaz.

8. Governing Law
These terms shall be governed by and construed in accordance with the laws of Spain, without regard to its conflict of law provisions.

9. Changes to Terms
We reserve the right to modify these terms at any time. We will notify you of any changes by updating the "Last updated" date at the top of this document. Continued use of the application constitutes acceptance of those changes.

10. Contact
For any questions regarding these Terms, please contact: recetasaplicacion@gmail.com''';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

// ---------------------------------------------------------------------------
// RATING WIDGETS
// ---------------------------------------------------------------------------

class _InteractiveStarRating extends StatelessWidget {
  final double rating;
  final double starSize;
  final ValueChanged<double> onRatingChanged;

  const _InteractiveStarRating({
    required this.rating,
    required this.starSize,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTapUp: (details) {
             final width = starSize; 
             final dx = details.localPosition.dx;
             double newRating = index + (dx < width / 2 ? 0.5 : 1.0);
             onRatingChanged(newRating);
          },
          child: Icon(
             _getIcon(index),
             size: starSize,
             color: Colors.amber,
          ),
        );
      }),
    );
  }

  IconData _getIcon(int index) {
      if (rating >= index + 1) return Icons.star_rounded;
      if (rating >= index + 0.5) return Icons.star_half_rounded;
      return Icons.star_outline_rounded;
  }
}

class _PremiumRatingButton extends StatelessWidget {
  final Recipe recipe;

  const _PremiumRatingButton({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = recipe.rating ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
           color: theme.colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                     'Tu valoración',
                     style: theme.textTheme.titleMedium?.copyWith(
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                   Text(
                      rating > 0 ? rating.toStringAsFixed(1) : 'Sin valorar',
                      style: theme.textTheme.titleMedium?.copyWith(
                         color: theme.colorScheme.primary,
                         fontWeight: FontWeight.bold,
                      ),
                   ),
                ],
             ),
             const SizedBox(height: 12),
             Center(
               child: _InteractiveStarRating(
                  rating: rating,
                  starSize: 42,
                  onRatingChanged: (val) {
                     if (val == rating) {
                         RecipeManager.rateRecipe(recipe, 0.0);
                     } else {
                         RecipeManager.rateRecipe(recipe, val);
                     }
                  },
               ),
             ),
         ],
      ),
    );
  }
}








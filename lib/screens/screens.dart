// ignore_for_file: unused_element
// ignore_for_file: unused_local_variable
// ignore_for_file: use_build_context_synchronously
// ignore_for_file: deprecated_member_use
// ignore_for_file: constant_identifier_names
// ignore_for_file: avoid_print
part of '../main.dart';

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
    return ValueListenableBuilder<String>(
      valueListenable: SettingsManager.language,
      builder: (context, lang, child) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [SearchPage(), SavedPage(), SettingsPage()],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            destinations: [
              NavigationDestination(
                icon: Icon(CupertinoIcons.search),
                label: 'Buscar'.tr,
              ),
              NavigationDestination(
                icon: Icon(CupertinoIcons.book),
                label: 'Mis Recetas'.tr,
              ),
              /*
              NavigationDestination(
                icon: Icon(CupertinoIcons.calendar),
                label: 'Calendario'.tr,
              ),
              */
              NavigationDestination(
                icon: Icon(CupertinoIcons.settings),
                label: 'Ajustes'.tr,
              ),
            ],
          ),
        );
      },
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController =
      TextEditingController(); // For recipes view
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
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(toolbarHeight: 0, elevation: 0),
      body: Column(
        children: [
          // Segmented Control
          Padding(
            padding: const EdgeInsets.all(16),
            child: _SlidingSegmentedControl(
              controller: _pageController,
              selectedIndex: _selectedIndex,
              onTap: _onSegmentChanged,
              tabs: ['Recetas'.tr, 'Ingredientes'.tr],
            ),
          ),

          // PageView for sliding content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _RecetasView(
                  searchController: _searchController,
                  searchQuery: _searchQuery,
                  onSearchChanged: (value) =>
                      setState(() => _searchQuery = value),
                ),
                IngredientSearchPage(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecipeDialog(context),
        child: Icon(CupertinoIcons.plus),
      ),
    );
  }

  void _showAddRecipeDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewRecipePage(),
        fullscreenDialog: true,
      ),
    );
  }
}

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
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
      duration: Duration(milliseconds: 300),
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
      appBar: AppBar(toolbarHeight: 0, elevation: 0),
      body: Column(
        children: [
          // Custom Segmented Control
          Padding(
            padding: const EdgeInsets.all(16),
            child: _SlidingSegmentedControl(
              controller: _pageController,
              selectedIndex: _selectedIndex,
              onTap: _onSegmentChanged,
              tabs: ['Guardados'.tr, 'Valoraciones'.tr],
            ),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _SavedRecipesView(
                  searchController: _searchController,
                  searchQuery: _searchQuery,
                  onSearchChanged: (value) =>
                      setState(() => _searchQuery = value),
                  showAppBar: false,
                ),
                RatedRecipesPage(),
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
    final categories = RecipeCategory.values
        .where((c) => allRecipes.any((r) => r.categories.contains(c)))
        .toList();

    // Search for recipes by name
    final searchResults = searchQuery.isEmpty
        ? <Recipe>[]
        : RecipeManager.recipes.where((recipe) {
            return _fuzzyMatch(recipe.title, searchQuery);
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar recetas por nombre...'.tr.tr,
              prefixIcon: Icon(CupertinoIcons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(CupertinoIcons.xmark_circle_fill),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    )
                  : IconButton(
                      icon: Icon(CupertinoIcons.shuffle),
                      tooltip: 'Receta aleatoria',
                      onPressed: () {
                        final allRecipes = RecipeManager.recipes;
                        if (allRecipes.isNotEmpty) {
                          final random = Random();
                          final recipe =
                              allRecipes[random.nextInt(allRecipes.length)];
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailPage(recipe: recipe),
                            ),
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('No hay recetas disponibles'.tr),
                              ),
                            );
                          }
                        }
                      },
                    ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Expanded(
          child: searchQuery.isNotEmpty
              ? searchResults.isEmpty
                    ? Center(child: Text('No se encontraron recetas'.tr))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final recipe = searchResults[index];
                          return _RecipeCard(recipe: recipe, matchCount: 0);
                        },
                      )
              : categories.isEmpty
              ? _EmptyStateWidget(
                  icon: Icons.restaurant_menu,
                  title: 'No hay recetas'.tr.tr,
                  subtitle:
                      'Añade tus propias recetas para verlas aquí'.tr.tr.tr,
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).cardColor
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    RecipesByCategoryPage(category: c),
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
                                SizedBox(height: 12),
                                Text(
                                  c.displayName,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
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

class _SavedRecipesView extends StatefulWidget {
  const _SavedRecipesView({
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
  State<_SavedRecipesView> createState() => _SavedRecipesViewState();
}

class _SavedRecipesViewState extends State<_SavedRecipesView> {
  String? _currentFolderId;
  final List<String> _folderPath = [];

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
            .where((r) => _fuzzyMatch(r.title, widget.searchQuery))
            .toList();
        foldersToShow = RecipeManager.allFolders
            .where((f) => _fuzzyMatch(f.name, widget.searchQuery))
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
                      hintText: 'Buscar en guardados...'.tr.tr,
                      prefixIcon: Icon(CupertinoIcons.search),
                      suffixIcon: widget.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(CupertinoIcons.xmark_circle_fill),
                              onPressed: () {
                                widget.searchController.clear();
                                widget.onSearchChanged('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(CupertinoIcons.add),
                    onPressed: () =>
                        _showCreateFolderDialog(context, _currentFolderId),
                    tooltip: 'Crear carpeta'.tr,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: foldersToShow.isEmpty && recipesToShow.isEmpty
                ? _EmptyStateWidget(
                    icon: widget.searchQuery.isEmpty
                        ? CupertinoIcons.bookmark
                        : CupertinoIcons.search,
                    title: widget.searchQuery.isEmpty
                        ? 'No tienes guardados'.tr
                        : 'Sin resultados'.tr,
                    subtitle: widget.searchQuery.isEmpty
                        ? 'Tus recetas guardadas aparecerán aquí'.tr
                        : 'Intenta con otra búsqueda'.tr,
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Folders
                      ...foldersToShow.map(
                        (folder) => _FolderCard(
                          folder: folder,
                          onTap: () => _navigateToFolder(folder.id),
                          onLongPress: () =>
                              _showFolderOptions(context, folder),
                        ),
                      ),
                      // Recipes
                      ...recipesToShow.map(
                        (recipe) => _RecipeCard(
                          recipe: recipe,
                          matchCount: 0,
                          showFolderOptions: true,
                        ),
                      ),
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
        recipesToShow = RecipeManager.getRecipesInFolderRecursive(
          _currentFolderId!,
        ).where((r) => _fuzzyMatch(r.title, widget.searchQuery)).toList();
        foldersToShow = RecipeManager.getSubFoldersRecursive(
          _currentFolderId!,
        ).where((f) => _fuzzyMatch(f.name, widget.searchQuery)).toList();
      } else {
        recipesToShow = RecipeManager.getRecipesInFolder(currentFolder);
        foldersToShow = subFolders;
      }

      return Scaffold(
        body: CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Pinned Navigation Header
            SliverAppBar(
              pinned: true,
              leading: IconButton(
                icon: Icon(CupertinoIcons.chevron_left),
                onPressed: _navigateBack,
              ),
              title: Text(currentFolder.name),
              actions: [
                IconButton(
                  icon: Icon(CupertinoIcons.add),
                  onPressed: () =>
                      _showCreateFolderDialog(context, _currentFolderId),
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
                  prefixIcon: Icon(CupertinoIcons.search),
                  suffixIcon: widget.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(CupertinoIcons.xmark_circle_fill),
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
                    ...foldersToShow.map(
                      (folder) => _FolderCard(
                        folder: folder,
                        onTap: () => _navigateToFolder(folder.id),
                        onLongPress: () => _showFolderOptions(context, folder),
                      ),
                    ),
                    // Recipes
                    ...recipesToShow.map(
                      (recipe) => _RecipeCard(
                        recipe: recipe,
                        matchCount: 0,
                        showFolderOptions: true,
                      ),
                    ),
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
  Recipe? _initialRecipeSnapshot;

  @override
  void initState() {
    super.initState();
    if (widget.recipeToEdit != null) {
      _loadRecipeData(widget.recipeToEdit!);
      // Snapshot the loaded state to detect real changes later
      _initialRecipeSnapshot = _buildCurrentRecipe();
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
      if (fact.label == 'Calorías') {
        _caloriesController.text = fact.value.toString();
      }
      if (fact.label == 'Proteína') {
        _proteinController.text = fact.value.toString();
      }
      if (fact.label == 'Carbohidratos') {
        _carbsController.text = fact.value.toString();
      }
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
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveRecipe();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(CupertinoIcons.camera),
              title: Text('Cámara'.tr),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(CupertinoIcons.photo),
              title: Text('Galería'.tr),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al seleccionar imagen: $e')),
          );
        }
      }
    }
  }

  Future<void> _scanRecipeLocally() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image == null) return;

    if (SettingsManager.aiApiKey.value.isEmpty) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Por favor configura un API Key de IA en Configuración primero.'
                  .tr,
            ),
          ),
        );
      }
      return;
    }

    final navigator = Navigator.of(context);
    bool isDialogShowing = false;

    if (mounted && context.mounted) {
      isDialogShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);
          return Dialog(
            backgroundColor: theme.brightness == Brightness.dark
                ? Color(0xFF1C1C1E)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.sparkles,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Analizando Receta...'.tr,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(strokeWidth: 3),
                  SizedBox(height: 32),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.info_circle_fill,
                          size: 20,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aviso: La IA puede equivocarse o saltarse algunos ingredientes. Revisa siempre los resultados.'
                                .tr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              height: 1.3,
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
        },
      );
    }

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final dio = Dio();
      final provider = SettingsManager.aiProvider.value;
      final apiKey = SettingsManager.aiApiKey.value;
      final promptText =
          'Extrae la receta de la imagen. Responde ÚNICAMENTE con un JSON válido con la estructura estricta: {"title": "String", "ingredients": [{"name": "String", "quantity": "String"}], "steps": ["String","String"]}. Extrae las cantidades al campo quantity y el nombre del ingrediente al campo name. No añadas texto fuera del JSON (ni bloques de código o markdown).';

      Response response;
      String responseText = '';

      if (provider == 'gemini') {
        final endpoint =
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';
        response = await dio.post(
          endpoint,
          options: Options(headers: {'Content-Type': 'application/json'}),
          data: {
            'contents': [
              {
                'parts': [
                  {'text': promptText},
                  {
                    'inline_data': {
                      'mime_type': 'image/jpeg',
                      'data': base64Image,
                    },
                  },
                ],
              },
            ],
            'generationConfig': {'response_mime_type': 'application/json'},
          },
        );

        responseText =
            response.data['candidates'][0]['content']['parts'][0]['text'];

        // Clean markdown blocks if Gemini fails to omit them
        if (responseText.startsWith('```json')) {
          responseText = responseText
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
        } else if (responseText.startsWith('```')) {
          responseText = responseText.replaceAll('```', '').trim();
        }
      } else {
        final endpoint = SettingsManager.aiApiEndpoint.value.isEmpty
            ? 'https://api.openai.com/v1/chat/completions'
            : SettingsManager.aiApiEndpoint.value;
        response = await dio.post(
          endpoint,
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
          ),
          data: {
            'model': 'gpt-4o',
            'messages': [
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': promptText},
                  {
                    'type': 'image_url',
                    'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
                  },
                ],
              },
            ],
            'response_format': {'type': 'json_object'},
          },
        );
        responseText = response.data['choices'][0]['message']['content'];
      }
      final Map<String, dynamic> recipeData = jsonDecode(responseText);

      setState(() {
        if (recipeData['title'] != null && _titleController.text.isEmpty) {
          _titleController.text = recipeData['title'].toString();
        }

        if (recipeData['ingredients'] is List) {
          for (var ing in (recipeData['ingredients'] as List)) {
            if (ing is Map) {
              _detailedIngredients.add(
                DetailedIngredient(
                  name: ing['name']?.toString() ?? '',
                  quantity: ing['quantity']?.toString() ?? '',
                ),
              );
            } else {
              _detailedIngredients.add(
                DetailedIngredient(name: ing.toString(), quantity: ''),
              );
            }
          }
        }

        if (recipeData['steps'] is List) {
          for (var step in (recipeData['steps'] as List)) {
            _steps.add(step.toString());
          }
        }
      });

      if (isDialogShowing) {
        navigator.pop();
        isDialogShowing = false;
      }

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Importación completada con éxito!'.tr)),
        );
      }
    } catch (e) {
      if (isDialogShowing) {
        navigator.pop();
        isDialogShowing = false;
      }

      if (mounted && context.mounted) {
        String errorMessage = 'Hubo un error con la IA'.tr + ': $e';
        if (e is DioException) {
          if (e.response?.statusCode == 401) {
            errorMessage =
                'La clave de API (API Key) es inválida o incorrecta. Por favor, revísala en Configuración.'
                    .tr;
          } else {
            errorMessage =
                'Error de conexión con la IA (Código ${e.response?.statusCode ?? "desconocido"}).'
                    .tr;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), duration: Duration(seconds: 5)),
        );
      }
    }
  }

  // --- Logic Helpers ---

  bool _areRecipesDifferent(Recipe oldR, Recipe newR) {
    if (oldR.title != newR.title) return true;
    if (oldR.prepTime != newR.prepTime) return true;
    if (oldR.imagePath != newR.imagePath) return true;

    // Compare detailed ingredients (the canonical source of truth)
    if (oldR.detailedIngredients.length != newR.detailedIngredients.length) {
      return true;
    }
    for (int i = 0; i < oldR.detailedIngredients.length; i++) {
      if (oldR.detailedIngredients[i].name !=
          newR.detailedIngredients[i].name) {
        return true;
      }
      if (oldR.detailedIngredients[i].quantity !=
          newR.detailedIngredients[i].quantity) {
        return true;
      }
    }

    if (!listEquals(oldR.steps, newR.steps)) return true;

    if (!setEquals(oldR.categories.toSet(), newR.categories.toSet())) {
      return true;
    }
    if (!setEquals(
      oldR.dietaryRestrictions.toSet(),
      newR.dietaryRestrictions.toSet(),
    )) {
      return true;
    }
    if (!setEquals(
      oldR.customDietaryTags.toSet(),
      newR.customDietaryTags.toSet(),
    )) {
      return true;
    }

    // Simple Nutrition check
    if (oldR.nutritionFacts.length != newR.nutritionFacts.length) return true;
    for (int i = 0; i < oldR.nutritionFacts.length; i++) {
      final f1 = oldR.nutritionFacts[i];
      final f2 = newR.nutritionFacts[i];
      if (f1.label != f2.label || f1.value != f2.value || f1.unit != f2.unit) {
        return true;
      }
    }

    return false;
  }

  Recipe _buildCurrentRecipe() {
    final normalizedIngredients =
        _detailedIngredients.map((d) => d.name).toList();
    List<NutritionFact> nutritionFacts = [];
    void addFact(TextEditingController ctrl, String label, String unit) {
      final txt = ctrl.text.trim().replaceAll(',', '.');
      if (txt.isNotEmpty) {
        final val = double.tryParse(txt);
        if (val != null && val > 0) {
          nutritionFacts.add(
            NutritionFact(label: label, value: val, unit: unit),
          );
        }
      }
    }

    addFact(_caloriesController, 'Calorías', 'kcal');
    addFact(_proteinController, 'Proteína', 'g');
    addFact(_carbsController, 'Carbohidratos', 'g');
    addFact(_fatController, 'Grasas', 'g');

    return Recipe(
      title: _titleController.text.trim(),
      ingredients: normalizedIngredients,
      detailedIngredients: List.of(_detailedIngredients),
      prepTime: _prepTimeController.text.trim().isNotEmpty
          ? _prepTimeController.text.trim()
          : null,
      categories: _selectedCategories.toList(),
      dietaryRestrictions: _selectedDietaryRestrictions.toList(),
      customDietaryTags: _selectedCustomTags.toList(),
      imagePath: _selectedImagePath,
      steps: List.of(_steps),
      nutritionFacts: nutritionFacts,
      rating: widget.recipeToEdit?.rating,
    );
  }

  bool _hasUnsavedChanges() {
    final current = _buildCurrentRecipe();
    if (_initialRecipeSnapshot != null) {
      return _areRecipesDifferent(_initialRecipeSnapshot!, current);
    } else {
      // New recipe: check if anything was entered
      return current.title.isNotEmpty ||
          current.detailedIngredients.isNotEmpty ||
          current.steps.isNotEmpty ||
          current.imagePath != null ||
          current.prepTime != null ||
          current.nutritionFacts.isNotEmpty ||
          current.categories.isNotEmpty ||
          current.dietaryRestrictions.isNotEmpty;
    }
  }

  Future<void> _attemptClose() async {
    if (!_hasUnsavedChanges()) {
      Navigator.of(context).pop();
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Salir sin guardar?'.tr),
        content: Text('Tienes cambios sin guardar. Si sales, los perderás.'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Salir'.tr),
          ),
        ],
      ),
    );

    if (discard == true) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _saveRecipe() async {
    if (_titleController.text.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor, escribe un nombre para la receta'.tr),
          ),
        );
      }
      return;
    }

    final newRecipe = _buildCurrentRecipe();

    // Check for changes if editing
    if (_initialRecipeSnapshot != null) {
      if (_areRecipesDifferent(_initialRecipeSnapshot!, newRecipe)) {
        final choice = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Guardar cambios'.tr),
            content: Text(
              'Has modificado la receta. ¿Deseas actualizar la actual o guardar como una nueva?'
                  .tr,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'new'),
                child: Text('Guardar como nueva'.tr),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, 'update'),
                child: Text('Actualizar'.tr),
              ),
            ],
          ),
        );

        if (choice == null) return; // Cancelled

        if (choice == 'new') {
          // Create copy
          Recipe recipeToSave = newRecipe;
          // If user didn't change title manually, we must change it to allow 'new'.
          if (newRecipe.title == widget.recipeToEdit!.title) {
            recipeToSave = newRecipe.copyWith(
              title: '${newRecipe.title} (Copia)',
            );
          }

          try {
            await RecipeManager.addRecipe(recipeToSave);
            // Also favorite the copy
            if (!RecipeManager.isFavorite(recipeToSave)) {
              await RecipeManager.toggleFavorite(recipeToSave);
            }

            if (mounted) {
              if (context.mounted) Navigator.of(context).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Receta guardada como nueva'.tr)),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error al guardar'.tr)));
              }
            }
          }
          return;
        }
        // If 'update', continue to standard saving logic below
      }
    }

    try {
      if (widget.recipeToEdit != null &&
          widget.recipeToEdit!.title != newRecipe.title) {
        await RecipeManager.removeRecipe(widget.recipeToEdit!);
      }
      await RecipeManager.addRecipe(newRecipe);

      if (!RecipeManager.isFavorite(newRecipe) && widget.recipeToEdit == null) {
        await RecipeManager.toggleFavorite(newRecipe);
      }

      if (mounted) {
        if (context.mounted) Navigator.of(context).pop(); // Close wizard
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.recipeToEdit != null
                    ? 'Receta actualizada'
                    : 'Receta creada',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar la receta'.tr)),
          );
        }
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
              leading: Icon(CupertinoIcons.pencil),
              title: Text('Editar paso'.tr),
              onTap: () {
                Navigator.pop(context);
                final controller = TextEditingController(text: _steps[index]);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Editar paso'.tr),
                    content: TextField(
                      controller: controller,
                      maxLines: 3,
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancelar'.tr),
                      ),
                      FilledButton(
                        onPressed: () {
                          _editStep(index, controller.text);
                          Navigator.pop(context);
                        },
                        child: Text('Guardar'.tr),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (index > 0 && !_isReorderingSteps)
              ListTile(
                leading: Icon(CupertinoIcons.arrow_up),
                title: Text('Mover arriba'.tr),
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
                leading: Icon(CupertinoIcons.arrow_down),
                title: Text('Mover abajo'.tr),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    final item = _steps.removeAt(index);
                    _steps.insert(index + 1, item);
                  });
                },
              ),
            ListTile(
              leading: Icon(CupertinoIcons.trash, color: Colors.redAccent),
              title: Text(
                'Eliminar paso'.tr,
                style: TextStyle(color: Colors.redAccent),
              ),
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
          decoration: InputDecoration(labelText: 'Ej: 200g, 1 un, al gusto...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Añadir'.tr),
          ),
        ],
      ),
    );
  }

  void _showAddStepDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Añadir paso'.tr),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Describe el paso...'.tr.tr),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'.tr),
          ),
          FilledButton(
            onPressed: () {
              _addStep(controller.text);
              Navigator.pop(context);
            },
            child: Text('Añadir'.tr),
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
          title: Text('Crear ingrediente'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: 'Nombre'.tr),
              ),
              SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                decoration: InputDecoration(
                  labelText: 'Cantidad (ej: 100g)'.tr,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).cardColor
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Theme.of(context).brightness == Brightness.dark
                      ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                      : null,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<IngredientCategory>(
                    isExpanded: true,
                    value: selectedCat,
                    hint: Text(
                      'Categoría (Opcional)'.tr,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    ),
                    items: IngredientCategory.values
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedCat = v),
                    icon: Icon(CupertinoIcons.chevron_down, size: 16),
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'.tr),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  if (selectedCat != null) {
                    RecipeManager.addCustomMapping(name, selectedCat!);
                  }
                  _addIngredient(
                    DetailedIngredient(
                      name: name,
                      quantity: qtyCtrl.text.trim(),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Añadir'.tr),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _attemptClose();
      },
      child: Scaffold(
        // backgroundColor: Use theme default
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar & Progress
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Close Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(CupertinoIcons.xmark),
                        onPressed: _attemptClose,
                      ),
                    ),

                    // Center Content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.recipeToEdit != null
                              ? 'EDITAR RECETA'.tr
                              : 'NUEVA RECETA'.tr,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_totalSteps, (index) {
                            final isActive = index <= _currentStep;
                            return Container(
                              width: 32,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? theme.colorScheme.primary
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.black.withValues(
                                              alpha: 0.1,
                                            )),
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
                  physics:
                      NeverScrollableScrollPhysics(), // Disable swipe, enforce buttons
                  onPageChanged: (index) =>
                      setState(() => _currentStep = index),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.chevron_left, size: 18),
                              SizedBox(width: 8),
                              Text('Atrás'.tr),
                            ],
                          ),
                        ),
                      ),
                    if (_currentStep > 0) SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _currentStep == _totalSteps - 1
                            ? _saveRecipe
                            : _nextStep,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.black, // High contrast
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep == _totalSteps - 1
                                  ? (widget.recipeToEdit != null
                                        ? 'Guardar Cambios'.tr
                                        : 'Finalizar Receta'.tr)
                                  : 'Siguiente'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_currentStep < _totalSteps - 1) ...[
                              SizedBox(width: 8),
                              Icon(CupertinoIcons.chevron_right, size: 18),
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
      ),
    );
  }

  // --- Step 1: Basics ---
  Widget _buildAddPhotoPlaceholder(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(CupertinoIcons.camera, size: 48, color: theme.colorScheme.primary),
        SizedBox(height: 12),
        Text(
          'Añadir foto'.tr,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

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
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _selectedImagePath == null
                  ? _buildAddPhotoPlaceholder(theme)
                  : (_selectedImagePath!.startsWith('assets/')
                        ? Image.asset(
                            _selectedImagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildAddPhotoPlaceholder(theme),
                          )
                        : Image.file(
                            File(_selectedImagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildAddPhotoPlaceholder(theme),
                          )),
            ),
          ),
          SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _scanRecipeLocally,
            icon: Icon(CupertinoIcons.doc_text_viewfinder),
            label: Text('Escanear receta desde foto (Beta)'.tr),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          SizedBox(height: 16),

          _buildInputSection(
            theme,
            title: 'NOMBRE'.tr.tr,
            children: [
              TextField(
                controller: _titleController,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'Nombre de la receta'.tr.tr,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),

          _buildInputSection(
            theme,
            title: 'TIEMPO ESTIMADO'.tr.tr,
            children: [
              TextField(
                controller: _prepTimeController,
                decoration: InputDecoration(
                  hintText: 'Ej: 30 min'.tr.tr,
                  prefixIcon: Icon(CupertinoIcons.clock, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),

          _buildInputSection(
            theme,
            title: 'NUTRICIÓN (OPCIONAL)'.tr.tr,
            children: [
              Theme(
                data: theme.copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  dividerColor: Colors
                      .transparent, // Ensure no dividers show up unexpectedly
                ),
                child: ExpansionTile(
                  title: Text('Información Nutricional'.tr),
                  leading: Icon(Icons.analytics_outlined),
                  shape: Border(),
                  collapsedShape: Border(),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactNutriInput(
                            theme,
                            _caloriesController,
                            'Calorías (kcal)',
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildCompactNutriInput(
                            theme,
                            _proteinController,
                            'Proteína (g)',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactNutriInput(
                            theme,
                            _carbsController,
                            'Carbohidratos (g)',
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildCompactNutriInput(
                            theme,
                            _fatController,
                            'Grasas (g)',
                          ),
                        ),
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

  Widget _buildInputSection(
    ThemeData theme, {
    String? title,
    required List<Widget> children,
  }) {
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
                ? theme.cardColor
                : theme.cardColor,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactNutriInput(
    ThemeData theme,
    TextEditingController controller,
    String label,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
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
              .take(6)
              .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INGREDIENTES'.tr,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ingredientController,
                      onChanged: (val) =>
                          setState(() => _ingredientQuery = val),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: 'Buscar ingredientes...'.tr.tr,
                        prefixIcon: Icon(CupertinoIcons.search),
                        suffixIcon: _ingredientQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  CupertinoIcons.xmark_circle_fill,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _ingredientController.clear();
                                  setState(() => _ingredientQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(CupertinoIcons.add),
                      onPressed: _showAddCustomIngredientDialog,
                      tooltip: 'Crear nuevo',
                    ),
                  ),
                ],
              ),
              // Search Results
              if (filteredList.isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final ing = filteredList[index];
                      return ListTile(
                        title: Text(ing),
                        leading: Icon(CupertinoIcons.add, size: 16),
                        visualDensity: VisualDensity.compact,
                        onTap: () async {
                          final qty = await _pickQuantityDialog(ing);
                          if (qty != null) {
                            _addIngredient(
                              DetailedIngredient(name: ing, quantity: qty),
                            );
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
              ? Center(
                  child: Text(
                    'Añade los ingredientes necesarios'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _detailedIngredients.length,
                  itemBuilder: (context, index) {
                    final item = _detailedIngredients[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.05,
                          ),
                        ),
                      ),
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Text(
                              item.quantity,
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            CupertinoIcons.trash,
                            size: 18,
                            color: Colors.grey,
                          ),
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
              Text(
                'PASOS A SEGUIR'.tr,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Row(
                children: [
                  FilledButton(
                    onPressed: () => setState(
                      () => _isReorderingSteps = !_isReorderingSteps,
                    ),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: _isReorderingSteps
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: _isReorderingSteps
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      minimumSize: Size(
                        48,
                        36,
                      ), // Ensure min height matches standard compact button
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ), // Restore some padding
                    ),
                    child: Icon(Icons.drag_handle, size: 20),
                  ),
                  SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _showAddStepDialog,
                    icon: Icon(CupertinoIcons.add),
                    label: Text('Añadir paso'.tr),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
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
                      Icon(
                        CupertinoIcons.list_bullet,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.2,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '¿Cómo se prepara?'.tr,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
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
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.05,
                            ),
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.drag_indicator,
                            color: Colors.grey,
                          ),
                          title: Text(_steps[index]),
                          trailing: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
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
                          side: BorderSide(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.05,
                            ),
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
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
            title: 'CATEGORÍA'.tr.tr,
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
          SizedBox(height: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DIETA'.tr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAddCustomTagDialog,
                    icon: Icon(CupertinoIcons.add, size: 16),
                    label: Text('Crear etiqueta'.tr),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
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
                        if (active) {
                          _selectedDietaryRestrictions.remove(r);
                        } else {
                          _selectedDietaryRestrictions.add(r);
                        }
                      }),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      selectedColor: theme.colorScheme.primary.withValues(
                        alpha: 0.3,
                      ),
                      checkmarkColor: theme.colorScheme.primary,
                      side: BorderSide(
                        color: active
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }),
                  ..._selectedCustomTags.map((tag) {
                    return FilterChip(
                      label: Text(tag),
                      selected: true,
                      onSelected: (_) =>
                          setState(() => _selectedCustomTags.remove(tag)),
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.3,
                      ),
                      selectedColor: theme.colorScheme.primary.withValues(
                        alpha: 0.3,
                      ),
                      checkmarkColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
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
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final active = isSelected(item);
            return FilterChip(
              label: Text(getLabel(item)),
              selected: active,
              onSelected: (_) => onToggle(item),
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.3),
              checkmarkColor: theme.colorScheme.primary,
              side: BorderSide(
                color: active ? theme.colorScheme.primary : Colors.transparent,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
        title: Text('Añadir etiqueta'.tr),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Ej: Keto, Low Carb...'.tr.tr),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'.tr),
          ),
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
            child: Text('Añadir'.tr),
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
      title: Text('Añadir ingrediente'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Nombre del ingrediente'.tr.tr,
              labelText: 'Ingrediente',
            ),
            autofocus: true,
          ),
          SizedBox(height: 12),
          TextField(
            controller: _quantityController,
            decoration: InputDecoration(
              hintText: 'Ej: 200g'.tr.tr,
              labelText: 'Cantidad',
            ),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<IngredientCategory>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            isExpanded: true,
            items: IngredientCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Row(
                  children: [
                    Icon(category.icon, size: 20),
                    SizedBox(width: 12),
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
          child: Text('Cancelar'.tr),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              widget.onAdd(
                _nameController.text.trim(),
                _quantityController.text.trim(),
                _selectedCategory,
              );
              if (context.mounted) Navigator.of(context).pop();
            }
          },
          child: Text('Añadir'.tr),
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
      title: Text('Añadir paso'.tr),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Describe el paso de la receta'.tr.tr,
          labelText: 'Paso',
        ),
        autofocus: true,
        maxLines: 3,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            widget.onAdd(value.trim());
            if (context.mounted) Navigator.of(context).pop();
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'.tr),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              widget.onAdd(_controller.text.trim());
              if (context.mounted) Navigator.of(context).pop();
            }
          },
          child: Text('Añadir'.tr),
        ),
      ],
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
    final filtered = RecipeManager.recipes
        .where((r) => r.categories.contains(widget.category))
        .toList();
    final searchFiltered = filtered.where((recipe) {
      if (_searchQuery.isEmpty) return true;
      return recipe.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.category.displayName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
              decoration: InputDecoration(
                hintText: 'Buscar recetas en ${widget.category.displayName}...',
                prefixIcon: Icon(CupertinoIcons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(CupertinoIcons.xmark_circle_fill),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : IconButton(
                        icon: Icon(CupertinoIcons.shuffle),
                        tooltip: 'Receta aleatoria',
                        onPressed: () {
                          if (searchFiltered.isNotEmpty) {
                            final random = Random();
                            final recipe =
                                searchFiltered[random.nextInt(
                                  searchFiltered.length,
                                )];
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    RecipeDetailPage(recipe: recipe),
                              ),
                            );
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'No hay recetas disponibles'.tr,
                                  ),
                                ),
                              );
                            }
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
  _RecipeCategory({
    required this.name,
    required this.icon,
    required this.matches,
  });

  final String name;
  final IconData icon;
  final bool Function(Recipe) matches;
}

class IngredientSearchPage extends StatefulWidget {
  const IngredientSearchPage({super.key});

  @override
  State<IngredientSearchPage> createState() => _IngredientSearchPageState();
}

class _IngredientSearchPageState extends State<IngredientSearchPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<String>? _cachedAllIngredients;
  Map<IngredientCategory, List<String>>? _cachedCategoryIngredientsMap;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    RecipeManager.addListener(_onRecipesChanged);
  }

  void _onRecipesChanged() {
    if (mounted) {
      setState(() {
        _cachedAllIngredients = null;
        _cachedCategoryIngredientsMap = null;
      });
    }
  }

  List<String> get _allIngredients {
    if (_cachedAllIngredients != null) return _cachedAllIngredients!;
    final allCategoryIngredients = <String>{};
    for (final ingredients in _categoryIngredientsMap.values) {
      allCategoryIngredients.addAll(ingredients);
    }
    _cachedAllIngredients = allCategoryIngredients.toList()..sort();
    return _cachedAllIngredients!;
  }

  Map<IngredientCategory, List<String>> get _categoryIngredientsMap {
    if (_cachedCategoryIngredientsMap != null) {
      return _cachedCategoryIngredientsMap!;
    }

    final allIngredientsFromRecipes = RecipeManager.allIngredients;
    final map = <IngredientCategory, List<String>>{};

    // Get ingredients from all categories
    for (final category in IngredientCategory.values) {
      map[category] = _getIngredientsForCategory(
        category,
        allIngredientsFromRecipes,
      );
    }

    _cachedCategoryIngredientsMap = map;
    return map;
  }

  final Set<String> _selected = <String>{};
  String _query = '';

  @override
  void dispose() {
    RecipeManager.removeListener(_onRecipesChanged);
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
    super.build(context);
    final theme = Theme.of(context);

    // Use the smart sort logic
    final filtered = _sortIngredients(
      _allIngredients,
      _query,
    ).where((i) => !_selected.contains(i)).take(12).toList();

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
                    hintText: 'Búsqueda por ingredientes...'.tr.tr,
                    prefixIcon: Icon(CupertinoIcons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(CupertinoIcons.xmark_circle_fill),
                            onPressed: () {
                              setState(() {
                                _query = '';
                                _controller.clear();
                              });
                            },
                          ),
                  ),
                ),
                SizedBox(height: 8),
                if (_selected.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Seleccionados'.tr,
                        style: theme.textTheme.titleMedium,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _selected.clear()),
                            child: Text('Borrar todo'.tr),
                          ),
                          SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () => _openResults(context),
                            icon: Icon(CupertinoIcons.search, size: 18),
                            label: Text('Buscar'.tr),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selected
                        .map(
                          (i) => InputChip(
                            label: Text(i),
                            selected: true,
                            onDeleted: () => _remove(i),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 12),
                ],
                if (_query.isNotEmpty) ...[
                  Text('Sugerencias'.tr, style: theme.textTheme.titleMedium),
                  SizedBox(height: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: _allIngredients.isEmpty
                ? _EmptyStateWidget(
                    icon: CupertinoIcons.search,
                    title: 'No hay ingredientes'.tr.tr,
                    subtitle:
                        'Añade recetas para explorar sus ingredientes'.tr.tr.tr,
                  )
                : _query.isEmpty
                ? _PopularIngredientsGrid(
                    categoryMap: _categoryIngredientsMap,
                    onPick: _add,
                    isSelected: (i) => _selected.contains(i),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        leading: Icon(CupertinoIcons.plus_circled),
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
        builder: (_) =>
            RecipeResultsPage(selectedIngredients: _selected.toList()),
      ),
    );
  }
}

class _PopularIngredientsGrid extends StatelessWidget {
  const _PopularIngredientsGrid({
    required this.categoryMap,
    required this.onPick,
    required this.isSelected,
  });

  final Map<IngredientCategory, List<String>> categoryMap;
  final void Function(String) onPick;
  final bool Function(String) isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesWithIngredients = categoryMap.entries
        .map((entry) {
          final category = entry.key;
          final categoryIngredients = entry.value;
          final availableIngredients = categoryIngredients
              .where((ingredient) => !isSelected(ingredient.toLowerCase()))
              .toList();
          return MapEntry(category, availableIngredients);
        })
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).cardColor
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
            boxShadow: [],
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
                    SizedBox(height: 12),
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
    final categoryIngredients = _getIngredientsForCategory(
      category,
      allIngredients,
    );
    final availableIngredients = categoryIngredients
        .where((ingredient) => !isSelected(ingredient.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(category.displayName)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: availableIngredients.isEmpty
              ? Center(
                  child: Text(
                    'No hay ingredientes disponibles en esta categoría'.tr,
                  ),
                )
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
                          color: theme.brightness == Brightness.dark
                              ? theme.cardColor
                              : theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              onPick(text);
                              if (context.mounted) Navigator.of(context).pop();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Text(
                                text,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface,
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
    final List<_ScoredRecipe> results =
        RecipeManager.recipes
            .map((r) {
              final matches = widget.selectedIngredients
                  .where(
                    (needle) =>
                        r.ingredients.any((i) => _ingredientsMatch(i, needle)),
                  )
                  .length;
              // Get the actual recipe ingredients that matched (to highlight them correctly)
              final matchedRecipeIngredients = r.ingredients
                  .where(
                    (ingredient) => widget.selectedIngredients.any(
                      (needle) => _ingredientsMatch(ingredient, needle),
                    ),
                  )
                  .map((e) => e.toLowerCase())
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
        title: Text('Recetas'.tr),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
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
                            icon: Icon(CupertinoIcons.xmark_circle, size: 16),
                            label: Text('Limpiar filtros'.tr),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ..._selectedFilters.map(
                            (filter) => Chip(
                              label: Text(filter.displayName),
                              onDeleted: () => setState(
                                () => _selectedFilters.remove(filter),
                              ),
                            ),
                          ),
                          ..._selectedCustomFilters.map(
                            (tag) => Chip(
                              label: Text(tag),
                              onDeleted: () => setState(
                                () => _selectedCustomFilters.remove(tag),
                              ),
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 12),
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

    final standardMatch =
        _selectedFilters.isEmpty ||
        _selectedFilters.every(
          (filter) => recipe.dietaryRestrictions.contains(filter),
        );

    final customMatch =
        _selectedCustomFilters.isEmpty ||
        _selectedCustomFilters.every(
          (tag) => recipe.customDietaryTags.contains(tag),
        );

    return standardMatch && customMatch;
  }

  bool _ingredientsMatch(String recipeIngredient, String searchIngredient) {
    final r = recipeIngredient.toLowerCase().trim();
    final s = searchIngredient.toLowerCase().trim();

    if (r == s) return true;

    // Check for plural forms (e.g. "tomate" matches "tomates", "huevo" matches "huevos")
    // If recipe has "tomates" and search is "tomate" -> r contains s
    // AND length diff is small to avoid "pan" matching "empanada" purely by string containment without checking boundaries here
    if (r.contains(s) && r.length <= s.length + 2) return true;

    // If recipe has "tomate" and search is "tomates" -> s contains r
    if (s.contains(r) && s.length <= r.length + 2) return true;

    // Word boundary check (allows "pan" -> "pan integral")
    // Matches if 's' appears as a whole word inside 'r'
    if (RegExp(r'\b' + RegExp.escape(s) + r'\b').hasMatch(r)) return true;

    return false;
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
        title: Text('Eliminar receta'.tr),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${_currentRecipe.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'.tr),
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
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close dialog
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close page
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Receta "${widget.recipe.title}" eliminada',
                        ),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  if (context.mounted) Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al eliminar la receta'.tr)),
                    );
                  }
                }
              }
            },
            child: Text('Eliminar'.tr),
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
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _toggleFavorite() async {
    await RecipeManager.toggleFavorite(widget.recipe);
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(CupertinoIcons.camera),
              title: Text('Cámara'.tr),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(CupertinoIcons.photo),
              title: Text('Galería'.tr),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'custom_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localImage = await File(
        pickedFile.path,
      ).copy('${appDir.path}/$fileName');

      await RecipeManager.setCustomImage(widget.recipe.title, localImage.path);

      if (mounted) {
        setState(() {}); // Refresh UI
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Imagen actualizada'.tr)));
        }
      }
    }
  }

  void _duplicateRecipe() async {
    int counter = 1;
    String newTitle = '${_currentRecipe.title} (Copia)';

    // Ensure unique title
    while (RecipeManager.recipes.any((r) => r.title == newTitle)) {
      counter++;
      newTitle = '${_currentRecipe.title} (Copia $counter)';
    }

    final duplicatedRecipe = _currentRecipe.copyWith(title: newTitle);

    await RecipeManager.addRecipe(duplicatedRecipe);
    await RecipeManager.toggleFavorite(duplicatedRecipe);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Receta duplicada'.tr)));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RecipeDetailPage(recipe: duplicatedRecipe),
        ),
      );
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Valorar receta'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Toca una estrella para valorar:'.tr),
            SizedBox(height: 16),
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
                    SizedBox(width: 8),
                    Text(
                      (widget.recipe.rating ?? 0).toStringAsFixed(1),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'.tr),
          ),
        ],
      ),
    );
  }

  void _showRecipeOptionsDialog(
    BuildContext context,
    ThemeData theme,
    bool isPersonalized,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Opciones de la receta'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _SelectionOption(
                        title: _isFavorite
                            ? 'Quitar de guardados'.tr
                            : 'Guardados'.tr,
                        icon: _isFavorite
                            ? CupertinoIcons.bookmark_fill
                            : CupertinoIcons.bookmark,
                        isSelected: false,
                        iconColor: _isFavorite
                            ? Colors.amber
                            : theme.colorScheme.primary,
                        onTap: () {
                          Navigator.pop(context);
                          _toggleFavorite();
                        },
                      ),
                      SizedBox(height: 12),
                      _SelectionOption(
                        title: 'Editar'.tr,
                        icon: CupertinoIcons.pencil,
                        isSelected: false,
                        iconColor: theme.colorScheme.primary,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  NewRecipePage(recipeToEdit: _currentRecipe),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 12),
                      _SelectionOption(
                        title: 'Duplicar'.tr,
                        icon: CupertinoIcons.doc_on_doc,
                        isSelected: false,
                        iconColor: theme.colorScheme.primary,
                        onTap: () {
                          Navigator.pop(context);
                          _duplicateRecipe();
                        },
                      ),
                      SizedBox(height: 12),
                      _SelectionOption(
                        title: 'Buscar en Internet'.tr,
                        icon: CupertinoIcons.globe,
                        isSelected: false,
                        iconColor: theme.colorScheme.primary,
                        onTap: () async {
                          Navigator.pop(context);
                          final query = Uri.encodeComponent(
                            _currentRecipe.title,
                          );
                          final url = Uri.parse(
                            'https://www.google.com/search?q=$query',
                          );
                          try {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (e) {
                            if (mounted && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'No se pudo abrir el navegador'.tr,
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      if (isPersonalized) ...[
                        SizedBox(height: 12),
                        _SelectionOption(
                          title: 'Eliminar'.tr,
                          icon: CupertinoIcons.trash,
                          isSelected: false,
                          isDestructive: true,
                          onTap: () {
                            Navigator.pop(context);
                            _showDeleteDialog();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 48),
              ],
            ),
          ),
        ),
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
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(_currentRecipe.title),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () =>
                _showRecipeOptionsDialog(context, theme, isPersonalized),
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
                    decoration: BoxDecoration(color: Colors.transparent),
                    child: displayImagePath.startsWith('assets/')
                        ? Hero(
                            tag: widget.heroTag ?? widget.recipe.title,
                            child: Material(
                              color: Colors.transparent,
                              child: Image.asset(
                                displayImagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholder(),
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
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholder(),
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
                    decoration: BoxDecoration(color: Colors.transparent),
                    child: _buildPlaceholder(),
                  ),
                ),

              // Floating Prep Time Chip
              if (_currentRecipe.prepTime != null)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      // border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.clock,
                          color: theme.colorScheme.onPrimary,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _currentRecipe.prepTime!,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
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
              tabs: ['Ingredientes'.tr, 'Instrucciones'.tr, 'Info'.tr],
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
    final theme = Theme.of(context);
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.photo,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            SizedBox(height: 8),
            Text(
              'Toca para añadir foto'.tr,
              style: TextStyle(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
              'Ajustes'.tr,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          _SettingsSection(
            title: 'GENERAL'.tr.tr,
            children: [
              ValueListenableBuilder<int>(
                valueListenable: SettingsManager.startScreenIndex,
                builder: (context, index, child) {
                  return _SettingsTile(
                    title: 'Pantalla predeterminada'.tr.tr,
                    icon: CupertinoIcons.home,
                    subtitle: index == 0 ? 'Buscador'.tr : 'Mis Recetas'.tr,
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onTap: () => _showStartScreenDialog(context, index),
                  );
                },
              ),
              _SettingsTile(
                title: 'Filtros dietéticos permanentes'.tr.tr,
                subtitle: 'Excluir siempre recetas incompatibles'.tr.tr.tr,
                icon: Icons.no_food,
                trailing: Icon(
                  CupertinoIcons.chevron_right,
                  size: 20,
                  color: Colors.grey,
                ),
                onTap: () {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => _DietarySettingsPage()),
                    );
                  }
                },
              ),
              ValueListenableBuilder<String>(
                valueListenable: SettingsManager.language,
                builder: (context, lang, child) {
                  return _SettingsTile(
                    title: 'Idioma / Language'.tr.tr,
                    icon: CupertinoIcons.globe,
                    subtitle: lang == 'en' ? 'English' : 'Español',
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onTap: () => _showLanguageScreenDialog(context, lang),
                  );
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: SettingsManager.isDarkMode,
                builder: (context, isDark, child) {
                  return _SettingsTile(
                    title: 'Modo Oscuro'.tr.tr,
                    isSwitch: true,
                    switchValue: isDark,
                    onSwitchChanged: (value) =>
                        SettingsManager.setDarkMode(value),
                    icon: CupertinoIcons.moon_fill,
                  );
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: SettingsManager.showDefaultRecipes,
                builder: (context, showDefaults, child) {
                  return _SettingsTile(
                    title: 'Mostrar Recetas Predeterminadas'.tr.tr,
                    isSwitch: true,
                    switchValue: showDefaults,
                    onSwitchChanged: (value) =>
                        SettingsManager.setShowDefaults(value),
                    icon: CupertinoIcons.book_fill,
                  );
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: SettingsManager.preventSleep,
                builder: (context, prevent, child) {
                  return _SettingsTile(
                    title: 'Mantener pantalla encendida'.tr.tr,
                    isSwitch: true,
                    switchValue: prevent,
                    onSwitchChanged: (value) =>
                        SettingsManager.setPreventSleep(value),
                    icon: CupertinoIcons.eye,
                    lastItem: true,
                  );
                },
              ),
            ],
          ),

          _SettingsSection(
            title: 'INTELIGENCIA ARTIFICIAL'.tr.tr,
            children: [
              _SettingsTile(
                title: 'Configurar API Key'.tr.tr,
                subtitle: 'Usar IA para extraer recetas de imágenes'.tr.tr,
                icon: CupertinoIcons.sparkles,
                trailing: Icon(
                  CupertinoIcons.chevron_right,
                  size: 20,
                  color: Colors.grey,
                ),
                onTap: () {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _AiSettingsPage(),
                      ),
                    );
                  }
                },
                lastItem: true,
              ),
            ],
          ),

          _SettingsSection(
            title: 'DATOS'.tr.tr,
            children: [
              _SettingsTile(
                title: 'Exportar recetas'.tr.tr,
                icon: CupertinoIcons.share,
                onTap: () => SettingsManager.exportRecipes(context),
              ),
              _SettingsTile(
                title: 'Importar recetas'.tr.tr,
                icon: CupertinoIcons.arrow_down_doc,
                onTap: () => SettingsManager.importRecipes(context),
              ),
              _SettingsTile(
                title: 'Borrar todos los datos'.tr.tr,
                icon: CupertinoIcons.delete,
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: () => SettingsManager.clearData(context),
                lastItem: true,
              ),
            ],
          ),

          _SettingsSection(
            title: 'INFORMACIÓN'.tr.tr,
            children: [
              _SettingsTile(
                title: 'Legal'.tr.tr,
                subtitle: 'Política de Privacidad y Términos'.tr.tr.tr,
                icon: CupertinoIcons.doc_text,
                trailing: Icon(
                  CupertinoIcons.chevron_right,
                  size: 20,
                  color: Colors.grey,
                ),
                onTap: () {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => _LegalPage()),
                    );
                  }
                },
                lastItem: true,
              ),
            ],
          ),

          SizedBox(height: 32),
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
              ? Color(0xFF1C1C1E) // iOS Dark Gray
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12),
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 24),

              Text(
                'Elegir pantalla predeterminada'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _SelectionOption(
                      title: 'Buscador'.tr.tr,
                      icon: CupertinoIcons.search,
                      isSelected: currentIndex == 0,
                      onTap: () {
                        SettingsManager.setStartScreenIndex(0);
                        Navigator.pop(context);
                      },
                    ),
                    SizedBox(height: 12),
                    _SelectionOption(
                      title: 'Mis Recetas'.tr.tr,
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
              SizedBox(height: 48), // Bottom spacing
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageScreenDialog(BuildContext context, String currentLanguage) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
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
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Idioma / Language'.tr,
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
                      title: 'Español'.tr,
                      icon: CupertinoIcons.globe,
                      isSelected: currentLanguage == 'es',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _changeLanguage(context, 'es');
                      },
                    ),
                    const SizedBox(height: 12),
                    _SelectionOption(
                      title: 'English'.tr,
                      icon: CupertinoIcons.globe,
                      isSelected: currentLanguage == 'en',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _changeLanguage(context, 'en');
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

  void _changeLanguage(BuildContext context, String lang) async {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              DefaultTextStyle(
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                child: Text(
                  lang == 'en' ? 'Applying language...' : 'Aplicando idioma...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(decoration: TextDecoration.none),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Store navigator before awaiting, so we can pop the dialog even if context unmounts
    final navigator = Navigator.of(context, rootNavigator: true);

    // Wait for the simulated loading & the actual language setting logic
    await Future.delayed(const Duration(milliseconds: 1000));
    await SettingsManager.setLanguage(lang);

    navigator.pop();
  }
}

class _SelectionOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDestructive;
  final Color? iconColor;

  const _SelectionOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isDestructive = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = isDestructive ? Colors.red : theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : theme.brightness == Brightness.dark
              ? theme.cardColor
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor
                    : isDestructive
                    ? Colors.red.withValues(alpha: 0.15)
                    : (iconColor != null)
                    ? iconColor!.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? (isDestructive ? Colors.white : Colors.black)
                    : (isDestructive
                          ? Colors.red
                          : (iconColor ?? theme.iconTheme.color)),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? activeColor
                      : (isDestructive ? Colors.red : null),
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

class _DietarySettingsPage extends StatelessWidget {
  const _DietarySettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Filtros Dietéticos'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                'Selecciona las restricciones que coincidan con tus preferencias (ej: si eres vegetariano, selecciona "vegetariano"). Añadirá un indicador rojo a las recetas que no cumplen con estas restricciones.'
                    .tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ValueListenableBuilder<Set<DietaryRestriction>>(
              valueListenable: SettingsManager.dietaryDefaults,
              builder: (context, defaults, child) {
                final restrictions = DietaryRestriction.values.toList();

                return _SettingsSection(
                  title: 'RESTRICCIONES'.tr.tr,
                  children: List.generate(restrictions.length, (index) {
                    final restriction = restrictions[index];
                    final isSelected = defaults.contains(restriction);
                    return _SettingsTile(
                      title: restriction.displayName,
                      subtitle: restriction
                          .description, // Added description for clarity
                      isSwitch: true,
                      switchValue: isSelected,
                      onSwitchChanged: (_) =>
                          SettingsManager.toggleDietaryDefault(restriction),
                      lastItem: index == restrictions.length - 1,
                    );
                  }),
                );
              },
            ),
            SizedBox(height: 24),
            ValueListenableBuilder<Set<String>>(
              valueListenable: SettingsManager.customDietaryDefaults,
              builder: (context, customDefaults, child) {
                final allCustomTags =
                    RecipeManager.allCustomDietaryTags.toList()..sort();
                if (allCustomTags.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: [
                    _SettingsSection(
                      title: 'ETIQUETAS PERSONALIZADAS'.tr.tr,
                      children: List.generate(allCustomTags.length, (index) {
                        final tag = allCustomTags[index];
                        final isSelected = customDefaults.contains(tag);
                        return _SettingsTile(
                          title: tag,
                          isSwitch: true,
                          switchValue: isSelected,
                          onSwitchChanged: (_) =>
                              SettingsManager.toggleCustomDietaryDefault(tag),
                          lastItem: index == allCustomTags.length - 1,
                        );
                      }),
                    ),
                    SizedBox(height: 24),
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
                      title: 'OPCIONES'.tr.tr,
                      children: [
                        _SettingsTile(
                          title: 'Aplicar a recetas predeterminadas'.tr.tr,
                          subtitle:
                              'Mostrar indicador rojo también en recetas incluidas en la app'
                                  .tr
                                  .tr
                                  .tr,
                          isSwitch: true,
                          switchValue: applyToDefaults,
                          onSwitchChanged: (value) =>
                              SettingsManager.setApplyDietaryToDefaults(value),
                          lastItem: false,
                        ),
                        _SettingsTile(
                          title: 'Ocultar recetas incompatibles'.tr.tr,
                          subtitle:
                              'No mostrar recetas que no cumplan con los filtros'
                                  .tr
                                  .tr
                                  .tr,
                          isSwitch: true,
                          switchValue: hideIncompatible,
                          onSwitchChanged: (val) =>
                              SettingsManager.setHideIncompatibleRecipes(val),

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
          ? Column(
              children: [
                SizedBox(height: 72),
                Expanded(
                  child: _EmptyStateWidget(
                    icon: CupertinoIcons.star_slash,
                    title: 'Sin valoraciones'.tr.tr,
                    subtitle: 'Valora recetas para verlas aquí'.tr.tr.tr,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortOption,
                            isDense: true,
                            icon: Icon(Icons.sort, size: 20),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'recent',
                                child: Text('Más recientes'.tr),
                              ),
                              DropdownMenuItem(
                                value: 'highest',
                                child: Text('Mejor valoradas'.tr),
                              ),
                              DropdownMenuItem(
                                value: 'lowest',
                                child: Text('Peor valoradas'.tr),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(16),
                            dropdownColor:
                                theme.colorScheme.surfaceContainerHigh,
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

class _AiSettingsPage extends StatefulWidget {
  @override
  State<_AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<_AiSettingsPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _apiEndpointController = TextEditingController();
  String _provider = 'gemini';

  @override
  void initState() {
    super.initState();
    _provider = SettingsManager.aiProvider.value.isEmpty
        ? 'gemini'
        : SettingsManager.aiProvider.value;
    _apiKeyController.text = SettingsManager.aiApiKey.value;
    _apiEndpointController.text = SettingsManager.aiApiEndpoint.value.isEmpty
        ? 'https://api.openai.com/v1/chat/completions'
        : SettingsManager.aiApiEndpoint.value;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiEndpointController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await SettingsManager.setAiProvider(_provider);
    await SettingsManager.setAiApiKey(_apiKeyController.text.trim());
    await SettingsManager.setAiApiEndpoint(_apiEndpointController.text.trim());
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _openLink(String urlString) async {
    final url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace'.tr)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración de IA'.tr),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _save,
            tooltip: 'Guardar'.tr,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            CupertinoIcons.sparkles,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: 16),
          Text(
            'Escaneo de Recetas Inteligente'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Para que la aplicación pueda leer fotos de recetas y convertirlas automáticamente en texto, necesitas conectar un servicio de Inteligencia Artificial.'
                .tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          SizedBox(height: 32),

          Text(
            '1. Elige tu proveedor de IA'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text('Google Gemini (Recomendado, Gratis)'.tr),
                  value: 'gemini',
                  groupValue: _provider,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (val) {
                    setState(() => _provider = val!);
                  },
                ),
                RadioListTile<String>(
                  title: Text('OpenAI / Otros compatibles'.tr),
                  value: 'openai',
                  groupValue: _provider,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (val) {
                    setState(() => _provider = val!);
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 32),

          Text(
            '2. Consigue tu Clave (API Key)'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          if (_provider == 'gemini') ...[
            Text(
              'Gemini ofrece una clave gratuita y es muy fácil de obtener. Solo entra a Google AI Studio pulsando el botón de abajo, inicia sesión con tu cuenta de Google, y pulsa en "Get API key" o "Crear clave de API".'
                  .tr,
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () =>
                  _openLink('https://aistudio.google.com/app/apikey'),
              icon: Icon(Icons.open_in_new),
              label: Text('Obtener clave de Gemini'.tr),
            ),
          ] else ...[
            Text(
              'Para usar OpenAI (ChatGPT) necesitas una cuenta de desarrollador de pago con saldo en platform.openai.com. También puedes usar servicios compatibles como OpenRouter editando el Endpoint.'
                  .tr,
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () =>
                  _openLink('https://platform.openai.com/api-keys'),
              icon: Icon(Icons.open_in_new),
              label: Text('Obtener clave de OpenAI'.tr),
            ),
          ],
          SizedBox(height: 32),

          Text(
            '3. Pega tu API Key aquí'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: 'Clave de API (API Key)'.tr,
              hintText: _provider == 'gemini' ? 'AIzaSy...' : 'sk-...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            obscureText: true,
          ),

          if (_provider != 'gemini') ...[
            SizedBox(height: 24),
            Text(
              'Opciones Avanzadas'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _apiEndpointController,
              decoration: InputDecoration(
                labelText: 'API Endpoint Url (Opcional)'.tr,
                hintText: 'https://api.openai.com/v1/chat/completions',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
          ],

          SizedBox(height: 48),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              backgroundColor:
                  theme.colorScheme.primary, // using simple primary
            ),
            child: Text(
              'Guardar Configuración'.tr,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _LegalPage extends StatelessWidget {
  const _LegalPage();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Legal'.tr),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Política de Privacidad'),
              Tab(text: 'Términos de Uso'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LegalContent(isPrivacy: true),
            _LegalContent(isPrivacy: false),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    SettingsManager.completeOnboarding();
    // Use pushReplacement to avoid going back to onboarding
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainNavigationPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress Bar (Wizard Style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (index) {
                  final isActive = index <= _currentPage;
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 4,
                    width: isActive ? 32 : 16, // Active step is wider
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(), // Enforce buttons
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildStep1Welcome(theme),
                  _buildStep2Features(theme, isDark),
                  _buildStep3Settings(theme, isDark),
                ],
              ),
            ),

            // Bottom Navigation
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor:
                        theme.colorScheme.onPrimary, // High contrast text
                  ),
                  child: Text(
                    _currentPage == _totalPages - 1
                        ? 'Comenzar a cocinar'.tr
                        : 'Siguiente'.tr,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 1: Welcome
  Widget _buildStep1Welcome(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Image.asset(
              isDark
                  ? 'assets/images/onboarding_logo_dark.png'
                  : 'assets/images/onboarding_logo_light.jpg',
              width: 160,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 32),
          Text(
            'Bienvenido a Recetas'.tr,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Step 2: All Features
  Widget _buildStep2Features(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // No title text requested
          _buildFeatureCard(
            theme,
            isDark,
            icon: CupertinoIcons.search,
            title: 'Búsqueda Inteligente'.tr.tr,
            desc:
                'Encuentra recetas según los ingredientes que ya tengas en tu nevera.'
                    .tr,
          ),
          SizedBox(height: 16),
          _buildFeatureCard(
            theme,
            isDark,
            icon: Icons.auto_awesome,
            title: '+1000 Recetas'.tr.tr,
            desc: 'Una base de datos inmensa de recetas creativas y deliciosas.'
                .tr,
          ),
          SizedBox(height: 16),
          _buildFeatureCard(
            theme,
            isDark,
            icon: CupertinoIcons.add_circled,
            title: 'Tus Propias Recetas'.tr.tr,
            desc: 'Añade y organiza tus creaciones culinarias en un solo lugar.'
                .tr,
          ),
          SizedBox(height: 16),
          _buildFeatureCard(
            theme,
            isDark,
            icon: CupertinoIcons.slider_horizontal_3,
            title: 'Filtros Dietéticos'.tr.tr,
            desc:
                'Vegetariano, vegano, sin gluten... Filtra según tus necesidades.'
                    .tr,
          ),
          SizedBox(height: 16),
          _buildFeatureCard(
            theme,
            isDark,
            icon: CupertinoIcons.moon,
            title: 'Modo Oscuro'.tr.tr,
            desc: 'Una interfaz elegante que cuida tus ojos.'.tr,
          ),
          SizedBox(height: 16),
          _buildFeatureCard(
            theme,
            isDark,
            icon: CupertinoIcons.cloud_upload,
            title: 'Importar/Exportar'.tr.tr,
            desc: 'Haz copias de seguridad de tus recetas y compártelas.'.tr,
          ),
          SizedBox(height: 16),
          _buildFeatureCard(
            theme,
            isDark,
            icon: CupertinoIcons.globe,
            title: 'Búsqueda en Internet'.tr.tr,
            desc: 'Busca recetas en Google desde la aplicación.'.tr,
          ),
          SizedBox(height: 16),
          _buildFeatureCard(
            theme,
            isDark,
            icon: CupertinoIcons.star,
            title: 'Valoración'.tr.tr,
            desc: 'Califica las recetas y organiza tus favoritas.'.tr,
          ),
          SizedBox(height: 16),
          _buildFeatureCard(
            theme,
            isDark,
            icon: CupertinoIcons.shuffle,
            title: 'Receta Aleatoria'.tr.tr,
            desc: '¿Indeciso? Deja que el azar decida qué cocinar hoy.'.tr,
          ),
        ],
      ),
    );
  }

  // Step 3: Initial Setup
  Widget _buildStep3Settings(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Personaliza tu experiencia'.tr,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),

            // Dark Mode Toggle
            ValueListenableBuilder<bool>(
              valueListenable: SettingsManager.isDarkMode,
              builder: (context, isDarkEnabled, _) {
                return _buildSettingToggle(
                  theme,
                  isDark,
                  title: 'Modo Oscuro'.tr.tr,
                  subtitle: 'Activa el tema oscuro.'.tr.tr.tr,
                  icon: isDarkEnabled
                      ? CupertinoIcons.moon_fill
                      : CupertinoIcons.sun_max_fill,
                  value: isDarkEnabled,
                  onChanged: (v) => SettingsManager.setDarkMode(v),
                );
              },
            ),
            SizedBox(height: 16),

            // Default Recipes
            ValueListenableBuilder<bool>(
              valueListenable: SettingsManager.showDefaultRecipes,
              builder: (context, showDefaults, _) {
                return _buildSettingToggle(
                  theme,
                  isDark,
                  title: 'Recetas Predeterminadas'.tr.tr,
                  subtitle: 'Carga nuestras +1000 recetas iniciales.'.tr.tr.tr,
                  icon: Icons.book,
                  value: showDefaults,
                  onChanged: (v) => SettingsManager.setShowDefaults(v),
                );
              },
            ),
            SizedBox(height: 16),

            // Language Setting
            ValueListenableBuilder<String>(
              valueListenable: SettingsManager.language,
              builder: (context, lang, _) {
                final isEnglish = lang == 'en';
                return _buildSettingToggle(
                  theme,
                  isDark,
                  title: 'Idioma / Language'.tr,
                  subtitle: isEnglish
                      ? 'App is in English'
                      : 'La aplicación está en Español',
                  icon: CupertinoIcons.globe,
                  value: isEnglish,
                  onChanged: (v) =>
                      SettingsManager.setLanguage(v ? 'en' : 'es'),
                );
              },
            ),
            SizedBox(height: 16),

            // Dietary Filters
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? theme.cardColor : theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.restaurant_menu,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filtros Dietéticos'.tr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Excluye recetas incompatibles. Elige las que coincidan con tu dieta.'
                                  .tr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ValueListenableBuilder<Set<DietaryRestriction>>(
                    valueListenable: SettingsManager.dietaryDefaults,
                    builder: (context, defaults, _) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: DietaryRestriction.values.map((restriction) {
                          final isSelected = defaults.contains(restriction);
                          return FilterChip(
                            label: Text(restriction.displayName),
                            selected: isSelected,
                            onSelected: (_) =>
                                SettingsManager.toggleDietaryDefault(
                                  restriction,
                                ),
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.withValues(alpha: 0.1),
                            selectedColor: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                            checkmarkColor: theme.colorScheme.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [],
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  desc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingToggle(
    ThemeData theme,
    bool isDark, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

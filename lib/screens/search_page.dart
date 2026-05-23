// ignore_for_file: unused_element
// ignore_for_file: unused_local_variable
// ignore_for_file: use_build_context_synchronously
// ignore_for_file: deprecated_member_use
// ignore_for_file: constant_identifier_names
// ignore_for_file: avoid_print
part of '../main.dart';


class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.showAppBar = true});
  final bool showAppBar;

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
      appBar: widget.showAppBar
          ? AppBar(title: Text('Buscar'.tr))
          : AppBar(toolbarHeight: 0, elevation: 0),
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
    final theme = Theme.of(context);
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
              hintText: 'Buscar recetas por nombre...'.tr,
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
                  title: 'No hay recetas'.tr,
                  subtitle: 'Añade tus propias recetas para verlas aquí'.tr,
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
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
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.brightness == Brightness.dark
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
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  c.displayName,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
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
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(height: 12),
                    Text(
                      category.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

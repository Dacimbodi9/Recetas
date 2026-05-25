part of '../main.dart';

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
                hintText: 'Buscar recetas en @cat...'.tr.replaceAll(
                  '@cat',
                  widget.category.displayName,
                ),
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

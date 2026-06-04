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
              textCapitalization: TextCapitalization.sentences,
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
              decoration: InputDecoration(
                hintText: 'Buscar recetas en @cat...'.tr.replaceAll(
                  '@cat',
                  widget.category.displayName,
                ),
                prefixIcon: const Icon(
                  CupertinoIcons.search,
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
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
                          return _RecipeCard(recipe: r, matchCount: 0)
                              .animate(delay: (index < 12 ? index * 50 : 0).ms)
                              .fade(duration: 400.ms)
                              .slideY(
                                begin: 0.1,
                                end: 0,
                                curve: Curves.easeOutCubic,
                              );
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
              int matches = 0;
              double totalScore = 0.0;
              final matchedRecipeIngredients = <String>[];

              for (final needle in widget.selectedIngredients) {
                double bestIngScore = 0.0;
                String? bestMatch;
                for (final ing in r.ingredients) {
                  final score = _fuzzyMatchScore(ing, needle);
                  if (score > bestIngScore) {
                    bestIngScore = score;
                    bestMatch = ing;
                  }
                }
                if (bestIngScore > 0) {
                  matches++;
                  totalScore += bestIngScore;
                  if (bestMatch != null) matchedRecipeIngredients.add(bestMatch.toLowerCase());
                }
              }
              
              final remainingIngredients = r.ingredients.length - matches;
              return _ScoredRecipe(
                recipe: r,
                matchCount: matches,
                remainingIngredients: remainingIngredients,
                relevanceScore: totalScore,
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
            // Luego ordenar por score de relevancia
            final scoreComparison = b.relevanceScore.compareTo(a.relevanceScore);
            if (scoreComparison != 0) return scoreComparison;
            // Si hay empate, ordenar por ingredientes sobrantes (menor a mayor - mejor resultado)
            return a.remainingIngredients.compareTo(b.remainingIngredients);
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
                    ...results.map((sr) {
                      final idx = results.indexOf(sr);
                      return _RecipeCard(
                            recipe: sr.recipe,
                            matchCount: sr.matchCount,
                            matchedIngredients: sr.matchedIngredients,
                          )
                          .animate(delay: (idx < 12 ? idx * 50 : 0).ms)
                          .fade(duration: 400.ms)
                          .slideY(
                            begin: 0.1,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          );
                    }),
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

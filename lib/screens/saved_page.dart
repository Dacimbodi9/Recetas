part of '../main.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key, this.showAppBar = true});
  final bool showAppBar;

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _inFolder = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: !_inFolder
          ? AppBar(
              title: Text('Guardados'.tr),
              automaticallyImplyLeading: widget.showAppBar,
            )
          : null,
      body: _SavedRecipesView(
        searchController: _searchController,
        searchQuery: _searchQuery,
        onSearchChanged: (value) => setState(() => _searchQuery = value),
        showAppBar: false,
        onFolderChanged: (inFolder) {
          if (_inFolder != inFolder) {
            setState(() {
              _inFolder = inFolder;
            });
          }
        },
      ),
    );
  }
}

class _SavedRecipesView extends StatefulWidget {
  const _SavedRecipesView({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    this.showAppBar = true,
    this.onFolderChanged,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final bool showAppBar;
  final ValueChanged<bool>? onFolderChanged;

  @override
  State<_SavedRecipesView> createState() => _SavedRecipesViewState();
}

class _SavedRecipesViewState extends State<_SavedRecipesView> {
  String? _currentFolderId;
  final List<String> _folderPath = [];
  bool _isSearchVisible = true;
  bool _navigationCooldown = false;

  bool _onScrollNotification(ScrollNotification notification) {
    if (_navigationCooldown) return false;
    if (notification is UserScrollNotification) {
      // Only react to actual user-initiated scrolls
      return false;
    }
    if (notification is OverscrollNotification) {
      if (notification.overscroll < -2.0) {
        if (!_isSearchVisible) setState(() => _isSearchVisible = true);
      } else if (notification.overscroll > 2.0 && widget.searchQuery.isEmpty) {
        if (_isSearchVisible) setState(() => _isSearchVisible = false);
      }
    } else if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta < -2.0) {
        if (!_isSearchVisible) setState(() => _isSearchVisible = true);
      } else if (delta > 2.0 && widget.searchQuery.isEmpty) {
        if (_isSearchVisible) setState(() => _isSearchVisible = false);
      }
    }
    return false;
  }

  void _startNavigationCooldown() {
    _navigationCooldown = true;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _navigationCooldown = false;
      }
    });
  }

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
      _isSearchVisible = false; // Hide search bar when navigating
    });
    widget.onFolderChanged?.call(_currentFolderId != null);
    _startNavigationCooldown();
  }

  void _navigateBack() {
    if (_folderPath.isNotEmpty) {
      setState(() {
        _currentFolderId = _folderPath.removeLast();
        _isSearchVisible = false; // Hide search bar when navigating
      });
    } else {
      setState(() {
        _currentFolderId = null;
        _folderPath.clear();
        _isSearchVisible = false; // Hide search bar when navigating
      });
    }
    widget.onFolderChanged?.call(_currentFolderId != null);
    _startNavigationCooldown();
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
        final scoredRecipes = RecipeManager.favoriteRecipes
            .map((r) => MapEntry(r, _fuzzyMatchScore(r.title, widget.searchQuery)))
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        recipesToShow = scoredRecipes.map((e) => e.key).toList();

        final scoredFolders = RecipeManager.allFolders
            .map((f) => MapEntry(f, _fuzzyMatchScore(f.name, widget.searchQuery)))
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        foldersToShow = scoredFolders.map((e) => e.key).toList();
      } else {
        // NORMAL ROOT VIEW
        final allRecipesInFolders = <String>{};
        for (final folder in RecipeManager.allFolders) {
          allRecipesInFolders.addAll(folder.recipeIds);
        }
        recipesToShow = RecipeManager.favoriteRecipes
            .where((r) => !allRecipesInFolders.contains(r.id))
            .toList();
        foldersToShow = rootFolders;
      }

      return NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _isSearchVisible || widget.searchQuery.isNotEmpty
                  ? 72
                  : 0,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(),
              curve: Curves.easeInOut,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Container(
                  height: 72,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          textCapitalization: TextCapitalization.sentences,
                          controller: widget.searchController,
                          onChanged: widget.onSearchChanged,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: 'Buscar en guardados...'.tr,
                            prefixIcon: const Icon(
                              CupertinoIcons.search,
                              color: Colors.grey,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
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
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                            suffixIcon: widget.searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      CupertinoIcons.xmark_circle_fill,
                                    ),
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
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            CupertinoIcons.add,
                            color: Colors.white,
                          ),
                          onPressed: () => _showCreateFolderDialog(
                            context,
                            _currentFolderId,
                          ),
                          tooltip: 'Crear carpeta'.tr,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child:
                  (foldersToShow.isEmpty &&
                      recipesToShow.isEmpty &&
                      !(_currentFolderId == null &&
                          RecipeManager.recipes.any(
                            (r) => (r.rating ?? 0) > 0,
                          ) &&
                          (widget.searchQuery.isEmpty ||
                              _fuzzyMatch('Valoraciones', widget.searchQuery))))
                  ? Center(
                      child: widget.searchQuery.isNotEmpty
                          ? _EmptyStateWidget(
                              icon: CupertinoIcons.search,
                              title: 'Sin resultados'.tr,
                              subtitle: 'Intenta con otra búsqueda'.tr,
                            )
                          : _EmptyStateWidget(
                              icon: CupertinoIcons.book,
                              title: 'No hay recetas'.tr,
                              subtitle:
                                  'Crea carpetas o guarda recetas para verlas aquí'.tr,
                            ),
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // "Valoraciones" Folder (Fixed at Root)
                        if (_currentFolderId == null &&
                            RecipeManager.recipes.any(
                              (r) => (r.rating ?? 0) > 0,
                            ) &&
                            (widget.searchQuery.isEmpty ||
                                _fuzzyMatch(
                                  'Valoraciones',
                                  widget.searchQuery,
                                )))
                          _ValoracionesFolderCard(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const RatedRecipesPage(),
                                    ),
                                  );
                                },
                              )
                              .animate()
                              .fade(duration: 400.ms)
                              .slideY(
                                begin: 0.1,
                                end: 0,
                                curve: Curves.easeOutCubic,
                              ),
                        // Folders
                        ...foldersToShow.map((folder) {
                          final idx = foldersToShow.indexOf(folder);
                          return _FolderCard(
                                folder: folder,
                                onTap: () => _navigateToFolder(folder.id),
                                onLongPress: () =>
                                    _showFolderOptions(context, folder),
                              )
                              .animate(delay: (idx < 12 ? idx * 50 + 50 : 0).ms)
                              .fade(duration: 400.ms)
                              .slideY(
                                begin: 0.1,
                                end: 0,
                                curve: Curves.easeOutCubic,
                              );
                        }),
                        // Recipes
                        ...recipesToShow.map((recipe) {
                          final idx = recipesToShow.indexOf(recipe);
                          return _RecipeCard(
                                recipe: recipe,
                                matchCount: 0,
                                showFolderOptions: true,
                              )
                              .animate(
                                delay:
                                    (idx * 50 + foldersToShow.length * 50 + 100)
                                        .ms,
                              )
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
          ],
        ),
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
        final scoredRecipes = RecipeManager.getRecipesInFolderRecursive(_currentFolderId!)
            .map((r) => MapEntry(r, _fuzzyMatchScore(r.title, widget.searchQuery)))
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        recipesToShow = scoredRecipes.map((e) => e.key).toList();
        
        final scoredFolders = RecipeManager.getSubFoldersRecursive(_currentFolderId!)
            .map((f) => MapEntry(f, _fuzzyMatchScore(f.name, widget.searchQuery)))
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        foldersToShow = scoredFolders.map((e) => e.key).toList();
      } else {
        recipesToShow = RecipeManager.getRecipesInFolder(currentFolder);
        foldersToShow = subFolders;
      }

      return NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: Scaffold(
          body: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Pinned Navigation Header
              SliverAppBar(
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
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

              // 2. Animated Search Bar
              SliverToBoxAdapter(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: _isSearchVisible || widget.searchQuery.isNotEmpty
                      ? 72
                      : 0,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  curve: Curves.easeInOut,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Container(
                      height: 72,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        textCapitalization: TextCapitalization.sentences,
                        controller: widget.searchController,
                        onChanged: widget.onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Buscar en @fld...'.tr.replaceAll(
                            '@fld',
                            currentFolder.name,
                          ),
                          prefixIcon: const Icon(
                            CupertinoIcons.search,
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
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
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                          suffixIcon: widget.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    CupertinoIcons.xmark_circle_fill,
                                  ),
                                  onPressed: () {
                                    widget.searchController.clear();
                                    widget.onSearchChanged('');
                                  },
                                )
                              : null,
                        ),
                      ),
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
                      ...foldersToShow.map((folder) {
                        final idx = foldersToShow.indexOf(folder);
                        return _FolderCard(
                              folder: folder,
                              onTap: () => _navigateToFolder(folder.id),
                              onLongPress: () =>
                                  _showFolderOptions(context, folder),
                            )
                            .animate(delay: (idx < 12 ? idx * 50 : 0).ms)
                            .fade(duration: 400.ms)
                            .slideY(
                              begin: 0.1,
                              end: 0,
                              curve: Curves.easeOutCubic,
                            );
                      }),
                      // Recipes
                      ...recipesToShow.map((recipe) {
                        final idx = recipesToShow.indexOf(recipe);
                        return _RecipeCard(
                              recipe: recipe,
                              matchCount: 0,
                              showFolderOptions: true,
                            )
                            .animate(
                              delay: (idx * 50 + foldersToShow.length * 50).ms,
                            )
                            .fade(duration: 400.ms)
                            .slideY(
                              begin: 0.1,
                              end: 0,
                              curve: Curves.easeOutCubic,
                            );
                      }),
                    ]),
                  ),
                ),
            ],
          ),
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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(CupertinoIcons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Valoraciones'.tr),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(CupertinoIcons.sort_down),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: theme.colorScheme.surfaceContainerHigh,
            onSelected: (val) {
              setState(() => _sortOption = val);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'recent',
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.clock,
                      size: 20,
                      color: _sortOption == 'recent'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Más recientes'.tr,
                      style: TextStyle(
                        color: _sortOption == 'recent'
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        fontWeight: _sortOption == 'recent'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'highest',
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.star_fill,
                      size: 20,
                      color: _sortOption == 'highest'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Mejor valoradas'.tr,
                      style: TextStyle(
                        color: _sortOption == 'highest'
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        fontWeight: _sortOption == 'highest'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'lowest',
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.star,
                      size: 20,
                      color: _sortOption == 'lowest'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Peor valoradas'.tr,
                      style: TextStyle(
                        color: _sortOption == 'lowest'
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        fontWeight: _sortOption == 'lowest'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ratedRecipes.isEmpty
          ? Center(
              child: _EmptyStateWidget(
                icon: CupertinoIcons.star_slash,
                title: 'Sin valoraciones'.tr.tr,
                subtitle: 'Valora recetas para verlas aquí'.tr.tr.tr,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: ratedRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = ratedRecipes[index];
                      return _RecipeCard(
                            recipe: recipe,
                            matchCount: 0,
                            heroTag: 'rated_${recipe.title}',
                            showRating: true,
                          )
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
              ],
            ),
    );
  }
}

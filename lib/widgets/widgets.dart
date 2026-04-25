// ignore_for_file: unused_element
// ignore_for_file: unused_local_variable
// ignore_for_file: prefer_const_constructors_in_immutables
// ignore_for_file: type_annotate_public_apis
// ignore_for_file: avoid_types_as_parameter_names
// ignore_for_file: use_build_context_synchronously
// ignore_for_file: deprecated_member_use
// ignore_for_file: constant_identifier_names
part of '../main.dart';

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
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [],
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
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  folder.icon,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(folder.name, style: theme.textTheme.titleLarge),
                    SizedBox(height: 4),
                    Text(
                      '$recipeCount receta${recipeCount != 1 ? 's' : ''} • $subFolderCount subcarpeta${subFolderCount != 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_right),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor ingresa un nombre para la carpeta'.tr),
          ),
        );
      }
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
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        widget.folderToEdit != null ? 'Editar carpeta'.tr : 'Crear carpeta'.tr,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre de la carpeta'.tr,
                hintText: 'Ej: Postres'.tr.tr,
              ),
              autofocus: true,
            ),
            SizedBox(height: 20),
            Text('Seleccionar icono'.tr, style: theme.textTheme.titleSmall),
            SizedBox(height: 12),
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
                          ? theme.colorScheme.primary.withValues(alpha: 0.3)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
          child: Text('Cancelar'.tr),
        ),
        FilledButton(
          onPressed: _saveFolder,
          child: Text(widget.folderToEdit != null ? 'Guardar'.tr : 'Crear'.tr),
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
            leading: Icon(CupertinoIcons.pencil),
            title: Text('Editar carpeta'.tr),
            onTap: () {
              if (context.mounted) Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => _CreateFolderDialog(folderToEdit: folder),
              );
            },
          ),
          ListTile(
            leading: Icon(CupertinoIcons.delete, color: Colors.red),
            title: Text(
              'Eliminar carpeta'.tr,
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              if (context.mounted) Navigator.of(context).pop();
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
        title: Text('Eliminar carpeta'.tr),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${folder.name}"? Esto también eliminará todas las subcarpetas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'.tr),
          ),
          FilledButton(
            onPressed: () async {
              await RecipeManager.deleteFolder(folder.id);
              if (context.mounted) {
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar'.tr),
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
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              folderId == null
                  ? 'Receta movida fuera de carpetas'
                  : 'Receta movida a carpeta',
            ),
          ),
        );
      }
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
              'Mover a carpeta'.tr,
              style: theme.textTheme.titleLarge,
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: Icon(CupertinoIcons.folder),
                  title: Text('Sin carpeta'.tr),
                  trailing: currentFolderId == null
                      ? Icon(CupertinoIcons.checkmark, color: Colors.green)
                      : null,
                  onTap: () => _moveToFolder(context, null),
                ),
                Divider(),
                ...allFolders.map((folder) {
                  final isSelected = currentFolderId == folder.id;
                  return ListTile(
                    leading: Icon(folder.icon),
                    title: Text(folder.name),
                    trailing: isSelected
                        ? Icon(CupertinoIcons.checkmark, color: Colors.green)
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
      title: Text('Filtros dietéticos'.tr),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Restricciones estándar:'.tr,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 8),
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
                SizedBox(height: 16),
                Text(
                  'Etiquetas personalizadas:'.tr,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 8),
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
          child: Text('Cancelar'.tr),
        ),
        FilledButton(
          onPressed: () {
            widget.onFiltersChanged(_selectedFilters, _selectedCustomFilters);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text('Aplicar'.tr),
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
          Icon(CupertinoIcons.exclamationmark_circle, size: 42),
          SizedBox(height: 12),
          Text(
            'No existen recetas'.tr,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'Se intentó con: ${selectedIngredients.join(', ')}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: [],
      ),
      child: OpenContainer(
        transitionDuration: Duration(milliseconds: 500),
        openBuilder: (context, _) =>
            RecipeDetailPage(recipe: recipe, heroTag: heroTag),
        closedElevation: 0,
        openElevation: 0,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        closedColor: Colors.transparent,
        middleColor: theme.cardColor,
        tappable: false,
        closedBuilder: (context, openContainer) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? theme.cardColor
                  : theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                InkWell(
                  onTap: openContainer,
                  onLongPress:
                      showFolderOptions && RecipeManager.isFavorite(recipe)
                      ? () => _showRecipeFolderMenu(context)
                      : isPersonalized
                      ? () => _showDeleteDialog(context)
                      : null,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: matchedIngredients.isEmpty
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: [
                        _RecipeAvatar(
                          title: recipe.title,
                          imagePath: displayImagePath,
                          heroTag: recipe.title,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: matchedIngredients.isEmpty
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
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
                                SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: recipe.ingredients.map((i) {
                                    final isMatch = matchedIngredients.contains(
                                      i.toLowerCase(),
                                    );
                                    return Chip(
                                      label: Text(
                                        i,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isMatch
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isMatch
                                              ? (Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black)
                                              : theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.6),
                                        ),
                                      ),
                                      backgroundColor: isMatch
                                          ? theme.colorScheme.primary
                                                .withValues(alpha: 0.3)
                                          : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.05),
                                      side: BorderSide(
                                        color: isMatch
                                            ? theme.colorScheme.primary
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              if (showRating && (recipe.rating ?? 0) > 0) ...[
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    ...List.generate(5, (index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 2,
                                        ),
                                        child: _PartialStar(
                                          filledPercentage:
                                              (recipe.rating! - index).clamp(
                                                0.0,
                                                1.0,
                                              ),
                                          size: 14,
                                        ),
                                      );
                                    }),
                                    SizedBox(width: 4),
                                    Text(
                                      recipe.rating!.toStringAsFixed(1),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
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
                if (!isDietaryCompatible)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar receta'.tr),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${recipe.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'.tr),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await RecipeManager.removeRecipe(recipe);
                if (context.mounted) Navigator.of(context).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Receta "${recipe.title}" eliminada'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) Navigator.of(context).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar la receta'.tr)),
                  );
                }
              }
            },
            child: Text('Eliminar'.tr),
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
    final bg = theme.colorScheme.primary.withValues(alpha: 0.2);
    final border = theme.colorScheme.primary.withValues(alpha: 0.35);

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
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFallback(title),
                              ),
                            ),
                          )
                        : Image.asset(
                            imagePath!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFallback(title),
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
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFallback(title),
                              ),
                            ),
                          )
                        : Image.file(
                            File(imagePath!),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFallback(title),
                          )),
            )
          : _buildFallback(title),
    );
  }

  Widget _buildFallback(String title) {
    return Center(
      child: Text(
        title.substring(0, 1).toUpperCase(),
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            fact.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 6),
          Text(
            '${fact.formattedAmount} ${fact.unit}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
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
                  final double page = controller.hasClients
                      ? (controller.page ?? selectedIndex.toDouble())
                      : selectedIndex.toDouble();
                  final double left = page * tabWidth;

                  return Positioned(
                    left: left,
                    top: 4,
                    bottom: 4,
                    width: tabWidth,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
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
                      behavior: HitTestBehavior
                          .translucent, // Ensure tap targets whole area
                      child: Center(
                        child: AnimatedBuilder(
                          animation: controller,
                          builder: (context, child) {
                            final double page = controller.hasClients
                                ? (controller.page ?? selectedIndex.toDouble())
                                : selectedIndex.toDouble();
                            // Calculate opacity/color based on distance from current page
                            final double distance = (page - index).abs();
                            final bool isSelected = distance < 0.5;

                            return Text(
                              tabs[index],
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimary
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
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

class _IngredientsViewState extends State<_IngredientsView>
    with AutomaticKeepAliveClientMixin {
  final Set<String> _checkedIngredients = {};

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.recipe.detailedIngredients.isNotEmpty ||
                widget.recipe.ingredients.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '${widget.recipe.detailedIngredients.isNotEmpty ? widget.recipe.detailedIngredients.length : widget.recipe.ingredients.length} ${'Ingredientes'.tr}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            if (widget.recipe.detailedIngredients.isNotEmpty)
              ...widget.recipe.detailedIngredients.map((ingredient) {
                final key = ingredient.name;
                final isChecked = _checkedIngredients.contains(key);

                return _IngredientRow(
                  name: ingredient.name,
                  quantity: ingredient.quantity,
                  isChecked: isChecked,
                  onTap: () {
                    setState(() {
                      if (isChecked) {
                        _checkedIngredients.remove(key);
                      } else {
                        _checkedIngredients.add(key);
                      }
                    });
                  },
                );
              })
            else if (widget.recipe.ingredients.isNotEmpty)
              // Fallback for old simple string list
              ...widget.recipe.ingredients.map((ingredient) {
                final isChecked = _checkedIngredients.contains(ingredient);
                return _IngredientRow(
                  name: ingredient,
                  quantity: '',
                  isChecked: isChecked,
                  onTap: () {
                    setState(() {
                      if (isChecked) {
                        _checkedIngredients.remove(ingredient);
                      } else {
                        _checkedIngredients.add(ingredient);
                      }
                    });
                  },
                );
              })
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.cart,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.2,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay ingredientes'.tr,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LikeButton extends StatefulWidget {
  const _LikeButton({required this.isFavorite, required this.onTap});
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite && !oldWidget.isFavorite) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(
          widget.isFavorite
              ? CupertinoIcons.bookmark_fill
              : CupertinoIcons.bookmark,
          color: widget.isFavorite ? Colors.amber : null,
        ),
        onPressed: () {
          // Trigger animation if turning ON, or just toggle
          // The parent handles the state change, so we rely on didUpdateWidget for the 'filling' animation.
          // But we can also animate on tap for immediate feedback.
          // If we want a "pop" effect on both check/uncheck, we can run it.
          // Usually hearts pop when filled.
          if (!widget.isFavorite) {
            _controller.forward(from: 0.0);
          }
          widget.onTap();
        },
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.name,
    required this.quantity,
    required this.isChecked,
    required this.onTap,
  });

  final String name;
  final String quantity;
  final bool isChecked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 300),
          opacity: isChecked ? 0.6 : 1.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: isChecked,
                  onChanged: (_) => onTap(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  activeColor: theme.colorScheme.primary,
                  checkColor: theme.colorScheme.onPrimary,
                  side: BorderSide(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyLarge?.copyWith(
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      color: isChecked
                          ? theme.textTheme.bodyLarge?.color?.withValues(
                              alpha: 0.5,
                            )
                          : theme.textTheme.bodyLarge?.color,
                    ),
                    children: [
                      TextSpan(
                        text: name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (quantity.isNotEmpty)
                        TextSpan(
                          text: '  $quantity',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: isChecked ? 0.3 : 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

    return SizedBox(
      width: double.infinity,
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
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.5,
                                ),
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
                          SizedBox(width: 12),
                          Expanded(child: _buildStepText(step, theme)),
                        ],
                      ),
                    );
                  }).toList()
                : [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.square_list,
                              size: 48,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.2,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No hay pasos disponibles para esta receta.'.tr,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

            SizedBox(height: 32),
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
              style: TextStyle(fontWeight: FontWeight.bold),
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

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dietary Restrictions
            // Dietary Restrictions
            if (recipe.dietaryRestrictions.isNotEmpty ||
                recipe.customDietaryTags.isNotEmpty) ...[
              Text(
                'Restricciones dietéticas'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...recipe.dietaryRestrictions.map(
                    (restriction) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Text(
                        restriction.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  ...recipe.customDietaryTags.map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
            ],

            // Nutrition Facts
            if (recipe.nutritionFacts.isNotEmpty) ...[
              Text(
                'Información nutricional'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: recipe.nutritionFacts
                    .map((fact) => _NutritionFactCard(fact: fact))
                    .toList(),
              ),
            ],

            SizedBox(height: 32),
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
            color: Colors.white.withValues(alpha: 0.3),
          ),
          SizedBox(height: 8),
          Text(
            'Toca para añadir foto'.tr,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _SettingsSection({this.title, required this.children});

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
                ? theme.cardColor
                : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: theme.brightness == Brightness.light
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(children: children),
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
            title: Text(
              title,
              style: TextStyle(
                color: textColor ?? theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  )
                : null,
            value: switchValue,
            onChanged: onSwitchChanged,
            secondary: icon != null
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: effectiveIconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: effectiveIconColor, size: 18),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 2,
            ),
            activeThumbColor: theme.colorScheme.primary,
          ),
          if (!lastItem)
            Divider(
              height: 1,
              indent: 56,
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
            ),
        ],
      );
    } else {
      return Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: TextStyle(
                color: textColor ?? theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  )
                : null,
            leading: icon != null
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: effectiveIconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: effectiveIconColor, size: 18),
                  )
                : null,
            trailing: trailing,
            onTap: onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 2,
            ),
          ),
          if (!lastItem)
            Divider(
              height: 1,
              indent: 56,
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
            ),
        ],
      );
    }
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
            final double singleStarWidth =
                starSize; // Roughly the width of one icon
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
  const _PartialStar({required this.filledPercentage, required this.size});

  final double filledPercentage;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Icon(
          Icons.star_rounded,
          color: Colors.grey.withValues(alpha: 0.3),
          size: size,
        ),
        if (filledPercentage > 0)
          ClipRect(
            clipper: _StarClipper(filledPercentage),
            child: Icon(Icons.star_rounded, color: Colors.amber, size: size),
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

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget({
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
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

Datos del Usuario (Recetas y Preferencias): Todas las recetas, ingredientes, configuraciones dietéticas y guardados creados dentro de la aplicación se almacenan localmente en la memoria interna de su dispositivo (utilizando SharedPreferences y almacenamiento de archivos local). Estos datos nunca se transmiten a nosotros ni a terceros.

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

User Data (Recipes & Preferences): All recipes, ingredients, dietary settings, and saved recipes created within the app are stored locally on your device’s internal memory using SharedPreferences and local file storage. This data is never transmitted to us or any third party.

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
          child: Icon(_getIcon(index), size: starSize, color: Colors.amber),
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

class PremiumRatingButton extends StatelessWidget {
  final Recipe recipe;

  const PremiumRatingButton({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = recipe.rating ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tu valoración'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                rating > 0 ? rating.toStringAsFixed(1) : 'Sin valorar'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
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

// --- Onboarding Flow ---

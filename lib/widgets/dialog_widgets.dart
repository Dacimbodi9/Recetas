import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:recetas/l10n.dart';
import 'package:recetas/models/models.dart';
import 'package:recetas/services/recipe_manager.dart';
import 'dart:async';



class CreateFolderDialog extends StatefulWidget {
  const CreateFolderDialog({super.key, this.parentId, this.folderToEdit});

  final String? parentId;
  final FavoriteFolder? folderToEdit;

  @override
  State<CreateFolderDialog> createState() => CreateFolderDialogState();
}

class CreateFolderDialogState extends State<CreateFolderDialog> {
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
              textCapitalization: TextCapitalization.sentences,
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre de la carpeta'.tr,
                hintText: 'Ej: Postres'.tr,
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

class FolderOptionsSheet extends StatelessWidget {
  const FolderOptionsSheet({super.key, required this.folder});

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
                builder: (context) => CreateFolderDialog(folderToEdit: folder),
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
          'Â¿EstÃ¡s seguro de que quieres eliminar "${folder.name}"? Esto tambiÃ©n eliminarÃ¡ todas las subcarpetas.',
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

class RecipeFolderMenu extends StatelessWidget {
  const RecipeFolderMenu({super.key, required this.recipe});

  final Recipe recipe;

  Future<void> _moveToFolder(BuildContext context, String? folderId) async {
    // Remove from all folders first
    for (final folder in RecipeManager.allFolders) {
      if (folder.recipeIds.contains(recipe.id)) {
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
      if (folder.recipeIds.contains(recipe.id)) {
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

class DietaryFilterDialog extends StatefulWidget {
  const DietaryFilterDialog({super.key, 
    required this.selectedFilters,
    required this.selectedCustomFilters,
    required this.onFiltersChanged,
  });

  final Set<DietaryRestriction> selectedFilters;
  final Set<String> selectedCustomFilters;
  final void Function(Set<DietaryRestriction>, Set<String>) onFiltersChanged;

  @override
  State<DietaryFilterDialog> createState() => DietaryFilterDialogState();
}

class DietaryFilterDialogState extends State<DietaryFilterDialog> {
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
      title: Text('Filtros dietÃ©ticos'.tr),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Restricciones estÃ¡ndar:'.tr,
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

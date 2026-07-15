import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:recetas/l10n.dart';
import 'package:recetas/models/models.dart';
import 'package:recetas/services/recipe_manager.dart';
import 'package:recetas/screens/recipe_details.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';


import 'package:recetas/widgets/widgets.dart';

class FolderCard extends StatelessWidget {
  const FolderCard({super.key, 
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
    final recipeCount = RecipeManager.getRecipesInFolderRecursive(
      folder.id,
    ).length;

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
                      '$recipeCount ${recipeCount == 1 ? 'receta'.tr : 'recetas'.tr}',
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

class ValoracionesFolderCard extends StatelessWidget {
  const ValoracionesFolderCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Count rated recipes
    final ratedCount = RecipeManager.recipes
        .where((r) => (r.rating ?? 0) > 0)
        .length;

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
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  CupertinoIcons.star_fill,
                  color: Colors.amber,
                  size: 28,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Valoraciones'.tr, style: theme.textTheme.titleLarge),
                    SizedBox(height: 4),
                    Text(
                      '$ratedCount ${ratedCount == 1 ? 'receta'.tr : 'recetas'.tr}',
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

class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, 
    required this.recipe,
    required this.matchCount,
    this.matchedIngredients = const [],
    this.showFolderOptions = false,
    this.heroTag,
    this.showRating = false,
    this.trailing,
  });

  final Recipe recipe;
  final int matchCount;
  final List<String> matchedIngredients;
  final bool showFolderOptions;
  final String? heroTag;
  final bool showRating;
  final Widget? trailing;

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
          child: Container(
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RecipeDetailPage(recipe: recipe, heroTag: null),
                      ),
                    );
                  },
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
                        RecipeAvatar(
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
                                        child: PartialStar(
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
                        if (trailing != null) trailing!,
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
          ),
        )
        .animate()
        .fade(duration: 400.ms)
        .slideY(
          begin: 0.03,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar receta'.tr),
        content: Text(
          '${'¿Estás seguro de que quieres eliminar'.tr} "${recipe.title}"?',
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
                      content: Text('${'Receta'.tr} "${recipe.title}" ${'eliminada'.tr}'),
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
      builder: (context) => RecipeFolderMenu(recipe: recipe),
    );
  }
}

class RecipeAvatar extends StatelessWidget {
  const RecipeAvatar({super.key, required this.title, this.imagePath, this.heroTag});

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
                  ? Image.asset(
                      imagePath!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallback(title),
                    )
                  : Image.file(
                      File(imagePath!),
                      width: 56,
                      height: 56,
                      cacheWidth: 150, // Decodes at lower resolution to save RAM
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallback(title),
                    ),
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

class IngredientsView extends StatefulWidget {
  const IngredientsView({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<IngredientsView> createState() => IngredientsViewState();
}

class IngredientsViewState extends State<IngredientsView>
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

                return IngredientRow(
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
                return IngredientRow(
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

class IngredientRow extends StatelessWidget {
  const IngredientRow({super.key, 
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
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
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

class InstructionsView extends StatelessWidget {
  const InstructionsView({super.key, required this.recipe});

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

class InfoView extends StatelessWidget {
  const InfoView({super.key, required this.recipe});

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
                    .map((fact) => NutritionFactCard(fact: fact))
                    .toList(),
              ),
            ],

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

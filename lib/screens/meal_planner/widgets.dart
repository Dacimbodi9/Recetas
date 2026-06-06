import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:recetas/l10n.dart';
import 'package:recetas/models/models.dart';
import 'package:recetas/services/recipe_manager.dart';
import 'package:recetas/screens/recipe_details.dart';


class TodayMealRow extends StatelessWidget {
  const TodayMealRow({super.key, 
    required this.mealType,
    required this.meals,
    required this.onToggle,
    required this.onSwap,
    required this.onRemove,
  });

  final MealType mealType;
  final List<PlannedMeal> meals;
  final void Function(PlannedMeal) onToggle;
  final void Function(PlannedMeal) onSwap;
  final void Function(PlannedMeal) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    mealType.icon,
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  mealType.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          ...meals.map((meal) {
            final recipe = RecipeManager.recipes
                .where((r) => r.id == meal.recipeId)
                .firstOrNull;
            if (recipe == null) return const SizedBox();

            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Dismissible(
                key: ValueKey(
                '${meal.dateKey}_${meal.mealType.name}_${meal.recipeId}_swipe',
              ),
              direction: DismissDirection.horizontal,
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.check,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              secondaryBackground: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  CupertinoIcons.delete,
                  color: Colors.red.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  onToggle(meal);
                  return false; // Rebounds after swipe
                }
                return true; // Deletes
              },
              onDismissed: (_) => onRemove(meal),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    // Recipe title
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailPage(recipe: recipe),
                            ),
                          );
                        },
                        child: Text(
                          recipe.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            decoration: meal.completed
                                ? TextDecoration.lineThrough
                                : null,
                            color: meal.completed
                                ? Colors.grey
                                : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                    // Swap button
                    IconButton(
                      icon: Icon(
                        CupertinoIcons.arrow_2_squarepath,
                        size: 16,
                        color: Colors.grey.withValues(alpha: 0.6),
                      ),
                      onPressed: () => onSwap(meal),
                      tooltip: 'Cambiar'.tr,
                      visualDensity: VisualDensity.compact,
                    ),
                    // Check / complete
                    GestureDetector(
                      onTap: () => onToggle(meal),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: meal.completed
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: meal.completed
                                ? theme.colorScheme.primary
                                : Colors.grey.withValues(alpha: 0.35),
                            width: 2,
                          ),
                        ),
                        child: meal.completed
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Meal Planner – Day Detail Page
// ─────────────────────────────────────────────


class MealSlotCard extends StatelessWidget {
  const MealSlotCard({super.key, 
    required this.mealType,
    required this.meals,
    required this.onAdd,
    required this.onToggle,
    required this.onSwap,
    required this.onRemove,
  });

  final MealType mealType;
  final List<PlannedMeal> meals;
  final VoidCallback onAdd;
  final void Function(PlannedMeal) onToggle;
  final void Function(PlannedMeal) onSwap;
  final void Function(PlannedMeal) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    mealType.icon,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mealType.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    CupertinoIcons.plus_circle,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  onPressed: onAdd,
                  tooltip: 'Añadir'.tr,
                ),
              ],
            ),
          ),

          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 52),
              child: Row(
                children: [
                  Text(
                    'Sin planificar'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          else
            ...meals.map((meal) {
              final recipe = RecipeManager.recipes
                  .where((r) => r.id == meal.recipeId)
                  .firstOrNull;
              if (recipe == null) return const SizedBox.shrink();
              return Dismissible(
                key: ValueKey(
                  '${meal.dateKey}_${meal.mealType.name}_${meal.recipeId}_dismiss',
                ),
                direction: DismissDirection.horizontal,
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.check, color: theme.colorScheme.primary),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    CupertinoIcons.delete,
                    color: Colors.red.withValues(alpha: 0.7),
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    onToggle(meal);
                    return false; // Rebounds
                  }
                  return true; // Deletes
                },
                onDismissed: (_) => onRemove(meal),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailPage(recipe: recipe),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // Check circle
                        GestureDetector(
                          onTap: () => onToggle(meal),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: meal.completed
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: meal.completed
                                    ? theme.colorScheme.primary
                                    : Colors.grey.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: meal.completed
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            recipe.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              decoration: meal.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: meal.completed
                                  ? Colors.grey
                                  : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        // Swap
                        IconButton(
                          icon: Icon(
                            CupertinoIcons.arrow_2_squarepath,
                            size: 16,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          onPressed: () => onSwap(meal),
                          tooltip: 'Cambiar'.tr,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}



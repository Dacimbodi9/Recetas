import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:recetas/l10n.dart';
import 'package:recetas/models/models.dart';
import 'package:recetas/services/recipe_manager.dart';
import 'package:recetas/services/meal_plan_manager.dart';


import 'package:recetas/screens/meal_planner/widgets.dart';
class DayDetailPage extends StatefulWidget {
  const DayDetailPage({super.key, required this.date});
  final DateTime date;

  @override
  State<DayDetailPage> createState() => DayDetailPageState();
}

class DayDetailPageState extends State<DayDetailPage> {
  @override
  void initState() {
    super.initState();
    MealPlanManager.addListener(_refresh);
  }

  @override
  void dispose() {
    MealPlanManager.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String _formattedDate() {
    final d = widget.date;
    const esDay = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const enDay = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const esMonth = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    const enMonth = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final isEn = AppLocalization.instance.currentLanguage == 'en';
    final dayName = isEn ? enDay[d.weekday - 1] : esDay[d.weekday - 1];
    final monthName = isEn ? enMonth[d.month - 1] : esMonth[d.month - 1];
    return '$dayName, ${d.day} $monthName';
  }

  void _showAddMealSheet(MealType mealType) {
    final allRecipes = RecipeManager.recipes;
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final filtered = searchQuery.isEmpty
                ? allRecipes
                : allRecipes
                      .where(
                        (r) => r.title.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.7,
              decoration: BoxDecoration(
                color: Theme.of(ctx).brightness == Brightness.dark
                    ? const Color(0xFF1C1C1E)
                    : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${'Añadir a'.tr} ${mealType.displayName}',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (v) => setSheet(() => searchQuery = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Buscar recetas por nombre...'.tr,
                        prefixIcon: const Icon(CupertinoIcons.search),
                        filled: true,
                        fillColor: Theme.of(
                          ctx,
                        ).colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(child: Text('No se encontraron recetas'.tr))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final r = filtered[i];
                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(ctx).colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.restaurant,
                                    color: Theme.of(ctx).colorScheme.primary,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  r.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () {
                                  MealPlanManager.addMeal(
                                    PlannedMeal(
                                      date: widget.date,
                                      mealType: mealType,
                                      recipeId: r.id,
                                    ),
                                  );
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final meals = MealPlanManager.getMealsForDate(widget.date);

    return Scaffold(
      appBar: AppBar(title: Text(_formattedDate())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: MealType.values.map((type) {
          final mealsOfType = meals.where((m) => m.mealType == type).toList();
          return MealSlotCard(
            mealType: type,
            meals: mealsOfType,
            onAdd: () => _showAddMealSheet(type),
            onToggle: (m) => MealPlanManager.toggleCompleted(m),
            onSwap: (m) {
              MealPlanManager.removeMeal(m);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Comida eliminada'.tr),
                  action: SnackBarAction(
                    label: 'Deshacer'.tr,
                    onPressed: () async {
                      await MealPlanManager.undoRemoveMeal();
                    },
                  ),
                ),
              );
              _showAddMealSheet(m.mealType);
            },
            onRemove: (m) {
              MealPlanManager.removeMeal(m);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Comida eliminada'.tr),
                  action: SnackBarAction(
                    label: 'Deshacer'.tr,
                    onPressed: () async {
                      await MealPlanManager.undoRemoveMeal();
                    },
                  ),
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Comida eliminada'.tr),
                  action: SnackBarAction(
                    label: 'Deshacer'.tr,
                    onPressed: () async {
                      await MealPlanManager.undoRemoveMeal();
                    },
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

/// Reusable meal-type card used in the day detail page


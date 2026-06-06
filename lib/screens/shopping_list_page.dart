import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:recetas/l10n.dart';
import 'package:recetas/models/models.dart';
import 'package:recetas/services/recipe_manager.dart';
import 'package:recetas/services/meal_plan_manager.dart';
import 'package:recetas/services/shopping_list_manager.dart';
import 'package:recetas/screens/recipe_creation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key, this.showAppBar = true, this.isActive = true});
  final bool showAppBar;
  final bool isActive;

  @override
  State<ShoppingListPage> createState() => ShoppingListPageState();
}

class ShoppingListPageState extends State<ShoppingListPage> {
  List<Map<String, dynamic>> _plannerItems = [];
  final TextEditingController _manualNameController = TextEditingController();
  final TextEditingController _manualQtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _plannerItems = ShoppingListManager.generateFromPlanner();
    ShoppingListManager.addListener(_refresh);
    MealPlanManager.addListener(_onPlanChanged);
  }

  @override
  void didUpdateWidget(covariant ShoppingListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      ShoppingListManager.archiveCheckedItems();
    }
  }

  @override
  void dispose() {
    if (widget.isActive) {
      ShoppingListManager.archiveCheckedItems();
    }
    _manualNameController.dispose();
    _manualQtyController.dispose();
    ShoppingListManager.removeListener(_refresh);
    MealPlanManager.removeListener(_onPlanChanged);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onPlanChanged() {
    if (mounted) {
      setState(() {
        _plannerItems = ShoppingListManager.generateFromPlanner();
      });
    }
  }

  void _regenerate() {
    setState(() {
      _plannerItems = ShoppingListManager.generateFromPlanner();
    });
  }

  void _showAddManualItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddIngredientSearchSheet(),
    );
  }

  /// Groups planner items by IngredientCategory using the existing keyword system
  Map<IngredientCategory?, List<Map<String, dynamic>>> _groupByCategory(
    List<Map<String, dynamic>> items,
  ) {
    final Map<IngredientCategory?, List<Map<String, dynamic>>> grouped = {};

    for (final item in items) {
      IngredientCategory? cat = item['category'] as IngredientCategory?;

      // If no explicit category, try to auto-detect
      if (cat == null) {
        final name = (item['name'] as String).toLowerCase();
        for (final category in IngredientCategory.values) {
          final matches = getIngredientsForCategory(category, [name]);
          if (matches.isNotEmpty) {
            cat = category;
            break;
          }
        }
        // Also check custom mappings
        cat ??= RecipeManager.getCategoryForIngredient(
          (item['name'] as String).toLowerCase(),
        );
      }

      grouped.putIfAbsent(cat, () => []);
      grouped[cat]!.add(item);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final manualItems = ShoppingListManager.manualItems;
    final List<Map<String, dynamic>> combinedItems = [];
    // Deep copy planner items to avoid mutating state directly
    for (final pi in _plannerItems) {
      combinedItems.add({
        ...pi,
        'sources': List<Map<String, String>>.from(pi['sources'] ?? []),
      });
    }

    for (int i = 0; i < manualItems.length; i++) {
      final mi = manualItems[i];
      final name = mi['name'] ?? '';
      final qty = mi['quantity'] ?? '';
      
      final existingIndex = combinedItems.indexWhere((item) => (item['name'] as String).toLowerCase() == name.toLowerCase());
      
      if (existingIndex != -1) {
        final existingSources = combinedItems[existingIndex]['sources'] as List<Map<String, String>>;
        if (qty.isNotEmpty) {
          existingSources.add({
            'recipeName': '',
            'quantity': qty,
            'manualIndex': i.toString(),
          });
        }
      } else {
        IngredientCategory? cat;
        if (mi['category'] != null) {
          try {
            cat = IngredientCategory.values.firstWhere((e) => e.name == mi['category']);
          } catch (_) {}
        }
        combinedItems.add({
          'name': name,
          'category': cat,
          'sources': qty.isNotEmpty ? [{'recipeName': '', 'quantity': qty, 'manualIndex': i.toString()}] : <Map<String, String>>[],
        });
      }
    }

    final allItemNames = combinedItems.map((i) => i['name'] as String).toList();
    final checkedCount = allItemNames
        .where((n) => ShoppingListManager.isChecked(n))
        .length;
    final totalCount = allItemNames.length;

    final groupedPlanner = _groupByCategory(combinedItems);
    // Sort categories: known ones first (by index), null last
    final sortedCategories = groupedPlanner.keys.toList()
      ..sort((a, b) {
        if (a == null && b == null) return 0;
        if (a == null) return 1;
        if (b == null) return -1;
        return a.index.compareTo(b.index);
      });

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: Text('Lista de Compra'.tr))
          : AppBar(toolbarHeight: 0, elevation: 0),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddManualItemSheet,
        child: const Icon(CupertinoIcons.plus),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Progress Bar and Days Ahead ───
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildProgressCard(theme, isDark, checkedCount, totalCount),
                  ),
                  const SizedBox(width: 12),
                  _buildDaysAheadButton(theme, isDark),
                ],
              ),
            ).animate().fade(duration: 400.ms).slideY(
                  begin: 0.1,
                  end: 0,
                  curve: Curves.easeOutCubic,
                ),

            const SizedBox(height: 24),

            if (totalCount == 0)
              _buildEmptyState(theme)
            else ...[
              // ─── Categorized ingredients ───
              ...sortedCategories.asMap().entries.map((entry) {
                final catIndex = entry.key;
                final category = entry.value;
                final items = groupedPlanner[category]!;
                return _buildCategorySection(
                      theme,
                      isDark,
                      category,
                      items,
                    )
                    .animate(delay: (100 + catIndex * 60).ms)
                    .fade(duration: 400.ms)
                    .slideY(
                      begin: 0.08,
                      end: 0,
                      curve: Curves.easeOutCubic,
                    );
              }),

              // Bottom padding for FAB
              const SizedBox(height: 80),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child:
            Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay ingredientes para comprar'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Planifica comidas primero para generar tu lista de compra'
                          .tr,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.tonalIcon(
                          icon: const Icon(CupertinoIcons.plus, size: 16),
                          label: Text('Añadir artículo'.tr),
                          onPressed: _showAddManualItemSheet,
                        ),
                      ],
                    ),
                  ],
                )
                .animate().fade(duration: 500.ms).scaleXY(
              begin: 0.95,
              end: 1.0,
              curve: Curves.easeOutCubic,
            ),
      ),
    );
  }

  Widget _buildDaysAheadButton(ThemeData theme, bool isDark) {
    final days = ShoppingListManager.daysAhead;
    return PopupMenuButton<int>(
      initialValue: days,
      onSelected: (val) {
        ShoppingListManager.setDaysAhead(val);
        _regenerate();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) {
        return [1, 2, 3, 4, 5, 6, 7, 10, 14].map((d) {
          return PopupMenuItem(
            value: d,
            child: Text('$d ${d == 1 ? 'día'.tr : 'días'.tr}'),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
        child: Center(
          child: Icon(Icons.date_range_outlined, color: theme.colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    ThemeData theme,
    bool isDark,
    int checked,
    int total,
  ) {
    final progress = total > 0 ? checked / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$checked / $total ${'comprados'.tr}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    ThemeData theme,
    bool isDark,
    IngredientCategory? category,
    List<Map<String, dynamic>> items,
  ) {
    final catName = category?.displayName ?? 'Otros'.tr;
    final catIcon = category?.icon ?? Icons.more_horiz;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    catIcon,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  catName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Items
          ...items.map((item) => _buildIngredientTile(theme, item)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildIngredientTile(ThemeData theme, Map<String, dynamic> item) {
    final name = item['name'] as String;
    final sources = item['sources'] as List<Map<String, String>>;
    final isChecked = ShoppingListManager.isChecked(name);

    return InkWell(
      onTap: () => ShoppingListManager.toggleChecked(name),
      onLongPress: () {
        if (sources.isEmpty) return;
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('${'Cantidades de'.tr} $name'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sources.map((s) {
                    final qty = s['quantity'] ?? '';
                    final recipeName = s['recipeName'] ?? '';
                    String label = '';
                    if (qty.isNotEmpty && recipeName.isNotEmpty) {
                      label = '$qty · $recipeName';
                    } else if (qty.isNotEmpty) {
                      label = qty;
                    } else if (recipeName.isNotEmpty) {
                      label = recipeName;
                    }
                    if (label.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.arrow_right, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cerrar'.tr),
                ),
              ],
            );
          },
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isChecked
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isChecked
                      ? theme.colorScheme.primary
                      : Colors.grey.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  decoration: isChecked ? TextDecoration.lineThrough : null,
                  color: isChecked ? Colors.grey : null,
                ),
              ),
            ),
            if (sources.isNotEmpty)
              Icon(
                Icons.info_outline,
                size: 16,
                color: isChecked ? Colors.grey.withValues(alpha: 0.5) : Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

}

class _AddIngredientSearchSheet extends StatefulWidget {
  const _AddIngredientSearchSheet();

  @override
  State<_AddIngredientSearchSheet> createState() => _AddIngredientSearchSheetState();
}

class _AddIngredientSearchSheetState extends State<_AddIngredientSearchSheet> {
  final TextEditingController _ingredientController = TextEditingController();
  String _ingredientQuery = '';

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  Future<String?> _pickQuantityDialog(String ingredientName) async {
    final qtyController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${'Cantidad de'.tr} $ingredientName'),
        content: TextField(
          textCapitalization: TextCapitalization.sentences,
          controller: qtyController,
          decoration: InputDecoration(
            hintText: 'Ej: 200g, 1 un, al gusto...'.tr,
            labelText: 'Cantidad'.tr,
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.of(context).pop(value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(qtyController.text.trim()),
            child: Text('Añadir'.tr),
          ),
        ],
      ),
    );
  }

  void _showAddCustomIngredientDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddIngredientDialog(
        onAdd: (name, qty, category) {
          if (name.isNotEmpty) {
            ShoppingListManager.addManualItem(name, qty, category);
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  List<String> sortIngredients(List<String> allIngredients, String query) {
    if (query.isEmpty) return allIngredients;
    final q = query.toLowerCase();
    return allIngredients.where((ing) => ing.toLowerCase().contains(q)).toList()
      ..sort((a, b) {
        final aLower = a.toLowerCase();
        final bLower = b.toLowerCase();
        if (aLower.startsWith(q) && !bLower.startsWith(q)) return -1;
        if (!aLower.startsWith(q) && bLower.startsWith(q)) return 1;
        return aLower.compareTo(bLower);
      });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allIngredients = RecipeManager.allIngredients;
    final filteredList = _ingredientQuery.isEmpty
        ? allIngredients.take(30).toList()
        : sortIngredients(allIngredients, _ingredientQuery);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF1C1C1E)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          children: [
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
              'Añadir artículo'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    textCapitalization: TextCapitalization.sentences,
                    controller: _ingredientController,
                    onChanged: (val) => setState(() => _ingredientQuery = val),
                    textAlignVertical: TextAlignVertical.center,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Buscar ingredientes...'.tr,
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
                      suffixIcon: _ingredientQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
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
                    icon: const Icon(CupertinoIcons.add, color: Colors.white),
                    onPressed: _showAddCustomIngredientDialog,
                    tooltip: 'Crear nuevo'.tr,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: filteredList.length,
                separatorBuilder: (_, __) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final ing = filteredList[index];
                  return ListTile(
                    title: Text(ing),
                    leading: Icon(CupertinoIcons.add, size: 16),
                    onTap: () async {
                      final qty = await _pickQuantityDialog(ing);
                      if (qty != null) {
                        ShoppingListManager.addManualItem(ing, qty);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}




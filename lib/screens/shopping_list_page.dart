part of '../main.dart';

class _ShoppingListPage extends StatefulWidget {
  const _ShoppingListPage({this.showAppBar = true});
  final bool showAppBar;

  @override
  State<_ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<_ShoppingListPage> {
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
  void dispose() {
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

  String _formatDate(DateTime d) {
    final isEn = AppLocalization.instance.currentLanguage == 'en';
    const esDay = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const enDay = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const esMonth = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    const enMonth = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = isEn ? enDay[d.weekday - 1] : esDay[d.weekday - 1];
    final month = isEn ? enMonth[d.month - 1] : esMonth[d.month - 1];
    return '$day ${d.day} $month';
  }

  Future<void> _pickDateRange() async {
    final theme = Theme.of(context);
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: ShoppingListManager.rangeStart,
        end: ShoppingListManager.rangeEnd,
      ),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (result != null) {
      await ShoppingListManager.setDateRange(result.start, result.end);
      _regenerate();
    }
  }

  void _showAddManualItemSheet() {
    _manualNameController.clear();
    _manualQtyController.clear();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF1C1C1E)
                  : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: _manualNameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Nombre del ingrediente'.tr,
                    prefixIcon: const Icon(Icons.shopping_basket_outlined),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: _manualQtyController,
                  decoration: InputDecoration(
                    hintText: 'Ej: 200g, 1 un, al gusto...'.tr,
                    prefixIcon: const Icon(Icons.scale_outlined),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(CupertinoIcons.plus, size: 16),
                    label: Text('Añadir'.tr),
                    onPressed: () {
                      final name = _manualNameController.text.trim();
                      if (name.isNotEmpty) {
                        ShoppingListManager.addManualItem(
                          name,
                          _manualQtyController.text.trim(),
                        );
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
          final matches = _getIngredientsForCategory(category, [name]);
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
    final allItemNames = [
      ..._plannerItems.map((i) => i['name'] as String),
      ...manualItems.map((i) => i['name'] ?? ''),
    ];
    final checkedCount = allItemNames
        .where((n) => ShoppingListManager.isChecked(n))
        .length;
    final totalCount = allItemNames.length;

    final groupedPlanner = _groupByCategory(_plannerItems);
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
      body: totalCount == 0 && manualItems.isEmpty
          ? _buildEmptyState(theme)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Date Range Card ───
                  _buildDateRangeCard(theme, isDark)
                      .animate()
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 16),

                  // ─── Progress Bar ───
                  if (totalCount > 0)
                    _buildProgressCard(theme, isDark, checkedCount, totalCount)
                        .animate(delay: 100.ms)
                        .fade(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

                  if (totalCount > 0) const SizedBox(height: 16),

                  // ─── Action Buttons ───
                  if (totalCount > 0)
                    Row(
                          children: [
                            Expanded(
                              child: _buildActionChip(
                                theme,
                                label: 'Marcar todo'.tr,
                                icon: Icons.check_circle_outline,
                                onTap: () =>
                                    ShoppingListManager.checkAll(allItemNames),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildActionChip(
                                theme,
                                label: 'Desmarcar todo'.tr,
                                icon: Icons.radio_button_unchecked,
                                onTap: () => ShoppingListManager.uncheckAll(),
                              ),
                            ),
                          ],
                        )
                        .animate(delay: 150.ms)
                        .fade(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

                  if (totalCount > 0) const SizedBox(height: 20),

                  // ─── Planner Section Header ───
                  if (_plannerItems.isNotEmpty) ...[
                    Padding(
                          padding: const EdgeInsets.only(bottom: 12, left: 4),
                          child: Text(
                            'Del Planificador'.tr,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        )
                        .animate(delay: 200.ms)
                        .fade(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

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
                          .animate(delay: (250 + catIndex * 60).ms)
                          .fade(duration: 400.ms)
                          .slideY(
                            begin: 0.08,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          );
                    }),
                  ],

                  // ─── Manual Items Section ───
                  if (manualItems.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 4),
                      child: Text(
                        'Añadidos Manualmente'.tr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    _buildManualItemsCard(theme, isDark, manualItems),
                  ],

                  // Bottom padding for FAB
                  const SizedBox(height: 80),
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
                .animate()
                .fade(duration: 500.ms)
                .scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  Widget _buildDateRangeCard(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _pickDateRange,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.date_range_outlined,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatDate(ShoppingListManager.rangeStart)} — ${_formatDate(ShoppingListManager.rangeEnd)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sincronizado con el planificador'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
          ],
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

  Widget _buildActionChip(
    ThemeData theme, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            // Name + sources
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      color: isChecked ? Colors.grey : null,
                    ),
                  ),
                  if (sources.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: sources.map((s) {
                        final qty = s['quantity'] ?? '';
                        final recipeName = s['recipeName'] ?? '';
                        final label = qty.isNotEmpty
                            ? '$qty · $recipeName'
                            : recipeName;
                        return Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            color: isChecked
                                ? Colors.grey.withValues(alpha: 0.5)
                                : Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualItemsCard(
    ThemeData theme,
    bool isDark,
    List<Map<String, String>> items,
  ) {
    return Container(
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
                    CupertinoIcons.pencil,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Añadido Manualmente'.tr,
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
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final name = item['name'] ?? '';
            final qty = item['quantity'] ?? '';
            final isChecked = ShoppingListManager.isChecked(name);

            return Dismissible(
              key: ValueKey('manual_${idx}_$name'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => ShoppingListManager.removeManualItem(idx),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.trash,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
              child: InkWell(
                onTap: () => ShoppingListManager.toggleChecked(name),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
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
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          qty.isNotEmpty ? '$name ($qty)' : name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            decoration: isChecked
                                ? TextDecoration.lineThrough
                                : null,
                            color: isChecked ? Colors.grey : null,
                          ),
                        ),
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

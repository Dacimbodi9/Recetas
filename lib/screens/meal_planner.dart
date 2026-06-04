part of '../main.dart';


// ─────────────────────────────────────────────
// Meal Planner – Main Page
// ─────────────────────────────────────────────

class _MealPlannerPage extends StatefulWidget {
  const _MealPlannerPage({this.showAppBar = true});
  final bool showAppBar;

  @override
  State<_MealPlannerPage> createState() => _MealPlannerPageState();
}

class _MealPlannerPageState extends State<_MealPlannerPage> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
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

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  void _previousMonth() => setState(
    () => _displayedMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month - 1,
    ),
  );

  void _nextMonth() => setState(
    () => _displayedMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
    ),
  );

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthYearLabel(DateTime d) {
    const es = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    const en = [
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
    return '${isEn ? en[d.month - 1] : es[d.month - 1]} ${d.year}';
  }

  List<String> get _weekdayHeaders {
    final isEn = AppLocalization.instance.currentLanguage == 'en';
    return isEn
        ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        : ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  }

  void _showAddMealSheet(DateTime date, MealType mealType) {
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
                                      date: date,
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

  void _openDayDetail(DateTime day) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _DayDetailPage(date: day)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final today = _today;
    final todayMeals = MealPlanManager.getMealsForDate(today);

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: Text('Planificador de comidas'.tr))
          : AppBar(toolbarHeight: 0, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            ValueListenableBuilder<bool>(
              valueListenable: SettingsManager.showTodayMealsInHome,
              builder: (context, showTodayMeals, _) {
                if (showTodayMeals) return const SizedBox.shrink();
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (todayMeals.isEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12, left: 4),
                            child: Text(
                              'HOY'.tr,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 32),
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
                              children: [
                                Icon(
                                  Icons.restaurant_menu,
                                  size: 40,
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No hay comidas planificadas'.tr,
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                FilledButton.tonalIcon(
                                  icon: const Icon(CupertinoIcons.plus, size: 16),
                                  label: Text('Planificar hoy'.tr),
                                  onPressed: () => _openDayDetail(today),
                                ),
                              ],
                            ),
                          ).animate(delay: 100.ms).fade(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                          boxShadow: [
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
                            Row(
                              children: [
                                Icon(Icons.restaurant, color: theme.colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Comidas de hoy'.tr,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 20),
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Añadir comida extra'.tr,
                                  onPressed: () {
                                    showGlobalAddMealSheet(context, DateTime.now(), MealType.snack);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...todayMeals.map((meal) {
                              final recipe = RecipeManager.recipes.where((r) => r.id == meal.recipeId).firstOrNull;
                              if (recipe == null) return const SizedBox.shrink();

                              final String typeName = meal.mealType.name;
                              final String capitalizedType = typeName.isNotEmpty 
                                  ? '${typeName[0].toUpperCase()}${typeName.substring(1)}'.tr 
                                  : '';

                              return ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Dismissible(
                                  key: Key('today_meal_${meal.dateKey}_${meal.mealType.name}_${meal.recipeId}'),
                                  direction: DismissDirection.startToEnd,
                                  confirmDismiss: (direction) async {
                                    MealPlanManager.toggleCompleted(meal);
                                    return false;
                                  },
                                  background: const SizedBox.shrink(),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        left: -1000,
                                        width: 1000,
                                        top: 4,
                                        bottom: 4,
                                        child: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(right: 20),
                                          decoration: BoxDecoration(
                                            color: meal.completed 
                                                ? Colors.orange.withValues(alpha: 0.15)
                                                : theme.colorScheme.primary.withValues(alpha: 0.1),
                                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                                          ),
                                          child: Icon(
                                            meal.completed ? Icons.undo : Icons.check,
                                            color: meal.completed ? Colors.orange : theme.colorScheme.primary,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: GestureDetector(
                                        onTap: () {
                                          MealPlanManager.toggleCompleted(meal);
                                        },
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: meal.completed ? theme.colorScheme.primary : Colors.grey,
                                              width: 2,
                                            ),
                                            color: meal.completed ? theme.colorScheme.primary : Colors.transparent,
                                          ),
                                          child: meal.completed
                                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                                              : null,
                                        ),
                                      ),
                                      title: Text(
                                        recipe.title,
                                        style: TextStyle(
                                          decoration: meal.completed ? TextDecoration.lineThrough : null,
                                          color: meal.completed ? Colors.grey : null,
                                        ),
                                      ),
                                      subtitle: Text(
                                        capitalizedType,
                                        style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: recipe)),
                                        );
                                      },
                                    ),
                                  ),
                                  ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ).animate(delay: 100.ms).fade(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
        
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
            // ──────── CALENDAR CARD ────────
            Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 4),
                  child: Text(
                    'CALENDARIO'.tr,
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
            Container(
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
                  child: Column(
                    children: [
                      // Month nav
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              CupertinoIcons.chevron_left,
                              size: 16,
                            ),
                            onPressed: _previousMonth,
                          ),
                          Text(
                            _monthYearLabel(_displayedMonth),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              CupertinoIcons.chevron_right,
                              size: 16,
                            ),
                            onPressed: _nextMonth,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Weekday headers
                      Row(
                        children: [
                          const SizedBox(
                            width: 32,
                          ), // Space for the week handle
                          ..._weekdayHeaders.map(
                            (h) => Expanded(
                              child: Center(
                                child: Text(
                                  h,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Calendar grid
                      _buildCalendarGrid(theme, today),
                    ],
                  ),
                )
                .animate(delay: 250.ms)
                .fade(duration: 400.ms)
                .scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOutCubic),
            const SizedBox(height: 24),

            // ──────── TEMPLATES ────────
            Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 4),
                  child: Text(
                    'PLANTILLAS'.tr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                )
                .animate(delay: 350.ms)
                .fade(duration: 400.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
            _buildTemplatesSection(theme, isDark)
                .animate(delay: 400.ms)
                .fade(duration: 400.ms)
                .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesSection(ThemeData theme, bool isDark) {
    final templates = MealPlanManager.templates;
    final List<Widget> items = [];

    // Create new template card
    items.add(
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const _TemplateEditorPage()),
          );
        },
        child: Container(
          width: 110,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              style: BorderStyle.solid,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.plus_circle_fill,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                'Crear plantilla'.tr.replaceFirst(' ', '\n'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Existing templates
    items.addAll(
      templates.asMap().entries.map((entry) {
        final idx = entry.key;
        final tmpl = entry.value;
        final dayCount = tmpl.days.values.where((v) => v.isNotEmpty).length;
        final mealCount = tmpl.days.values.fold<int>(0, (s, v) => s + v.length);

        return Container(
          width: 150,
          margin: const EdgeInsets.only(right: 16),
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
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _TemplateEditorPage(
                        template: tmpl,
                        templateIndex: idx,
                      ),
                    ),
                  ).then((_) {
                    if (mounted) setState(() {});
                  });
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            idx < MealPlanManager.defaultTemplatesCount
                                ? Icons.star_rounded
                                : Icons.receipt_long_outlined,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          tmpl.name.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$dayCount ${'días'.tr} · $mealCount ${'comidas'.tr}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        );
      }),
    );

    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: items,
      ),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme, DateTime today) {
    final firstOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );
    final prevMonthEnd = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      0,
    );
    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;
    final startOffset = firstOfMonth.weekday - 1;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        // Monday of this row
        final rowFirstCellIndex = row * 7;
        final rowFirstDayNum = rowFirstCellIndex - startOffset + 1;
        final rowFirstDate = DateTime(
          _displayedMonth.year,
          _displayedMonth.month,
          rowFirstDayNum,
        );
        final rowMonday = rowFirstDate.subtract(
          Duration(days: rowFirstDate.weekday - 1),
        );

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              // ── Dedicated Week Selector Handle ──
              GestureDetector(
                onTap: () => _showTemplatePickerSheet(rowMonday),
                child: Container(
                  width: 24,
                  height: 42,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // ── Days Row ──
              Expanded(
                child: Row(
                  children: List.generate(7, (col) {
                    final cellIndex = row * 7 + col;
                    DateTime date;
                    bool isCurrentMonth = true;

                    if (cellIndex < startOffset) {
                      date = DateTime(
                        prevMonthEnd.year,
                        prevMonthEnd.month,
                        prevMonthEnd.day - (startOffset - cellIndex - 1),
                      );
                      isCurrentMonth = false;
                    } else if (cellIndex >= startOffset + daysInMonth) {
                      date = DateTime(
                        _displayedMonth.year,
                        _displayedMonth.month + 1,
                        cellIndex - (startOffset + daysInMonth) + 1,
                      );
                      isCurrentMonth = false;
                    } else {
                      date = DateTime(
                        _displayedMonth.year,
                        _displayedMonth.month,
                        cellIndex - startOffset + 1,
                      );
                    }

                    final isToday = _isSameDay(date, today);
                    final hasMeals = MealPlanManager.getMealsForDate(
                      date,
                    ).isNotEmpty;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _openDayDetail(date),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: 42,
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: isToday
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: (isToday || isCurrentMonth)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isToday
                                      ? Colors.white
                                      : (isCurrentMonth
                                            ? theme.textTheme.bodyLarge?.color
                                            : theme.textTheme.bodyLarge?.color
                                                  ?.withValues(alpha: 0.3)),
                                ),
                              ),
                              if (hasMeals)
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isToday
                                        ? Colors.white
                                        : theme.colorScheme.primary.withValues(
                                            alpha: isCurrentMonth ? 1.0 : 0.4,
                                          ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showTemplatePickerSheet(DateTime weekMonday) {
    final templates = MealPlanManager.templates;
    if (templates.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Crea una plantilla primero'.tr)));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Seleccionar plantilla'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      MealPlanManager.clearWeek(weekMonday);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Semana limpiada'.tr)),
                      );
                    },
                    icon: const Icon(CupertinoIcons.trash, size: 18, color: Colors.redAccent),
                    label: Text(
                      'Limpiar semana'.tr,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: templates.length,
                  itemBuilder: (_, i) {
                    final t = templates[i];
                    return ListTile(
                      leading: Icon(
                        Icons.receipt_long_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(t.name.tr),
                      onTap: () {
                        Navigator.pop(ctx);
                        MealPlanManager.applyTemplate(t, weekMonday);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Plantilla aplicada'.tr)),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Template Editor Page
// ─────────────────────────────────────────────

class _TemplateEditorPage extends StatefulWidget {
  const _TemplateEditorPage({this.template, this.templateIndex});
  final MealTemplate? template;
  final int? templateIndex;

  @override
  State<_TemplateEditorPage> createState() => _TemplateEditorPageState();
}

class _TemplateEditorPageState extends State<_TemplateEditorPage> {
  late TextEditingController _nameController;
  late Map<int, List<TemplateMealEntry>> _days;
  late PageController _pageController;
  int _currentPage = 0;

  bool get _isEditing => widget.template != null;

  bool get _isDefaultTemplate =>
      widget.templateIndex != null &&
      widget.templateIndex! < MealPlanManager.defaultTemplatesCount;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _pageController = PageController();
    _days = {};
    if (widget.template != null) {
      widget.template!.days.forEach((k, v) {
        _days[k] = List.from(v);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<String> _dayNames() {
    final isEn = AppLocalization.instance.currentLanguage == 'en';
    return isEn
        ? [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ]
        : [
            'Lunes',
            'Martes',
            'Miércoles',
            'Jueves',
            'Viernes',
            'Sábado',
            'Domingo',
          ];
  }

  List<String> _shortDayNames() {
    final isEn = AppLocalization.instance.currentLanguage == 'en';
    return isEn
        ? ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  }

  void _addRecipeToDay(int weekday, MealType mealType) {
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
              height: MediaQuery.of(ctx).size.height * 0.85,
              decoration: BoxDecoration(
                color: Theme.of(ctx).brightness == Brightness.dark
                    ? const Color(0xFF1C1C1E)
                    : Theme.of(ctx).scaffoldBackgroundColor,
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
                  const SizedBox(height: 16),
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
                          borderRadius: BorderRadius.circular(16),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final r = filtered[i];
                              final imagePath =
                                  RecipeManager.getCustomImage(r.title) ??
                                  r.imagePath;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    setState(() {
                                      _days.putIfAbsent(weekday, () => []);
                                      _days[weekday]!.add(
                                        TemplateMealEntry(
                                          mealType: mealType,
                                          recipeId: r.id,
                                        ),
                                      );
                                    });
                                    Navigator.pop(ctx);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: Theme.of(ctx)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: imagePath != null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child:
                                                      imagePath.startsWith(
                                                        'assets/',
                                                      )
                                                      ? Image.asset(
                                                          imagePath,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __, ___) => Icon(
                                                            Icons.restaurant,
                                                            color: Theme.of(ctx).colorScheme.primary,
                                                          ),
                                                        )
                                                      : Image.file(
                                                          File(imagePath),
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __, ___) => Icon(
                                                            Icons.restaurant,
                                                            color: Theme.of(ctx).colorScheme.primary,
                                                          ),
                                                        ),
                                                )
                                              : Icon(
                                                  Icons.restaurant,
                                                  color: Theme.of(
                                                    ctx,
                                                  ).colorScheme.primary,
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            r.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          CupertinoIcons.add_circled_solid,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          size: 28,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Escribe un nombre para la plantilla'.tr)),
      );
      return;
    }

    final template = MealTemplate(name: name, days: _days);
    if (_isEditing && widget.templateIndex != null) {
      MealPlanManager.updateTemplate(widget.templateIndex!, template);
    } else {
      MealPlanManager.addTemplate(template);
    }
    Navigator.pop(context);
  }

  Widget _buildMealSection(
    int weekday,
    MealType mealType,
    ThemeData theme,
    bool isDark,
  ) {
    final entries = _days[weekday] ?? [];
    final typeEntries = entries.where((e) => e.mealType == mealType).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4),
          child: Row(
            children: [
              Icon(mealType.icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                mealType.displayName.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        if (typeEntries.isEmpty)
          if (!_isDefaultTemplate)
            GestureDetector(
              onTap: () => _addRecipeToDay(weekday, mealType),
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.plus,
                      size: 24,
                      color: Colors.grey.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${'Añadir'.tr} ${mealType.displayName.toLowerCase()}',
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox.shrink()
        else
          Column(
            children: [
              ...typeEntries.asMap().entries.map((e) {
                final idx = entries.indexOf(
                  e.value,
                ); // absolute index in _days[weekday]
                final recipe = RecipeManager.getRecipeById(e.value.recipeId);
                final imagePath = recipe != null
                    ? (RecipeManager.getCustomImage(recipe.title) ??
                          recipe.imagePath)
                    : null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: imagePath.startsWith('assets/')
                                  ? Image.asset(
                                      imagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.restaurant,
                                        color: theme.colorScheme.primary,
                                        size: 20,
                                      ),
                                    )
                                  : Image.file(
                                      File(imagePath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.restaurant,
                                        color: theme.colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                            )
                          : Icon(
                              Icons.restaurant,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                    ),
                    title: Text(
                      recipe?.title ?? 'Receta eliminada'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    trailing: _isDefaultTemplate 
                        ? null 
                        : IconButton(
                            icon: Icon(
                              CupertinoIcons.trash,
                              size: 18,
                              color: Colors.red.withValues(alpha: 0.8),
                            ),
                            onPressed: () {
                              setState(() {
                                _days[weekday]!.removeAt(idx);
                                if (_days[weekday]!.isEmpty) {
                                  _days.remove(weekday);
                                }
                              });
                            },
                          ),
                  ),
                );
              }),

              // "Add another" button
              if (!_isDefaultTemplate)
                GestureDetector(
                  onTap: () => _addRecipeToDay(weekday, mealType),
                  child: Container(
                    margin: const EdgeInsets.only(top: 4, bottom: 24),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.plus_circle_fill,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Añadir otra receta'.tr,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_isDefaultTemplate)
                const SizedBox(height: 24),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dayNames = _dayNames();
    final shortDayNames = _shortDayNames();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        enabled: !_isDefaultTemplate,
                        textCapitalization: TextCapitalization.sentences,
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.2,
                          color: theme.colorScheme.primary,
                        ),
                        decoration: InputDecoration(
                          filled: false,
                          hintText: _isEditing
                              ? 'EDITAR PLANTILLA'.tr
                              : 'NUEVA PLANTILLA'.tr,
                          hintStyle: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(
                            bottom: 14,
                          ), // Align text vertically
                        ),
                      ),
                    ),
                  ),
                  if (!_isDefaultTemplate)
                    TextButton(
                      onPressed: _save,
                      child: Text(
                        'Guardar'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  if (_isEditing)
                    PopupMenuButton<int>(
                      icon: const Icon(CupertinoIcons.ellipsis_vertical, size: 20),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 0,
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.doc_on_doc, size: 18),
                              const SizedBox(width: 8),
                              Text('Duplicar'.tr),
                            ],
                          ),
                        ),
                        if (!_isDefaultTemplate)
                          PopupMenuItem(
                            value: 1,
                            child: Row(
                              children: [
                                const Icon(CupertinoIcons.trash, size: 18, color: Colors.redAccent),
                                const SizedBox(width: 8),
                                Text('Eliminar'.tr, style: const TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                          ),
                      ],
                      onSelected: (val) {
                        if (val == 0) {
                          // Duplicar
                          final copyName = '${widget.template!.name} (${'Copia'.tr})';
                          final newTemplate = MealTemplate(name: copyName, days: widget.template!.days);
                          MealPlanManager.addTemplate(newTemplate);
                          Navigator.pop(context);
                        } else if (val == 1) {
                          // Eliminar
                          MealPlanManager.deleteTemplate(widget.templateIndex!);
                          Navigator.pop(context);
                        }
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Day Selector Tabs
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: List.generate(7, (index) {
                  final isSelected = _currentPage == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            shortDayNames[index],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey, // High contrast text on primary
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            // Pager for Days
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final weekday = index + 1;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Text(
                            dayNames[index],
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildMealSection(
                          weekday,
                          MealType.desayuno,
                          theme,
                          isDark,
                        ),
                        _buildMealSection(
                          weekday,
                          MealType.almuerzo,
                          theme,
                          isDark,
                        ),
                        _buildMealSection(
                          weekday,
                          MealType.cena,
                          theme,
                          isDark,
                        ),
                        _buildMealSection(
                          weekday,
                          MealType.snack,
                          theme,
                          isDark,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
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

/// A single meal-type row for today's overview (compact, actionable)
class _TodayMealRow extends StatelessWidget {
  const _TodayMealRow({
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

class _DayDetailPage extends StatefulWidget {
  const _DayDetailPage({required this.date});
  final DateTime date;

  @override
  State<_DayDetailPage> createState() => _DayDetailPageState();
}

class _DayDetailPageState extends State<_DayDetailPage> {
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
          return _MealSlotCard(
            mealType: type,
            meals: mealsOfType,
            onAdd: () => _showAddMealSheet(type),
            onToggle: (m) => MealPlanManager.toggleCompleted(m),
            onSwap: (m) {
              MealPlanManager.removeMeal(m);
              _showAddMealSheet(m.mealType);
            },
            onRemove: (m) => MealPlanManager.removeMeal(m),
          );
        }).toList(),
      ),
    );
  }
}

/// Reusable meal-type card used in the day detail page
class _MealSlotCard extends StatelessWidget {
  const _MealSlotCard({
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

void showGlobalAddMealSheet(BuildContext context, DateTime date, MealType mealType) {
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
                                    date: date,
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

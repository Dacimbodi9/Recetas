// ignore_for_file: unused_element
// ignore_for_file: unused_local_variable
// ignore_for_file: use_build_context_synchronously
// ignore_for_file: deprecated_member_use
// ignore_for_file: constant_identifier_names
// ignore_for_file: avoid_print
part of '../main.dart';


class _NutritionalGraphCard extends StatefulWidget {
  const _NutritionalGraphCard();

  @override
  State<_NutritionalGraphCard> createState() => _NutritionalGraphCardState();
}

class _NutritionalGraphCardState extends State<_NutritionalGraphCard> {
  String _selectedNutrient = 'Calorías';
  final List<String> _nutrients = [
    'Calorías',
    'Proteínas',
    'Carbohidratos',
    'Grasas',
  ];

  String _selectedInterval = 'Semana';
  final List<String> _intervals = ['Semana', 'Mes', 'Año'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Generate mock graph data depending on interval
    int dataCount;
    List<String> labels;
    if (_selectedInterval == 'Semana') {
      dataCount = 7;
      labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    } else if (_selectedInterval == 'Mes') {
      dataCount = 4;
      labels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
    } else {
      dataCount = 12;
      labels = ['E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    }

    final double maxVal = _selectedNutrient == 'Calorías' ? 2500 : 150;

    // stable pseudorandom data
    final random = Random(
      _selectedNutrient.hashCode ^ _selectedInterval.hashCode,
    );
    final List<double> values = List.generate(
      dataCount,
      (i) => maxVal * 0.4 + random.nextDouble() * (maxVal * 0.6),
    );

    return Container(
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
          // Header with dropdowns
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDropdown(
                _nutrients,
                _selectedNutrient,
                (val) => setState(() => _selectedNutrient = val!),
                theme,
              ),
              _buildDropdown(
                _intervals,
                _selectedInterval,
                (val) => setState(() => _selectedInterval = val!),
                theme,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Graph area
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(dataCount, (index) {
                final ratio = values[index] / maxVal;
                final isToday =
                    _selectedInterval == 'Semana' &&
                    index == 5; // Fake "today" for accent
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: dataCount > 7 ? 2.0 : 6.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: ratio,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isToday
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          labels[index],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isToday
                                ? theme.colorScheme.primary
                                : Colors.grey,
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: dataCount > 7 ? 10 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
    ThemeData theme,
  ) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(CupertinoIcons.chevron_down, size: 14),
          iconEnabledColor: Colors.grey,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item.tr));
          }).toList(),
        ),
      ),
    );
  }
}
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
                                      recipeTitle: r.title,
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
            // ──────── TODAY'S MEALS ────────
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
            ),
            if (todayMeals.isEmpty)
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
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
              )
            else
              ...MealType.values.map((type) {
                final mealsOfType = todayMeals
                    .where((m) => m.mealType == type)
                    .toList();
                if (mealsOfType.isEmpty) return const SizedBox.shrink();
                return _TodayMealRow(
                  mealType: type,
                  meals: mealsOfType,
                  onToggle: (m) => MealPlanManager.toggleCompleted(m),
                  onSwap: (m) {
                    MealPlanManager.removeMeal(m);
                    _showAddMealSheet(today, m.mealType);
                  },
                  onRemove: (m) => MealPlanManager.removeMeal(m),
                );
              }),

            const SizedBox(height: 24),

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
            ),
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
                        icon: const Icon(CupertinoIcons.chevron_left, size: 16),
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
                      const SizedBox(width: 32), // Space for the week handle
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
            ),
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
            ),
            _buildTemplatesSection(theme, isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesSection(ThemeData theme, bool isDark) {
    final templates = MealPlanManager.templates;

    return Column(
      children: [
        // Saved templates
        if (templates.isNotEmpty)
          ...templates.asMap().entries.map((entry) {
            final idx = entry.key;
            final tmpl = entry.value;
            final dayCount = tmpl.days.values.where((v) => v.isNotEmpty).length;
            final mealCount = tmpl.days.values.fold<int>(
              0,
              (s, v) => s + v.length,
            );

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
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  tmpl.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '$dayCount ${'días'.tr} · $mealCount ${'comidas'.tr}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.pencil,
                        size: 18,
                        color: Colors.blueGrey,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _TemplateEditorPage(
                              template: tmpl,
                              templateIndex: idx,
                            ),
                          ),
                        );
                      },
                    ),
                    // Delete
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.delete,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => MealPlanManager.deleteTemplate(idx),
                    ),
                  ],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          }),
        // Create button
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _TemplateEditorPage()),
              );
            },
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.plus,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(
              'Crear plantilla'.tr,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  void _showApplyTemplateDialog(MealTemplate template) {
    final today = _today;
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    final nextMonday = thisMonday.add(const Duration(days: 7));

    final isEn = AppLocalization.instance.currentLanguage == 'en';

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Aplicar plantilla'.tr),
          content: Text(
            '¿A qué semana quieres aplicar esta plantilla? Se reemplazarán las comidas existentes.'
                .tr,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar'.tr),
            ),
            FilledButton.tonal(
              onPressed: () {
                Navigator.pop(ctx);
                MealPlanManager.applyTemplate(template, thisMonday);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Plantilla aplicada a esta semana'.tr),
                  ),
                );
              },
              child: Text('Esta semana'.tr),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                MealPlanManager.applyTemplate(template, nextMonday);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Plantilla aplicada a la próxima semana'.tr),
                  ),
                );
              },
              child: Text('Próxima semana'.tr),
            ),
          ],
        );
      },
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
              Text(
                'Seleccionar plantilla'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                      title: Text(t.name),
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

  bool get _isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
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
              height: MediaQuery.of(ctx).size.height * 0.65,
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
                                  setState(() {
                                    _days.putIfAbsent(weekday, () => []);
                                    _days[weekday]!.add(
                                      TemplateMealEntry(
                                        mealType: mealType,
                                        recipeTitle: r.title,
                                      ),
                                    );
                                  });
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

  void _showMealTypePicker(int weekday) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: MealType.values
              .map(
                (type) => ListTile(
                  leading: Icon(
                    type.icon,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                  title: Text(type.displayName),
                  onTap: () {
                    Navigator.pop(ctx);
                    _addRecipeToDay(weekday, type);
                  },
                ),
              )
              .toList(),
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dayNames = _dayNames();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        Navigator.pop(context);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Close Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(CupertinoIcons.xmark),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    // Center Content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isEditing ? 'EDITAR PLANTILLA'.tr : 'NUEVA PLANTILLA'.tr,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Name field
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre de la plantilla'.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Days
                    ...List.generate(7, (i) {
                      final weekday = i + 1; // 1=Mon
                      final entries = _days[weekday] ?? [];
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
                          children: [
                            // Day header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                              child: Row(
                                children: [
                                  Text(
                                    dayNames[i],
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: Icon(
                                      CupertinoIcons.plus_circle,
                                      color: theme.colorScheme.primary,
                                      size: 22,
                                    ),
                                    onPressed: () => _showMealTypePicker(weekday),
                                    tooltip: 'Añadir'.tr,
                                  ),
                                ],
                              ),
                            ),
                            if (entries.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12, left: 16),
                                child: Row(
                                  children: [
                                    Text(
                                      'Sin comidas'.tr,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...entries.asMap().entries.map((e) {
                                final idx = e.key;
                                final entry = e.value;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        entry.mealType.icon,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        entry.mealType.displayName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.recipeTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _days[weekday]!.removeAt(idx);
                                            if (_days[weekday]!.isEmpty)
                                              _days.remove(weekday);
                                          });
                                        },
                                        child: Icon(
                                          CupertinoIcons.xmark_circle_fill,
                                          size: 16,
                                          color: Colors.grey.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // Bottom Action Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.black, // High contrast
                        ),
                        child: Text(
                          'Guardar'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                .where((r) => r.title == meal.recipeTitle)
                .firstOrNull;
            return Dismissible(
              key: ValueKey(
                '${meal.dateKey}_${meal.mealType.name}_${meal.recipeTitle}_swipe',
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
                          if (recipe != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RecipeDetailPage(recipe: recipe),
                              ),
                            );
                          }
                        },
                        child: Text(
                          meal.recipeTitle,
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
                                      recipeTitle: r.title,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
                  .where((r) => r.title == meal.recipeTitle)
                  .firstOrNull;
              return Dismissible(
                key: ValueKey(
                  '${meal.dateKey}_${meal.mealType.name}_${meal.recipeTitle}_dismiss',
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
                    if (recipe != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailPage(recipe: recipe),
                        ),
                      );
                    }
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
                            meal.recipeTitle,
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

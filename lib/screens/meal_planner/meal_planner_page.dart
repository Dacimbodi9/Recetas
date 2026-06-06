import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:recetas/l10n.dart';
import 'package:recetas/models/models.dart';
import 'package:recetas/services/meal_plan_manager.dart';
import 'package:recetas/services/settings_manager.dart';
import 'package:recetas/services/recipe_manager.dart';
import 'package:recetas/screens/meal_planner/day_detail_page.dart';
import 'package:recetas/screens/meal_planner/helpers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:recetas/screens/recipe_details.dart';
import 'package:recetas/screens/meal_planner/template_editor_page.dart';

class MealPlannerPage extends StatefulWidget {
  const MealPlannerPage({super.key, this.showAppBar = true});
  final bool showAppBar;

  @override
  State<MealPlannerPage> createState() => MealPlannerPageState();
}

class MealPlannerPageState extends State<MealPlannerPage> {
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

  void _openDayDetail(DateTime day) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DayDetailPage(date: day)),
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
            MaterialPageRoute(builder: (_) => const TemplateEditorPage()),
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
                      builder: (_) => TemplateEditorPage(
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


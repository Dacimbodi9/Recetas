part of '../main.dart';

class StatsPage extends StatefulWidget {
  final bool showAppBar;
  const StatsPage({super.key, this.showAppBar = true});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  @override
  void initState() {
    super.initState();
    MealPlanManager.addListener(_onDataChanged);
    RecipeManager.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    MealPlanManager.removeListener(_onDataChanged);
    RecipeManager.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.showAppBar ? AppBar(
        title: Text(
          'Estadísticas'.tr,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ) : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(theme, 'RESUMEN'.tr),
              const SizedBox(height: 8),
              _DailySummaryCard(theme: theme, isDark: isDark, date: today),
              const SizedBox(height: 24),
              
              _buildSectionTitle(theme, 'GRÁFICO'.tr),
              const SizedBox(height: 8),
              _StatsNutritionChartCard(theme: theme, isDark: isDark),
              const SizedBox(height: 24),

              _buildSectionTitle(theme, 'MACROS'.tr),
              const SizedBox(height: 8),
              _MacroDistributionCard(theme: theme, isDark: isDark, date: today),
              const SizedBox(height: 24),

              _buildSectionTitle(theme, 'CONSISTENCIA'.tr),
              const SizedBox(height: 8),
              _StreakCard(theme: theme, isDark: isDark),
              const SizedBox(height: 24),

              _buildSectionTitle(theme, 'TOP RECETAS'.tr),
              const SizedBox(height: 8),
              _TopRecipesSection(theme: theme, isDark: isDark),
              const SizedBox(height: 24),

              _buildSectionTitle(theme, 'CATEGORÍAS'.tr),
              const SizedBox(height: 8),
              _CategoryDistributionCard(theme: theme, isDark: isDark),
              const SizedBox(height: 24),

              _buildSectionTitle(theme, 'DETALLE'.tr),
              const SizedBox(height: 8),
              _NutritionTableCard(theme: theme, isDark: isDark, date: today),
              const SizedBox(height: 24),
              
              ValueListenableBuilder<double?>(
                valueListenable: SettingsManager.userWeight,
                builder: (context, weight, child) {
                  return ValueListenableBuilder<double?>(
                    valueListenable: SettingsManager.userHeight,
                    builder: (context, height, child) {
                      if (weight != null && height != null && height > 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(theme, 'PERFIL CORPORAL'.tr),
                            const SizedBox(height: 8),
                            _BodyProfileCard(theme: theme, isDark: isDark),
                            const SizedBox(height: 24),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// UI COMPONENTS
// -----------------------------------------------------------------------------

Widget _buildBaseCard({
  required ThemeData theme, 
  required bool isDark, 
  required Widget child,
  EdgeInsets padding = const EdgeInsets.all(20),
}) {
  return Container(
    padding: padding,
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
      ),
      boxShadow: isDark ? null : [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  ).animate().fade(duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic);
}

class _DailySummaryCard extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final DateTime date;

  const _DailySummaryCard({required this.theme, required this.isDark, required this.date});

  @override
  Widget build(BuildContext context) {
    final nutrition = NutritionStatsService.getNutritionForDate(date);
    final consumedCals = nutrition['calorías'] ?? nutrition['calories'] ?? 0.0;
    final protein = nutrition['proteína'] ?? nutrition['proteínas'] ?? nutrition['proteins'] ?? nutrition['protein'] ?? 0.0;
    final carbs = nutrition['carbohidratos'] ?? nutrition['carbohydrates'] ?? nutrition['carbs'] ?? 0.0;
    final fat = nutrition['grasas'] ?? nutrition['fats'] ?? nutrition['fat'] ?? 0.0;
    
    double goalCals = NutritionStatsService.getDailyCalorieGoal() ?? 2000.0;
    if (goalCals <= 0) goalCals = 2000.0;
    
    double progress = consumedCals / goalCals;
    if (progress > 1.0) progress = 1.0;

    return _buildBaseCard(
      theme: theme,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Consumo de hoy'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Ring
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _CalorieRingPainter(
                    progress: progress,
                    primaryColor: theme.colorScheme.primary,
                    trackColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          consumedCals.toInt().toString(),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          '/ ${goalCals.toInt()} kcal',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Macros
              Expanded(
                child: Column(
                  children: [
                    _MacroBar(theme: theme, label: 'Proteínas'.tr, value: protein, unit: 'g', max: 150, color: Colors.blue.shade400),
                    const SizedBox(height: 12),
                    _MacroBar(theme: theme, label: 'Carbohidratos'.tr, value: carbs, unit: 'g', max: 250, color: Colors.amber.shade600),
                    const SizedBox(height: 12),
                    _MacroBar(theme: theme, label: 'Grasas'.tr, value: fat, unit: 'g', max: 80, color: Colors.red.shade400),
                  ],
                ),
              )
            ],
          ),
          if (consumedCals == 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Completa comidas del planificador para ver tus estadísticas'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final double value;
  final String unit;
  final double max;
  final Color color;

  const _MacroBar({
    required this.theme,
    required this.label,
    required this.value,
    required this.unit,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    double progress = value / max;
    if (progress > 1.0) progress = 1.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text('${value.toStringAsFixed(1)}$unit', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _StatsNutritionChartCard extends StatefulWidget {
  final ThemeData theme;
  final bool isDark;

  const _StatsNutritionChartCard({required this.theme, required this.isDark});

  @override
  State<_StatsNutritionChartCard> createState() => _StatsNutritionChartCardState();
}

class _StatsNutritionChartCardState extends State<_StatsNutritionChartCard> {
  String _selectedNutrient = 'Calorías';
  String _selectedInterval = 'Semana';

  @override
  Widget build(BuildContext context) {
    return _buildBaseCard(
      theme: widget.theme,
      isDark: widget.isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: widget.theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Gráfico nutricional'.tr,
                style: widget.theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Dropdowns
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  ['Calorías', 'Proteínas', 'Carbohidratos', 'Grasas'],
                  _selectedNutrient,
                  (val) => setState(() => _selectedNutrient = val!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  ['Semana', 'Mes', 'Año'],
                  _selectedInterval,
                  (val) => setState(() => _selectedInterval = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildChart(),
        ],
      ),
    );
  }
  
  Widget _buildDropdown(List<String> items, String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? widget.theme.cardColor : widget.theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item.tr, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildChart() {
    final now = DateTime.now();
    List<double> values = [];
    List<String> labels = [];
    int highlightIndex = -1;
    
    // Normalize nutrient keys to match logic in service
    String queryKey = _selectedNutrient.toLowerCase();
    if (queryKey == 'calorías') queryKey = 'calorías'; // Might also match 'calories' in service if we do logic there
    
    if (_selectedInterval == 'Semana') {
      // Last 7 days including today
      final start = now.subtract(const Duration(days: 6));
      final dailyData = NutritionStatsService.getDailyNutritionList(start, now);
      for (int i = 0; i < 7; i++) {
        final d = start.add(Duration(days: i));
        // Spanish day abbreviations: L, M, X, J, V, S, D
        const weekDays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
        labels.add(weekDays[d.weekday - 1]);
        if (i < dailyData.length) {
          double val = dailyData[i][queryKey] ?? dailyData[i][queryKey.replaceAll('ías', 'ies')] ?? 0;
          if (queryKey == 'grasas') val = dailyData[i]['grasas'] ?? dailyData[i]['fats'] ?? dailyData[i]['fat'] ?? 0;
          if (queryKey == 'proteínas') val = dailyData[i]['proteína'] ?? dailyData[i]['proteínas'] ?? dailyData[i]['proteins'] ?? dailyData[i]['protein'] ?? 0;
          if (queryKey == 'carbohidratos') val = dailyData[i]['carbohidratos'] ?? dailyData[i]['carbs'] ?? 0;
          values.add(val);
        } else {
          values.add(0);
        }
      }
      highlightIndex = 6; // Today is the last one
    } else if (_selectedInterval == 'Mes') {
      final weeklyData = NutritionStatsService.getWeeklyAverages();
      labels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
      for (final w in weeklyData) {
        double val = w[queryKey] ?? w[queryKey.replaceAll('ías', 'ies')] ?? 0;
        if (queryKey == 'grasas') val = w['grasas'] ?? w['fats'] ?? w['fat'] ?? 0;
        if (queryKey == 'proteínas') val = w['proteína'] ?? w['proteínas'] ?? w['proteins'] ?? w['protein'] ?? 0;
        if (queryKey == 'carbohidratos') val = w['carbohidratos'] ?? w['carbs'] ?? 0;
        values.add(val);
      }
      values = values.reversed.toList(); // Oldest first
      highlightIndex = 3; // Current week
    } else { // Año
      final monthlyData = NutritionStatsService.getMonthlyAverages();
      final months = ['E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
      for (int i = 11; i >= 0; i--) {
        final m = DateTime(now.year, now.month - i, 1);
        labels.add(months[m.month - 1]);
      }
      for (final m in monthlyData) {
        double val = m[queryKey] ?? m[queryKey.replaceAll('ías', 'ies')] ?? 0;
        if (queryKey == 'grasas') val = m['grasas'] ?? m['fats'] ?? m['fat'] ?? 0;
        if (queryKey == 'proteínas') val = m['proteína'] ?? m['proteínas'] ?? m['proteins'] ?? m['protein'] ?? 0;
        if (queryKey == 'carbohidratos') val = m['carbohidratos'] ?? m['carbs'] ?? 0;
        values.add(val);
      }
      values = values.reversed.toList();
      highlightIndex = 11; // Current month
    }

    double maxVal = values.isEmpty ? 1 : values.reduce(max);
    if (maxVal == 0) maxVal = 1; // Prevent division by zero

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(values.length, (i) {
          final val = values[i];
          final heightFactor = val / maxVal;
          final isHighlighted = i == highlightIndex;
          
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (val > 0)
                  Text(
                    val.toInt().toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                const SizedBox(height: 4),
                Flexible(
                  child: FractionallySizedBox(
                    heightFactor: heightFactor > 0 ? heightFactor : 0.05, // Minimum height
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isHighlighted 
                            ? widget.theme.colorScheme.primary 
                            : widget.theme.colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                    color: isHighlighted 
                        ? widget.theme.colorScheme.onSurface 
                        : widget.theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _MacroDistributionCard extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final DateTime date;

  const _MacroDistributionCard({required this.theme, required this.isDark, required this.date});

  @override
  Widget build(BuildContext context) {
    final dist = NutritionStatsService.getMacroDistribution(date);
    final protein = dist['proteína'] ?? dist['proteínas'] ?? dist['proteins'] ?? dist['protein'] ?? 0.0;
    final carbs = dist['carbohidratos'] ?? 0.0;
    final fat = dist['grasas'] ?? 0.0;
    
    final hasData = protein > 0 || carbs > 0 || fat > 0;
    
    final colorProtein = Colors.blue.shade400;
    final colorCarbs = Colors.amber.shade600;
    final colorFat = Colors.red.shade400;

    return _buildBaseCard(
      theme: theme,
      isDark: isDark,
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Distribución de macros'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (hasData) ...[
            SizedBox(
              height: 160,
              width: double.infinity,
              child: CustomPaint(
                painter: _DonutChartPainter(
                  segments: [
                    if (protein > 0) _ChartSegment(protein, colorProtein),
                    if (carbs > 0) _ChartSegment(carbs, colorCarbs),
                    if (fat > 0) _ChartSegment(fat, colorFat),
                  ],
                ),
                child: Center(
                  child: Text(
                    '100%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(theme, 'Proteínas'.tr, protein, colorProtein),
                _buildLegendItem(theme, 'Carbohidratos'.tr, carbs, colorCarbs),
                _buildLegendItem(theme, 'Grasas'.tr, fat, colorFat),
              ],
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No hay datos suficientes'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          ]
        ],
      ),
    );
  }
  
  Widget _buildLegendItem(ThemeData theme, String label, double pct, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${pct.toStringAsFixed(1)}%',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;

  const _StreakCard({required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final streak = NutritionStatsService.getStreakDays();
    
    return _buildBaseCard(
      theme: theme,
      isDark: isDark,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: streak > 0 
                    ? [Colors.orange.shade400, Colors.deepOrange.shade600]
                    : [Colors.grey.shade400, Colors.grey.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak ${'días de racha'.tr}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  streak > 0 
                      ? '¡Sigue así!'.tr 
                      : 'Planifica y completa comidas para iniciar tu racha'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopRecipesSection extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;

  const _TopRecipesSection({required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final topRecipes = NutritionStatsService.getMostConsumedRecipes(30); // Last 30 days
    
    if (topRecipes.isEmpty) {
      return _buildBaseCard(
        theme: theme,
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.restaurant_menu, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(
                  'No hay recetas consumidas aún'.tr,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Completa comidas para ver las más consumidas'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: topRecipes.length,
        itemBuilder: (context, index) {
          final entry = topRecipes[index];
          final recipe = entry.key;
          final count = entry.value;
          
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: isDark ? null : [
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '$count ${'veces'.tr}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  recipe.title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ).animate().fade(delay: (index * 100).ms).slideX(begin: 0.1);
        },
      ),
    );
  }
}

class _CategoryDistributionCard extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;

  const _CategoryDistributionCard({required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final catDist = NutritionStatsService.getCategoryDistribution(30);
    
    if (catDist.isEmpty) {
      return _buildBaseCard(
        theme: theme,
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'Sin categorías aún'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    }
    
    final sortedCats = catDist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final maxVal = sortedCats.first.value.toDouble();

    return _buildBaseCard(
      theme: theme,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Distribución por categoría'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...sortedCats.map((entry) {
            final cat = entry.key;
            final count = entry.value;
            final progress = count / maxVal;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(cat.icon, size: 16, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(cat.displayName, style: theme.textTheme.bodySmall),
                            Text(count.toString(), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _NutritionTableCard extends StatefulWidget {
  final ThemeData theme;
  final bool isDark;
  final DateTime date;

  const _NutritionTableCard({required this.theme, required this.isDark, required this.date});

  @override
  State<_NutritionTableCard> createState() => _NutritionTableCardState();
}

class _NutritionTableCardState extends State<_NutritionTableCard> {
  int _selectedTotalIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = widget.isDark;
    final date = widget.date;
    final meals = NutritionStatsService.getCompletedMealDetails(date);
    
    if (meals.isEmpty) {
      return _buildBaseCard(
        theme: theme,
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'Hoy no hay comidas completadas'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    }

    return _buildBaseCard(
      theme: theme,
      isDark: isDark,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.table_chart, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tabla nutricional'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: meals.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
            itemBuilder: (context, index) {
              final plannedMeal = meals[index].key;
              final recipe = meals[index].value;
              
              double cals = 0, prot = 0, carbs = 0, fat = 0;
              for (final fact in recipe.nutritionFacts) {
                final lbl = fact.label.toLowerCase();
                if (lbl.contains('cal')) {
                  cals += fact.value;
                } else if (lbl.contains('prot')) {
                  prot += fact.value;
                } else if (lbl.contains('carb')) {
                  carbs += fact.value;
                } else if (lbl.contains('gras') || lbl.contains('fat')) {
                  fat += fact.value;
                }
              }
              
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(plannedMeal.mealType.icon, size: 16, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Text(
                        recipe.title,
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildMiniMacro(theme, '${cals.toInt()}k', Colors.orange),
                          const SizedBox(width: 8),
                          _buildMiniMacro(theme, '${prot.toInt()}p', Colors.blue),
                          const SizedBox(width: 8),
                          _buildMiniMacro(theme, '${carbs.toInt()}c', Colors.amber),
                          const SizedBox(width: 8),
                          _buildMiniMacro(theme, '${fat.toInt()}g', Colors.red),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Total row
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                onTap: () {
                  setState(() {
                    _selectedTotalIndex = (_selectedTotalIndex + 1) % 4;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total del día'.tr,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Builder(
                        builder: (context) {
                          final totalNut = NutritionStatsService.getNutritionForDate(date);
                          final totalCals = totalNut['calorías'] ?? totalNut['calories'] ?? 0.0;
                          final totalProt = totalNut['proteína'] ?? totalNut['proteínas'] ?? totalNut['proteins'] ?? totalNut['protein'] ?? 0.0;
                          final totalCarbs = totalNut['carbohidratos'] ?? totalNut['carbohydrates'] ?? totalNut['carbs'] ?? 0.0;
                          final totalFat = totalNut['grasas'] ?? totalNut['fats'] ?? totalNut['fat'] ?? 0.0;
                          
                          String text = '';
                          Color textColor = theme.colorScheme.primary;
                          if (_selectedTotalIndex == 0) {
                            text = '${totalCals.toInt()} kcal';
                          } else if (_selectedTotalIndex == 1) {
                            text = '${totalProt.toInt()}g ${'Proteínas'.tr}';
                            textColor = Colors.blue;
                          } else if (_selectedTotalIndex == 2) {
                            text = '${totalCarbs.toInt()}g ${'Carbohidratos'.tr}';
                            textColor = Colors.amber.shade700;
                          } else {
                            text = '${totalFat.toInt()}g ${'Grasas'.tr}';
                            textColor = Colors.red;
                          }
                          
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              text,
                              key: ValueKey(_selectedTotalIndex),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMacro(ThemeData theme, String text, Color color) {
    return Container(
      width: 32,
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _BodyProfileCard extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;

  const _BodyProfileCard({required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final weight = SettingsManager.userWeight.value;
    final height = SettingsManager.userHeight.value;
    final age = SettingsManager.userAge.value;

    final bmi = NutritionStatsService.calculateBMI();
    final bmiCat = NutritionStatsService.getBMICategory();
    final tdee = NutritionStatsService.calculateTDEE();

    return _buildBaseCard(
      theme: theme,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Perfil corporal'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BodyProfileSettingsPage(),
                    ),
                  );
                },
                tooltip: 'Editar perfil corporal'.tr,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildProfileStat(theme, 'Peso'.tr, '${weight?.toStringAsFixed(1)} kg'),
              Container(width: 1, height: 40, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              _buildProfileStat(theme, 'Altura'.tr, '${height?.toInt()} cm'),
              Container(width: 1, height: 40, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              _buildProfileStat(theme, 'Edad'.tr, '${age ?? "-"} ${'años'.tr}'),
            ],
          ),
          const SizedBox(height: 24),
          if (bmi != null && bmiCat != null) ...[
            Text('IMC'.tr, style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 20,
              width: double.infinity,
              child: CustomPaint(
                painter: _BMIGaugePainter(
                  bmi: bmi,
                  markerColor: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bmi.toStringAsFixed(1),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBMIColor(bmi).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bmiCat,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getBMIColor(bmi),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          if (tdee != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department, color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gasto Energético Diario'.tr,
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          '${tdee.toInt()} kcal',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildProfileStat(ThemeData theme, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}

// -----------------------------------------------------------------------------
// CUSTOM PAINTERS
// -----------------------------------------------------------------------------

class _CalorieRingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color trackColor;

  _CalorieRingPainter({
    required this.progress,
    required this.primaryColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 8;
    
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
      
    canvas.drawCircle(center, radius, trackPaint);
    
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
        
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.primaryColor != primaryColor ||
           oldDelegate.trackColor != trackColor;
  }
}

class _ChartSegment {
  final double value;
  final Color color;
  _ChartSegment(this.value, this.color);
}

class _DonutChartPainter extends CustomPainter {
  final List<_ChartSegment> segments;

  _DonutChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 16;
    
    double total = 0;
    for (final s in segments) {
      total += s.value;
    }
    if (total == 0) return;
    
    double startAngle = -pi / 2;
    
    for (final segment in segments) {
      final sweepAngle = (segment.value / total) * 2 * pi;
      
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.butt;
        
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      
      // Gap between segments
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true; // Simplification
}

class _BMIGaugePainter extends CustomPainter {
  final double bmi;
  final Color markerColor;

  _BMIGaugePainter({required this.bmi, required this.markerColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    
    // Draw the gauge background
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Gradient from blue -> green -> orange -> red
    paint.shader = LinearGradient(
      colors: [Colors.blue.shade300, Colors.green.shade400, Colors.orange.shade400, Colors.red.shade400],
      stops: const [0.1, 0.4, 0.7, 0.9],
    ).createShader(rect);
    
    canvas.drawRRect(rrect, paint);
    
    // Draw marker
    // Map BMI to position. Let's say range is 15 to 40
    double pct = (bmi - 15) / (40 - 15);
    if (pct < 0) pct = 0;
    if (pct > 1) pct = 1;
    
    final markerX = size.width * pct;
    
    final markerPaint = Paint()
      ..color = markerColor
      ..style = PaintingStyle.fill;
      
    // Draw triangle marker
    final path = Path();
    path.moveTo(markerX, -4);
    path.lineTo(markerX - 6, 6);
    path.lineTo(markerX + 6, 6);
    path.close();
    
    canvas.drawPath(path, markerPaint);
    
    final linePaint = Paint()
      ..color = markerColor
      ..strokeWidth = 2;
    canvas.drawLine(Offset(markerX, 6), Offset(markerX, size.height), linePaint);
  }

  @override
  bool shouldRepaint(covariant _BMIGaugePainter oldDelegate) => oldDelegate.bmi != bmi;
}

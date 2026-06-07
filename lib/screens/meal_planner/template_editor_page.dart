import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:recetas/l10n.dart';
import 'package:recetas/models/models.dart';
import 'package:recetas/services/recipe_manager.dart';
import 'package:recetas/services/meal_plan_manager.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:recetas/screens/settings_page.dart';


class TemplateEditorPage extends StatefulWidget {
  const TemplateEditorPage({super.key, this.template, this.templateIndex});
  final MealTemplate? template;
  final int? templateIndex;

  @override
  State<TemplateEditorPage> createState() => TemplateEditorPageState();
}

class TemplateEditorPageState extends State<TemplateEditorPage> {
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

  bool _hasUnsavedChanges() {
    if (widget.template == null) {
      return _nameController.text.trim().isNotEmpty || _days.isNotEmpty;
    } else {
      if (_nameController.text.trim() != widget.template!.name) return true;
      if (_days.length != widget.template!.days.length) return true;
      for (final key in _days.keys) {
        if (!widget.template!.days.containsKey(key)) return true;
        final currentEntries = _days[key]!;
        final originalEntries = widget.template!.days[key]!;
        if (currentEntries.length != originalEntries.length) return true;
        for (int i = 0; i < currentEntries.length; i++) {
          if (currentEntries[i].recipeId != originalEntries[i].recipeId ||
              currentEntries[i].mealType != originalEntries[i].mealType) {
            return true;
          }
        }
      }
      return false;
    }
  }

  Future<void> _attemptClose() async {
    if (!_hasUnsavedChanges()) {
      Navigator.of(context).pop();
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Salir sin guardar?'.tr),
        content: Text('Tienes cambios sin guardar. Si sales, los perderás.'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Salir'.tr),
          ),
        ],
      ),
    );

    if (discard == true) {
      if (mounted) Navigator.of(context).pop();
    }
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

  void _showEditNameMenu() {
    final theme = Theme.of(context);
    final editController = TextEditingController(text: _nameController.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Editar nombre'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                textCapitalization: TextCapitalization.sentences,
                controller: editController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la plantilla'.tr,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      _nameController.text = editController.text;
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Guardar'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplateOptionsDialog(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (!_isDefaultTemplate)
                        SelectionOption(
                          title: 'Editar nombre'.tr,
                          icon: CupertinoIcons.pencil,
                          isSelected: false,
                          iconColor: theme.colorScheme.primary,
                          onTap: () {
                            Navigator.pop(context);
                            _showEditNameMenu();
                          },
                        ),
                      if (!_isDefaultTemplate) SizedBox(height: 12),
                      SelectionOption(
                        title: 'Duplicar'.tr,
                        icon: CupertinoIcons.doc_on_doc,
                        isSelected: false,
                        iconColor: theme.colorScheme.primary,
                        onTap: () {
                          final copyName = '${widget.template!.name} (${'Copia'.tr})';
                          final newTemplate = MealTemplate(name: copyName, days: widget.template!.days);
                          MealPlanManager.addTemplate(newTemplate);
                          Navigator.pop(context);
                        },
                      ),
                      SizedBox(height: 12),
                      SelectionOption(
                        title: 'Compartir'.tr,
                        icon: CupertinoIcons.share,
                        isSelected: false,
                        iconColor: theme.colorScheme.primary,
                        onTap: () {
                          Navigator.pop(context);
                          _shareAsFile();
                        },
                      ),
                      if (!_isDefaultTemplate) ...[
                        SizedBox(height: 12),
                        SelectionOption(
                          title: 'Eliminar'.tr,
                          icon: CupertinoIcons.trash,
                          isSelected: false,
                          isDestructive: true,
                          onTap: () {
                            MealPlanManager.deleteTemplate(widget.templateIndex!);
                            Navigator.pop(context); // Close dialog
                            Navigator.pop(context); // Close page
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Future<void> _shareAsFile() async {
    try {
      final name = widget.template!.name;
      final usedRecipes = <Recipe>[];
      for (final entries in widget.template!.days.values) {
        for (final entry in entries) {
          final recipe = RecipeManager.getRecipeById(entry.recipeId);
          if (recipe != null && !usedRecipes.contains(recipe)) {
            usedRecipes.add(recipe);
          }
        }
      }
      final data = widget.template!.toShareableData(usedRecipes);
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${name.replaceAll(' ', '_')}.recetas');
      await file.writeAsString(data);
      
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Plantilla de Recetas: $name',
          text: '¡Echa un vistazo a esta plantilla de comidas: $name!',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al compartir plantilla'.tr)),
        );
      }
    }
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _attemptClose();
      },
      child: Scaffold(
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
                    onPressed: _attemptClose,
                  ),
                  Expanded(
                    child: _isEditing
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Text(
                                _nameController.text,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          )
                        : Container(
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
                                hintText: 'NUEVA PLANTILLA'.tr,
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
                                ),
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
                  if (_isEditing) ...[
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showTemplateOptionsDialog(context, theme),
                    ),
                  ],
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
    ));
  }
}

/// A single meal-type row for today's overview (compact, actionable)


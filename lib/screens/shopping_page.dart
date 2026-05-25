part of '../main.dart';

// ─────────────────────────────────────────────
// Shopping & Pantry
// ─────────────────────────────────────────────

class _ShoppingPage extends StatefulWidget {
  const _ShoppingPage({this.showAppBar = true});
  final bool showAppBar;

  @override
  State<_ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<_ShoppingPage> {
  final PageController _pageController = PageController();
  final TextEditingController _shoppingController = TextEditingController();
  final TextEditingController _pantryController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    ShoppingManager.addListener(_refresh);
  }

  @override
  void dispose() {
    ShoppingManager.removeListener(_refresh);
    _pageController.dispose();
    _shoppingController.dispose();
    _pantryController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onSegmentChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final autoItems = ShoppingManager.getAutoIngredients();

    // Sort auto items: by date, then recipe
    autoItems.sort((a, b) => a.date.compareTo(b.date));

    // SHOPPING LIST
    final autoShopping = autoItems.where((i) => !i.isBought).toList();
    final manualShopping = ShoppingManager.manualShoppingList;

    // PANTRY
    final autoPantry = autoItems.where((i) => i.isBought).toList();
    final manualPantry = ShoppingManager.manualPantry;

    final Set<String> uniqueIngredients = {};
    for (final r in RecipeManager.recipes) {
      if (r.detailedIngredients.isNotEmpty) {
        uniqueIngredients.addAll(r.detailedIngredients.map((d) => d.name));
      } else {
        uniqueIngredients.addAll(r.ingredients);
      }
    }
    final allIngredients = uniqueIngredients.toList()..sort();

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: Text('Compra'.tr))
          : AppBar(toolbarHeight: 0, elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _SlidingSegmentedControl(
              controller: _pageController,
              selectedIndex: _selectedIndex,
              onTap: _onSegmentChanged,
              tabs: ['Lista de Compra'.tr, 'Despensa'.tr],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                // Shopping List Tab
                _buildListTab(
                  theme: theme,
                  autoItems: autoShopping,
                  manualItems: manualShopping,
                  isPantry: false,
                  controller: _shoppingController,
                  allIngredients: allIngredients,
                  onAddManual: (val) async {
                    final qty = await _pickQuantityDialog(val);
                    if (qty != null) {
                      ShoppingManager.addManualShoppingItem(
                        DetailedIngredient(name: val, quantity: qty),
                      );
                      _shoppingController.clear();
                    }
                  },
                  onAddCustom: () => _showAddCustomIngredientDialog(false),
                  onToggleManual: (val) =>
                      ShoppingManager.toggleManualShoppingItemBought(val),
                  onRemoveManual: (val) =>
                      ShoppingManager.removeManualShoppingItem(val),
                  onToggleAuto: (key) =>
                      ShoppingManager.toggleAutoItemBought(key),
                ),
                // Pantry Tab
                _buildListTab(
                  theme: theme,
                  autoItems: autoPantry,
                  manualItems: manualPantry,
                  isPantry: true,
                  controller: _pantryController,
                  allIngredients: allIngredients,
                  onAddManual: (val) async {
                    final qty = await _pickQuantityDialog(val);
                    if (qty != null) {
                      ShoppingManager.addManualPantryItem(
                        DetailedIngredient(name: val, quantity: qty),
                      );
                      _pantryController.clear();
                    }
                  },
                  onAddCustom: () => _showAddCustomIngredientDialog(true),
                  onToggleManual: (val) {
                    ShoppingManager.removeManualPantryItem(val);
                    ShoppingManager.addManualShoppingItem(val);
                  },
                  onRemoveManual: (val) =>
                      ShoppingManager.removeManualPantryItem(val),
                  onToggleAuto: (key) =>
                      ShoppingManager.toggleAutoItemBought(key),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickQuantityDialog(String ingredientName) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${'Cantidad para'.tr} $ingredientName'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Ej: 200g, 1 un, al gusto...'.tr,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Añadir'.tr),
          ),
        ],
      ),
    );
  }

  void _showAddCustomIngredientDialog(bool isPantry) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    IngredientCategory? selectedCat;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Crear ingrediente'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: 'Nombre'.tr,
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                decoration: InputDecoration(
                  hintText: 'Cantidad (ej: 100g)'.tr,
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<IngredientCategory>(
                    isExpanded: true,
                    value: selectedCat,
                    hint: Text(
                      'Categoría (Opcional)'.tr,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    ),
                    items: IngredientCategory.values
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => selectedCat = val),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'.tr),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final ing = DetailedIngredient(
                  name: nameCtrl.text.trim(),
                  quantity: qtyCtrl.text.trim(),
                  category: selectedCat,
                );
                if (isPantry) {
                  ShoppingManager.addManualPantryItem(ing);
                } else {
                  ShoppingManager.addManualShoppingItem(ing);
                }
                Navigator.pop(context);
              },
              child: Text('Añadir'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTab({
    required ThemeData theme,
    required List<AutoIngredientInfo> autoItems,
    required List<DetailedIngredient> manualItems,
    required bool isPantry,
    required TextEditingController controller,
    required Function(String) onAddManual,
    required VoidCallback onAddCustom,
    required Function(DetailedIngredient) onToggleManual,
    required Function(DetailedIngredient) onRemoveManual,
    required Function(String) onToggleAuto,
    required List<String> allIngredients,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: RawAutocomplete<String>(
                  textEditingController: controller,
                  focusNode: FocusNode(),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return allIngredients.where((String option) {
                      return option.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    });
                  },
                  onSelected: (String selection) {
                    onAddManual(selection);
                  },
                  fieldViewBuilder:
                      (
                        BuildContext context,
                        TextEditingController textEditingController,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted,
                      ) {
                        return ValueListenableBuilder<TextEditingValue>(
                          valueListenable: textEditingController,
                          builder: (context, value, child) {
                            return TextField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                hintText: isPantry
                                    ? 'Añadir a despensa...'.tr
                                    : 'Añadir a lista...'.tr,
                                prefixIcon: const Icon(CupertinoIcons.search),
                                suffixIcon: value.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          CupertinoIcons.xmark_circle_fill,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          textEditingController.clear();
                                        },
                                      )
                                    : null,
                              ),
                              onSubmitted: (String value) {
                                onFieldSubmitted();
                                onAddManual(value);
                              },
                            );
                          },
                        );
                      },
                  optionsViewBuilder:
                      (
                        BuildContext context,
                        AutocompleteOnSelected<String> onSelected,
                        Iterable<String> options,
                      ) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 8, // Higher elevation
                            borderRadius: BorderRadius.circular(16),
                            color: theme.colorScheme.surface, // Fully opaque
                            child: Container(
                              margin: const EdgeInsets.only(top: 8),
                              constraints: BoxConstraints(
                                maxHeight: 180,
                                maxWidth:
                                    MediaQuery.of(context).size.width - 96,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (BuildContext context, int index) {
                                  final String option = options.elementAt(
                                    index,
                                  );
                                  return ListTile(
                                    title: Text(option),
                                    leading: const Icon(
                                      CupertinoIcons.add,
                                      size: 16,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(CupertinoIcons.add),
                  onPressed: onAddCustom,
                  tooltip: 'Crear nuevo'.tr,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (isPantry) ...[
                Builder(
                  builder: (context) {
                    final Map<String, List<dynamic>> groupedItems = {};
                    for (final auto in autoItems) {
                      final n = auto.name.toLowerCase();
                      groupedItems.putIfAbsent(n, () => []).add(auto);
                    }
                    for (final manual in manualItems) {
                      final n = manual.name.toLowerCase();
                      groupedItems.putIfAbsent(n, () => []).add(manual);
                    }

                    final keys = groupedItems.keys.toList()..sort();
                    return Column(
                      children: keys.map((key) {
                        final items = groupedItems[key]!;
                        final mainName = items.first is AutoIngredientInfo
                            ? (items.first as AutoIngredientInfo).name
                            : (items.first as DetailedIngredient).name;
                        return _buildGroupedPantryCard(
                          theme: theme,
                          isDark: isDark,
                          title: mainName,
                          items: items,
                          onToggleAuto: onToggleAuto,
                          onToggleManual: onToggleManual,
                          onRemoveManual: onRemoveManual,
                        );
                      }).toList(),
                    );
                  },
                ),
              ] else ...[
                if (autoItems.isNotEmpty &&
                    ShoppingManager.autoShoppingEnabled.value) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 8, left: 4),
                    child: Text(
                      'Del Planificador'.tr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...autoItems.map((item) {
                    return _buildItemCard(
                      theme: theme,
                      isDark: isDark,
                      title: item.name,
                      subtitle:
                          '${item.recipeTitle} (${item.date.day}/${item.date.month})',
                      quantity: item.quantity,
                      isChecked: item.isBought,
                      onToggle: () => onToggleAuto(item.autoKey),
                      isPantry: false,
                    );
                  }),
                ],
                if (manualItems.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                      top: 16,
                      left: 4,
                    ),
                    child: Text(
                      'Añadidos Manualmente'.tr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...manualItems.map((item) {
                    return Dismissible(
                      key: ValueKey('manual_${item.name}_${item.quantity}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          CupertinoIcons.delete,
                          color: Colors.red.withValues(alpha: 0.7),
                        ),
                      ),
                      onDismissed: (_) => onRemoveManual(item),
                      child: _buildItemCard(
                        theme: theme,
                        isDark: isDark,
                        title: item.name,
                        subtitle: null,
                        quantity: item.quantity,
                        isChecked: false,
                        onToggle: () => onToggleManual(item),
                        isPantry: false,
                        onRemove: () => onRemoveManual(item),
                      ),
                    );
                  }),
                ],
              ],
              if (autoItems.isEmpty && manualItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPantry
                              ? CupertinoIcons.archivebox
                              : CupertinoIcons.cart,
                          size: 64,
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nada por aquí'.tr,
                          style: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard({
    required ThemeData theme,
    required bool isDark,
    required String title,
    required String? subtitle,
    required String? quantity,
    required bool isChecked,
    required VoidCallback onToggle,
    required bool isPantry,
    VoidCallback? onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isChecked
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: isChecked
                            ? theme.colorScheme.primary
                            : Colors.grey.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: isChecked
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          decoration: isChecked && !isPantry
                              ? TextDecoration.lineThrough
                              : null,
                          color: isChecked && !isPantry
                              ? Colors.grey
                              : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (quantity != null && quantity.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    quantity,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                if (onRemove != null)
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.clear,
                      size: 16,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedPantryCard({
    required ThemeData theme,
    required bool isDark,
    required String title,
    required List<dynamic> items,
    required Function(String) onToggleAuto,
    required Function(DetailedIngredient) onToggleManual,
    required Function(DetailedIngredient) onRemoveManual,
  }) {
    final displayTitle = title.isNotEmpty
        ? '${title[0].toUpperCase()}${title.substring(1)}'
        : title;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.archivebox,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  displayTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          children: items.map((item) {
            if (item is AutoIngredientInfo) {
              return _buildItemCard(
                theme: theme,
                isDark: isDark,
                title: item.ingredient,
                subtitle:
                    '${item.recipeTitle} (${item.date.day}/${item.date.month})',
                quantity: item.quantity,
                isChecked: true, // it's in pantry
                onToggle: () => onToggleAuto(item.autoKey),
                isPantry: true,
              );
            } else {
              final manualItem = item as DetailedIngredient;
              return Dismissible(
                key: ValueKey(
                  'manual_${manualItem.name}_${manualItem.quantity}',
                ),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    CupertinoIcons.delete,
                    color: Colors.red.withValues(alpha: 0.7),
                  ),
                ),
                onDismissed: (_) => onRemoveManual(manualItem),
                child: _buildItemCard(
                  theme: theme,
                  isDark: isDark,
                  title: manualItem.name,
                  subtitle: null,
                  quantity: manualItem.quantity,
                  isChecked: true, // it's in pantry
                  onToggle: () => onToggleManual(manualItem),
                  isPantry: true,
                  onRemove: () => onRemoveManual(manualItem),
                ),
              );
            }
          }).toList(),
        ),
      ),
    );
  }
}

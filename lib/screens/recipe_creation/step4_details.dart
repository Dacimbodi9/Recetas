// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api
part of '../recipe_creation.dart';

extension Buildstep4details on _NewRecipePageState {
  Widget _buildStep4Details(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTagSection(
            theme: theme,
            title: 'CATEGORÍA'.tr,
            items: RecipeCategory.values,
            isSelected: (c) => _selectedCategories.contains(c),
            onToggle: (c) {
              setState(() {
                if (_selectedCategories.contains(c)) {
                  _selectedCategories.remove(c);
                } else {
                  _selectedCategories.add(c);
                }
              });
            },
            getLabel: (c) => c.displayName,
          ),
          SizedBox(height: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DIETA'.tr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAddCustomTagDialog,
                    icon: Icon(CupertinoIcons.add, size: 16),
                    label: Text('Crear etiqueta'.tr),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...DietaryRestriction.values.map((r) {
                    final active = _selectedDietaryRestrictions.contains(r);
                    return FilterChip(
                      label: Text(r.displayName),
                      selected: active,
                      onSelected: (_) => setState(() {
                        if (active) {
                          _selectedDietaryRestrictions.remove(r);
                        } else {
                          _selectedDietaryRestrictions.add(r);
                        }
                      }),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      selectedColor: theme.colorScheme.primary.withValues(
                        alpha: 0.3,
                      ),
                      checkmarkColor: theme.colorScheme.primary,
                      side: BorderSide(
                        color: active
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }),
                  ..._selectedCustomTags.map((tag) {
                    return FilterChip(
                      label: Text(tag),
                      selected: true,
                      onSelected: (_) =>
                          setState(() => _selectedCustomTags.remove(tag)),
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.3,
                      ),
                      selectedColor: theme.colorScheme.primary.withValues(
                        alpha: 0.3,
                      ),
                      checkmarkColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

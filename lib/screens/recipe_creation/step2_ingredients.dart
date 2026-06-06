// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api
part of '../recipe_creation.dart';

extension Buildstep2ingredients on _NewRecipePageState {
  Widget _buildStep2Ingredients(ThemeData theme) {
    final allIngredients = RecipeManager.allIngredients;
    final filteredList = _ingredientQuery.isEmpty
        ? <String>[]
        : sortIngredients(allIngredients, _ingredientQuery)
              .where((i) => !_detailedIngredients.any((d) => d.name == i))
              .take(6)
              .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INGREDIENTES'.tr,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      textCapitalization: TextCapitalization.sentences,
                      controller: _ingredientController,
                      onChanged: (val) =>
                          setState(() => _ingredientQuery = val),
                      textAlignVertical: TextAlignVertical.center,
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
              // Search Results
              if (filteredList.isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final ing = filteredList[index];
                      return ListTile(
                        title: Text(ing),
                        leading: Icon(CupertinoIcons.add, size: 16),
                        visualDensity: VisualDensity.compact,
                        onTap: () async {
                          final qty = await _pickQuantityDialog(ing);
                          if (qty != null) {
                            _addIngredient(
                              DetailedIngredient(name: ing, quantity: qty),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _detailedIngredients.isEmpty
              ? const SizedBox.shrink()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _detailedIngredients.length,
                  itemBuilder: (context, index) {
                    final item = _detailedIngredients[index];
                    return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.05,
                              ),
                            ),
                          ),
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.quantity,
                                  style: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                CupertinoIcons.trash,
                                size: 18,
                                color: Colors.grey,
                              ),
                              onPressed: () => _removeIngredient(item),
                            ),
                          ),
                        )
                        .animate(delay: (index * 50).ms)
                        .fade(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
                  },
                ),
        ),
      ],
    );
  }
}

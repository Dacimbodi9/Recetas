// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api
part of '../recipe_creation.dart';

extension Buildstep3instructions on _NewRecipePageState {
  Widget _buildStep3Instructions(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PASOS A SEGUIR'.tr,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Row(
                children: [
                  FilledButton(
                    onPressed: () => setState(
                      () => _isReorderingSteps = !_isReorderingSteps,
                    ),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: _isReorderingSteps
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: _isReorderingSteps
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      minimumSize: Size(
                        48,
                        36,
                      ), // Ensure min height matches standard compact button
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ), // Restore some padding
                    ),
                    child: Icon(Icons.swap_vert, size: 20),
                  ),
                  SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _showAddStepDialog,
                    icon: Icon(CupertinoIcons.add),
                    label: Text('Añadir paso'.tr),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _steps.isEmpty
              ? const SizedBox.shrink()
              : _isReorderingSteps
              ? ReorderableListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) newIndex -= 1;
                      final item = _steps.removeAt(oldIndex);
                      _steps.insert(newIndex, item);
                    });
                  },
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (BuildContext context, Widget? child) {
                        final double animValue = Curves.easeInOut.transform(animation.value);
                        return Transform.scale(
                          scale: 1 + (animValue * 0.02),
                          child: Material(
                            type: MaterialType.transparency,
                            elevation: 0,
                            child: child,
                          ),
                        );
                      },
                      child: child,
                    );
                  },
                  children: [
                    for (int index = 0; index < _steps.length; index++)
                      Container(
                        key: ValueKey('step_${_steps[index]}_$index'),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.05,
                            ),
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.drag_indicator,
                            color: Colors.grey,
                          ),
                          title: Text(_steps[index]),
                          trailing: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: theme.colorScheme.surface,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.05,
                            ),
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          title: Text(_steps[index]),
                          onTap: () => _showStepOptions(context, index),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

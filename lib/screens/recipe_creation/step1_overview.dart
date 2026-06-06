// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api
part of '../recipe_creation.dart';

extension Buildstep1overview on _NewRecipePageState {
  Widget _buildStep1Overview(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _selectedImagePath == null
                  ? _buildAddPhotoPlaceholder(theme)
                  : (_selectedImagePath!.startsWith('assets/')
                        ? Image.asset(
                            _selectedImagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildAddPhotoPlaceholder(theme),
                          )
                        : Image.file(
                            File(_selectedImagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildAddPhotoPlaceholder(theme),
                          )),
            ),
          ),
          SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _scanRecipeLocally,
            icon: Icon(CupertinoIcons.doc_text_viewfinder),
            label: Text('Escanear receta desde foto (Beta)'.tr),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          SizedBox(height: 16),

          _buildInputSection(
            theme,
            title: 'NOMBRE'.tr,
            children: [
              TextField(
                textCapitalization: TextCapitalization.sentences,
                controller: _titleController,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'Nombre de la receta'.tr,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),

          _buildInputSection(
            theme,
            title: 'TIEMPO ESTIMADO'.tr,
            children: [
              TextField(
                textCapitalization: TextCapitalization.sentences,
                controller: _prepTimeController,
                decoration: InputDecoration(
                  hintText: 'Ej: 30 min'.tr,
                  prefixIcon: Icon(CupertinoIcons.clock, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),

          _buildInputSection(
            theme,
            title: 'NUTRICIÓN (OPCIONAL)'.tr,
            children: [
              Theme(
                data: theme.copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  dividerColor: Colors
                      .transparent, // Ensure no dividers show up unexpectedly
                ),
                child: ExpansionTile(
                  title: Text('Información Nutricional'.tr),
                  leading: Icon(Icons.analytics_outlined),
                  shape: Border(),
                  collapsedShape: Border(),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactNutriInput(
                            theme,
                            _caloriesController,
                            'Calorías (kcal)'.tr,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildCompactNutriInput(
                            theme,
                            _proteinController,
                            'Proteína (g)'.tr,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactNutriInput(
                            theme,
                            _carbsController,
                            'Carbohidratos (g)'.tr,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildCompactNutriInput(
                            theme,
                            _fatController,
                            'Grasas (g)'.tr,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

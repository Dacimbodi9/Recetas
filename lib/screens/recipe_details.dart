import 'package:recetas/screens/profile_page.dart';
import 'package:recetas/screens/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:recetas/l10n.dart';
import 'package:recetas/models/models.dart';
import 'package:recetas/services/recipe_manager.dart';
import 'package:recetas/widgets/widgets.dart';
import 'package:recetas/screens/recipe_creation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'dart:async';

class RecipeDetailPage extends StatefulWidget {
  const RecipeDetailPage({super.key, required this.recipe, this.heroTag});

  final Recipe recipe;
  final String? heroTag;

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  late PageController _pageController;
  final ScrollController _scrollController = ScrollController();

  bool _isFavorite = false;
  late Recipe _currentRecipe;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentRecipe = widget.recipe;
    _isFavorite = RecipeManager.isFavorite(_currentRecipe);
    RecipeManager.addListener(_onRecipesChanged);
  }

  // ... callbacks

  void _onRecipesChanged() {
    setState(() {
      // Find the updated recipe object from the manager to get new rating
      final updatedRecipe = RecipeManager.recipes.cast<Recipe?>().firstWhere(
        (r) => r?.title == _currentRecipe.title,
        orElse: () => null,
      );

      if (updatedRecipe != null) {
        _currentRecipe = updatedRecipe;
      }

      _isFavorite = RecipeManager.isFavorite(_currentRecipe);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    RecipeManager.removeListener(_onRecipesChanged);
    super.dispose();
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar receta'.tr),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${_currentRecipe.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'.tr),
          ),
          FilledButton(
            onPressed: () async {
              try {
                // Remove from favorites first if it's there
                if (RecipeManager.isFavorite(widget.recipe)) {
                  await RecipeManager.toggleFavorite(widget.recipe);
                }

                await RecipeManager.removeRecipe(widget.recipe);

                if (mounted) {
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close dialog
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close page
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Receta "${widget.recipe.title}" eliminada',
                        ),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  if (context.mounted) Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al eliminar la receta'.tr)),
                    );
                  }
                }
              }
            },
            child: Text('Eliminar'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    await RecipeManager.toggleFavorite(widget.recipe);
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(CupertinoIcons.camera),
              title: Text('Cámara'.tr),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(CupertinoIcons.photo),
              title: Text('Galería'.tr),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'custom_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localImage = await File(
        pickedFile.path,
      ).copy('${appDir.path}/$fileName');

      await RecipeManager.setCustomImage(widget.recipe.title, localImage.path);

      if (mounted) {
        setState(() {}); // Refresh UI
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Imagen actualizada'.tr)));
        }
      }
    }
  }

  void _duplicateRecipe() async {
    int counter = 1;
    String newTitle = '${_currentRecipe.title} (Copia)';

    // Ensure unique title
    while (RecipeManager.recipes.any((r) => r.title == newTitle)) {
      counter++;
      newTitle = '${_currentRecipe.title} (Copia $counter)';
    }

    final duplicatedRecipe = _currentRecipe.copyWith(title: newTitle);

    await RecipeManager.addRecipe(duplicatedRecipe);

    // Copy custom image if the original has one
    final customImage = RecipeManager.getCustomImage(_currentRecipe.title);
    if (customImage != null) {
      await RecipeManager.setCustomImage(newTitle, customImage);
    }
    await RecipeManager.toggleFavorite(duplicatedRecipe);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Receta duplicada'.tr)));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RecipeDetailPage(recipe: duplicatedRecipe),
        ),
      );
    }
  }

  void _showShareOptions() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 24),
              Text(
                'Compartir receta'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(CupertinoIcons.paperplane),
                title: Text('Compartir archivo'.tr),
                subtitle: Text(
                  'Envía un archivo .receta por WhatsApp, Telegram...'.tr,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _shareAsFile();
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.qrcode),
                title: Text('Mostrar código QR'.tr),
                subtitle: Text('Muestra un QR para que otros lo escaneen'.tr),
                onTap: () {
                  Navigator.pop(context);
                  _shareAsQR();
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareAsFile() async {
    try {
      final data = _currentRecipe.toShareableData();
      final tempDir = await getTemporaryDirectory();
      final safeTitle = _currentRecipe.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');
      final fileName = '$safeTitle.receta';
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsString(data);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '${'¡Mira esta receta de'.tr} ${_currentRecipe.title}!',
          subject: _currentRecipe.title,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al compartir'.tr)));
      }
    }
  }

  void _shareAsQR() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareQRCodePage(recipe: _currentRecipe),
      ),
    );
  }

  Future<void> _searchOnInternet() async {
    final query = Uri.encodeComponent(_currentRecipe.title);
    final url = Uri.parse('https://www.google.com/search?q=$query');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el navegador'.tr)),
        );
      }
    }
  }

  void _showRecipeOptionsDialog(
    BuildContext context,
    ThemeData theme,
    bool isPersonalized,
  ) {
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
                      SelectionOption(
                        title: 'Editar'.tr,
                        icon: CupertinoIcons.pencil,
                        isSelected: false,
                        iconColor: theme.colorScheme.primary,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  NewRecipePage(recipeToEdit: _currentRecipe),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 12),
                      SelectionOption(
                        title: 'Duplicar'.tr,
                        icon: CupertinoIcons.doc_on_doc,
                        isSelected: false,
                        iconColor: theme.colorScheme.primary,
                        onTap: () {
                          Navigator.pop(context);
                          _duplicateRecipe();
                        },
                      ),
                      if (isPersonalized) ...[
                        SizedBox(height: 12),
                        SelectionOption(
                          title: 'Eliminar'.tr,
                          icon: CupertinoIcons.trash,
                          isSelected: false,
                          isDestructive: true,
                          onTap: () {
                            Navigator.pop(context);
                            _showDeleteDialog();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPersonalized = !RecipeManager.isDefaultRecipe(_currentRecipe);
    final customImagePath = RecipeManager.getCustomImage(_currentRecipe.title);
    final displayImagePath = customImagePath ?? _currentRecipe.imagePath;

    final hasIngredients =
        _currentRecipe.detailedIngredients.isNotEmpty ||
        _currentRecipe.ingredients.isNotEmpty;
    final hasInstructions = _currentRecipe.steps.isNotEmpty;
    final hasInfo =
        _currentRecipe.dietaryRestrictions.isNotEmpty ||
        _currentRecipe.customDietaryTags.isNotEmpty ||
        _currentRecipe.nutritionFacts.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              style: IconButton.styleFrom(
                backgroundColor: theme.scaffoldBackgroundColor.withValues(
                  alpha: 0.75,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                ),
                child: LikeButton(
                  isFavorite: _isFavorite,
                  onTap: _toggleFavorite,
                ),
              ),
              IconButton(
                icon: Icon(CupertinoIcons.globe),
                style: IconButton.styleFrom(
                  backgroundColor: theme.scaffoldBackgroundColor.withValues(
                    alpha: 0.75,
                  ),
                ),
                onPressed: _searchOnInternet,
              ),
              IconButton(
                icon: Icon(CupertinoIcons.share),
                style: IconButton.styleFrom(
                  backgroundColor: theme.scaffoldBackgroundColor.withValues(
                    alpha: 0.75,
                  ),
                ),
                onPressed: _showShareOptions,
              ),
              IconButton(
                icon: Icon(Icons.more_vert),
                style: IconButton.styleFrom(
                  backgroundColor: theme.scaffoldBackgroundColor.withValues(
                    alpha: 0.75,
                  ),
                ),
                onPressed: () =>
                    _showRecipeOptionsDialog(context, theme, isPersonalized),
              ),
              SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  if (displayImagePath != null)
                    GestureDetector(
                      onTap: _pickImage,
                      child: displayImagePath.startsWith('assets/')
                          ? Image.asset(
                              displayImagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholder(),
                            ).animate().fade(duration: 600.ms)
                          : Image.file(
                              File(displayImagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholder(),
                            ).animate().fade(duration: 600.ms),
                    )
                  else
                    GestureDetector(
                      onTap: _pickImage,
                      child: _buildPlaceholder(),
                    ),
                  // Gradient over image for text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            theme.scaffoldBackgroundColor,
                            theme.scaffoldBackgroundColor.withValues(
                              alpha: 0.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  // Title
                  Text(
                        _currentRecipe.title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      )
                      .animate()
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.05, curve: Curves.easeOutCubic),
                  SizedBox(height: 16),

                  // Meta Row (Time, Rating)
                  SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            if (_currentRecipe.prepTime != null) ...[
                              _buildMetaChip(
                                theme,
                                icon: CupertinoIcons.clock,
                                label: _currentRecipe.prepTime!,
                              ),
                              SizedBox(width: 8),
                            ],
                            GestureDetector(
                              onTap: () {
                                if (_scrollController.hasClients) {
                                  _scrollController.animateTo(
                                    _scrollController.position.maxScrollExtent,
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeOutCubic,
                                  );
                                }
                              },
                              child: _buildMetaChip(
                                theme,
                                icon: CupertinoIcons.star_fill,
                                iconColor: Colors.amber,
                                label: (_currentRecipe.rating ?? 0) > 0
                                    ? (_currentRecipe.rating!).toStringAsFixed(
                                        1,
                                      )
                                    : 'Sin valorar'.tr,
                              ),
                            ),
                            if (!isPersonalized) ...[
                              SizedBox(width: 8),
                              _buildMetaChip(
                                theme,
                                icon: CupertinoIcons.checkmark_seal_fill,
                                label: 'Predeterminada'.tr,
                              ),
                            ],
                          ],
                        ),
                      )
                      .animate(delay: 150.ms)
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.05, curve: Curves.easeOutCubic),
                  SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),

                  if (hasIngredients)
                    IngredientsView(recipe: _currentRecipe)
                        .animate(delay: 200.ms)
                        .fade(duration: 400.ms)
                        .slideY(begin: 0.05, curve: Curves.easeOutCubic),
                  if (hasIngredients && (hasInstructions || hasInfo))
                    Divider(
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.1),
                    ).animate(delay: 250.ms).fade(),
                  if (hasInstructions)
                    InstructionsView(recipe: _currentRecipe)
                        .animate(delay: 250.ms)
                        .fade(duration: 400.ms)
                        .slideY(begin: 0.05, curve: Curves.easeOutCubic),
                  if (hasInstructions && hasInfo)
                    Divider(
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.1),
                    ).animate(delay: 300.ms).fade(),
                  if (hasInfo)
                    InfoView(recipe: _currentRecipe)
                        .animate(delay: 300.ms)
                        .fade(duration: 400.ms)
                        .slideY(begin: 0.05, curve: Curves.easeOutCubic),

                  if (hasIngredients || hasInstructions || hasInfo)
                    Divider(
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.1),
                    ).animate(delay: 350.ms).fade(),

                  Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: PremiumRatingButton(recipe: _currentRecipe),
                      )
                      .animate(delay: 350.ms)
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.05, curve: Curves.easeOutCubic),

                  SizedBox(height: 80), // spacing for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor ?? theme.colorScheme.primary),
          SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    final theme = Theme.of(context);
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.photo,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            SizedBox(height: 8),
            Text(
              'Toca para añadir foto'.tr,
              style: TextStyle(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}






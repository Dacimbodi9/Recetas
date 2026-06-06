import 'package:recetas/main.dart';
import 'package:flutter/material.dart';
import 'package:recetas/services/snackbar_service.dart';
import 'package:flutter/services.dart';
import 'package:recetas/l10n.dart';
import 'package:recetas/models/models.dart';
import 'package:recetas/services/recipe_manager.dart';
import 'package:app_links/app_links.dart';
import 'dart:io';
import 'dart:async';

class DeepLinkHandler {
  DeepLinkHandler._();
  static final DeepLinkHandler instance = DeepLinkHandler._();

  static const _channel = MethodChannel('com.daniel.recetas/file_reader');
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  void init() {
    _appLinks = AppLinks();
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
    _sub = _appLinks.uriLinkStream.listen(_handleDeepLink);
    _checkInitialFileIntent();
  }

  void dispose() => _sub?.cancel();

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'recetas' || uri.host != 'recipe') return;
    final segments = uri.pathSegments;
    if (segments.isEmpty) return;
    final encodedData = segments.first;
    final recipe = Recipe.fromShareableData(encodedData);
    if (recipe != null) {
      final sanitized = _sanitizeRecipe(recipe);
      Future.delayed(
        const Duration(milliseconds: 500),
        () => _showImportDialog(sanitized),
      );
    }
  }

  Future<void> _checkInitialFileIntent() async {
    try {
      final uriString = await _channel.invokeMethod<String>('getIntentData');
      if (uriString != null) await _handleFileUri(uriString);
    } catch (e) {
      debugPrint('Error checking initial file intent: $e'); SnackbarService.showError('Error checking initial file intent: $e');
    }
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewFileIntent') {
        final uriString = call.arguments as String?;
        if (uriString != null) await _handleFileUri(uriString);
      }
    });
  }

  Future<void> _handleFileUri(String uriString) async {
    if (uriString.startsWith('recetas://')) return;
    try {
      String? content;
      if (uriString.startsWith('content://')) {
        content = await _channel.invokeMethod<String>('readContentUri', {
          'uri': uriString,
        });
      } else if (uriString.startsWith('file://')) {
        final path = Uri.parse(uriString).toFilePath();
        content = await File(path).readAsString();
      }
      if (content != null) {
        final recipe = Recipe.fromShareableData(content.trim());
        if (recipe != null) {
          final sanitized = _sanitizeRecipe(recipe);
          Future.delayed(
            const Duration(milliseconds: 500),
            () => _showImportDialog(sanitized),
          );
        }
      }
    } catch (e) {
      debugPrint('Error handling file URI: $e'); SnackbarService.showError('Error handling file URI: $e');
    }
  }

  Recipe _sanitizeRecipe(Recipe original) {
    String sanitizeText(String input) {
      return input.replaceAll(RegExp(r'<[^>]*>', multiLine: true), '').trim();
    }

    return Recipe(
      id: original.id,
      title: sanitizeText(original.title).isEmpty ? 'Untitled Recipe' : sanitizeText(original.title),
      ingredients: original.ingredients.map(sanitizeText).where((s) => s.isNotEmpty).toList(),
      dietaryRestrictions: original.dietaryRestrictions,
      customDietaryTags: original.customDietaryTags.map(sanitizeText).where((s) => s.isNotEmpty).toList(),
      categories: original.categories,
      imagePath: original.imagePath != null ? sanitizeText(original.imagePath!) : null,
      steps: original.steps.map(sanitizeText).where((s) => s.isNotEmpty).toList(),
      nutritionFacts: original.nutritionFacts,
      prepTime: original.prepTime != null ? sanitizeText(original.prepTime!) : null,
      detailedIngredients: original.detailedIngredients.map((d) => DetailedIngredient(
        name: sanitizeText(d.name),
        quantity: sanitizeText(d.quantity),
        category: d.category,
      )).toList(),
      rating: original.rating,
      dateRated: original.dateRated,
    );
  }

  void _showImportDialog(Recipe recipe) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final exists = RecipeManager.recipes.any((r) => r.title == recipe.title);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Receta compartida detectada'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'¿Quieres importar la receta'.tr} "${recipe.title}"?'),
            if (exists) ...[
              const SizedBox(height: 12),
              Text(
                'Nota: Ya tienes una receta con este nombre.'.tr,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'.tr),
          ),
          FilledButton(
            onPressed: () async {
              await RecipeManager.addRecipe(recipe);
              if (!RecipeManager.isFavorite(recipe)) {
                await RecipeManager.toggleFavorite(recipe);
              }
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Receta importada correctamente'.tr)),
                );
              }
            },
            child: Text('Importar'.tr),
          ),
        ],
      ),
    );
  }
}

part of '../main.dart';

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
      Future.delayed(
        const Duration(milliseconds: 500),
        () => _showImportDialog(recipe),
      );
    }
  }

  Future<void> _checkInitialFileIntent() async {
    try {
      final uriString = await _channel.invokeMethod<String>('getIntentData');
      if (uriString != null) await _handleFileUri(uriString);
    } catch (e) {
      debugPrint('Error checking initial file intent: $e');
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
          Future.delayed(
            const Duration(milliseconds: 500),
            () => _showImportDialog(recipe),
          );
        }
      }
    } catch (e) {
      debugPrint('Error handling file URI: $e');
    }
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

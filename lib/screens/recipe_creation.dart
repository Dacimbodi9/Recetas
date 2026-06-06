import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:recetas/l10n.dart';
import 'package:recetas/models/models.dart';
import 'package:recetas/utils/utils.dart';
import 'package:recetas/services/settings_manager.dart';
import 'package:recetas/services/recipe_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

part 'recipe_creation/step1_overview.dart';
part 'recipe_creation/step2_ingredients.dart';
part 'recipe_creation/step3_instructions.dart';
part 'recipe_creation/step4_details.dart';

class NewRecipePage extends StatefulWidget {
  const NewRecipePage({super.key, this.recipeToEdit});

  final Recipe? recipeToEdit;

  @override
  State<NewRecipePage> createState() => _NewRecipePageState();
}

class _NewRecipePageState extends State<NewRecipePage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final TextEditingController _ingredientController = TextEditingController();

  // Data
  String? _selectedImagePath;
  String _ingredientQuery = '';
  final List<DetailedIngredient> _detailedIngredients = [];
  final List<String> _steps = [];
  bool _isReorderingSteps = false;
  final Set<RecipeCategory> _selectedCategories = {};
  final Set<DietaryRestriction> _selectedDietaryRestrictions = {};
  final Set<String> _selectedCustomTags = {};

  // Nutrition (Simplified for UI, but kept in code)
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  Recipe? _initialRecipeSnapshot;
  Timer? _autoSaveTimer;
  static const String _draftKey = 'recipe_draft';

  @override
  void initState() {
    super.initState();
    if (widget.recipeToEdit != null) {
      _loadRecipeData(widget.recipeToEdit!);
      // Snapshot the loaded state to detect real changes later
      _initialRecipeSnapshot = _buildCurrentRecipe();
    } else {
      _checkDraft();
      _startAutoSave();
    }
  }

  Future<void> _checkDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString(_draftKey);
    if (draftJson != null && draftJson.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Borrador encontrado'.tr),
            action: SnackBarAction(
              label: 'Restaurar'.tr,
              onPressed: () {
                final draftMap = json.decode(draftJson) as Map<String, dynamic>;
                final draftRecipe = Recipe.fromJson(draftMap);
                setState(() {
                  _loadRecipeData(draftRecipe);
                });
              },
            ),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_titleController.text.trim().isNotEmpty) {
        final current = _buildCurrentRecipe();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_draftKey, json.encode(current.toJson()));
      }
    });
  }

  void _loadRecipeData(Recipe recipe) {
    _titleController.text = recipe.title;
    if (recipe.prepTime != null) _prepTimeController.text = recipe.prepTime!;

    _detailedIngredients.addAll(recipe.detailedIngredients);
    // If old simple ingredients exist and detailed are empty, try to convert?
    // For now we rely on detailedIngredients being populated or manual entry.

    _steps.addAll(recipe.steps);
    _selectedCategories.addAll(recipe.categories);
    _selectedDietaryRestrictions.addAll(recipe.dietaryRestrictions);
    _selectedCustomTags.addAll(recipe.customDietaryTags);

    if (recipe.imagePath != null) _selectedImagePath = recipe.imagePath;

    for (final fact in recipe.nutritionFacts) {
      if (fact.label == 'Calorías') {
        _caloriesController.text = fact.value.toString();
      }
      if (fact.label == 'Proteína') {
        _proteinController.text = fact.value.toString();
      }
      if (fact.label == 'Carbohidratos') {
        _carbsController.text = fact.value.toString();
      }
      if (fact.label == 'Grasas') _fatController.text = fact.value.toString();
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _pageController.dispose();
    _titleController.dispose();
    _prepTimeController.dispose();
    _ingredientController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveRecipe();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
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

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final imageDir = Directory('${appDir.path}/recipe_images');
        if (!await imageDir.exists()) {
          await imageDir.create(recursive: true);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'recipe_$timestamp.jpg';
        final savedImage = File('${imageDir.path}/$fileName');

        await File(image.path).copy(savedImage.path);

        setState(() {
          _selectedImagePath = savedImage.path;
        });
      }
    } catch (e) {
      if (mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al seleccionar imagen: $e')),
          );
        }
      }
    }
  }

  Future<void> _scanRecipeLocally() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image == null) return;
    if (!mounted) return;

    if (SettingsManager.aiApiKey.value.isEmpty) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Por favor configura un API Key de IA en Configuración primero.'
                  .tr,
            ),
          ),
        );
      }
      return;
    }

    final navigator = Navigator.of(context);
    bool isDialogShowing = false;

    if (mounted && context.mounted) {
      isDialogShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);
          return Dialog(
            backgroundColor: theme.brightness == Brightness.dark
                ? Color(0xFF1C1C1E)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.sparkles,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Analizando Receta...'.tr,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(strokeWidth: 3),
                  SizedBox(height: 32),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.info_circle_fill,
                          size: 20,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aviso: La IA puede equivocarse o saltarse algunos ingredientes. Revisa siempre los resultados.'
                                .tr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final dio = Dio();
      final provider = SettingsManager.aiProvider.value;
      final apiKey = SettingsManager.aiApiKey.value;
      final promptText =
          'Extrae la receta de la imagen. Responde ÚNICAMENTE con un JSON válido con la estructura estricta: {"title": "String", "ingredients": [{"name": "String", "quantity": "String"}], "steps": ["String","String"]}. Extrae las cantidades al campo quantity y el nombre del ingrediente al campo name. No añadas texto fuera del JSON (ni bloques de código o markdown).';

      Response response;
      String responseText = '';

      if (provider == 'gemini') {
        final endpoint =
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';
        response = await dio.post(
          endpoint,
          options: Options(headers: {'Content-Type': 'application/json'}),
          data: {
            'contents': [
              {
                'parts': [
                  {'text': promptText},
                  {
                    'inline_data': {
                      'mime_type': 'image/jpeg',
                      'data': base64Image,
                    },
                  },
                ],
              },
            ],
            'generationConfig': {'response_mime_type': 'application/json'},
          },
        );

        responseText =
            response.data['candidates'][0]['content']['parts'][0]['text'];

        // Clean markdown blocks if Gemini fails to omit them
        if (responseText.startsWith('```json')) {
          responseText = responseText
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
        } else if (responseText.startsWith('```')) {
          responseText = responseText.replaceAll('```', '').trim();
        }
      } else {
        final endpoint = SettingsManager.aiApiEndpoint.value.isEmpty
            ? 'https://api.openai.com/v1/chat/completions'
            : SettingsManager.aiApiEndpoint.value;
        response = await dio.post(
          endpoint,
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
          ),
          data: {
            'model': 'gpt-4o',
            'messages': [
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': promptText},
                  {
                    'type': 'image_url',
                    'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
                  },
                ],
              },
            ],
            'response_format': {'type': 'json_object'},
          },
        );
        responseText = response.data['choices'][0]['message']['content'];
      }
      final Map<String, dynamic> recipeData = jsonDecode(responseText);

      setState(() {
        if (recipeData['title'] != null && _titleController.text.isEmpty) {
          _titleController.text = recipeData['title'].toString();
        }

        if (recipeData['ingredients'] is List) {
          for (var ing in (recipeData['ingredients'] as List)) {
            if (ing is Map) {
              _detailedIngredients.add(
                DetailedIngredient(
                  name: ing['name']?.toString() ?? '',
                  quantity: ing['quantity']?.toString() ?? '',
                ),
              );
            } else {
              _detailedIngredients.add(
                DetailedIngredient(name: ing.toString(), quantity: ''),
              );
            }
          }
        }

        if (recipeData['steps'] is List) {
          for (var step in (recipeData['steps'] as List)) {
            _steps.add(step.toString());
          }
        }
      });

      if (isDialogShowing) {
        navigator.pop();
        isDialogShowing = false;
      }

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Importación completada con éxito!'.tr)),
        );
      }
    } catch (e) {
      if (isDialogShowing) {
        navigator.pop();
        isDialogShowing = false;
      }

      if (mounted && context.mounted) {
        String errorMessage = '${'Hubo un error con la IA'.tr}: $e';
        if (e is DioException) {
          if (e.response?.statusCode == 401) {
            errorMessage =
                'La clave de API (API Key) es inválida o incorrecta. Por favor, revísala en Configuración.'
                    .tr;
          } else {
            errorMessage =
                'Error de conexión con la IA (Código ${e.response?.statusCode ?? "desconocido"}).'
                    .tr;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), duration: Duration(seconds: 5)),
        );
      }
    }
  }

  // --- Logic Helpers ---

  bool _areRecipesDifferent(Recipe oldR, Recipe newR) {
    if (oldR.title != newR.title) return true;
    if (oldR.prepTime != newR.prepTime) return true;
    if (oldR.imagePath != newR.imagePath) return true;

    // Compare detailed ingredients (the canonical source of truth)
    if (oldR.detailedIngredients.length != newR.detailedIngredients.length) {
      return true;
    }
    for (int i = 0; i < oldR.detailedIngredients.length; i++) {
      if (oldR.detailedIngredients[i].name !=
          newR.detailedIngredients[i].name) {
        return true;
      }
      if (oldR.detailedIngredients[i].quantity !=
          newR.detailedIngredients[i].quantity) {
        return true;
      }
    }

    if (!listEquals(oldR.steps, newR.steps)) return true;

    if (!setEquals(oldR.categories.toSet(), newR.categories.toSet())) {
      return true;
    }
    if (!setEquals(
      oldR.dietaryRestrictions.toSet(),
      newR.dietaryRestrictions.toSet(),
    )) {
      return true;
    }
    if (!setEquals(
      oldR.customDietaryTags.toSet(),
      newR.customDietaryTags.toSet(),
    )) {
      return true;
    }

    // Simple Nutrition check
    if (oldR.nutritionFacts.length != newR.nutritionFacts.length) return true;
    for (int i = 0; i < oldR.nutritionFacts.length; i++) {
      final f1 = oldR.nutritionFacts[i];
      final f2 = newR.nutritionFacts[i];
      if (f1.label != f2.label || f1.value != f2.value || f1.unit != f2.unit) {
        return true;
      }
    }

    return false;
  }

  Recipe _buildCurrentRecipe() {
    final normalizedIngredients = _detailedIngredients
        .map((d) => d.name)
        .toList();
    List<NutritionFact> nutritionFacts = [];
    void addFact(TextEditingController ctrl, String label, String unit) {
      final txt = ctrl.text.trim().replaceAll(',', '.');
      if (txt.isNotEmpty) {
        final val = double.tryParse(txt);
        if (val != null && val > 0) {
          nutritionFacts.add(
            NutritionFact(label: label, value: val, unit: unit),
          );
        }
      }
    }

    addFact(_caloriesController, 'Calorías', 'kcal');
    addFact(_proteinController, 'Proteína', 'g');
    addFact(_carbsController, 'Carbohidratos', 'g');
    addFact(_fatController, 'Grasas', 'g');

    return Recipe(
      title: _titleController.text.trim(),
      ingredients: normalizedIngredients,
      detailedIngredients: List.of(_detailedIngredients),
      prepTime: _prepTimeController.text.trim().isNotEmpty
          ? _prepTimeController.text.trim()
          : null,
      categories: _selectedCategories.toList(),
      dietaryRestrictions: _selectedDietaryRestrictions.toList(),
      customDietaryTags: _selectedCustomTags.toList(),
      imagePath: _selectedImagePath,
      steps: List.of(_steps),
      nutritionFacts: nutritionFacts,
      rating: widget.recipeToEdit?.rating,
    );
  }

  bool _hasUnsavedChanges() {
    final current = _buildCurrentRecipe();
    if (_initialRecipeSnapshot != null) {
      return _areRecipesDifferent(_initialRecipeSnapshot!, current);
    } else {
      // New recipe: check if anything was entered
      return current.title.isNotEmpty ||
          current.detailedIngredients.isNotEmpty ||
          current.steps.isNotEmpty ||
          current.imagePath != null ||
          current.prepTime != null ||
          current.nutritionFacts.isNotEmpty ||
          current.categories.isNotEmpty ||
          current.dietaryRestrictions.isNotEmpty;
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

  Future<void> _saveRecipe() async {
    if (_titleController.text.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor, escribe un nombre para la receta'.tr),
          ),
        );
      }
      return;
    }

    final newRecipe = _buildCurrentRecipe();

    // Check for changes if editing
    if (_initialRecipeSnapshot != null) {
      if (_areRecipesDifferent(_initialRecipeSnapshot!, newRecipe)) {
        final choice = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Guardar cambios'.tr),
            content: Text(
              'Has modificado la receta. ¿Deseas actualizar la actual o guardar como una nueva?'
                  .tr,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'new'),
                child: Text('Guardar como nueva'.tr),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, 'update'),
                child: Text('Actualizar'.tr),
              ),
            ],
          ),
        );

        if (choice == null) return; // Cancelled

        if (choice == 'new') {
          // Create copy
          Recipe recipeToSave = newRecipe;
          // If user didn't change title manually, we must change it to allow 'new'.
          if (newRecipe.title == widget.recipeToEdit!.title) {
            recipeToSave = newRecipe.copyWith(
              title: '${newRecipe.title} (Copia)',
            );
          }

          try {
            await RecipeManager.addRecipe(recipeToSave);
            // Also favorite the copy
            if (!RecipeManager.isFavorite(recipeToSave)) {
              await RecipeManager.toggleFavorite(recipeToSave);
            }

            if (mounted) {
              if (context.mounted) Navigator.of(context).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Receta guardada como nueva'.tr)),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error al guardar'.tr)));
              }
            }
          }
          return;
        }
        // If 'update', continue to standard saving logic below
      }
    }

    try {
      if (widget.recipeToEdit != null &&
          widget.recipeToEdit!.title != newRecipe.title) {
        await RecipeManager.removeRecipe(widget.recipeToEdit!);
      }
      await RecipeManager.addRecipe(newRecipe);

      if (!RecipeManager.isFavorite(newRecipe) && widget.recipeToEdit == null) {
        await RecipeManager.toggleFavorite(newRecipe);
      }

      // Clear draft on successful save
      if (widget.recipeToEdit == null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_draftKey);
      }

      if (mounted) {
        if (context.mounted) Navigator.of(context).pop(); // Close wizard
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.recipeToEdit != null
                    ? 'Receta actualizada'.tr
                    : 'Receta creada'.tr,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar la receta'.tr)),
          );
        }
      }
    }
  }

  void _addIngredient(DetailedIngredient ingredient) {
    setState(() {
      _detailedIngredients.add(ingredient);
      _ingredientController.clear();
      _ingredientQuery = '';
    });
  }

  void _removeIngredient(DetailedIngredient ingredient) {
    setState(() {
      _detailedIngredients.remove(ingredient);
    });
  }

  void _addStep(String step) {
    if (step.trim().isNotEmpty) {
      setState(() => _steps.add(step.trim()));
    }
  }

  void _editStep(int index, String newText) {
    if (newText.trim().isNotEmpty) {
      setState(() => _steps[index] = newText.trim());
    }
  }

  void _showStepOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(CupertinoIcons.pencil),
              title: Text('Editar paso'.tr),
              onTap: () {
                Navigator.pop(context);
                final controller = TextEditingController(text: _steps[index]);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Editar paso'.tr),
                    content: TextField(
                      textCapitalization: TextCapitalization.sentences,
                      controller: controller,
                      maxLines: 3,
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancelar'.tr),
                      ),
                      FilledButton(
                        onPressed: () {
                          _editStep(index, controller.text);
                          Navigator.pop(context);
                        },
                        child: Text('Guardar'.tr),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (index > 0 && !_isReorderingSteps)
              ListTile(
                leading: Icon(CupertinoIcons.arrow_up),
                title: Text('Mover arriba'.tr),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    final item = _steps.removeAt(index);
                    _steps.insert(index - 1, item);
                  });
                },
              ),
            if (index < _steps.length - 1 && !_isReorderingSteps)
              ListTile(
                leading: Icon(CupertinoIcons.arrow_down),
                title: Text('Mover abajo'.tr),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    final item = _steps.removeAt(index);
                    _steps.insert(index + 1, item);
                  });
                },
              ),
            ListTile(
              leading: Icon(CupertinoIcons.trash, color: Colors.redAccent),
              title: Text(
                'Eliminar paso'.tr,
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() => _steps.removeAt(index));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickQuantityDialog(String ingredientName) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cantidad para $ingredientName'),
        content: TextField(
          textCapitalization: TextCapitalization.sentences,
          controller: controller,
          decoration: InputDecoration(labelText: 'Ej: 200g, 1 un, al gusto...'),
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

  void _showAddStepDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Añadir paso'.tr),
        content: TextField(
          textCapitalization: TextCapitalization.sentences,
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Describe el paso...'.tr),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'.tr),
          ),
          FilledButton(
            onPressed: () {
              _addStep(controller.text);
              Navigator.pop(context);
            },
            child: Text('Añadir'.tr),
          ),
        ],
      ),
    );
  }

  void _showAddCustomIngredientDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddIngredientDialog(
        onAdd: (name, qty, category) {
          if (name.isNotEmpty) {
            if (category != null) {
              RecipeManager.addCustomMapping(name, category);
            }
            _addIngredient(DetailedIngredient(name: name, quantity: qty));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _attemptClose();
      },
      child: Scaffold(
        // backgroundColor: Use theme default
        body: SafeArea(
          child: FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: Column(
            children: [
              // Top Bar & Progress
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Close Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(CupertinoIcons.xmark),
                        onPressed: _attemptClose,
                      ),
                    ),

                    // Center Content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.recipeToEdit != null
                              ? 'EDITAR RECETA'.tr
                              : 'NUEVA RECETA'.tr,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_totalSteps, (index) {
                            final isActive = index <= _currentStep;
                            return Container(
                              width: 32,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? theme.colorScheme.primary
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.black.withValues(
                                              alpha: 0.1,
                                            )),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics:
                      NeverScrollableScrollPhysics(), // Disable swipe, enforce buttons
                  onPageChanged: (index) =>
                      setState(() => _currentStep = index),
                  children: [
                    _buildStep1Overview(theme),
                    _buildStep2Ingredients(theme),
                    _buildStep3Instructions(theme),
                    _buildStep4Details(theme),
                  ],
                ),
              ),

              // Bottom Action Bar (Back / Next)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: _prevStep,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.chevron_left, size: 18),
                              SizedBox(width: 8),
                              Text('Atrás'.tr),
                            ],
                          ),
                        ),
                      ),
                    if (_currentStep > 0) SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _currentStep == _totalSteps - 1
                            ? _saveRecipe
                            : _nextStep,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep == _totalSteps - 1
                                  ? (widget.recipeToEdit != null
                                        ? 'Guardar Cambios'.tr
                                        : 'Finalizar Receta'.tr)
                                  : 'Siguiente'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_currentStep < _totalSteps - 1) ...[
                              SizedBox(width: 8),
                              Icon(CupertinoIcons.chevron_right, size: 18),
                            ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Step 1: Basics ---
  Widget _buildAddPhotoPlaceholder(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(CupertinoIcons.camera, size: 48, color: theme.colorScheme.primary),
        SizedBox(height: 12),
        Text(
          'Añadir foto'.tr,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }



  Widget _buildInputSection(
    ThemeData theme, {
    String? title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8, top: 4),
            child: Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Material(
            color: theme.brightness == Brightness.dark
                ? theme.cardColor
                : theme.cardColor,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactNutriInput(
    ThemeData theme,
    TextEditingController controller,
    String label,
  ) {
    return TextField(
      textCapitalization: TextCapitalization.sentences,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // --- Step 2: Ingredients ---


  // --- Step 3: Instructions ---


  // --- Step 4: Tags & Finish ---


  Widget _buildTagSection<T>({
    required ThemeData theme,
    required String title,
    required List<T> items,
    required bool Function(T) isSelected,
    required Function(T) onToggle,
    required String Function(T) getLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final active = isSelected(item);
            return FilterChip(
              label: Text(getLabel(item)),
              selected: active,
              onSelected: (_) => onToggle(item),
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.3),
              checkmarkColor: theme.colorScheme.primary,
              side: BorderSide(
                color: active ? theme.colorScheme.primary : Colors.transparent,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showAddCustomTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Añadir etiqueta'.tr),
        content: TextField(
          textCapitalization: TextCapitalization.sentences,
          controller: controller,
          decoration: InputDecoration(hintText: 'Ej: Keto, Low Carb...'.tr),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'.tr),
          ),
          FilledButton(
            onPressed: () {
              final tag = controller.text.trim();
              if (tag.isNotEmpty) {
                setState(() {
                  _selectedCustomTags.add(tag);
                });
              }
              Navigator.pop(context);
            },
            child: Text('Añadir'.tr),
          ),
        ],
      ),
    );
  }
}

class AddIngredientDialog extends StatefulWidget {
  const AddIngredientDialog({super.key, required this.onAdd});

  final void Function(String, String, IngredientCategory?) onAdd;

  @override
  State<AddIngredientDialog> createState() => AddIngredientDialogState();
}

class AddIngredientDialogState extends State<AddIngredientDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  IngredientCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _quantityController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Crear ingrediente'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            textCapitalization: TextCapitalization.sentences,
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Nombre del ingrediente'.tr,
              labelText: 'Ingrediente'.tr,
            ),
            autofocus: true,
          ),
          SizedBox(height: 12),
          TextField(
            textCapitalization: TextCapitalization.sentences,
            controller: _quantityController,
            decoration: InputDecoration(
              hintText: 'Ej: 200g'.tr,
              labelText: 'Cantidad'.tr,
            ),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<IngredientCategory>(
            initialValue: _selectedCategory,
            borderRadius: BorderRadius.circular(16),
            dropdownColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.white,
            icon: Icon(CupertinoIcons.chevron_down, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            decoration: InputDecoration(
              labelText: 'Categoría'.tr,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            isExpanded: true,
            items: IngredientCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Row(
                  children: [
                    Icon(category.icon, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'.tr),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              widget.onAdd(
                _nameController.text.trim(),
                _quantityController.text.trim(),
                _selectedCategory,
              );
              if (context.mounted) Navigator.of(context).pop();
            }
          },
          child: Text('Crear'.tr),
        ),
      ],
    );
  }
}

class _AddStepDialog extends StatefulWidget {
  const _AddStepDialog({required this.onAdd});

  final void Function(String) onAdd;

  @override
  State<_AddStepDialog> createState() => _AddStepDialogState();
}

class _AddStepDialogState extends State<_AddStepDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Añadir paso'.tr),
      content: TextField(
        textCapitalization: TextCapitalization.sentences,
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Describe el paso de la receta'.tr,
          labelText: 'Paso'.tr,
        ),
        autofocus: true,
        maxLines: 3,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            widget.onAdd(value.trim());
            if (context.mounted) Navigator.of(context).pop();
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'.tr),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              widget.onAdd(_controller.text.trim());
              if (context.mounted) Navigator.of(context).pop();
            }
          },
          child: Text('Añadir'.tr),
        ),
      ],
    );
  }
}





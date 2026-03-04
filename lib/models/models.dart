// ignore_for_file: deprecated_member_use
// ignore_for_file: unused_local_variable
// ignore_for_file: constant_identifier_names
part of '../main.dart';

enum DietaryRestriction {
  vegetariano,
  vegano,
  sinlactosa,
  singluten,
  sinfrutossecos,
  sinmariscos,
}

extension DietaryRestrictionExtension on DietaryRestriction {
  String get displayName {
    switch (this) {
      case DietaryRestriction.vegetariano:
        return 'Vegetariano'.tr;
      case DietaryRestriction.vegano:
        return 'Vegano'.tr;
      case DietaryRestriction.sinlactosa:
        return 'Sin lactosa'.tr;
      case DietaryRestriction.singluten:
        return 'Sin gluten'.tr;
      case DietaryRestriction.sinfrutossecos:
        return 'Sin frutos secos'.tr;
      case DietaryRestriction.sinmariscos:
        return 'Sin mariscos'.tr;
    }
  }

  String get description {
    switch (this) {
      case DietaryRestriction.vegetariano:
        return 'No contiene carne'.tr;
      case DietaryRestriction.vegano:
        return 'No contiene productos animales'.tr;
      case DietaryRestriction.sinlactosa:
        return 'Sin lactosa'.tr;
      case DietaryRestriction.singluten:
        return 'Sin gluten'.tr;
      case DietaryRestriction.sinfrutossecos:
        return 'Sin frutos secos'.tr;
      case DietaryRestriction.sinmariscos:
        return 'Sin mariscos'.tr;
    }
  }
}

enum RecipeCategory {
  entrantes,
  sopasycremas,
  ensaladas,
  platosprincipales,
  guarniciones,
  postresydulces,
  bebidas,
  otros,
}

extension RecipeCategoryX on RecipeCategory {
  String get displayName {
    switch (this) {
      case RecipeCategory.entrantes:
        return 'Entrantes'.tr;
      case RecipeCategory.sopasycremas:
        return 'Sopas y Cremas'.tr;
      case RecipeCategory.ensaladas:
        return 'Ensaladas'.tr;
      case RecipeCategory.platosprincipales:
        return 'Platos Principales'.tr;
      case RecipeCategory.guarniciones:
        return 'Guarniciones'.tr;
      case RecipeCategory.postresydulces:
        return 'Postres y Dulces'.tr;
      case RecipeCategory.bebidas:
        return 'Bebidas'.tr;
      case RecipeCategory.otros:
        return 'Otros'.tr;
    }
  }

  IconData get icon {
    switch (this) {
      case RecipeCategory.entrantes:
        return Icons.tapas;
      case RecipeCategory.sopasycremas:
        return Icons.soup_kitchen;
      case RecipeCategory.ensaladas:
        return Icons.grass;
      case RecipeCategory.platosprincipales:
        return Icons.dinner_dining;
      case RecipeCategory.guarniciones:
        return Icons.breakfast_dining;
      case RecipeCategory.postresydulces:
        return Icons.bakery_dining;
      case RecipeCategory.bebidas:
        return Icons.local_bar;
      case RecipeCategory.otros:
        return Icons.kitchen;
    }
  }
}

enum IngredientCategory {
  frescosVegetales,
  proteinaAnimal,
  lacteosYHuevos,
  granosYPastas,
  aceitesYGrasas,
  condimentosYEspecias,
  reposteriaYHarinas,
  conservasYVarios,
}

extension IngredientCategoryX on IngredientCategory {
  String get displayName {
    switch (this) {
      case IngredientCategory.frescosVegetales:
        return 'Frescos Vegetales'.tr;
      case IngredientCategory.proteinaAnimal:
        return 'Proteína Animal'.tr;
      case IngredientCategory.lacteosYHuevos:
        return 'Lácteos y Huevos'.tr;
      case IngredientCategory.granosYPastas:
        return 'Granos y Pastas'.tr;
      case IngredientCategory.aceitesYGrasas:
        return 'Aceites y Grasas'.tr;
      case IngredientCategory.condimentosYEspecias:
        return 'Condimentos y Especias'.tr;
      case IngredientCategory.reposteriaYHarinas:
        return 'Repostería y Harinas'.tr;
      case IngredientCategory.conservasYVarios:
        return 'Conservas y Varios'.tr;
    }
  }

  IconData get icon {
    switch (this) {
      case IngredientCategory.frescosVegetales:
        return Icons.eco;
      case IngredientCategory.proteinaAnimal:
        return Icons.set_meal;
      case IngredientCategory.lacteosYHuevos:
        return Icons.local_drink;
      case IngredientCategory.granosYPastas:
        return Icons.grain;
      case IngredientCategory.aceitesYGrasas:
        return Icons.oil_barrel;
      case IngredientCategory.condimentosYEspecias:
        return Icons.restaurant_menu;
      case IngredientCategory.reposteriaYHarinas:
        return Icons.cake;
      case IngredientCategory.conservasYVarios:
        return Icons.inventory;
    }
  }
}

class DetailedIngredient {
  DetailedIngredient({required this.name, required this.quantity});

  final String name;
  final String quantity;

  Map<String, dynamic> toJson() => {'name': name, 'quantity': quantity};

  factory DetailedIngredient.fromJson(Map<String, dynamic> json) {
    return DetailedIngredient(
      name: json['name'] as String,
      quantity: json['quantity'] as String,
    );
  }
}

class Recipe {
  Recipe({
    required this.title,
    required this.ingredients,
    this.dietaryRestrictions = const [],
    this.categories = const [],
    this.imagePath,
    this.steps = const [],
    this.nutritionFacts = const [],
    this.prepTime,
    this.detailedIngredients = const [],
    this.rating,
    this.dateRated,
    this.customDietaryTags = const [],
  });

  final String title;
  final List<String> ingredients;
  final List<DietaryRestriction> dietaryRestrictions;
  final List<String> customDietaryTags;
  final List<RecipeCategory> categories;
  final String? imagePath;
  final List<String> steps;
  final List<NutritionFact> nutritionFacts;
  final String? prepTime;
  final List<DetailedIngredient> detailedIngredients;
  final double? rating;
  final DateTime? dateRated;

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'ingredients': ingredients,
      'dietaryRestrictions': dietaryRestrictions.map((r) => r.name).toList(),
      if (customDietaryTags.isNotEmpty) 'customDietaryTags': customDietaryTags,
      'categories': categories.map((c) => c.name).toList(),
      if (imagePath != null) 'imagePath': imagePath,
      if (steps.isNotEmpty) 'steps': steps,
      if (nutritionFacts.isNotEmpty)
        'nutritionFacts': nutritionFacts.map((fact) => fact.toJson()).toList(),
      if (prepTime != null) 'prepTime': prepTime,
      if (detailedIngredients.isNotEmpty)
        'detailedIngredients': detailedIngredients
            .map((i) => i.toJson())
            .toList(),
      if (rating != null) 'rating': rating,
      if (dateRated != null) 'dateRated': dateRated!.toIso8601String(),
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      title: json['title'] as String,
      ingredients: (json['ingredients'] != null)
          ? List<String>.from(json['ingredients'])
          : <String>[],
      dietaryRestrictions: (json['dietaryRestrictions'] != null)
          ? (json['dietaryRestrictions'] as List)
                .map((r) {
                  try {
                    final raw = r.toString().toLowerCase().replaceAll(' ', '').replaceAll('-', '');
                    return DietaryRestriction.values.firstWhere((e) {
                      if (e.name == raw) return true;
                      if (e.displayName.toLowerCase().replaceAll(' ', '').replaceAll('-', '') == raw) return true;
                      
                      final Map<DietaryRestriction, List<String>> allNames = {
                        DietaryRestriction.vegetariano: ['vegetariano', 'vegetarian'],
                        DietaryRestriction.vegano: ['vegano', 'vegan'],
                        DietaryRestriction.sinlactosa: ['sinlactosa', 'lactosefree', 'dairyfree'],
                        DietaryRestriction.singluten: ['singluten', 'glutenfree'],
                        DietaryRestriction.sinfrutossecos: ['sinfrutossecos', 'nutfree'],
                        DietaryRestriction.sinmariscos: ['sinmariscos', 'seafoodfree'],
                      };
                      return allNames[e]?.contains(raw) ?? false;
                    });
                  } catch (e) {
                    return null;
                  }
                })
                .whereType<DietaryRestriction>()
                .toList()
          : [],
      customDietaryTags: (json['customDietaryTags'] != null)
          ? List<String>.from(json['customDietaryTags'])
          : [],
      categories: _parseCategories(json['categories']),
      imagePath: json['imagePath'] as String?,
      prepTime: json['prepTime'] as String?,
      detailedIngredients: (json['detailedIngredients'] != null)
          ? (json['detailedIngredients'] as List)
                .map(
                  (i) => DetailedIngredient.fromJson(i as Map<String, dynamic>),
                )
                .toList()
          : [],
      steps: (json['steps'] != null) ? List<String>.from(json['steps']) : [],
      nutritionFacts: (json['nutritionFacts'] != null)
          ? (json['nutritionFacts'] as List)
                .map(
                  (item) =>
                      NutritionFact.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : [],
      rating: (json['rating'] as num?)?.toDouble(),
      dateRated: json['dateRated'] != null
          ? DateTime.parse(json['dateRated'])
          : null,
    );
  }

  static List<RecipeCategory> _parseCategories(dynamic rawCategories) {
    if (rawCategories == null) return [RecipeCategory.otros];

    final list = (rawCategories as List)
        .map((c) {
          try {
            final categoryStr = c.toString().toLowerCase().replaceAll(' ', '').replaceAll('&', 'y').replaceAll('and', 'y');
            return RecipeCategory.values.firstWhere((e) {
               if (e.name == categoryStr) return true;
               if (e.displayName.toLowerCase().replaceAll(' ', '').replaceAll('&', 'y') == categoryStr) return true;
               
               final Map<RecipeCategory, List<String>> allNames = {
                  RecipeCategory.entrantes: ['entrantes', 'appetizers'],
                  RecipeCategory.sopasycremas: ['sopasycremas', 'soupscreams', 'soups'],
                  RecipeCategory.ensaladas: ['ensaladas', 'salads'],
                  RecipeCategory.platosprincipales: ['platosprincipales', 'maindishes', 'maincourses'],
                  RecipeCategory.guarniciones: ['guarniciones', 'sidedishes', 'sides'],
                  RecipeCategory.postresydulces: ['postresydulces', 'dessertssweets', 'desserts'],
                  RecipeCategory.bebidas: ['bebidas', 'beverages', 'drinks'],
                  RecipeCategory.otros: ['otros', 'others', 'other'],
               };
               return allNames[e]?.contains(categoryStr) ?? false;
            });
          } catch (e) {
            return null;
          }
        })
        .whereType<RecipeCategory>()
        .toList();

    // CRITICAL: Ensure at least one category exists so it appears in UI
    if (list.isEmpty) {
      return [RecipeCategory.otros];
    }

    return list;
  }

  Recipe copyWith({
    String? title,
    List<String>? ingredients,
    List<DietaryRestriction>? dietaryRestrictions,
    List<String>? customDietaryTags,
    List<RecipeCategory>? categories,
    String? imagePath,
    List<String>? steps,
    List<NutritionFact>? nutritionFacts,
    String? prepTime,
    List<DetailedIngredient>? detailedIngredients,
    double? rating,
    DateTime? dateRated,
    bool nullifyRating = false,
  }) {
    return Recipe(
      title: title ?? this.title,
      ingredients: ingredients ?? this.ingredients,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      customDietaryTags: customDietaryTags ?? this.customDietaryTags,
      categories: categories ?? this.categories,
      imagePath: imagePath ?? this.imagePath,
      steps: steps ?? this.steps,
      nutritionFacts: nutritionFacts ?? this.nutritionFacts,
      prepTime: prepTime ?? this.prepTime,
      detailedIngredients: detailedIngredients ?? this.detailedIngredients,
      rating: nullifyRating ? null : (rating ?? this.rating),
      dateRated: nullifyRating ? null : (dateRated ?? this.dateRated),
    );
  }
}

class NutritionFact {
  NutritionFact({required this.label, required this.value, required this.unit});

  final String label;
  final double value;
  final String unit;

  String get formattedAmount {
    final isWhole = value % 1 == 0;
    return value.toStringAsFixed(isWhole ? 0 : 1);
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'value': value,
    'unit': unit,
  };

  factory NutritionFact.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic raw) {
      if (raw is int) return raw.toDouble();
      if (raw is double) return raw;
      if (raw is String) return double.tryParse(raw) ?? 0;
      return 0;
    }

    return NutritionFact(
      label: json['label'] as String? ?? '',
      value: toDouble(json['value']),
      unit: json['unit'] as String? ?? 'g',
    );
  }
}

class FavoriteFolder {
  FavoriteFolder({
    required this.id,
    required this.name,
    required this.icon,
    this.recipeTitles = const [],
    this.subFolders = const [],
    this.parentId,
  });

  final String id;
  final String name;
  final IconData icon;
  final List<String> recipeTitles;
  final List<FavoriteFolder> subFolders;
  final String? parentId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'recipeTitles': recipeTitles,
      'subFolders': subFolders.map((f) => f.toJson()).toList(),
      'parentId': parentId,
    };
  }

  factory FavoriteFolder.fromJson(Map<String, dynamic> json) {
    // Find the matching icon in the available list to avoid dynamic IconData creation
    final int iconCode = json['icon'] as int;
    final IconData icon = RecipeManager.availableFolderIcons.firstWhere(
      (i) => i.codePoint == iconCode,
      orElse: () => CupertinoIcons.folder,
    );

    return FavoriteFolder(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: icon,
      recipeTitles: (json['recipeTitles'] as List?)?.cast<String>() ?? [],
      subFolders:
          (json['subFolders'] as List?)
              ?.map((f) => FavoriteFolder.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      parentId: json['parentId'] as String?,
    );
  }

  FavoriteFolder copyWith({
    String? id,
    String? name,
    IconData? icon,
    List<String>? recipeTitles,
    List<FavoriteFolder>? subFolders,
    String? parentId,
  }) {
    return FavoriteFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      recipeTitles: recipeTitles ?? this.recipeTitles,
      subFolders: subFolders ?? this.subFolders,
      parentId: parentId ?? this.parentId,
    );
  }
}

class _ScoredRecipe {
  _ScoredRecipe({
    required this.recipe,
    required this.matchCount,
    required this.remainingIngredients,
    this.matchedIngredients = const [],
  });

  final Recipe recipe;
  final int matchCount;
  final int remainingIngredients;
  final List<String> matchedIngredients;
}

// Helper function to categorize ingredients based on keywords
List<String> _getIngredientsForCategory(
  IngredientCategory category,
  List<String> allIngredients,
) {
  final keywords = <IngredientCategory, List<String>>{
    IngredientCategory.frescosVegetales: [
      'fruta', 'verdura', 'vegetal', 'hortaliza', 'tomate', 'cebolla', 'ajo',
      'pimiento', 'papa', 'patata', 'zanahoria', 'lechuga', 'espinaca', 'brócoli',
      'coliflor', 'calabaza', 'pepino', 'berenjena', 'calabacín', 'puerro', 'apio',
      'remolacha', 'rábano', 'manzana', 'plátano', 'naranja', 'limón', 'fresa',
      'uva', 'melón', 'sandía', 'aguacate', 'champiñón', 'seta', 'hongo',
      'espárrago', 'alcachofa', 'endibia', 'rúcula', 'canónigo', 'perejil',
      'cilantro', 'albahaca', 'eneldo', 'menta', 'romero', 'salvia', 'tomillo',
      // English
      'fruit', 'vegetable', 'veg', 'tomato', 'onion', 'garlic', 'pepper', 'potato',
      'carrot', 'lettuce', 'spinach', 'broccoli', 'cauliflower', 'pumpkin', 'cucumber',
      'eggplant', 'zucchini', 'leek', 'celery', 'beet', 'radish', 'apple', 'banana',
      'orange', 'lemon', 'strawberry', 'grape', 'melon', 'watermelon', 'avocado',
      'mushroom', 'asparagus', 'artichoke', 'endive', 'arugula', 'parsley', 'cilantro',
      'coriander', 'basil', 'dill', 'mint', 'rosemary', 'sage', 'thyme', 'herb',
      'squash', 'cabbage', 'berries'
    ],
    IngredientCategory.proteinaAnimal: [
      'pollo', 'ternera', 'cerdo', 'cordero', 'carne', 'res', 'vacuno',
      'carnero', 'cabrito', 'pavo', 'gallina', 'pato', 'conejo', 'liebre',
      'venado', 'ciervo', 'jabalí', 'pescado', 'salmón', 'atún', 'merluza',
      'bacalao', 'trucha', 'lubina', 'dorada', 'lenguado', 'pez', 'sardina',
      'anchoa', 'arenque', 'caballa', 'mero', 'pargo', 'marisco', 'gamba',
      'camarón', 'langostino', 'langosta', 'mejillón', 'almeja', 'ostra',
      'vieira', 'calamar', 'pulpo', 'sepia', 'cangrejo', 'centollo', 'nécora', 'percebe',
      // English
      'chicken', 'beef', 'pork', 'lamb', 'meat', 'veal', 'turkey', 'duck', 'rabbit',
      'venison', 'fish', 'salmon', 'tuna', 'hake', 'cod', 'trout', 'bass', 'sole',
      'sardine', 'anchovy', 'herring', 'mackerel', 'grouper', 'snapper', 'seafood',
      'shrimp', 'prawn', 'lobster', 'mussel', 'clam', 'oyster', 'scallop', 'squid',
      'octopus', 'crab', 'bacon', 'pancetta', 'sausage', 'chorizo', 'ham'
    ],
    IngredientCategory.lacteosYHuevos: [
      'leche', 'yogur', 'queso', 'mantequilla', 'nata', 'crema', 'requesón',
      'cuajada', 'helado', 'kefir', 'mascarpone', 'provolone', 'gorgonzola',
      'roquefort', 'mozzarella', 'parmesano', 'cheddar', 'ricotta', 'feta',
      'manchego', 'gouda', 'emmental', 'brie', 'huevo',
      // English
      'milk', 'yogurt', 'cheese', 'butter', 'cream', 'curd', 'ice cream', 'kefir',
      'mascarpone', 'provolone', 'gorgonzola', 'roquefort', 'mozzarella', 'parmesan',
      'cheddar', 'ricotta', 'feta', 'manchego', 'gouda', 'emmental', 'brie', 'egg', 'dairy'
    ],
    IngredientCategory.granosYPastas: [
      'arroz', 'lenteja', 'garbanzo', 'frijol', 'judía', 'haba', 'guisante',
      'arveja', 'soja', 'pasta', 'espagueti', 'fideos', 'macarrones',
      'tallarines', 'canelones', 'lasaña', 'pan', 'galleta',
      // English
      'rice', 'lentil', 'chickpea', 'bean', 'pea', 'soy', 'pasta', 'spaghetti', 'noodle',
      'macaroni', 'lasagna', 'bread', 'cookie', 'biscuit', 'wheat', 'oat', 'barley', 'quinoa',
      'corn', 'cereal'
    ],
    IngredientCategory.aceitesYGrasas: [
      'aceite', 'oliva', 'girasol', 'manteca', 'margarina', 'grasa',
      // English
      'oil', 'olive', 'sunflower', 'lard', 'margarine', 'fat', 'ghee'
    ],
    IngredientCategory.condimentosYEspecias: [
      'sal', 'pimienta', 'comino', 'cúrcuma', 'curry', 'paprika', 'pimentón',
      'clavo', 'canela', 'nuez moscada', 'cardamomo', 'jengibre', 'azafrán',
      'orégano', 'tomillo', 'romero', 'laurel', 'estragón', 'hinojo', 'vinagre',
      'mostaza', 'ketchup', 'mayonesa', 'salsa', 'soja', 'worcestershire',
      'hoisin', 'teriyaki', 'tahini', 'miso', 'harissa', 'pesto', 'gochujang',
      // English
      'salt', 'pepper', 'cumin', 'turmeric', 'curry', 'paprika', 'clove', 'cinnamon',
      'nutmeg', 'cardamom', 'ginger', 'saffron', 'oregano', 'thyme', 'rosemary',
      'bay leaf', 'tarragon', 'fennel', 'vinegar', 'mustard', 'ketchup', 'mayonnaise',
      'sauce', 'soy', 'worcestershire', 'hoisin', 'teriyaki', 'tahini', 'miso',
      'harissa', 'pesto', 'gochujang', 'spice', 'seasoning', 'broth', 'bouillon', 'stock'
    ],
    IngredientCategory.reposteriaYHarinas: [
      'harina', 'trigo', 'centeno', 'cebada', 'espelta', 'azúcar', 'miel',
      'chocolate', 'cacao', 'levadura', 'vainilla', 'stevia', 'panela',
      'piloncillo', 'melaza', 'sirope', 'bicarbonato', 'polvo',
      // English
      'flour', 'wheat', 'rye', 'barley', 'spelt', 'sugar', 'honey', 'chocolate', 'cocoa',
      'yeast', 'vanilla', 'stevia', 'molasses', 'syrup', 'baking', 'powder', 'soda', 'sweetener'
    ],
    IngredientCategory.conservasYVarios: [
      'lata', 'atún', 'maíz', 'encurtido', 'aceituna', 'fruto seco', 'nuez',
      'almendra', 'avellana', 'cacahuete', 'pistacho', 'caldo preparado',
      'caldo', 'conserva',
      // English
      'can', 'canned', 'tuna', 'corn', 'pickle', 'olive', 'nut', 'almond', 'hazelnut',
      'peanut', 'pistachio', 'broth', 'preserve', 'jam', 'jelly', 'peanut butter', 'walnut', 'pecan'
    ],
  };

  final categoryKeywords = keywords[category] ?? [];
  return allIngredients.where((ingredient) {
    final lower = ingredient.toLowerCase();

    // Check custom mapping first
    final customCat = RecipeManager.getCategoryForIngredient(lower);
    if (customCat != null) {
      return customCat == category;
    }

    return categoryKeywords.any((keyword) => lower.contains(keyword));
  }).toList();
}

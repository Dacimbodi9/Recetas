import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('recetas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Recipes table
    await db.execute('''
      CREATE TABLE recipes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        ingredients TEXT NOT NULL,
        detailedIngredients TEXT NOT NULL,
        steps TEXT NOT NULL,
        imagePath TEXT,
        customImage TEXT,
        prepTime INTEGER,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        rating REAL,
        dateRated TEXT,
        categories TEXT NOT NULL,
        dietaryRestrictions TEXT NOT NULL,
        customDietaryTags TEXT NOT NULL,
        nutritionFacts TEXT NOT NULL
      )
    ''');
    
    // Folders table
    await db.execute('''
      CREATE TABLE folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconCodePoint INTEGER NOT NULL,
        iconFontFamily TEXT,
        iconFontPackage TEXT,
        parentId TEXT,
        recipeIds TEXT NOT NULL
      )
    ''');

    // Planned meals table
    await db.execute('''
      CREATE TABLE meals (
        id TEXT PRIMARY KEY,
        dateKey TEXT NOT NULL,
        date TEXT NOT NULL,
        mealTypeIndex INTEGER NOT NULL,
        recipeId TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Indexes for fast lookup
    await db.execute('CREATE INDEX idx_meals_date ON meals(dateKey)');
    await db.execute('CREATE INDEX idx_recipes_favorite ON recipes(isFavorite)');
  }
}

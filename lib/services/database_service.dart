import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:nutri_tracker/features/food_tracking/models/food_item.dart';
import 'package:nutri_tracker/features/user_profile/models/user_profile.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'nutri_tracker.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE food_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        portion REAL NOT NULL,
        unit TEXT NOT NULL,
        dateAdded INTEGER NOT NULL,
        imageUrl TEXT,
        isAIDetected INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profiles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        gender TEXT NOT NULL,
        activityLevel TEXT NOT NULL,
        goal TEXT NOT NULL,
        dailyCalorieGoal REAL NOT NULL
      )
    ''');
  }

  // CRUD para FoodItem
  Future<int> insertFoodItem(FoodItem foodItem) async {
    final db = await database;
    return await db.insert('food_items', foodItem.toMap());
  }

  Future<List<FoodItem>> getFoodItemsByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'food_items',
      where: 'dateAdded >= ? AND dateAdded < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'dateAdded DESC',
    );

    return List.generate(maps.length, (i) => FoodItem.fromMap(maps[i]));
  }

  Future<Map<String, double>> getDailyTotals(DateTime date) async {
    final foods = await getFoodItemsByDate(date);
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var food in foods) {
      totalCalories += food.calories;
      totalProtein += food.protein;
      totalCarbs += food.carbs;
      totalFat += food.fat;
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  Future<void> deleteFoodItem(int id) async {
    final db = await database;
    await db.delete('food_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FoodItem>> getAllFoodItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'food_items',
      orderBy: 'dateAdded DESC',
    );

    return List.generate(maps.length, (i) => FoodItem.fromMap(maps[i]));
  }

  // CRUD para UserProfile
  Future<int> insertUserProfile(UserProfile profile) async {
    final db = await database;
    return await db.insert('user_profiles', profile.toMap());
  }

  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profiles',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    final db = await database;
    await db.update(
      'user_profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<void> deleteUserProfile(int id) async {
    final db = await database;
    await db.delete('user_profiles', where: 'id = ?', whereArgs: [id]);
  }

  // Método para limpar todos os dados
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('food_items');
    await db.delete('user_profiles');
  }
}

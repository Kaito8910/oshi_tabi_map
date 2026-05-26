import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('oshi_tabi_map.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        venue TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE goods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER,
        group_name TEXT NOT NULL,
        member_name TEXT NOT NULL,
        category TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price INTEGER NOT NULL,
        oshi_id INTEGER,
        oshi_name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER,
        event_name TEXT,
        category TEXT NOT NULL,
        amount INTEGER NOT NULL,
        memo TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE oshis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        group_name TEXT,
        group_name_normalized TEXT,
        color TEXT,
        color_value TEXT,
        memo TEXT
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE goods ADD COLUMN oshi_id INTEGER
      ''');

      await db.execute('''
        ALTER TABLE goods ADD COLUMN oshi_name TEXT
      ''');

      await db.execute('''
        CREATE TABLE oshis (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          group_name TEXT,
          group_name_normalized TEXT,
          color TEXT,
          memo TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE oshis ADD COLUMN color_value TEXT
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        ALTER TABLE oshis ADD COLUMN group_name_normalized TEXT
      ''');
    }
  }

  Future<int> insertEvent(Map<String, dynamic> event) async {
    final db = await instance.database;

    return await db.insert('events', event);
  }

  Future<int> updateEvent(int id, Map<String, dynamic> event) async {
    final db = await instance.database;

    return await db.update(
      'events',
      event,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    final db = await instance.database;

    return await db.query(
      'events',
      orderBy: 'date ASC',
    );
  }

  Future<int> insertGoods(Map<String, dynamic> goods) async {
    final db = await instance.database;

    return await db.insert('goods', goods);
  }

  Future<List<Map<String, dynamic>>> getGoods() async {
    final db = await instance.database;

    return await db.query(
      'goods',
      orderBy: 'id DESC',
    );
  }

  Future<int> updateGoods(int id, Map<String, dynamic> goods) async {
    final db = await instance.database;

    return await db.update(
      'goods',
      goods,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getGoodsByEventId(int eventId) async {
    final db = await instance.database;

    return await db.query(
      'goods',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'id DESC',
    );
  }

  Future<int> deleteGoods(int id) async {
    final db = await instance.database;

    return await db.delete(
      'goods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;

    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getExpensesByEventId(
    int eventId,
  ) async {
    final db = await instance.database;

    return await db.query(
      'expenses',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'id DESC',
    );
  }

  Future<int> insertExpense(Map<String, dynamic> expense) async {
    final db = await instance.database;

    return await db.insert('expenses', expense);
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await instance.database;

    return await db.query(
      'expenses',
      orderBy: 'id DESC',
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await instance.database;

    await db.delete(
      'goods',
      where: 'event_id = ?',
      whereArgs: [id],
    );

    await db.delete(
      'expenses',
      where: 'event_id = ?',
      whereArgs: [id],
    );

    return await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateExpense(int id, Map<String, dynamic> expense) async {
    final db = await instance.database;

    return await db.update(
      'expenses',
      expense,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertOshi(Map<String, dynamic> oshi) async {
    final db = await instance.database;
    return await db.insert('oshis', oshi);
  }

  Future<List<Map<String, dynamic>>> getOshis() async {
    final db = await instance.database;
    return await db.query('oshis', orderBy: 'id DESC');
  }

  Future<int> updateOshi(int id, Map<String, dynamic> oshi) async {
    final db = await instance.database;
    return await db.update(
      'oshis',
      oshi,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteOshi(int id) async {
    final db = await instance.database;
    return await db.delete(
      'oshis',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        venue TEXT NOT NULL,
        prefecture TEXT NOT NULL
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
        oshi_id INTEGER
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
        memo TEXT,
        start_date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER,
        goods_id INTEGER,
        image_path TEXT NOT NULL,
        created_at TEXT
      )
    ''');
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

  Future<int> insertPhoto(Map<String, dynamic> photo) async {
    final db = await instance.database;

    return await db.insert('photos', photo);
  }

  Future<List<Map<String, dynamic>>> getPhotosByEventId(
    int eventId,
  ) async {
    final db = await instance.database;

    return await db.query(
      'photos',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPhotosByGoodsId(
    int goodsId,
  ) async {
    final db = await instance.database;

    return await db.query(
      'photos',
      where: 'goods_id = ?',
      whereArgs: [goodsId],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllPhotos() async {
    final db = await instance.database;

    return await db.rawQuery('''
      SELECT
        photos.*,
        events.title AS event_title,
        events.date AS event_date
      FROM photos
      LEFT JOIN events
        ON photos.event_id = events.id
      ORDER BY photos.id DESC
    ''');
  }

  Future<int> deletePhoto(int id) async {
    final db = await instance.database;

    return await db.delete(
      'photos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;

  return {
    'oshis': await db.query('oshis'),
    'events': await db.query('events'),
    'goods': await db.query('goods'),
    'expenses': await db.query('expenses'),
    'photos': await db.query('photos'),
    };
  }

  Future<void> clearAllData() async {
    final db = await database;

    await db.delete('photos');
    await db.delete('expenses');
    await db.delete('goods');
    await db.delete('events');
    await db.delete('oshis');
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    final db = await database;

    await clearAllData();

    for (final item in data['oshis'] ?? []) {
      await db.insert('oshis', Map<String, dynamic>.from(item));
    }

    for (final item in data['events'] ?? []) {
      await db.insert('events', Map<String, dynamic>.from(item));
    }

    for (final item in data['goods'] ?? []) {
      await db.insert('goods', Map<String, dynamic>.from(item));
    }

    for (final item in data['expenses'] ?? []) {
      await db.insert('expenses', Map<String, dynamic>.from(item));
    }

    for (final item in data['photos'] ?? []) {
      await db.insert('photos', Map<String, dynamic>.from(item));
    }
  }
}
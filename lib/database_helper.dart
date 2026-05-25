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
        venue TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertEvent(Map<String, dynamic> event) async {
    final db = await instance.database;

    return await db.insert('events', event);
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    final db = await instance.database;

    return await db.query(
      'events',
      orderBy: 'id DESC',
    );
  }
}
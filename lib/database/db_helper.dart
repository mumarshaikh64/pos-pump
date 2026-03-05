import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/entry_model.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'pos_pump.db');
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        date TEXT NOT NULL,
        details TEXT NOT NULL,
        vehicle_number TEXT NOT NULL,
        diesel_expense REAL NOT NULL,
        other_expense REAL NOT NULL,
        total_expense REAL NOT NULL,
        earnings REAL NOT NULL,
        rate_per_ton REAL,
        total_ton REAL,
        profit REAL NOT NULL
      )
    ''');
  }

  Future<int> insertEntry(EntryModel entry) async {
    final db = await database;
    return await db.insert('entries', entry.toMap());
  }

  Future<List<EntryModel>> getAllEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'entries',
      orderBy: 'date DESC, id DESC',
    );
    return List.generate(maps.length, (i) => EntryModel.fromMap(maps[i]));
  }

  Future<int> updateEntry(EntryModel entry) async {
    final db = await database;
    return await db.update(
      'entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<EntryModel>> searchEntries(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'entries',
      where: 'vehicle_number LIKE ? OR details LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date DESC, id DESC',
    );
    return List.generate(maps.length, (i) => EntryModel.fromMap(maps[i]));
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
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
    String databasesPath;
    try {
      if (kIsWeb) {
        databasesPath = 'web_db';
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final directory = await getApplicationSupportDirectory();
        databasesPath = directory.path;
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      } else {
        databasesPath = await getDatabasesPath();
      }
      String path = join(databasesPath, 'pos_pump.db');
      final db = await openDatabase(
        path,
        version: 4,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );

      // Robust check: Ensure all columns exist regardless of upgrade path
      await _ensureColumnsExist(db);

      return db;
    } catch (e) {
      debugPrint("Database initialization error: $e");
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Simply use our robust column check for upgrades
    await _ensureColumnsExist(db);
  }

  Future<void> _ensureColumnsExist(Database db) async {
    final List<Map<String, dynamic>> columns =
        await db.rawQuery('PRAGMA table_info(entries)');
    final columnNames = columns.map((c) => c['name'] as String).toList();

    final Map<String, String> requiredColumns = {
      'slip_number': 'TEXT',
      'material': 'TEXT',
      'party_name': 'TEXT',
      'site_name': 'TEXT',
      'batch_id': 'TEXT',
    };

    for (var entry in requiredColumns.entries) {
      if (!columnNames.contains(entry.key)) {
        try {
          await db.execute(
              'ALTER TABLE entries ADD COLUMN ${entry.key} ${entry.value}');
        } catch (e) {
          debugPrint("Safe column addition (already exists or error): $e");
        }
      }
    }
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
        profit REAL NOT NULL,
        slip_number TEXT,
        material TEXT,
        party_name TEXT,
        site_name TEXT,
        batch_id TEXT
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

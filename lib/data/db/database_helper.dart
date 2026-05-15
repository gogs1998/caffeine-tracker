import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = 'caffeine_tracker.db';
  static const _databaseVersion = 2;

  static const tableEntries = 'caffeine_entries';

  static const columnId = 'id';
  static const columnDrinkName = 'drink_name';
  static const columnMgAmount = 'mg_amount';
  static const columnConsumedAt = 'consumed_at';
  static const columnNotes = 'notes';
  static const columnPresetId = 'preset_id';

  // In-memory store for web
  static final List<Map<String, dynamic>> _webEntries = [];

  static bool get _isWeb => kIsWeb;

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database?> get database async {
    if (_isWeb) return null;
    _database ??= await _initDatabase();
    return _database;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE $tableEntries ADD COLUMN $columnPresetId TEXT');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableEntries (
        $columnId TEXT PRIMARY KEY,
        $columnDrinkName TEXT NOT NULL,
        $columnMgAmount REAL NOT NULL,
        $columnConsumedAt TEXT NOT NULL,
        $columnNotes TEXT,
        $columnPresetId TEXT
      )
    ''');
  }

  // Web CRUD methods
  Future<int> insertEntry(Map<String, dynamic> entry) async {
    if (_isWeb) {
      // Remove existing entry with same id if present
      _webEntries.removeWhere((e) => e[columnId] == entry[columnId]);
      _webEntries.add(Map<String, dynamic>.from(entry));
      return _webEntries.length;
    }
    final db = (await database)!;
    return db.insert(tableEntries, entry,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllEntries(
      {String? orderBy, String? where, List<dynamic>? whereArgs}) async {
    if (_isWeb) {
      var results = List<Map<String, dynamic>>.from(_webEntries);
      if (where != null && whereArgs != null) {
        // Simple range filter for consumed_at >= ? AND consumed_at <= ?
        if (where.contains('>=') && where.contains('<=') && whereArgs.length == 2) {
          final from = whereArgs[0] as String;
          final to = whereArgs[1] as String;
          results = results.where((e) {
            final t = e[columnConsumedAt] as String;
            return t.compareTo(from) >= 0 && t.compareTo(to) <= 0;
          }).toList();
        }
      }
      results.sort((a, b) =>
          (a[columnConsumedAt] as String).compareTo(b[columnConsumedAt] as String));
      return results;
    }
    final db = (await database)!;
    return db.query(tableEntries, orderBy: orderBy, where: where, whereArgs: whereArgs);
  }

  Future<int> deleteEntry(String id) async {
    if (_isWeb) {
      final before = _webEntries.length;
      _webEntries.removeWhere((e) => e[columnId] == id);
      return before - _webEntries.length;
    }
    final db = (await database)!;
    return db.delete(tableEntries, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> deleteAllEntries() async {
    if (_isWeb) {
      final count = _webEntries.length;
      _webEntries.clear();
      return count;
    }
    final db = (await database)!;
    return db.delete(tableEntries);
  }

  /// Seed demo data for web preview.
  static Future<void> seedWebData() async {
    if (!_isWeb) return;
    final now = DateTime.now();
    final seeds = [
      {
        columnId: 'seed-1',
        columnDrinkName: 'Espresso',
        columnMgAmount: 75.0,
        columnConsumedAt:
            now.subtract(const Duration(hours: 6)).toIso8601String(),
        columnNotes: null,
        columnPresetId: null,
      },
      {
        columnId: 'seed-2',
        columnDrinkName: 'Flat White',
        columnMgAmount: 130.0,
        columnConsumedAt: now
            .subtract(const Duration(minutes: 210))
            .toIso8601String(), // 3.5 hours
        columnNotes: null,
        columnPresetId: null,
      },
      {
        columnId: 'seed-3',
        columnDrinkName: 'Red Bull',
        columnMgAmount: 80.0,
        columnConsumedAt:
            now.subtract(const Duration(hours: 1)).toIso8601String(),
        columnNotes: null,
        columnPresetId: null,
      },
    ];
    for (final entry in seeds) {
      await DatabaseHelper.instance.insertEntry(entry);
    }
  }

  /// For testing: inject a pre-opened database directly.
  void overrideDatabase(Database db) {
    _database = db;
  }
}

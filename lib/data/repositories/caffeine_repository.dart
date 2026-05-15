import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/caffeine_entry.dart';

class CaffeineRepository {
  final DatabaseHelper _dbHelper;

  CaffeineRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<Database> get _db => _dbHelper.database;

  Future<void> insert(CaffeineEntry entry) async {
    final db = await _db;
    await db.insert(
      DatabaseHelper.tableEntries,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CaffeineEntry>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      DatabaseHelper.tableEntries,
      orderBy: '${DatabaseHelper.columnConsumedAt} ASC',
    );
    return maps.map(CaffeineEntry.fromMap).toList();
  }

  Future<List<CaffeineEntry>> getByDateRange(
      DateTime from, DateTime to) async {
    final db = await _db;
    final maps = await db.query(
      DatabaseHelper.tableEntries,
      where:
          '${DatabaseHelper.columnConsumedAt} >= ? AND ${DatabaseHelper.columnConsumedAt} <= ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      orderBy: '${DatabaseHelper.columnConsumedAt} ASC',
    );
    return maps.map(CaffeineEntry.fromMap).toList();
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete(
      DatabaseHelper.tableEntries,
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAll() async {
    final db = await _db;
    await db.delete(DatabaseHelper.tableEntries);
  }
}

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/caffeine_entry.dart';

class CaffeineRepository {
  final DatabaseHelper _dbHelper;

  CaffeineRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> insert(CaffeineEntry entry) async {
    if (kIsWeb) {
      await _dbHelper.insertEntry(entry.toMap());
      return;
    }
    final db = (await _dbHelper.database)!;
    await db.insert(
      DatabaseHelper.tableEntries,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CaffeineEntry>> getAll() async {
    if (kIsWeb) {
      final maps = await _dbHelper.getAllEntries(
          orderBy: '${DatabaseHelper.columnConsumedAt} ASC');
      return maps.map(CaffeineEntry.fromMap).toList();
    }
    final db = (await _dbHelper.database)!;
    final maps = await db.query(
      DatabaseHelper.tableEntries,
      orderBy: '${DatabaseHelper.columnConsumedAt} ASC',
    );
    return maps.map(CaffeineEntry.fromMap).toList();
  }

  Future<List<CaffeineEntry>> getByDateRange(
      DateTime from, DateTime to) async {
    if (kIsWeb) {
      final maps = await _dbHelper.getAllEntries(
        where:
            '${DatabaseHelper.columnConsumedAt} >= ? AND ${DatabaseHelper.columnConsumedAt} <= ?',
        whereArgs: [from.toIso8601String(), to.toIso8601String()],
        orderBy: '${DatabaseHelper.columnConsumedAt} ASC',
      );
      return maps.map(CaffeineEntry.fromMap).toList();
    }
    final db = (await _dbHelper.database)!;
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
    if (kIsWeb) {
      await _dbHelper.deleteEntry(id);
      return;
    }
    final db = (await _dbHelper.database)!;
    await db.delete(
      DatabaseHelper.tableEntries,
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAll() async {
    if (kIsWeb) {
      await _dbHelper.deleteAllEntries();
      return;
    }
    final db = (await _dbHelper.database)!;
    await db.delete(DatabaseHelper.tableEntries);
  }
}

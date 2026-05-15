import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = 'caffeine_tracker.db';
  static const _databaseVersion = 1;

  static const tableEntries = 'caffeine_entries';

  static const columnId = 'id';
  static const columnDrinkName = 'drink_name';
  static const columnMgAmount = 'mg_amount';
  static const columnConsumedAt = 'consumed_at';
  static const columnNotes = 'notes';

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableEntries (
        $columnId TEXT PRIMARY KEY,
        $columnDrinkName TEXT NOT NULL,
        $columnMgAmount REAL NOT NULL,
        $columnConsumedAt TEXT NOT NULL,
        $columnNotes TEXT
      )
    ''');
  }

  /// For testing: inject a pre-opened database directly.
  void overrideDatabase(Database db) {
    _database = db;
  }
}

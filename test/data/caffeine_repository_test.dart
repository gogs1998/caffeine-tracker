import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:caffeine_tracker/data/db/database_helper.dart';
import 'package:caffeine_tracker/data/models/caffeine_entry.dart';
import 'package:caffeine_tracker/data/repositories/caffeine_repository.dart';

void main() {
  late CaffeineRepository repo;
  late DatabaseHelper helper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // Track the current DB so we can close it between tests.
  Database? currentDb;

  tearDown(() async {
    await currentDb?.close();
    currentDb = null;
  });

  setUp(() async {
    helper = DatabaseHelper.instance;
    // Open a fresh in-memory DB for each test.
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE ${DatabaseHelper.tableEntries} (
              ${DatabaseHelper.columnId} TEXT PRIMARY KEY,
              ${DatabaseHelper.columnDrinkName} TEXT NOT NULL,
              ${DatabaseHelper.columnMgAmount} REAL NOT NULL,
              ${DatabaseHelper.columnConsumedAt} TEXT NOT NULL,
              ${DatabaseHelper.columnNotes} TEXT,
              ${DatabaseHelper.columnPresetId} TEXT
            )
          ''');
        },
      ),
    );
    currentDb = db;
    helper.overrideDatabase(db);
    repo = CaffeineRepository(dbHelper: helper);
  });

  final base = DateTime(2024, 1, 1, 8, 0);

  CaffeineEntry makeEntry({
    String id = '1',
    String drink = 'Coffee',
    double mg = 200,
    DateTime? at,
    String? notes,
  }) =>
      CaffeineEntry(
        id: id,
        drinkName: drink,
        mgAmount: mg,
        consumedAt: at ?? base,
        notes: notes,
      );

  group('insert / getAll', () {
    test('insert and retrieve one entry', () async {
      final e = makeEntry();
      await repo.insert(e);
      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.id, '1');
      expect(all.first.mgAmount, 200.0);
    });

    test('insert multiple entries returns all', () async {
      await repo.insert(makeEntry(id: '1', mg: 100));
      await repo.insert(makeEntry(id: '2', mg: 200));
      await repo.insert(makeEntry(id: '3', mg: 80));
      final all = await repo.getAll();
      expect(all.length, 3);
    });

    test('insert same id replaces entry (upsert)', () async {
      await repo.insert(makeEntry(id: '1', mg: 100));
      await repo.insert(makeEntry(id: '1', mg: 999));
      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.mgAmount, 999.0);
    });

    test('notes are persisted correctly', () async {
      await repo.insert(makeEntry(notes: 'morning brew'));
      final all = await repo.getAll();
      expect(all.first.notes, 'morning brew');
    });

    test('null notes round-trips as null', () async {
      await repo.insert(makeEntry());
      final all = await repo.getAll();
      expect(all.first.notes, isNull);
    });
  });

  group('getByDateRange', () {
    test('returns entries within range', () async {
      await repo.insert(makeEntry(id: '1', at: DateTime(2024, 1, 1, 7, 0)));
      await repo.insert(makeEntry(id: '2', at: DateTime(2024, 1, 1, 10, 0)));
      await repo.insert(makeEntry(id: '3', at: DateTime(2024, 1, 1, 14, 0)));

      final results = await repo.getByDateRange(
        DateTime(2024, 1, 1, 8, 0),
        DateTime(2024, 1, 1, 12, 0),
      );
      expect(results.length, 1);
      expect(results.first.id, '2');
    });

    test('returns empty list when no entries in range', () async {
      await repo.insert(makeEntry(at: DateTime(2024, 1, 1, 6, 0)));
      final results = await repo.getByDateRange(
        DateTime(2024, 1, 1, 8, 0),
        DateTime(2024, 1, 1, 12, 0),
      );
      expect(results, isEmpty);
    });
  });

  group('delete', () {
    test('delete by id removes correct entry', () async {
      await repo.insert(makeEntry(id: '1'));
      await repo.insert(makeEntry(id: '2', mg: 50));
      await repo.delete('1');
      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.id, '2');
    });

    test('delete non-existent id is a no-op', () async {
      await repo.insert(makeEntry(id: '1'));
      await repo.delete('999');
      expect((await repo.getAll()).length, 1);
    });
  });

  group('deleteAll', () {
    test('clears all entries', () async {
      await repo.insert(makeEntry(id: '1'));
      await repo.insert(makeEntry(id: '2'));
      await repo.deleteAll();
      expect(await repo.getAll(), isEmpty);
    });
  });
}

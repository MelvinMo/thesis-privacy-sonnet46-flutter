// MIGRATION: services/data/LocalDatabaseManager.ts → Dart singleton.
//
//            expo-sqlite → sqflite ^2.
//
//            SCHEMA COMPATIBILITY (Rule 13):
//              Table names `journals` and `sensor_data` preserved exactly.
//              All column names preserved exactly so existing SQLite databases
//              created by the React Native app remain readable.
//
//            sqflite uses the same underlying SQLite engine, so SQL syntax is
//            identical. The only difference: sqflite uses named placeholders
//            (?1, ?2) or positional (?) — we use positional to match source.

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDatabaseManager {
  // Singleton pattern (matches source).
  static LocalDatabaseManager? _instance;
  static LocalDatabaseManager getInstance() {
    _instance ??= LocalDatabaseManager._();
    return _instance!;
  }

  LocalDatabaseManager._();

  Database? _db;
  static const _dbName = 'sleeptracker_data.db'; // MIGRATION: same file name as source.

  // ---------------------------------------------------------------------------
  // SQL DDL — column names identical to source (Rule 13).
  // ---------------------------------------------------------------------------
  static const _createJournalTableSql = '''
    CREATE TABLE IF NOT EXISTS journals (
      journalId    TEXT PRIMARY KEY NOT NULL,
      userId       TEXT NOT NULL,
      date         TEXT NOT NULL,
      bedtime      TEXT,
      alarmTime    TEXT,
      sleepDuration TEXT,
      diaryEntry   TEXT,
      sleepNotes   TEXT,
      createdAt    TEXT NOT NULL DEFAULT (STRFTIME('%Y-%m-%dT%H:%M:%fZ', 'NOW'))
    )
  ''';

  static const _createSensorDataTableSql = '''
    CREATE TABLE IF NOT EXISTS sensor_data (
      id                TEXT PRIMARY KEY NOT NULL,
      userId            TEXT NOT NULL,
      timestamp         INTEGER NOT NULL,
      date              TEXT NOT NULL,
      sensorType        TEXT NOT NULL,
      averageDecibels   TEXT,
      peakDecibels      TEXT,
      frequencyBands    TEXT,
      audioClipUri      TEXT,
      snoreDetected     INTEGER,
      ambientNoiseLevel TEXT,
      illuminance       TEXT,
      lightLevel        TEXT,
      x                 TEXT,
      y                 TEXT,
      z                 TEXT,
      magnitude         TEXT,
      movementIntensity TEXT,
      createdAt         TEXT NOT NULL DEFAULT (STRFTIME('%Y-%m-%dT%H:%M:%fZ', 'NOW'))
    )
  ''';

  // ---------------------------------------------------------------------------
  // openDatabase
  // ---------------------------------------------------------------------------
  Future<Database> _getDb() async {
    if (_db != null && _db!.isOpen) return _db!;
    final dbPath = p.join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute(_createJournalTableSql);
        await db.execute(_createSensorDataTableSql);
      },
    );
    return _db!;
  }

  // ---------------------------------------------------------------------------
  // executeSql — INSERT / UPDATE / DELETE (mirrors source executeSql).
  // ---------------------------------------------------------------------------
  Future<({int rowsAffected, int? insertId})> executeSql(
      String sql, List<Object?> params) async {
    final db = await _getDb();
    // MIGRATION: expo-sqlite prepareAsync + executeAsync → sqflite rawInsert/rawUpdate/rawDelete.
    //            sqflite's rawInsert returns the last inserted row id;
    //            rawUpdate/rawDelete return affected rows.
    final lowerSql = sql.trimLeft().toLowerCase();
    if (lowerSql.startsWith('insert')) {
      final id = await db.rawInsert(sql, params);
      return (rowsAffected: 1, insertId: id);
    } else if (lowerSql.startsWith('update') || lowerSql.startsWith('delete')) {
      final count = await db.rawUpdate(sql, params);
      return (rowsAffected: count, insertId: null);
    } else {
      await db.execute(sql, params);
      return (rowsAffected: 0, insertId: null);
    }
  }

  // ---------------------------------------------------------------------------
  // getAll<T> — SELECT (mirrors source getAll).
  // ---------------------------------------------------------------------------
  Future<List<Map<String, Object?>>> getAll(
      String sql, List<Object?> params) async {
    final db = await _getDb();
    return db.rawQuery(sql, params);
  }

  // ---------------------------------------------------------------------------
  // getOne<T> — SELECT single row (mirrors source getOne).
  // ---------------------------------------------------------------------------
  Future<Map<String, Object?>?> getOne(
      String sql, List<Object?> params) async {
    final db = await _getDb();
    final rows = await db.rawQuery(sql, params);
    return rows.isEmpty ? null : rows.first;
  }

  // ---------------------------------------------------------------------------
  // Utility: drop all tables (matches source deleteAllTables — dev only).
  // ---------------------------------------------------------------------------
  Future<void> deleteAllTables() async {
    final db = await _getDb();
    await db.execute('DROP TABLE IF EXISTS sensor_data');
    await db.execute('DROP TABLE IF EXISTS journals');
  }
}

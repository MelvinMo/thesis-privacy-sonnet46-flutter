// MIGRATION: services/data/data-sources/LocalJournalDataSource.ts → Dart.
//            SQLite queries use same table/column names (Rule 13).

import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../../../core/models/journal_data.dart';
import '../../encryption_service.dart';
import '../../local_database_manager.dart';
import 'journal_data_source.dart';

class LocalJournalDataSource implements JournalDataSource {
  final LocalDatabaseManager _db;
  final EncryptionService _encryption;

  LocalJournalDataSource({
    required LocalDatabaseManager db,
    required EncryptionService encryption,
  })  : _db = db,
        _encryption = encryption;

  @override
  Future<JournalData?> getJournalByDate(String date, String userId) async {
    final row = await _db.getOne(
      'SELECT * FROM journals WHERE date = ? AND userId = ? LIMIT 1',
      [date, userId],
    );
    if (row == null) return null;
    final journal = _rowToJournal(row);
    return _encryption.decryptJournalData(journal);
  }

  @override
  Future<JournalData?> editJournal(
      Map<String, dynamic> partialJournal, String date, String userId) async {
    // Check if record exists.
    final existing = await getJournalByDate(date, userId);

    // Merge partial update onto existing (or create new if not exists).
    final merged = existing != null
        ? existing.copyWith(
            bedtime: partialJournal['bedtime'] as String? ?? existing.bedtime,
            alarmTime:
                partialJournal['alarmTime'] as String? ?? existing.alarmTime,
            sleepDuration: partialJournal['sleepDuration'] as String? ??
                existing.sleepDuration,
            diaryEntry:
                partialJournal['diaryEntry'] as String? ?? existing.diaryEntry,
            sleepNotes: partialJournal['sleepNotes'] != null
                ? (partialJournal['sleepNotes'] as List)
                    .map((e) => SleepNoteJson.fromJson(e as String))
                    .toList()
                : existing.sleepNotes,
          )
        : JournalData(
            journalId: const Uuid().v4(),
            userId: userId,
            date: date,
            bedtime: partialJournal['bedtime'] as String? ?? '',
            alarmTime: partialJournal['alarmTime'] as String? ?? '',
            sleepDuration: partialJournal['sleepDuration'] as String? ?? '',
            diaryEntry: partialJournal['diaryEntry'] as String? ?? '',
            sleepNotes: partialJournal['sleepNotes'] != null
                ? (partialJournal['sleepNotes'] as List)
                    .map((e) => SleepNoteJson.fromJson(e as String))
                    .toList()
                : [],
          );

    final encrypted = await _encryption.encryptJournalData(merged);

    if (existing != null) {
      await _db.executeSql(
        '''UPDATE journals SET bedtime=?, alarmTime=?, sleepDuration=?,
           diaryEntry=?, sleepNotes=? WHERE journalId=?''',
        [
          encrypted.bedtime,
          encrypted.alarmTime,
          encrypted.sleepDuration,
          encrypted.diaryEntry,
          encrypted.sleepNotesJson,
          encrypted.journalId,
        ],
      );
    } else {
      await _db.executeSql(
        '''INSERT INTO journals (journalId, userId, date, bedtime, alarmTime,
           sleepDuration, diaryEntry, sleepNotes)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          encrypted.journalId,
          encrypted.userId,
          encrypted.date,
          encrypted.bedtime,
          encrypted.alarmTime,
          encrypted.sleepDuration,
          encrypted.diaryEntry,
          encrypted.sleepNotesJson,
        ],
      );
    }
    return merged; // Return the plain (decrypted) version to the caller.
  }

  @override
  Future<void> deleteJournal(String journalId) async {
    await _db.executeSql(
        'DELETE FROM journals WHERE journalId = ?', [journalId]);
  }

  // ---------------------------------------------------------------------------
  // Helper: convert raw SQLite row map → JournalData.
  // ---------------------------------------------------------------------------
  JournalData _rowToJournal(Map<String, Object?> row) {
    final notesRaw = row['sleepNotes'] as String? ?? '[]';
    List<SleepNote> notes = [];
    try {
      final decoded = jsonDecode(notesRaw) as List<dynamic>;
      notes = decoded.map((e) => SleepNoteJson.fromJson(e as String)).toList();
    } catch (_) {}

    return JournalData(
      journalId: row['journalId'] as String,
      userId: row['userId'] as String,
      date: row['date'] as String,
      bedtime: row['bedtime'] as String? ?? '',
      alarmTime: row['alarmTime'] as String? ?? '',
      sleepDuration: row['sleepDuration'] as String? ?? '',
      diaryEntry: row['diaryEntry'] as String? ?? '',
      sleepNotes: notes,
    );
  }
}

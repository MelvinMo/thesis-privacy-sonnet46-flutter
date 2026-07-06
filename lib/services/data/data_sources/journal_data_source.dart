// MIGRATION: services/data/data-sources/JournalDataSource.ts → Dart abstract class.
//            Abstract interface for the Repository pattern (Rule 4).

import '../../../core/models/journal_data.dart';

abstract class JournalDataSource {
  Future<JournalData?> getJournalByDate(String date, String userId);
  Future<JournalData?> editJournal(
      Map<String, dynamic> partialJournal, String date, String userId);
  Future<void> deleteJournal(String journalId);
}

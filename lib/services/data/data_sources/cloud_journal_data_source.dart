// MIGRATION: services/data/data-sources/CloudJournalDataSource.ts → Dart.
//            HTTP calls via AppHttpClient (replaces fetch in source).

import '../../../core/models/journal_data.dart';
import '../../http_client.dart';
import 'journal_data_source.dart';

class CloudJournalDataSource implements JournalDataSource {
  final AppHttpClient _httpClient;
  final String userId;

  CloudJournalDataSource({
    required AppHttpClient httpClient,
    required this.userId,
  }) : _httpClient = httpClient;

  @override
  Future<JournalData?> getJournalByDate(String date, String uid) async {
    try {
      final response =
          await _httpClient.get('/api/phi/journal/by-date/$date');
      if (response.isEmpty) return null;
      return JournalData.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<JournalData?> editJournal(
      Map<String, dynamic> partialJournal, String date, String uid) async {
    final response = await _httpClient.put(
      '/api/phi/journal/$date',
      partialJournal,
    );
    return JournalData.fromJson(response);
  }

  @override
  Future<void> deleteJournal(String journalId) async {
    await _httpClient.delete('/api/phi/journal/$journalId');
  }
}

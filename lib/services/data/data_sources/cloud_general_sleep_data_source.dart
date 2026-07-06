// MIGRATION: CloudGeneralSleepDataSource.ts → Dart.

import '../../../core/models/general_sleep_data.dart';
import '../../http_client.dart';
import 'general_sleep_data_source.dart';

class CloudGeneralSleepDataSource implements GeneralSleepDataSource {
  final AppHttpClient _httpClient;

  CloudGeneralSleepDataSource({required AppHttpClient httpClient})
      : _httpClient = httpClient;

  @override
  Future<GeneralSleepData?> getSleepData(String userId) async {
    try {
      final response = await _httpClient.get('/api/phi/generalSleep/$userId');
      return GeneralSleepData.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<GeneralSleepData> createSleepData(GeneralSleepData sleepData) async {
    final response =
        await _httpClient.post('/api/phi/generalSleep', sleepData.toJson());
    return GeneralSleepData.fromJson(response);
  }

  @override
  Future<void> deleteSleepData(String userId) async {
    await _httpClient.delete('/api/phi/generalSleep/$userId');
  }
}

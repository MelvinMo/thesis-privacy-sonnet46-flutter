// MIGRATION: services/data/data-sources/CloudSensorDataSource.ts → Dart.

import '../../../core/models/sensor_data.dart';
import '../../http_client.dart';
import 'sensor_data_source.dart';

class CloudSensorDataSource implements SensorDataSource {
  final AppHttpClient _httpClient;
  final String userId;

  CloudSensorDataSource({
    required AppHttpClient httpClient,
    required this.userId,
  }) : _httpClient = httpClient;

  @override
  Future<SensorData> createSensorReading(SensorData sensorData) async {
    final response = await _httpClient.post(
        '/api/phi/sensor-data', sensorData.toJson());
    return SensorData.fromJson(response);
  }

  @override
  Future<SensorData?> getSensorReadingById(String id) async {
    try {
      final response = await _httpClient.get('/api/phi/sensor-data/$id');
      return SensorData.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SensorData>> getSensorReadingsByUserId(String uid) async {
    final response = await _httpClient.get('/api/phi/sensor-data/user/$uid');
    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => SensorData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<SensorData>> getSensorReadingsByDate(
      String date, String uid) async {
    final response =
        await _httpClient.get('/api/phi/sensor-data/by-date/$date');
    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => SensorData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> deleteSensorReading(String id) async {
    try {
      await _httpClient.delete('/api/phi/sensor-data/$id');
      return true;
    } catch (_) {
      return false;
    }
  }
}

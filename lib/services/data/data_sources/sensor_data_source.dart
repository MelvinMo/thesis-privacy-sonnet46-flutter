// MIGRATION: services/data/data-sources/SensorDataSource.ts → Dart abstract.

import '../../../core/models/sensor_data.dart';

abstract class SensorDataSource {
  Future<SensorData> createSensorReading(SensorData sensorData);
  Future<SensorData?> getSensorReadingById(String id);
  Future<List<SensorData>> getSensorReadingsByUserId(String userId);
  Future<List<SensorData>> getSensorReadingsByDate(String date, String userId);
  Future<bool> deleteSensorReading(String id);
}

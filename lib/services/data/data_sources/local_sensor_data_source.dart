// MIGRATION: services/data/data-sources/LocalSensorDataSource.ts → Dart.
//            SQLite schema identical to source (Rule 13).

import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../../../core/models/sensor_data.dart';
import '../../encryption_service.dart';
import '../../local_database_manager.dart';
import 'sensor_data_source.dart';

class LocalSensorDataSource implements SensorDataSource {
  final LocalDatabaseManager _db;
  final EncryptionService _encryption;

  LocalSensorDataSource({
    required LocalDatabaseManager db,
    required EncryptionService encryption,
  })  : _db = db,
        _encryption = encryption;

  @override
  Future<SensorData> createSensorReading(SensorData sensorData) async {
    final withId = _ensureId(sensorData);
    final encrypted = await _encryption.encryptSensorData(withId);
    await _db.executeSql(_insertSql(encrypted), _insertParams(encrypted));
    return withId; // Return unencrypted to caller.
  }

  @override
  Future<SensorData?> getSensorReadingById(String id) async {
    final row = await _db.getOne(
        'SELECT * FROM sensor_data WHERE id = ? LIMIT 1', [id]);
    if (row == null) return null;
    final parsed = _rowToSensorData(row);
    return _encryption.decryptSensorData(parsed);
  }

  @override
  Future<List<SensorData>> getSensorReadingsByUserId(String userId) async {
    final rows = await _db.getAll(
        'SELECT * FROM sensor_data WHERE userId = ?', [userId]);
    return _decryptAll(rows);
  }

  @override
  Future<List<SensorData>> getSensorReadingsByDate(
      String date, String userId) async {
    final rows = await _db.getAll(
        'SELECT * FROM sensor_data WHERE date = ? AND userId = ?',
        [date, userId]);
    return _decryptAll(rows);
  }

  @override
  Future<bool> deleteSensorReading(String id) async {
    final result = await _db.executeSql(
        'DELETE FROM sensor_data WHERE id = ?', [id]);
    return result.rowsAffected > 0;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  SensorData _ensureId(SensorData d) {
    // MIGRATION: Source uses `Omit<SensorData, 'id'|'userId'>` — we ensure id.
    return switch (d) {
      AudioSensorData s when s.id.isEmpty =>
        s.copyWith(id: const Uuid().v4()),
      LightSensorData s when s.id.isEmpty =>
        s.copyWith(id: const Uuid().v4()),
      AccelerometerSensorData s when s.id.isEmpty =>
        s.copyWith(id: const Uuid().v4()),
      _ => d,
    };
  }

  Future<List<SensorData>> _decryptAll(
      List<Map<String, Object?>> rows) async {
    final result = <SensorData>[];
    for (final row in rows) {
      try {
        final parsed = _rowToSensorData(row);
        result.add(await _encryption.decryptSensorData(parsed));
      } catch (_) {
        // Skip corrupt rows.
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Row → SensorData (mirrors LocalSensorDataSource._rowToSensorData in source)
  // ---------------------------------------------------------------------------
  SensorData _rowToSensorData(Map<String, Object?> row) {
    final type = row['sensorType'] as String;
    final base = {
      'id': row['id'],
      'userId': row['userId'],
      'timestamp': row['timestamp'].toString(),
      'date': row['date'],
      'sensorType': type,
    };

    return switch (type) {
      'audio' => AudioSensorData.fromJson({
          ...base,
          'averageDecibels': row['averageDecibels'],
          'peakDecibels': row['peakDecibels'],
          'frequencyBands': row['frequencyBands'] != null
              ? jsonDecode(row['frequencyBands'] as String)
              : {'low': '0', 'mid': '0', 'high': '0'},
          'audioClipUri': row['audioClipUri'],
          'snoreDetected': row['snoreDetected'],
          'ambientNoiseLevel': row['ambientNoiseLevel'] ?? 'quiet',
        }),
      'light' => LightSensorData.fromJson({
          ...base,
          'illuminance': row['illuminance'],
          'lightLevel': row['lightLevel'] ?? 'dark',
        }),
      'accelerometer' => AccelerometerSensorData.fromJson({
          ...base,
          'x': row['x'],
          'y': row['y'],
          'z': row['z'],
          'magnitude': row['magnitude'],
          'movementIntensity': row['movementIntensity'] ?? 'still',
        }),
      _ => throw ArgumentError('Unknown sensorType: $type'),
    };
  }

  // ---------------------------------------------------------------------------
  // INSERT SQL builders (all 3 sensor types go into the same table — Rule 13)
  // ---------------------------------------------------------------------------
  String _insertSql(SensorData d) => switch (d) {
        AudioSensorData _ => '''
          INSERT INTO sensor_data
            (id, userId, timestamp, date, sensorType, averageDecibels,
             peakDecibels, frequencyBands, audioClipUri, snoreDetected,
             ambientNoiseLevel)
          VALUES (?,?,?,?,?,?,?,?,?,?,?)
        ''',
        LightSensorData _ => '''
          INSERT INTO sensor_data
            (id, userId, timestamp, date, sensorType, illuminance, lightLevel)
          VALUES (?,?,?,?,?,?,?)
        ''',
        AccelerometerSensorData _ => '''
          INSERT INTO sensor_data
            (id, userId, timestamp, date, sensorType, x, y, z, magnitude,
             movementIntensity)
          VALUES (?,?,?,?,?,?,?,?,?,?)
        ''',
      };

  List<Object?> _insertParams(SensorData d) => switch (d) {
        AudioSensorData s => [
            s.id, s.userId, s.timestamp, s.date, s.sensorType,
            s.averageDecibels, s.peakDecibels,
            jsonEncode(s.frequencyBands.toJson()),
            s.audioClipUri,
            s.snoreDetected ? 1 : 0,
            s.ambientNoiseLevel.toJson(),
          ],
        LightSensorData s => [
            s.id, s.userId, s.timestamp, s.date, s.sensorType,
            s.illuminance, s.lightLevel.toJson(),
          ],
        AccelerometerSensorData s => [
            s.id, s.userId, s.timestamp, s.date, s.sensorType,
            s.x, s.y, s.z, s.magnitude, s.movementIntensity.toJson(),
          ],
      };
}

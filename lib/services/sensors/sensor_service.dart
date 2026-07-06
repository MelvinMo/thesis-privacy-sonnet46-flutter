// MIGRATION: services/sensors/SensorService.ts (abstract class) → Dart abstract class.
//            Abstract method signatures preserved exactly.
//            Callback pattern preserved: onAudioData / onLightData / onAccelerometerData.

import 'dart:io' show Platform;
import '../../core/constants/sensor_config.dart';
import '../../core/models/sensor_data.dart';

// MIGRATION: TypeScript abstract class → Dart abstract class.
//            Protected fields → underscore-prefixed in Dart (no `protected` keyword).
abstract class SensorService {
  SensorServiceConfig config;
  bool isRecording = false;
  String? currentSessionId;

  SensorService(this.config);

  // ── Abstract methods (platform-specific implementations) ──────────────────
  Future<bool> isAudioAvailable();
  Future<bool> isLightAvailable();
  Future<bool> isAccelerometerAvailable();

  Future<void> startAudioMonitoring();
  Future<void> stopAudioMonitoring();
  Future<void> startLightMonitoring();
  Future<void> stopLightMonitoring();
  Future<void> startAccelerometerMonitoring();
  Future<void> stopAccelerometerMonitoring();

  // ── Common methods ─────────────────────────────────────────────────────────
  String? getSessionId() => currentSessionId;
  bool isRecordingActive() => isRecording;

  void updateConfig(SensorServiceConfig newConfig) {
    config = newConfig;
  }

  // ── Callbacks (bridge sensor data to storage services) ────────────────────
  // MIGRATION: onAudioData / onLightData / onAccelerometerData are empty hooks
  //            in the source. In Dart, SensorRepository overrides these by
  //            assigning closures via the function fields below — identical pattern.
  void Function(AudioSensorData data)? onAudioData;
  void Function(LightSensorData data)? onLightData;
  void Function(AccelerometerSensorData data)? onAccelerometerData;
  void Function(Object error, String sensorType)? onError;

  // Default error handler.
  void handleError(Object error, String sensorType) {
    if (onError != null) {
      onError!(error, sensorType);
    } else {
      // ignore: avoid_print
      print('Sensor error ($sensorType): $error');
    }
  }

  // ── Platform detection helper ────────────────────────────────────────────
  // MIGRATION: expo-sensors LightSensor not available on iOS without a native
  //            module → stub with SensorNotAvailableWidget (Rule 10).
  bool get isIos => Platform.isIOS;
}

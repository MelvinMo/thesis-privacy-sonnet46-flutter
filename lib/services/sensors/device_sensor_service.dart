// MIGRATION: services/sensors/ExpoSensorService.ts → DeviceSensorService.
//
//            API mappings:
//              expo-sensors.Accelerometer → sensors_plus AccelerometerEvent
//              expo-sensors.LightSensor   → sensors_plus (Android only; iOS stub Rule 10)
//              expo-av.Audio              → record ^5 (amplitude metering for dB)
//
//            Interval logic: source polls every samplingRates.audio/light/accelerometer
//            seconds via setInterval. Flutter: Timer.periodic() equivalent.
//
//            MIGRATION_FLAG: sensors_plus LightSensor is available on Android only.
//              On iOS, isLightAvailable() returns false → caller shows SensorNotAvailableWidget.

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:record/record.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../core/constants/sensor_config.dart';
import '../../core/models/sensor_data.dart';
import 'sensor_service.dart';

class DeviceSensorService extends SensorService {
  DeviceSensorService(super.config);

  // ── Audio ──────────────────────────────────────────────────────────────────
  final _audioRecorder = AudioRecorder();
  Timer? _audioTimer;

  // ── Light ──────────────────────────────────────────────────────────────────
  // MIGRATION_FLAG: sensors_plus does not expose a LightSensor stream on iOS.
  //                 On Android, use SensorsPlatform.instance stream equivalents.
  //                 For now, wrap with null check + stub.
  StreamSubscription<dynamic>? _lightSub;
  Timer? _lightTimer;
  double _lastLux = 0;

  // ── Accelerometer ──────────────────────────────────────────────────────────
  StreamSubscription<AccelerometerEvent>? _accelSub;
  Timer? _accelTimer;
  AccelerometerEvent? _lastAccel;

  // ---------------------------------------------------------------------------
  // Availability checks
  // ---------------------------------------------------------------------------
  @override
  Future<bool> isAudioAvailable() async {
    return _audioRecorder.hasPermission();
  }

  @override
  Future<bool> isLightAvailable() async {
    // MIGRATION: iOS does not expose a light sensor via sensors_plus (Rule 10).
    if (Platform.isIOS) return false;
    // MIGRATION_FLAG: No canStream() API in sensors_plus; assume available on Android.
    return true;
  }

  @override
  Future<bool> isAccelerometerAvailable() async {
    // MIGRATION: AccelerometerEvent stream is always available on both platforms.
    return true;
  }

  // ---------------------------------------------------------------------------
  // Audio monitoring
  // MIGRATION: expo-av Audio.Recording → record ^5.
  //            record uses amplitude metering (dBFS) which we normalise to
  //            approximate SPL dB values (range shift from -∞→0 to 30→90 dB).
  // ---------------------------------------------------------------------------
  @override
  Future<void> startAudioMonitoring() async {
    if (!config.audioEnabled) return;
    await _audioRecorder.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
      ),
      path: '/dev/null', // We only need amplitude, no file storage by default.
    );
    _audioTimer = Timer.periodic(
      Duration(seconds: config.samplingRates.audioSeconds),
      (_) => _sampleAudio(),
    );
  }

  Future<void> _sampleAudio() async {
    try {
      final amp = await _audioRecorder.getAmplitude();
      // MIGRATION: expo-av metering → record amplitude.
      //            amp.current is dBFS (negative). Convert to approximate SPL:
      //            SPL ≈ dBFS + 90 (device-dependent offset; tune as needed).
      // MIGRATION_FLAG: Without calibration, dB values are relative, not absolute.
      final avgDb = (amp.current + 90).clamp(30.0, 120.0);
      final peakDb = (amp.max + 90).clamp(30.0, 120.0);

      final level = _ambientNoiseLevel(avgDb);
      final snore = config.audioProcessing.enableSnoreDetection &&
          avgDb > 50 && avgDb < 75;

      final data = AudioSensorData(
        id: const Uuid().v4(),
        userId: '',
        timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        averageDecibels: avgDb.toStringAsFixed(2),
        peakDecibels: peakDb.toStringAsFixed(2),
        frequencyBands: const FrequencyBands(low: '0', mid: '0', high: '0'),
        snoreDetected: snore,
        ambientNoiseLevel: level,
      );
      onAudioData?.call(data);
    } catch (e) {
      handleError(e, 'audio');
    }
  }

  @override
  Future<void> stopAudioMonitoring() async {
    _audioTimer?.cancel();
    _audioTimer = null;
    await _audioRecorder.stop();
  }

  // ---------------------------------------------------------------------------
  // Light monitoring
  // ---------------------------------------------------------------------------
  @override
  Future<void> startLightMonitoring() async {
    if (!config.lightEnabled || Platform.isIOS) return;

    // MIGRATION: sensors_plus does not expose LightSensor as a named stream.
    //            On Android we use a platform channel stub or the generic
    //            SensorsPlatform.sensorEvents stream with the light sensor type.
    // MIGRATION_FLAG: sensors_plus ^4 removed direct light sensor stream.
    //                 Using a Timer-based poll that reads the last known lux value.
    //                 A proper plugin (flutter_light_sensor) can replace this.
    _lightTimer = Timer.periodic(
      Duration(seconds: config.samplingRates.lightSeconds),
      (_) => _sampleLight(),
    );
  }

  void _sampleLight() {
    // MIGRATION_FLAG: _lastLux must be updated by a platform-level light sensor
    //                 stream once the appropriate plugin is added.
    //                 Currently defaults to 0 lux until integrated.
    final lux = _lastLux;
    final data = LightSensorData(
      id: const Uuid().v4(),
      userId: '',
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      illuminance: lux.toStringAsFixed(2),
      lightLevel: _lightLevel(lux),
    );
    onLightData?.call(data);
  }

  @override
  Future<void> stopLightMonitoring() async {
    _lightTimer?.cancel();
    _lightTimer = null;
    await _lightSub?.cancel();
    _lightSub = null;
  }

  // ---------------------------------------------------------------------------
  // Accelerometer monitoring
  // MIGRATION: expo-sensors.Accelerometer → sensors_plus.accelerometerEventStream()
  // ---------------------------------------------------------------------------
  @override
  Future<void> startAccelerometerMonitoring() async {
    if (!config.accelerometerEnabled) return;
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 500),
    ).listen(
      (event) {
        _lastAccel = event;
      },
      onError: (e) => handleError(e, 'accelerometer'),
    );
    _accelTimer = Timer.periodic(
      Duration(seconds: config.samplingRates.accelerometerSeconds),
      (_) => _sampleAccelerometer(),
    );
  }

  void _sampleAccelerometer() {
    final event = _lastAccel;
    if (event == null) return;
    final mag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    final data = AccelerometerSensorData(
      id: const Uuid().v4(),
      userId: '',
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      x: event.x.toStringAsFixed(4),
      y: event.y.toStringAsFixed(4),
      z: event.z.toStringAsFixed(4),
      magnitude: mag.toStringAsFixed(4),
      movementIntensity: _movementIntensity(mag),
    );
    onAccelerometerData?.call(data);
  }

  @override
  Future<void> stopAccelerometerMonitoring() async {
    _accelTimer?.cancel();
    _accelTimer = null;
    await _accelSub?.cancel();
    _accelSub = null;
  }

  // ---------------------------------------------------------------------------
  // Classification helpers (mirrors ExpoSensorService categorisation logic)
  // ---------------------------------------------------------------------------
  AmbientNoiseLevel _ambientNoiseLevel(double db) {
    if (db < 40) return AmbientNoiseLevel.quiet;
    if (db < 60) return AmbientNoiseLevel.moderate;
    if (db < 75) return AmbientNoiseLevel.loud;
    return AmbientNoiseLevel.veryLoud;
  }

  LightLevel _lightLevel(double lux) {
    if (lux < 5) return LightLevel.dark;
    if (lux < 50) return LightLevel.dim;
    if (lux < 200) return LightLevel.moderate;
    return LightLevel.bright;
  }

  MovementIntensity _movementIntensity(double mag) {
    if (mag < 0.1) return MovementIntensity.still;
    if (mag < 0.5) return MovementIntensity.light;
    if (mag < 1.5) return MovementIntensity.moderate;
    return MovementIntensity.active;
  }
}

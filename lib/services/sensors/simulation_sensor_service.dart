// MIGRATION: services/sensors/SimulationSensorService.ts → Dart.
//            Preserves all demo-mode fake data patterns:
//              - Audio: quieter at night (22:00–6:00)
//              - Light: time-aware (dark at night, bright during day)
//              - Accelerometer: sleep-like movement patterns
//            Used for demo mode AND iOS light sensor (always returns available).
//            Rule 7: Demo Mode (fake sensors, encryption toggle) fully preserved.

import 'dart:async';
import 'dart:math';

import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../core/constants/sensor_config.dart';
import '../../core/models/sensor_data.dart';
import 'sensor_service.dart';

class SimulationSensorService extends SensorService {
  SimulationSensorService(super.config);

  final _rng = Random();
  Timer? _audioTimer;
  Timer? _lightTimer;
  Timer? _accelTimer;

  // ---------------------------------------------------------------------------
  // Always available (no permissions needed for simulation).
  // ---------------------------------------------------------------------------
  @override
  Future<bool> isAudioAvailable() async => true;

  @override
  Future<bool> isLightAvailable() async => true; // Always available in simulation.

  @override
  Future<bool> isAccelerometerAvailable() async => true;

  // ---------------------------------------------------------------------------
  // Audio simulation — mirrors SimulationSensorService.ts audio logic.
  // ---------------------------------------------------------------------------
  @override
  Future<void> startAudioMonitoring() async {
    _audioTimer = Timer.periodic(
      Duration(seconds: config.samplingRates.audioSeconds),
      (_) => _simulateAudio(),
    );
  }

  void _simulateAudio() {
    final hour = DateTime.now().hour;
    // MIGRATION: TS: audioData quieter at night (22:00–6:00).
    final isNight = hour >= 22 || hour < 6;
    final baseDb = isNight ? 35.0 : 55.0;
    final avgDb = baseDb + _rng.nextDouble() * 15;
    final peakDb = avgDb + _rng.nextDouble() * 10;
    final snore = isNight && avgDb > 48;
    final level = avgDb < 40
        ? AmbientNoiseLevel.quiet
        : avgDb < 60
            ? AmbientNoiseLevel.moderate
            : avgDb < 75
                ? AmbientNoiseLevel.loud
                : AmbientNoiseLevel.veryLoud;

    onAudioData?.call(AudioSensorData(
      id: const Uuid().v4(),
      userId: '',
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      averageDecibels: avgDb.toStringAsFixed(2),
      peakDecibels: peakDb.toStringAsFixed(2),
      frequencyBands: FrequencyBands(
        low: (0.3 + _rng.nextDouble() * 0.4).toStringAsFixed(3),
        mid: (0.2 + _rng.nextDouble() * 0.3).toStringAsFixed(3),
        high: (0.1 + _rng.nextDouble() * 0.2).toStringAsFixed(3),
      ),
      snoreDetected: snore,
      ambientNoiseLevel: level,
    ));
  }

  @override
  Future<void> stopAudioMonitoring() async {
    _audioTimer?.cancel();
    _audioTimer = null;
  }

  // ---------------------------------------------------------------------------
  // Light simulation — time-aware (dark at night, bright during day).
  // ---------------------------------------------------------------------------
  @override
  Future<void> startLightMonitoring() async {
    _lightTimer = Timer.periodic(
      Duration(seconds: config.samplingRates.lightSeconds),
      (_) => _simulateLight(),
    );
  }

  void _simulateLight() {
    final hour = DateTime.now().hour;
    // MIGRATION: TS light simulation: dark at night, bright daytime.
    double baseLux;
    LightLevel level;
    if (hour >= 22 || hour < 6) {
      baseLux = _rng.nextDouble() * 5;
      level = LightLevel.dark;
    } else if (hour < 9 || hour >= 18) {
      baseLux = 20 + _rng.nextDouble() * 80;
      level = LightLevel.dim;
    } else {
      baseLux = 100 + _rng.nextDouble() * 400;
      level = LightLevel.bright;
    }

    onLightData?.call(LightSensorData(
      id: const Uuid().v4(),
      userId: '',
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      illuminance: baseLux.toStringAsFixed(2),
      lightLevel: level,
    ));
  }

  @override
  Future<void> stopLightMonitoring() async {
    _lightTimer?.cancel();
    _lightTimer = null;
  }

  // ---------------------------------------------------------------------------
  // Accelerometer simulation — sleep-like movement patterns.
  // ---------------------------------------------------------------------------
  @override
  Future<void> startAccelerometerMonitoring() async {
    _accelTimer = Timer.periodic(
      Duration(seconds: config.samplingRates.accelerometerSeconds),
      (_) => _simulateAccelerometer(),
    );
  }

  void _simulateAccelerometer() {
    final hour = DateTime.now().hour;
    // MIGRATION: TS: mostly still during sleep hours.
    final isSleeping = hour >= 22 || hour < 7;
    final maxMag = isSleeping ? 0.3 : 1.5;
    final x = (_rng.nextDouble() - 0.5) * maxMag;
    final y = (_rng.nextDouble() - 0.5) * maxMag;
    final z = (_rng.nextDouble() - 0.5) * maxMag;
    final mag = sqrt(x * x + y * y + z * z);
    final intensity = mag < 0.1
        ? MovementIntensity.still
        : mag < 0.5
            ? MovementIntensity.light
            : mag < 1.5
                ? MovementIntensity.moderate
                : MovementIntensity.active;

    onAccelerometerData?.call(AccelerometerSensorData(
      id: const Uuid().v4(),
      userId: '',
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      x: x.toStringAsFixed(4),
      y: y.toStringAsFixed(4),
      z: z.toStringAsFixed(4),
      magnitude: mag.toStringAsFixed(4),
      movementIntensity: intensity,
    ));
  }

  @override
  Future<void> stopAccelerometerMonitoring() async {
    _accelTimer?.cancel();
    _accelTimer = null;
  }
}

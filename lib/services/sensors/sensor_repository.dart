// MIGRATION: services/sensors/SensorRepository.ts → Dart.
//            Facade that:
//              1. Selects real (DeviceSensorService) vs simulation (SimulationSensorService)
//                 based on config.useSimulation or platform (iOS always simulates light).
//              2. Bridges sensor data callbacks → SensorStorageRepository.
//              3. Respects user consent preferences before starting sensors.
//
//            Background note (Rule 11): actual ForegroundService wiring is in
//            BackgroundSensorService; this class manages the sensor lifecycle
//            regardless of foreground/background context.

import 'dart:io' show Platform;

import '../../blocs/transparency/transparency_bloc.dart';
import '../../blocs/transparency/transparency_event.dart';
import '../../blocs/user_profile/user_profile_cubit.dart';
import '../../core/constants/sensor_config.dart';
import '../../core/constants/transparency_config.dart';
import '../../core/models/sensor_data.dart';
import '../../core/models/transparency.dart';
import '../../core/models/user_consent_preferences.dart';
import '../data/sensor_storage_repository.dart';
import 'device_sensor_service.dart';
import 'sensor_service.dart';
import 'simulation_sensor_service.dart';

class SensorRepository {
  final DeviceSensorService _deviceService;
  final SimulationSensorService _simulationService;
  final SensorStorageRepository _storageRepository;
  final UserProfileCubit _profileCubit;
  final TransparencyBloc _transparencyBloc;

  SensorServiceConfig _config;

  // True while sleep mode is active (between startAll and stopAll).
  bool _sensorsRunning = false;

  SensorRepository({
    required DeviceSensorService deviceService,
    required SimulationSensorService simulationService,
    required SensorStorageRepository storageRepository,
    required UserProfileCubit profileCubit,
    required TransparencyBloc transparencyBloc,
    SensorServiceConfig config = const SensorServiceConfig(),
  })  : _deviceService = deviceService,
        _simulationService = simulationService,
        _storageRepository = storageRepository,
        _profileCubit = profileCubit,
        _transparencyBloc = transparencyBloc,
        _config = config {
    _wireSensorCallbacks();
  }

  // ---------------------------------------------------------------------------
  // Active service selection (matches SensorRepository.ts logic).
  // ---------------------------------------------------------------------------
  SensorService get _activeService =>
      _config.useSimulation || TransparencyConfig.inDemoMode
          ? _simulationService
          : _deviceService;

  // For light specifically: if iOS, always use simulation (Rule 10).
  SensorService get _activeLightService =>
      Platform.isIOS ? _simulationService : _activeService;

  // ---------------------------------------------------------------------------
  // Wire data callbacks → SensorStorageRepository.
  // MIGRATION: Source wires callbacks inside SensorRepository constructor.
  // ---------------------------------------------------------------------------
  void _wireSensorCallbacks() {
    for (final svc in [_deviceService, _simulationService]) {
      svc.onAudioData = _handleAudioData;
      svc.onLightData = _handleLightData;
      svc.onAccelerometerData = _handleAccelerometerData;
    }
  }

  void _handleAudioData(AudioSensorData data) {
    final prefs = _profileCubit.consentPreferences;
    if (!prefs.microphoneEnabled) return;
    final withUser = data.copyWith(userId: _userId);
    _storageRepository.createSensorReading(withUser)
        .then((_) {}, onError: (e) => print('Failed to save audio data: $e'));
    _updateBackgroundMode('audio');
  }

  void _handleLightData(LightSensorData data) {
    final prefs = _profileCubit.consentPreferences;
    if (!prefs.lightSensorEnabled) return;
    final withUser = data.copyWith(userId: _userId);
    _storageRepository.createSensorReading(withUser)
        .then((_) {}, onError: (e) => print('Failed to save light data: $e'));
    _updateBackgroundMode('light');
  }

  void _handleAccelerometerData(AccelerometerSensorData data) {
    final prefs = _profileCubit.consentPreferences;
    if (!prefs.accelerometerEnabled) return;
    final withUser = data.copyWith(userId: _userId);
    _storageRepository.createSensorReading(withUser)
        .then((_) {}, onError: (e) => print('Failed to save accelerometer data: $e'));
    _updateBackgroundMode('accelerometer');
  }

  // Update the backgroundMode flag in each sensor's transparency channel.
  void _updateBackgroundMode(String sensorType) {
    switch (sensorType) {
      case 'audio':
        final c = _transparencyBloc.state.microphoneTransparency;
        _transparencyBloc.add(SetMicrophoneTransparencyEvent(
            c.copyWith(backgroundMode: true)));
      case 'light':
        final c = _transparencyBloc.state.lightSensorTransparency;
        _transparencyBloc.add(SetLightSensorTransparencyEvent(
            c.copyWith(backgroundMode: true)));
      case 'accelerometer':
        final c = _transparencyBloc.state.accelerometerTransparency;
        _transparencyBloc.add(SetAccelerometerTransparencyEvent(
            c.copyWith(backgroundMode: true)));
    }
  }

  String get _userId {
    // MIGRATION: userId comes from AuthCubit; passed via ServiceLocator at call site.
    // MIGRATION_FLAG: Inject AuthCubit here if userId is needed at callback time.
    return '';
  }

  // ---------------------------------------------------------------------------
  // Public API (mirrors SensorRepository.ts public methods)
  // ---------------------------------------------------------------------------

  Future<void> startAudioMonitoring() async {
    if (!_profileCubit.consentPreferences.microphoneEnabled) return;
    await _activeService.startAudioMonitoring();
  }

  Future<void> stopAudioMonitoring() async {
    await _activeService.stopAudioMonitoring();
  }

  Future<void> startLightMonitoring() async {
    if (!_profileCubit.consentPreferences.lightSensorEnabled) return;
    await _activeLightService.startLightMonitoring();
  }

  Future<void> stopLightMonitoring() async {
    await _activeLightService.stopLightMonitoring();
  }

  Future<void> startAccelerometerMonitoring() async {
    if (!_profileCubit.consentPreferences.accelerometerEnabled) return;
    await _activeService.startAccelerometerMonitoring();
  }

  Future<void> stopAccelerometerMonitoring() async {
    await _activeService.stopAccelerometerMonitoring();
  }

  /// Start all sensors allowed by current consent. Call when entering sleep mode.
  Future<void> startAll() async {
    _sensorsRunning = true;
    await Future.wait([
      startAudioMonitoring(),
      startLightMonitoring(),
      startAccelerometerMonitoring(),
    ]);
  }

  /// Stop all sensors. Call when exiting sleep mode.
  Future<void> stopAll() async {
    _sensorsRunning = false;
    await Future.wait([
      stopAudioMonitoring(),
      stopLightMonitoring(),
      stopAccelerometerMonitoring(),
    ]);
  }

  /// Called whenever the user changes consent preferences.
  /// Updates the sensor config and, if sensors are running (sleep mode is active),
  /// immediately stops sensors whose consent was revoked and starts newly-granted ones.
  Future<void> syncWithConsent(UserConsentPreferences prefs) async {
    // Update config so subsequent startAll() respects new consent.
    _config = _config.copyWith(
      audioEnabled: prefs.microphoneEnabled,
      lightEnabled: prefs.lightSensorEnabled,
      accelerometerEnabled: prefs.accelerometerEnabled,
    );
    _activeService.updateConfig(_config);
    _activeLightService.updateConfig(_config);

    // If not in sleep mode there is nothing running to stop or start.
    if (!_sensorsRunning) return;

    // Stop sensors whose consent was just revoked (safe to call even if not running).
    if (!prefs.microphoneEnabled) await _activeService.stopAudioMonitoring();
    if (!prefs.lightSensorEnabled) await _activeLightService.stopLightMonitoring();
    if (!prefs.accelerometerEnabled) {
      await _activeService.stopAccelerometerMonitoring();
    }

    // Start sensors whose consent was just granted.
    if (prefs.microphoneEnabled) await _activeService.startAudioMonitoring();
    if (prefs.lightSensorEnabled) await _activeLightService.startLightMonitoring();
    if (prefs.accelerometerEnabled) {
      await _activeService.startAccelerometerMonitoring();
    }
  }

  Future<void> updateConfig(SensorServiceConfig partial) async {
    _config = partial;
    _activeService.updateConfig(partial);
  }

  // Current config (read by SleepModeScreen to check useSimulation flag).
  SensorServiceConfig get currentConfig => _config;

  // Availability checks.
  Future<bool> isLightAvailable() => _activeLightService.isLightAvailable();
  Future<bool> isAudioAvailable() => _activeService.isAudioAvailable();
  Future<bool> isAccelerometerAvailable() =>
      _activeService.isAccelerometerAvailable();
}

// MIGRATION: SensorStorageRepository.ts → Dart.
//            Routes sensor writes to local or cloud based on cloudStorageEnabled.

import '../../blocs/transparency/transparency_bloc.dart';
import '../../blocs/transparency/transparency_event.dart';
import '../../blocs/user_profile/user_profile_cubit.dart';
import '../../core/models/sensor_data.dart';
import '../../core/models/transparency.dart';
import '../transparency_service.dart';
import 'data_sources/sensor_data_source.dart';

class SensorStorageRepository {
  final SensorDataSource _localSource;
  final SensorDataSource _cloudSource;
  final UserProfileCubit _profileCubit;
  final TransparencyBloc _transparencyBloc;
  final TransparencyService _transparencyService;

  SensorStorageRepository({
    required SensorDataSource localSource,
    required SensorDataSource cloudSource,
    required UserProfileCubit profileCubit,
    required TransparencyBloc transparencyBloc,
    required TransparencyService transparencyService,
  })  : _localSource = localSource,
        _cloudSource = cloudSource,
        _profileCubit = profileCubit,
        _transparencyBloc = transparencyBloc,
        _transparencyService = transparencyService;

  SensorDataSource get _activeSource =>
      _profileCubit.cloudStorageEnabled ? _cloudSource : _localSource;

  Future<SensorData> createSensorReading(SensorData sensorData) async {
    final result = await _activeSource.createSensorReading(sensorData);
    _updateSensorTransparencyStorage(sensorData.sensorType);
    return result;
  }

  Future<SensorData?> getSensorReadingById(String id) async {
    return _activeSource.getSensorReadingById(id);
  }

  Future<List<SensorData>> getSensorReadingsByUserId(String userId) async {
    return _activeSource.getSensorReadingsByUserId(userId);
  }

  Future<List<SensorData>> getSensorReadingsByDate(
      String date, String userId) async {
    return _activeSource.getSensorReadingsByDate(date, userId);
  }

  Future<bool> deleteSensorReading(String id) async {
    return _activeSource.deleteSensorReading(id);
  }

  // ---------------------------------------------------------------------------
  // Transparency channel updates per sensor type.
  // ---------------------------------------------------------------------------
  void _updateSensorTransparencyStorage(String sensorType) {
    final dest = _profileCubit.cloudStorageEnabled
        ? DataDestination.googleCloud
        : DataDestination.sqliteDb;

    switch (sensorType) {
      case 'audio':
        final c = _transparencyBloc.state.microphoneTransparency;
        _transparencyBloc.add(SetMicrophoneTransparencyEvent(
            c.copyWith(storageLocation: dest)));
        _analyzeAndEmit('audio');
      case 'light':
        final c = _transparencyBloc.state.lightSensorTransparency;
        _transparencyBloc.add(SetLightSensorTransparencyEvent(
            c.copyWith(storageLocation: dest)));
        _analyzeAndEmit('light');
      case 'accelerometer':
        final c = _transparencyBloc.state.accelerometerTransparency;
        _transparencyBloc.add(SetAccelerometerTransparencyEvent(
            c.copyWith(storageLocation: dest)));
        _analyzeAndEmit('accelerometer');
    }
  }

  void _analyzeAndEmit(String sensorType) {
    final bloc = _transparencyBloc;
    final prefs = _profileCubit.consentPreferences;

    TransparencyEvent current;
    void Function(TransparencyEvent) emitter;

    switch (sensorType) {
      case 'audio':
        current = bloc.state.microphoneTransparency;
        emitter = (e) => bloc.add(SetMicrophoneTransparencyEvent(e));
      case 'light':
        current = bloc.state.lightSensorTransparency;
        emitter = (e) => bloc.add(SetLightSensorTransparencyEvent(e));
      case 'accelerometer':
        current = bloc.state.accelerometerTransparency;
        emitter = (e) => bloc.add(SetAccelerometerTransparencyEvent(e));
      default:
        return;
    }

    _transparencyService
        .analyzePrivacyRisks(current, prefs)
        .then(emitter)
        .catchError((_) {});
  }
}

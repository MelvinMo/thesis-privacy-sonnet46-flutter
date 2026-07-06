// MIGRATION: GeneralSleepDataRepository.ts → Dart.

import '../../blocs/transparency/transparency_bloc.dart';
import '../../blocs/transparency/transparency_event.dart';
import '../../blocs/user_profile/user_profile_cubit.dart';
import '../../core/models/general_sleep_data.dart';
import '../../core/models/transparency.dart';
import '../transparency_service.dart';
import 'data_sources/general_sleep_data_source.dart';

class GeneralSleepDataRepository {
  final GeneralSleepDataSource _localSource;
  final GeneralSleepDataSource _cloudSource;
  final UserProfileCubit _profileCubit;
  final TransparencyBloc _transparencyBloc;
  final TransparencyService _transparencyService;

  GeneralSleepDataRepository({
    required GeneralSleepDataSource localSource,
    required GeneralSleepDataSource cloudSource,
    required UserProfileCubit profileCubit,
    required TransparencyBloc transparencyBloc,
    required TransparencyService transparencyService,
  })  : _localSource = localSource,
        _cloudSource = cloudSource,
        _profileCubit = profileCubit,
        _transparencyBloc = transparencyBloc,
        _transparencyService = transparencyService;

  GeneralSleepDataSource get _activeSource =>
      _profileCubit.cloudStorageEnabled ? _cloudSource : _localSource;

  Future<GeneralSleepData?> getSleepData(String userId) async {
    final data = await _activeSource.getSleepData(userId);
    _updateTransparencyStorage();
    return data;
  }

  Future<GeneralSleepData> createSleepData(GeneralSleepData sleepData) async {
    final result = await _activeSource.createSleepData(sleepData);
    _triggerTransparencyAnalysis();
    return result;
  }

  Future<void> deleteSleepData(String userId) async {
    await _activeSource.deleteSleepData(userId);
  }

  void _updateTransparencyStorage() {
    final current = _transparencyBloc.state.generalSleepTransparency;
    final dest = _profileCubit.cloudStorageEnabled
        ? DataDestination.googleCloud
        : DataDestination.asyncStorage;
    _transparencyBloc
        .add(SetGeneralSleepTransparencyEvent(current.copyWith(storageLocation: dest)));
  }

  void _triggerTransparencyAnalysis() {
    final current = _transparencyBloc.state.generalSleepTransparency;
    _transparencyService
        .analyzePrivacyRisks(current, _profileCubit.consentPreferences)
        .then((updated) =>
            _transparencyBloc.add(SetGeneralSleepTransparencyEvent(updated)))
        .catchError((_) {});
  }
}

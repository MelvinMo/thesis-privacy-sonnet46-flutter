// MIGRATION: services/data/JournalDataRepository.ts → Dart.
//            Repository pattern (Rule 4): switches between local/cloud data source
//            based on user consent (cloudStorageEnabled).

import '../../blocs/transparency/transparency_bloc.dart';
import '../../blocs/transparency/transparency_event.dart';
import '../../blocs/user_profile/user_profile_cubit.dart';
import '../../core/models/journal_data.dart';
import '../../core/models/transparency.dart';
import '../transparency_service.dart';
import 'data_sources/journal_data_source.dart';

class JournalDataRepository {
  final JournalDataSource _localSource;
  final JournalDataSource _cloudSource;
  final UserProfileCubit _profileCubit;
  final TransparencyBloc _transparencyBloc;
  final TransparencyService _transparencyService;

  JournalDataRepository({
    required JournalDataSource localSource,
    required JournalDataSource cloudSource,
    required UserProfileCubit profileCubit,
    required TransparencyBloc transparencyBloc,
    required TransparencyService transparencyService,
  })  : _localSource = localSource,
        _cloudSource = cloudSource,
        _profileCubit = profileCubit,
        _transparencyBloc = transparencyBloc,
        _transparencyService = transparencyService;

  JournalDataSource get _activeSource =>
      _profileCubit.cloudStorageEnabled ? _cloudSource : _localSource;

  String get _userId => _profileCubit.state.runtimeType.toString(); // placeholder; replaced at runtime

  // ---------------------------------------------------------------------------
  // getJournalByDate
  // ---------------------------------------------------------------------------
  Future<JournalData?> getJournalByDate(String date, String userId) async {
    final journal = await _activeSource.getJournalByDate(date, userId);
    _updateTransparencyStorage();
    return journal;
  }

  // ---------------------------------------------------------------------------
  // editJournal
  // ---------------------------------------------------------------------------
  Future<JournalData?> editJournal(
      Map<String, dynamic> partial, String date, String userId) async {
    final result = await _activeSource.editJournal(partial, date, userId);
    _triggerTransparencyAnalysis();
    return result;
  }

  // ---------------------------------------------------------------------------
  // deleteJournal
  // ---------------------------------------------------------------------------
  Future<void> deleteJournal(String journalId) async {
    await _activeSource.deleteJournal(journalId);
  }

  // ---------------------------------------------------------------------------
  // Transparency helpers
  // ---------------------------------------------------------------------------

  // MIGRATION: Source repositories call transparencyStore.setJournalTransparency
  //            after saving/loading. We dispatch the BLoC event instead.
  void _updateTransparencyStorage() {
    final current = _transparencyBloc.state.journalTransparency;
    final destination = _profileCubit.cloudStorageEnabled
        ? DataDestination.googleCloud
        : DataDestination.sqliteDb;
    _transparencyBloc.add(SetJournalTransparencyEvent(
        current.copyWith(storageLocation: destination)));
  }

  // MIGRATION: Source calls transparencyService.analyzePrivacyRisks() as fire-and-forget.
  void _triggerTransparencyAnalysis() {
    final current = _transparencyBloc.state.journalTransparency;
    _transparencyService
        .analyzePrivacyRisks(
          current,
          _profileCubit.consentPreferences,
        )
        .then((updated) =>
            _transparencyBloc.add(SetJournalTransparencyEvent(updated)))
        .catchError((_) {});
  }
}

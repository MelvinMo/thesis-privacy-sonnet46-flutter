// MIGRATION: app/(tabs)/journal.tsx → Dart StatefulWidget.
//            Mirrors NormalJournalPage: Sleep Goal card, Diary, Sleep Notes,
//            Activity Tracker (Steps + Calories circular progress).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../app/app.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/transparency/transparency_bloc.dart';
import '../../blocs/transparency/transparency_event.dart';
import '../../blocs/transparency/transparency_state.dart';
import '../../blocs/user_profile/user_profile_cubit.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/transparency_config.dart';
import '../../core/di/service_locator.dart';
import '../../core/models/journal_data.dart';
import '../../core/models/transparency.dart';
import '../../core/utils/transparency_utils.dart';
import '../../widgets/calendar_widget.dart';
import '../../widgets/loader.dart';
import '../../widgets/modals/journal_entry_modal.dart';
import '../../widgets/modals/sleep_notes_modal.dart';
import '../../widgets/transparency/privacy_icon.dart';
import '../../widgets/transparency/privacy_tooltip.dart';
import '../../widgets/transparency/privacy_page_components.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _showCalendar = false;

  String _diaryEntry = '';
  List<SleepNote> _sleepNotes = [];
  String _bedtime = '';
  String _alarmTime = '';
  String _sleepGoal = '';

  bool _isLoading = false;
  bool _isSaving = false;
  bool _showJournalModal = false;
  bool _showNotesModal = false;
  bool _displayNormalUI = true;

  String get _userId {
    final s = context.read<AuthCubit>().state;
    return s is AuthAuthenticated ? s.user.userId : '';
  }

  @override
  void initState() {
    super.initState();
    _loadJournalData();
  }

  Future<void> _loadJournalData() async {
    setState(() => _isLoading = true);
    try {
      final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final journal =
          await ServiceLocator.journalRepository.getJournalByDate(date, _userId);
      if (mounted) {
        setState(() {
          _diaryEntry = journal?.diaryEntry ?? '';
          _sleepNotes = journal?.sleepNotes ?? [];
          _bedtime = journal?.bedtime ?? '';
          _alarmTime = journal?.alarmTime ?? '';
          _sleepGoal = journal?.sleepDuration ?? '';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDiaryEntry(String entry) async {
    setState(() {
      _diaryEntry = entry;
      _showJournalModal = false;
      _isSaving = true;
    });
    final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
    await ServiceLocator.journalRepository
        .editJournal({'diaryEntry': entry}, date, _userId);
    if (mounted) setState(() => _isSaving = false);

    final t = context.read<TransparencyBloc>().state.journalTransparency;
    ServiceLocator.transparencyService
        .analyzePrivacyRisks(
            t, context.read<UserProfileCubit>().consentPreferences)
        .then((u) =>
            context.read<TransparencyBloc>().add(SetJournalTransparencyEvent(u)))
        .catchError((_) {});
  }

  Future<void> _saveSleepNotes(List<SleepNote> notes) async {
    setState(() {
      _sleepNotes = notes;
      _showNotesModal = false;
      _isSaving = true;
    });
    final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
    await ServiceLocator.journalRepository.editJournal(
        {'sleepNotes': notes.map((n) => n.toJson()).toList()}, date, _userId);
    if (mounted) setState(() => _isSaving = false);
  }

  String _formatDate(DateTime d) =>
      DateFormat('MMMM dd').format(d);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransparencyBloc, TransparencyState>(
      builder: (context, ts) {
        final journalT = ts.journalTransparency;
        final accelT = ts.accelerometerTransparency;

        if (_isLoading || _isSaving) return const Loader();

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // ── Header: background overlay + date + calendar ─────
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xCC000A14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date header row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(30, 50, 70, 20),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _showCalendar = !_showCalendar),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Today',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Text(_formatDate(_selectedDate),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w400)),
                                      const SizedBox(width: 6),
                                      Icon(
                                        _showCalendar
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: Colors.white, size: 20,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Expandable calendar
                          if (_showCalendar)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: CalendarWidget(
                                selectedDate: _selectedDate,
                                onDateSelected: (d) {
                                  setState(() {
                                    _selectedDate = d;
                                    _showCalendar = false;
                                  });
                                  _loadJournalData();
                                },
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    // ── Scrollable body ──────────────────────────────────
                    Expanded(
                      child: _displayNormalUI
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Sleep Goal card ────────────────────
                                  _sectionTitle('Sleep Goal'),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    margin: const EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBackground,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Bedtime + Alarm column
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: const [
                                                  Icon(Icons.nightlight_outlined,
                                                      color: Colors.white,
                                                      size: 16),
                                                  SizedBox(width: 4),
                                                  Text('Bedtime',
                                                      style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 14)),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _bedtime.isEmpty
                                                    ? '—'
                                                    : _bedtime,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              const SizedBox(height: 15),
                                              Row(
                                                children: const [
                                                  Icon(Icons.alarm_outlined,
                                                      color: Colors.white,
                                                      size: 16),
                                                  SizedBox(width: 4),
                                                  Text('Alarm',
                                                      style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 14)),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _alarmTime.isEmpty
                                                    ? '—'
                                                    : _alarmTime,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Goal column
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              children: const [
                                                Icon(
                                                    Icons.explore_outlined,
                                                    color: Colors.white,
                                                    size: 16),
                                                SizedBox(width: 4),
                                                Text('Goal',
                                                    style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 14)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _sleepGoal.isEmpty
                                                  ? '—'
                                                  : _sleepGoal,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ── Diary section ──────────────────────
                                  _diaryTitleRow(journalT, accelT),

                                  // Sleep Notes subsection
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    margin: const EdgeInsets.only(bottom: 15),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBackground,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Sleep Notes',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600)),
                                            GestureDetector(
                                              onTap: () => setState(
                                                  () => _showNotesModal = true),
                                              child: Icon(
                                                  Icons.add_circle_outline,
                                                  color: AppColors.generalBlue,
                                                  size: 24),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        if (_sleepNotes.isEmpty)
                                          const Text('No sleep notes added yet.',
                                              style: TextStyle(
                                                  color: Color(0xFF8E8E93),
                                                  fontSize: 16,
                                                  fontStyle: FontStyle.italic))
                                        else
                                          ...(_sleepNotes.map((n) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 5),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text('• ',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 18)),
                                                    Expanded(
                                                      child: Text(n.toJson(),
                                                          style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 16)),
                                                    ),
                                                  ],
                                                ),
                                              ))),
                                      ],
                                    ),
                                  ),

                                  // Journal entry card
                                  Container(
                                    padding: const EdgeInsets.all(15),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBackground,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 6,
                                          child: Text(
                                            _diaryEntry.isEmpty
                                                ? 'Write something to record your day... '
                                                : _diaryEntry,
                                            style: TextStyle(
                                              color: _diaryEntry.isEmpty
                                                  ? Colors.white38
                                                  : Colors.white,
                                              fontSize: 16,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: GestureDetector(
                                            onTap: () => setState(
                                                () => _showJournalModal = true),
                                            child: const Icon(
                                                Icons.edit_outlined,
                                                color: Colors.white,
                                                size: 24),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // ── Activity Tracker ───────────────────
                                  _activityTitleRow(accelT),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    margin: const EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBackground,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _ActivityItem(
                                            label: 'Steps',
                                            value: '83',
                                            unit: 'steps'),
                                        _ActivityItem(
                                            label: 'Calories',
                                            value: '83',
                                            unit: 'kcal'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const PrivacyJournalPage(),
                    ),
                  ],
                ),

                // ── Transparency icon (top-right) ────────────────────────
                Positioned(
                  top: 50, right: 30,
                  child: TransparencyConfig.journalTooltipEnabled
                      ? PrivacyTooltip(
                          color: getPrivacyRiskColor(journalT.privacyRisk),
                          iconName: getPrivacyRiskIcon(journalT.privacyRisk),
                          violationsDetected:
                              getPrivacyRiskLabel(journalT.privacyRisk),
                          privacyViolations: formatPrivacyViolations(journalT),
                          purpose: journalT.aiExplanation?.why ?? '',
                          storage: journalT.aiExplanation?.storage ?? '',
                          access: journalT.aiExplanation?.access ?? '',
                          optOutLink: AppRoutes.consentPreferences,
                          privacyPolicySectionLink:
                              journalT.aiExplanation?.privacyPolicyLink
                                  .firstOrNull,
                          regulationLink:
                              journalT.aiExplanation?.regulationLink.firstOrNull,
                          dataType: 'journal',
                        )
                      : PrivacyIcon(
                          handleIconPress: () => setState(
                              () => _displayNormalUI = !_displayNormalUI),
                          isOpen: !_displayNormalUI,
                          iconName: getPrivacyRiskIcon(journalT.privacyRisk),
                        ),
                ),

                // ── Modals ────────────────────────────────────────────────
                if (_showJournalModal)
                  JournalEntryModal(
                    isVisible: true,
                    tempDiaryEntry: _diaryEntry,
                    onDiaryEntryChanged: (_) {},
                    onSave: () => _saveDiaryEntry(_diaryEntry),
                    onCancel: () => setState(() => _showJournalModal = false),
                  ),
                if (_showNotesModal)
                  SleepNotesModal(
                    isVisible: true,
                    selectedNotes: _sleepNotes,
                    onSave: _saveSleepNotes,
                    onCancel: () => setState(() => _showNotesModal = false),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// "Diary" title row — with PrivacyTooltip when tooltips are on.
  Widget _diaryTitleRow(TransparencyEvent journalT, TransparencyEvent accelT) {
    if (!TransparencyConfig.journalTooltipEnabled) {
      return _sectionTitle('Diary');
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Diary',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          PrivacyTooltip(
            color: getPrivacyRiskColor(journalT.privacyRisk),
            iconName: getPrivacyRiskIcon(journalT.privacyRisk),
            violationsDetected: getPrivacyRiskLabel(journalT.privacyRisk),
            privacyViolations: formatPrivacyViolations(journalT),
            purpose: journalT.aiExplanation?.why ?? '',
            storage: journalT.aiExplanation?.storage ?? '',
            access: journalT.aiExplanation?.access ?? '',
            optOutLink: AppRoutes.consentPreferences,
            privacyPolicySectionLink:
                journalT.aiExplanation?.privacyPolicyLink.firstOrNull,
            regulationLink:
                journalT.aiExplanation?.regulationLink.firstOrNull,
            dataType: 'Journal',
          ),
        ],
      ),
    );
  }

  /// "Activity Tracker" title row — with PrivacyTooltip when tooltips are on.
  Widget _activityTitleRow(TransparencyEvent accelT) {
    if (!TransparencyConfig.journalTooltipEnabled) {
      return _sectionTitle('Activity Tracker');
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Activity Tracker',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          PrivacyTooltip(
            color: getPrivacyRiskColor(accelT.privacyRisk),
            iconName: getPrivacyRiskIcon(accelT.privacyRisk),
            violationsDetected: getPrivacyRiskLabel(accelT.privacyRisk),
            privacyViolations: formatPrivacyViolations(accelT),
            purpose: accelT.aiExplanation?.why ?? '',
            storage: accelT.aiExplanation?.storage ?? '',
            access: accelT.aiExplanation?.access ?? '',
            optOutLink: AppRoutes.consentPreferences,
            privacyPolicySectionLink:
                accelT.aiExplanation?.privacyPolicyLink.firstOrNull,
            regulationLink: accelT.aiExplanation?.regulationLink.firstOrNull,
            dataType: 'Activity Tracker',
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String label) => Padding(
        padding: const EdgeInsets.only(left: 10, bottom: 15),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity item — circular progress indicator (placeholder values)
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _ActivityItem(
      {required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white10,
            border: Border.all(color: AppColors.generalBlue, width: 3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
              Text(unit,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

// MIGRATION: app/(tabs)/sleep/index.tsx + components/NormalSleepPage.tsx → Dart.
//
//            Key translations:
//              journalDataRepository.editJournal → injected via ServiceLocator
//              useTransparencyStore → BlocBuilder<TransparencyBloc>
//              useProfileStore     → BlocBuilder<UserProfileCubit>
//              TimeModal (React)    → Flutter TimeModal widget
//              expo-router push     → context.push(AppRoutes.sleepMode)
//              PrivacyTooltip / PrivacyIcon → Dart PrivacyTooltip widget
//              TRANSPARENCY_UI_CONFIG flags → TransparencyConfig constants
//              NormalSleepPage.tsx layout preserved exactly:
//                - sleep-duration-wheel.png image (full width, aspectRatio 1)
//                - inputCard row: label | value | pencil icon (horizontal)
//                - SLEEP NOW button with blue shadow (elevation 10)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app.dart';
import '../../../blocs/transparency/transparency_bloc.dart';
import '../../../blocs/transparency/transparency_event.dart';
import '../../../blocs/transparency/transparency_state.dart';
import '../../../blocs/user_profile/user_profile_cubit.dart';
import '../../../blocs/auth/auth_cubit.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/transparency_config.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/models/transparency.dart';
import '../../../core/utils/transparency_utils.dart';
import '../../../widgets/loader.dart';
import '../../../widgets/modals/time_modal.dart';
import '../../../widgets/transparency/privacy_icon.dart';
import '../../../widgets/transparency/privacy_tooltip.dart';
import '../../../widgets/transparency/privacy_page_components.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  String _bedtime = '';
  String _alarmTime = '';
  bool _isLoading = false;
  bool _showBedtimeModal = false;
  bool _showAlarmModal = false;
  bool _displayNormalUI = true;

  String get _todayDate => DateFormat('yyyy-MM-dd').format(DateTime.now());

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
      final journal = await ServiceLocator.journalRepository
          .getJournalByDate(_todayDate, _userId);
      if (journal != null && mounted) {
        setState(() {
          _bedtime = journal.bedtime;
          _alarmTime = journal.alarmTime;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBedtime(String newBedtime) async {
    setState(() {
      _bedtime = newBedtime;
      _showBedtimeModal = false;
    });
    await ServiceLocator.journalRepository.editJournal(
      {'bedtime': newBedtime},
      _todayDate,
      _userId,
    );
    final t = context.read<TransparencyBloc>().state.journalTransparency;
    ServiceLocator.transparencyService
        .analyzePrivacyRisks(
            t, context.read<UserProfileCubit>().consentPreferences)
        .then((updated) =>
            context.read<TransparencyBloc>().add(SetJournalTransparencyEvent(updated)))
        .catchError((_) {});
  }

  Future<void> _saveAlarmTime(String newAlarm) async {
    setState(() {
      _alarmTime = newAlarm;
      _showAlarmModal = false;
    });
    await ServiceLocator.journalRepository.editJournal(
      {'alarmTime': newAlarm},
      _todayDate,
      _userId,
    );
  }

  Future<void> _startSleepSession() async {
    if (_bedtime.isEmpty || _alarmTime.isEmpty ||
        _bedtime == 'Set Time' || _alarmTime == 'Set Time') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please set your Bedtime and Alarm before starting sleep mode.'),
        ),
      );
      return;
    }
    context.push(AppRoutes.sleepMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<TransparencyBloc, TransparencyState>(
        builder: (context, transparencyState) {
          final journalT = transparencyState.journalTransparency;
          return SafeArea(
            child: Stack(
              children: [
                // ── Main content ────────────────────────────────────────────
                // Positioned.fill gives tight constraints so Column + Spacer
                // inside _NormalSleepContent never overflows.
                Positioned.fill(
                  child: (_displayNormalUI || TransparencyConfig.sleepPageTooltipEnabled)
                      ? (_isLoading
                          ? const Loader()
                          : _NormalSleepContent(
                              bedtime: _bedtime,
                              alarmTime: _alarmTime,
                              onEditBedtime: () =>
                                  setState(() => _showBedtimeModal = true),
                              onEditAlarm: () =>
                                  setState(() => _showAlarmModal = true),
                              onStartSleep: _startSleepSession,
                            ))
                      : const PrivacySleepPage(),
                ),

                // ── Privacy icon (top-right, matches RN headerContainer) ───
                if (!TransparencyConfig.sleepPageTooltipEnabled)
                  Positioned(
                    top: 50,
                    right: 20,
                    child: PrivacyIcon(
                      handleIconPress: () =>
                          setState(() => _displayNormalUI = !_displayNormalUI),
                      isOpen: !_displayNormalUI,
                      iconName: getPrivacyRiskIcon(journalT.privacyRisk),
                      iconSize: 50,
                    ),
                  ),
                if (TransparencyConfig.sleepPageTooltipEnabled)
                  Positioned(
                    top: 50,
                    right: 20,
                    child: PrivacyTooltip(
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
                      dataType: _profileToDataType(context),
                    ),
                  ),

                // ── Bedtime modal ───────────────────────────────────────────
                if (_showBedtimeModal)
                  TimeModal(
                    isVisible: true,
                    label: 'Set Bedtime',
                    defaultTime: _bedtime.isEmpty ? '10:00 PM' : _bedtime,
                    onSave: _saveBedtime,
                    onCancel: () => setState(() => _showBedtimeModal = false),
                  ),
                // ── Alarm modal ─────────────────────────────────────────────
                if (_showAlarmModal)
                  TimeModal(
                    isVisible: true,
                    label: 'Set Alarm',
                    defaultTime: _alarmTime.isEmpty ? '7:00 AM' : _alarmTime,
                    onSave: _saveAlarmTime,
                    onCancel: () => setState(() => _showAlarmModal = false),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _profileToDataType(BuildContext context) {
    final cloud = context.read<UserProfileCubit>().cloudStorageEnabled;
    return cloud ? 'journal-cloud' : 'journal-local';
  }
}

// ---------------------------------------------------------------------------
// Normal sleep content — mirrors NormalSleepPage.tsx exactly:
//   sleep-duration-wheel.png image → AspectRatio(1)
//   inputCard row → horizontal label | value | pencil icon
//   SLEEP NOW button → blue with shadow/elevation
// ---------------------------------------------------------------------------
class _NormalSleepContent extends StatelessWidget {
  final String bedtime;
  final String alarmTime;
  final VoidCallback onEditBedtime;
  final VoidCallback onEditAlarm;
  final VoidCallback onStartSleep;

  const _NormalSleepContent({
    required this.bedtime,
    required this.alarmTime,
    required this.onEditBedtime,
    required this.onEditAlarm,
    required this.onStartSleep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scrollable body — expands to all space above the button
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.only(top: 50, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Sleep Tracker',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 70),
                    ],
                  ),
                ),

                // Sleep duration wheel image
                AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset(
                    'assets/images/sleep-duration-wheel.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 30),

                // Bedtime input card
                _InputCard(
                  label: 'Bedtime',
                  value: bedtime.isEmpty ? 'Set Time' : bedtime,
                  onEdit: onEditBedtime,
                ),
                const SizedBox(height: 15),

                // Alarm input card
                _InputCard(
                  label: 'Alarm',
                  value: alarmTime.isEmpty ? 'Set Time' : alarmTime,
                  onEdit: onEditAlarm,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // SLEEP NOW always pinned at bottom
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          child: _SleepNowButton(onPress: onStartSleep),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Input card — matches NormalSleepPage inputCard style exactly:
//   horizontal row: label (flex 1, 18pt white) | value (18pt white 0.8) | pencil icon
// ---------------------------------------------------------------------------
class _InputCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _InputCard(
      {required this.label, required this.value, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onEdit,
            child: const Icon(
              Icons.edit_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SLEEP NOW button — matches sleepNowButton style:
//   blue background, borderRadius 12, paddingV 18, shadow (elevation 10)
// ---------------------------------------------------------------------------
class _SleepNowButton extends StatelessWidget {
  final VoidCallback onPress;
  const _SleepNowButton({required this.onPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.generalBlue,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.generalBlue.withOpacity(0.5),
              offset: const Offset(0, 5),
              blurRadius: 10,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'SLEEP NOW',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

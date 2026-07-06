// MIGRATION: app/(tabs)/sleep/sleep-mode.tsx → Dart StatefulWidget.
//
//            Key translations:
//              setInterval(1s) current time  → Timer.periodic(1s)
//              long-press (2s) wake up       → GestureDetector + Timer.periodic(100ms)
//              ImageBackground                → Stack + Image.asset(fit: BoxFit.cover)
//              PrivacyTooltip row layout     → same Row/Column layout preserved
//              router.replace → go_router context.go() (replace equivalent)
//              SensorBackgroundTaskManager.updateConfig → ServiceLocator.sensorRepository
//
//            Rule 14 (smart tooltip positioning) is implemented inside PrivacyTooltip.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app.dart';
import '../../../blocs/transparency/transparency_bloc.dart';
import '../../../blocs/transparency/transparency_state.dart';
import '../../../blocs/user_profile/user_profile_cubit.dart';
import '../../../blocs/auth/auth_cubit.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/transparency_config.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/models/transparency.dart';
import '../../../core/utils/transparency_utils.dart';
import '../../../widgets/transparency/privacy_icon.dart';
import '../../../widgets/transparency/privacy_tooltip.dart';
import '../../../widgets/transparency/privacy_page_components.dart';

class SleepModeScreen extends StatefulWidget {
  const SleepModeScreen({super.key});

  @override
  State<SleepModeScreen> createState() => _SleepModeScreenState();
}

class _SleepModeScreenState extends State<SleepModeScreen> {
  // MIGRATION: setInterval(1000) → Timer.periodic(Duration(seconds:1)).
  Timer? _clockTimer;
  String _currentTime = '';
  String _alarmTime = '';

  // Elapsed sleep time — starts the moment sleep mode is entered.
  late final DateTime _sleepStartTime;

  // Long-press wake-up logic (replaces pressIntervalRef + setInterval).
  Timer? _pressTimer;
  int _pressDuration = 0; // milliseconds
  static const int _requiredDuration = 2000;

  bool _displayNormalUI = true;

  @override
  void initState() {
    super.initState();
    _sleepStartTime = DateTime.now();
    _startClock();
    _loadAlarm();
    _enterSleepMode();
  }

  String get _elapsedTime {
    final elapsed = DateTime.now().difference(_sleepStartTime);
    final h = elapsed.inHours;
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  void _startClock() {
    _currentTime = DateFormat('hh:mm a').format(DateTime.now());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateFormat('hh:mm a').format(DateTime.now());
        });
      }
    });
  }

  Future<void> _loadAlarm() async {
    final userId = _userId;
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final journal =
        await ServiceLocator.journalRepository.getJournalByDate(date, userId);
    if (journal != null && mounted) {
      setState(() => _alarmTime = journal.alarmTime);
    }
  }

  Future<void> _enterSleepMode() async {
    // MIGRATION: sensorBackgroundTaskManager.updateConfig() →
    //            ServiceLocator.sensorRepository.updateConfig() + startAll().
    final prefs = context.read<UserProfileCubit>().consentPreferences;
    await ServiceLocator.sensorRepository.updateConfig(
      ServiceLocator.sensorRepository.currentConfig.copyWith(
        audioEnabled: prefs.microphoneEnabled,
        lightEnabled: prefs.lightSensorEnabled,
        accelerometerEnabled: prefs.accelerometerEnabled,
      ),
    );
    // Actually start the physical sensors for this sleep session.
    await ServiceLocator.sensorRepository.startAll();
  }

  // ---------------------------------------------------------------------------
  // Long-press wake-up (mirrors handlePressIn / handlePressOut / handleWakeUp)
  // ---------------------------------------------------------------------------
  void _handlePressIn() {
    _pressDuration = 0;
    _pressTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() {
        _pressDuration += 100;
        if (_pressDuration >= _requiredDuration) {
          _pressTimer?.cancel();
          _pressTimer = null;
          _handleWakeUp();
        }
      });
    });
  }

  void _handlePressOut() {
    _pressTimer?.cancel();
    _pressTimer = null;
    if (mounted) setState(() => _pressDuration = 0);
  }

  Future<void> _handleWakeUp() async {
    try {
      await ServiceLocator.sensorRepository.stopAll();
    } catch (_) {}
    if (!mounted) return;
    // MIGRATION: router.replace('/(tabs)/sleep') then router.replace('/(tabs)/statistics')
    //            → context.go(sleep) then Future.delayed → context.go(statistics).
    context.go(AppRoutes.sleep);
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) context.go(AppRoutes.statistics);
    });
  }

  double get _progress => (_pressDuration / _requiredDuration).clamp(0.0, 1.0);

  String get _userId {
    final s = context.read<AuthCubit>().state;
    return s is AuthAuthenticated ? s.user.userId : '';
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransparencyBloc, TransparencyState>(
      builder: (context, transparencyState) {
        final accelT = transparencyState.accelerometerTransparency;
        final lightT = transparencyState.lightSensorTransparency;
        final micT = transparencyState.microphoneTransparency;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Background image.
              // MIGRATION: ImageBackground → Stack with Image.asset(fit: cover).
              Image.asset(
                'assets/images/sleep-mode-bg.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: AppColors.background),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // ── Transparency controls (top of screen) ────────────
                      _buildTransparencyRow(
                        context,
                        accelT: accelT,
                        lightT: lightT,
                        micT: micT,
                      ),
                      const Spacer(),
                      // ── Normal UI or privacy page ─────────────────────────
                      if (_displayNormalUI) ...[
                        // Current time.
                        Text(
                          _currentTime,
                          style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Color(0x80000000),
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Elapsed sleep time (chronometer).
                        Text(
                          _elapsedTime,
                          style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                            shadows: [
                              Shadow(
                                color: Color(0x80000000),
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Alarm box.
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(
                            color: AppColors.overlayDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Alarm',
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    color: Colors.white70,
                                    fontSize: 16,
                                  )),
                              Text(_alarmTime,
                                  style: const TextStyle(
                                    fontFamily: 'SpaceMono',
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Wake up button with progress fill.
                        GestureDetector(
                          onTapDown: (_) => _handlePressIn(),
                          onTapUp: (_) => _handlePressOut(),
                          onTapCancel: _handlePressOut,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.generalBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: _progress,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                _pressDuration >= _requiredDuration
                                    ? 'Releasing…'
                                    : 'Wake up',
                                style: const TextStyle(
                                  fontFamily: 'SpaceMono',
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        const Expanded(child: PrivacySleepMode()),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build the transparency row at the top of the screen.
  // MIGRATION: Mirrors the absolute-positioned tooltipContainer in sleep-mode.tsx.
  // ---------------------------------------------------------------------------
  Widget _buildTransparencyRow(
    BuildContext context, {
    required TransparencyEvent accelT,
    required TransparencyEvent lightT,
    required TransparencyEvent micT,
  }) {
    // Tooltip mode (TRANSPARENCY_UI_CONFIG.sleepModeTooltipEnabled).
    if (TransparencyConfig.sleepModeTooltipEnabled) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            // Row 1: accelerometer + light.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                  regulationLink:
                      accelT.aiExplanation?.regulationLink.firstOrNull,
                  dataType:
                      'sensor-accelerometer-${accelT.storageLocation == DataDestination.googleCloud ? 'cloud' : 'local'}',
                ),
                PrivacyTooltip(
                  color: getPrivacyRiskColor(lightT.privacyRisk),
                  iconName: getPrivacyRiskIcon(lightT.privacyRisk),
                  violationsDetected: getPrivacyRiskLabel(lightT.privacyRisk),
                  privacyViolations: formatPrivacyViolations(lightT),
                  purpose: lightT.aiExplanation?.why ?? '',
                  storage: lightT.aiExplanation?.storage ?? '',
                  access: lightT.aiExplanation?.access ?? '',
                  optOutLink: AppRoutes.consentPreferences,
                  privacyPolicySectionLink:
                      lightT.aiExplanation?.privacyPolicyLink.firstOrNull,
                  regulationLink:
                      lightT.aiExplanation?.regulationLink.firstOrNull,
                  dataType:
                      'sensor-light-${lightT.storageLocation == DataDestination.googleCloud ? 'cloud' : 'local'}',
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Row 2: microphone (centered).
            PrivacyTooltip(
              color: getPrivacyRiskColor(micT.privacyRisk),
              iconName: getPrivacyRiskIcon(micT.privacyRisk),
              violationsDetected: getPrivacyRiskLabel(micT.privacyRisk),
              privacyViolations: formatPrivacyViolations(micT),
              purpose: micT.aiExplanation?.why ?? '',
              storage: micT.aiExplanation?.storage ?? '',
              access: micT.aiExplanation?.access ?? '',
              optOutLink: AppRoutes.consentPreferences,
              privacyPolicySectionLink:
                  micT.aiExplanation?.privacyPolicyLink.firstOrNull,
              regulationLink: micT.aiExplanation?.regulationLink.firstOrNull,
              dataType:
                  'sensor-microphone-${micT.storageLocation == DataDestination.googleCloud ? 'cloud' : 'local'}',
            ),
          ],
        ),
      );
    }
    // Non-tooltip mode: single privacy icon.
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Align(
        alignment: Alignment.topRight,
        child: PrivacyIcon(
          handleIconPress: () =>
              setState(() => _displayNormalUI = !_displayNormalUI),
          isOpen: !_displayNormalUI,
          iconName: getPrivacyRiskIconForPage([
            accelT.privacyRisk,
            lightT.privacyRisk,
            micT.privacyRisk,
          ]),
          iconSize: 50,
        ),
      ),
    );
  }
}

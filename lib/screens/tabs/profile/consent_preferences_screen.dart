// MIGRATION: app/(tabs)/profile/consent-preferences.tsx → Dart.
//            Mirrors original exactly: 4 toggles (Microphone, Accelerometer,
//            Light Sensor, Cloud Storage) each followed by a privacy-policy
//            deep-link. The extra Analytics/Marketing/Notifications toggles
//            added during migration are removed — they are not in the original.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app.dart';
import '../../../blocs/transparency/transparency_bloc.dart';
import '../../../blocs/transparency/transparency_event.dart';
import '../../../blocs/user_profile/user_profile_cubit.dart';
import '../../../blocs/user_profile/user_profile_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/models/transparency.dart';
import '../../../core/models/user_consent_preferences.dart';
import '../../../widgets/permissions_toggle.dart';

class ConsentPreferencesScreen extends StatelessWidget {
  const ConsentPreferencesScreen({super.key});

  // Dispatch all 6 transparency channels based on current consent preferences.
  // Sensor revoked → MEDIUM (violation detected); sensor granted → LOW (normal).
  // Cloud enabled → MEDIUM (data leaves device); cloud disabled → LOW (local).
  // Shared channels (journal/sleep/stats) reflect worst-case across all prefs.
  static void _applyTransparency(
      BuildContext context, UserConsentPreferences p) {
    final bloc = context.read<TransparencyBloc>();
    final micRisk = p.microphoneEnabled ? PrivacyRisk.low : PrivacyRisk.medium;
    final accelRisk =
        p.accelerometerEnabled ? PrivacyRisk.low : PrivacyRisk.medium;
    final lightRisk =
        p.lightSensorEnabled ? PrivacyRisk.low : PrivacyRisk.medium;
    final anyRisk = !p.microphoneEnabled ||
        !p.accelerometerEnabled ||
        !p.lightSensorEnabled;
    final sharedRisk = anyRisk ? PrivacyRisk.medium : PrivacyRisk.low;

    bloc.add(SetMicrophoneTransparencyEvent(
        defaultMicrophoneTransparencyEvent.copyWith(privacyRisk: micRisk)));
    bloc.add(SetAccelerometerTransparencyEvent(
        defaultAccelerometerTransparencyEvent.copyWith(privacyRisk: accelRisk)));
    bloc.add(SetLightSensorTransparencyEvent(
        defaultLightSensorTransparencyEvent.copyWith(privacyRisk: lightRisk)));
    bloc.add(SetJournalTransparencyEvent(
        defaultJournalTransparencyEvent.copyWith(privacyRisk: sharedRisk)));
    bloc.add(SetStatisticsTransparencyEvent(
        defaultStatisticsTransparencyEvent.copyWith(
          privacyRisk: sharedRisk,
          aiExplanation: defaultStatisticsTransparencyEvent.aiExplanation?.copyWith(
            privacyExplanation: sharedRisk == PrivacyRisk.medium
                ? 'One or more sensor permissions have been revoked.'
                : 'No privacy risks',
          ),
        )));
    bloc.add(SetGeneralSleepTransparencyEvent(
        defaultGeneralSleepTransparencyEvent.copyWith(privacyRisk: sharedRisk)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Your Privacy Matters to Us',
            style: TextStyle(fontFamily: 'SpaceMono', fontSize: 15)),
      ),
      body: BlocBuilder<UserProfileCubit, UserProfileState>(
        builder: (context, state) {
          if (state is! UserProfileLoaded) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.generalBlue));
          }
          final prefs = state.userConsentPreferences;
          final cubit = context.read<UserProfileCubit>();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Microphone ───────────────────────────────────────────
                PermissionsToggle(
                  label: 'Yes, you have permission to access my microphone to '
                      'record my sleep sounds.',
                  value: prefs.microphoneEnabled,
                  onValueChange: (v) async {
                    final updated = prefs.copyWith(microphoneEnabled: v);
                    unawaited(cubit.setUserConsentPreferences(updated));
                    _applyTransparency(context, updated);
                    unawaited(ServiceLocator.sensorRepository
                        .syncWithConsent(updated));
                  },
                ),
                _PrivacyLink(
                  text: 'Read more about sound data and snoring detection',
                  sectionId: 'microphone',
                ),

                // ── Accelerometer ────────────────────────────────────────
                PermissionsToggle(
                  label: 'Yes, you have my permission to access my accelerometer '
                      'to track my activity levels.',
                  value: prefs.accelerometerEnabled,
                  onValueChange: (v) async {
                    final updated = prefs.copyWith(accelerometerEnabled: v);
                    unawaited(cubit.setUserConsentPreferences(updated));
                    _applyTransparency(context, updated);
                    unawaited(ServiceLocator.sensorRepository
                        .syncWithConsent(updated));
                  },
                ),
                _PrivacyLink(
                  text: 'More about collecting activity data',
                  sectionId: 'accelerometer',
                ),

                // ── Light Sensor ─────────────────────────────────────────
                PermissionsToggle(
                  label: 'Yes, you have my permission to access my light sensor '
                      'to track ambient light levels.',
                  value: prefs.lightSensorEnabled,
                  onValueChange: (v) async {
                    final updated = prefs.copyWith(lightSensorEnabled: v);
                    unawaited(cubit.setUserConsentPreferences(updated));
                    _applyTransparency(context, updated);
                    unawaited(ServiceLocator.sensorRepository
                        .syncWithConsent(updated));
                  },
                ),
                _PrivacyLink(
                  text: 'More about collecting ambient light data',
                  sectionId: 'lightSensor',
                ),

                // ── Cloud Storage ─────────────────────────────────────────
                // Cloud enabled → MEDIUM (data leaves device); disabled → LOW.
                PermissionsToggle(
                  label: 'Yes, you have my permission to store my personal health '
                      'information on secure Google Cloud servers',
                  value: prefs.cloudStorageEnabled,
                  onValueChange: (v) async {
                    final updated = prefs.copyWith(cloudStorageEnabled: v);
                    unawaited(cubit.setUserConsentPreferences(updated));
                    _applyTransparency(context, updated);
                    unawaited(ServiceLocator.sensorRepository
                        .syncWithConsent(updated));
                  },
                ),
                _PrivacyLink(
                  text: 'More about data storage and data access',
                  sectionId: 'cloudVsLocalStorage',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Privacy policy deep-link (mirrors TouchableOpacity → router.push in RN)
// ─────────────────────────────────────────────────────────────────────────────

class _PrivacyLink extends StatelessWidget {
  final String text;
  final String sectionId;
  const _PrivacyLink({required this.text, required this.sectionId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.push('${AppRoutes.privacyPolicy}?sectionId=$sectionId'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            color: AppColors.hyperlinkBlue,
            fontSize: 14,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.hyperlinkBlue,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

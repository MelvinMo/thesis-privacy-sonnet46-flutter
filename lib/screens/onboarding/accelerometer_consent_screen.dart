// MIGRATION: app/(onboarding)/accelerometer-consent.tsx → Dart.
//            ImageBackground (running-bg.png) → Container with DecorationImage.
//            flex(3)/flex(4) split replicated with Flexible weights.
//            SafeArea wraps outer Column (not inner image) so flex heights are correct.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../blocs/transparency/transparency_bloc.dart';
import '../../blocs/transparency/transparency_event.dart';
import '../../blocs/user_profile/user_profile_cubit.dart';
import '../../blocs/user_profile/user_profile_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/models/transparency.dart';
import '../../core/models/user_consent_preferences.dart';
import '../../widgets/general_button.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/permissions_toggle.dart';

// Dispatch all 6 transparency channels: sensor revoked=MEDIUM, granted=LOW.
void _applyAllTransparency(BuildContext context, UserConsentPreferences p) {
  final bloc = context.read<TransparencyBloc>();
  final micRisk = p.microphoneEnabled ? PrivacyRisk.low : PrivacyRisk.medium;
  final accelRisk =
      p.accelerometerEnabled ? PrivacyRisk.low : PrivacyRisk.medium;
  final lightRisk = p.lightSensorEnabled ? PrivacyRisk.low : PrivacyRisk.medium;
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
  // Sync physical sensors to reflect new consent (no-op if not in sleep mode).
  unawaited(ServiceLocator.sensorRepository.syncWithConsent(p));
}

class AccelerometerConsentScreen extends StatelessWidget {
  const AccelerometerConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top half: running background image (flex 3) ──────────────────
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/running-bg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: OnboardingHeader(
                    title: 'Your Privacy Matters to Us',
                    onBackPress: () => context.pop(),
                  ),
                ),
              ),
            ),

            // ── Bottom half: consent content (flex 4) ────────────────────────
            Expanded(
              flex: 4,
              child: BlocBuilder<UserProfileCubit, UserProfileState>(
                builder: (context, _) {
                  final cubit = context.read<UserProfileCubit>();
                  final prefs = cubit.consentPreferences;
                  return Column(
                    children: [
                      // Scrollable content — grows to fill space above button
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Purpose:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'The accelerometer on your device will be used to track your body '
                                'movements during sleep and throughout the day continuously in the '
                                'background. This will help us to correlate activity levels with '
                                'sleep quality.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => context.push(
                                    '${AppRoutes.privacyPolicy}?sectionId=accelerometer'),
                                child: const Text(
                                  'More about collecting activity data',
                                  style: TextStyle(
                                    color: AppColors.hyperlinkBlue,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.hyperlinkBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              PermissionsToggle(
                                value: prefs.accelerometerEnabled,
                                onValueChange: (v) async {
                                  final updated = prefs.copyWith(accelerometerEnabled: v);
                                  await cubit.setUserConsentPreferences(updated);
                                  if (context.mounted) {
                                    _applyAllTransparency(context, updated);
                                  }
                                },
                                label:
                                    'Yes, you have my permission to access my accelerometer to track my activity levels.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Button always pinned to bottom
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                        child: GeneralButton(
                          title: 'Continue',
                          onPress: () =>
                              context.go(AppRoutes.onboardingLightSensor),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

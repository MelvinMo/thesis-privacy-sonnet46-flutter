// MIGRATION: app/(onboarding)/transparency.tsx → Dart.
//            Explains the app's real-time privacy-transparency UI features.
//            ScrollView + static icon demonstrations + Continue button.
//            setHasCompletedPrivacyOnboarding → UserProfileCubit.
//            router.push('/questions-explanation') → context.push(AppRoutes.onboardingQuestionsExplain).
//
//            PrivacyIcon / SensorPrivacyIcon rendered as demonstrations
//            (handleIconPress: no-op; isOpen: false) — exactly as source.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../blocs/user_profile/user_profile_cubit.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/general_button.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/transparency/privacy_icon.dart';
import '../../widgets/transparency/sensor_privacy_icon.dart';

class TransparencyScreen extends StatelessWidget {
  const TransparencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OnboardingHeader(
                title: 'Your Privacy Matters to Us',
                onBackPress: () => context.pop(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  children: [
                    // MIGRATION: ScrollView → Expanded + ListView/SingleChildScrollView.
                    //            persistentScrollbar → AlwaysScrollableScrollPhysics.
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Privacy Features In this App',
                                style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'This prototype app is designed to prioritize transparency '
                                'by embedding details about data collection within the UI. '
                                'Our real-time privacy analysis system monitors data '
                                'collection and provides instant visual feedback through '
                                'dynamic privacy icons.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── Key Features ─────────────────────────────
                              const Text(
                                'Key Features:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _FeatureItem(
                                text: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.43),
                                    children: [
                                      TextSpan(
                                          text: 'Tooltip System: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      TextSpan(
                                          text:
                                              'Click privacy icons next to data types for contextual information'),
                                    ],
                                  ),
                                ),
                              ),
                              _FeatureItem(
                                text: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.43),
                                    children: [
                                      TextSpan(
                                          text: 'Privacy Pages: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      TextSpan(
                                          text:
                                              'Transform entire screens to show comprehensive privacy details'),
                                    ],
                                  ),
                                ),
                              ),
                              _FeatureItem(
                                text: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.43),
                                    children: [
                                      TextSpan(
                                          text: 'Real-time Analysis: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      TextSpan(
                                          text:
                                              'AI-powered system detects and explains privacy risks as they occur'),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Privacy Risk Indicators ───────────────────
                              const Center(
                                child: Text(
                                  'Privacy Risk Indicators',
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _IconDemo(
                                    icon: PrivacyIcon(
                                      handleIconPress: () {},
                                      isOpen: false,
                                      iconName:
                                          'assets/images/privacy/privacy-high.png',
                                    ),
                                    label: 'Major Risk',
                                    description:
                                        'Policy violations, unauthorized collection',
                                  ),
                                  _IconDemo(
                                    icon: PrivacyIcon(
                                      handleIconPress: () {},
                                      isOpen: false,
                                      iconName:
                                          'assets/images/privacy/privacy-medium.png',
                                    ),
                                    label: 'Medium Risk',
                                    description:
                                        'Suboptimal practices, vague purposes',
                                  ),
                                  _IconDemo(
                                    icon: PrivacyIcon(
                                      handleIconPress: () {},
                                      isOpen: false,
                                      iconName:
                                          'assets/images/privacy/privacy-low.png',
                                    ),
                                    label: 'Low Risk',
                                    description:
                                        'Compliant, secure data handling. You will see this by default',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // ── Sensor Data Icons ─────────────────────────
                              const Center(
                                child: Text(
                                  'Sensor Data Icons',
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Center(
                                child: Text(
                                  'Below are examples of icons used to convey sensor data privacy risks:',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // First row – 2 sensor icons (source: sensorIconRow).
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _SensorIconDemo(
                                      icon: SensorPrivacyIcon(
                                        handleIconPress: () {},
                                        iconName:
                                            'assets/images/privacy/privacy-high.png',
                                        storageType: 'cloud',
                                        sensorType: 'accelerometer',
                                      ),
                                      description:
                                          'Major risk due to accelerometer data being stored in cloud',
                                    ),
                                  ),
                                  Expanded(
                                    child: _SensorIconDemo(
                                      icon: SensorPrivacyIcon(
                                        handleIconPress: () {},
                                        iconName:
                                            'assets/images/privacy/privacy-medium.png',
                                        storageType: 'local',
                                        sensorType: 'light',
                                      ),
                                      description:
                                          'Medium risk due to light sensor data being stored locally',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Second row – 1 sensor icon centred (source: sensorIconRowSingle).
                              // MIGRATION: sensorIconItemSingle width:'50%' → SizedBox half-screen.
                              Center(
                                child: SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width / 2,
                                  child: _SensorIconDemo(
                                    icon: SensorPrivacyIcon(
                                      handleIconPress: () {},
                                      iconName:
                                          'assets/images/privacy/privacy-low.png',
                                      storageType: 'cloud',
                                      sensorType: 'microphone',
                                    ),
                                    description:
                                        'Low risk from microphone data being stored in cloud',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Continue button ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 40),
                      child: GeneralButton(
                        title: 'Continue',
                        onPress: () async {
                          final cubit = context.read<UserProfileCubit>();
                          // MIGRATION: setHasCompletedPrivacyOnboarding(true) before push.
                          await cubit.setHasCompletedPrivacyOnboarding(true);
                          if (context.mounted) {
                            context.go(
                                AppRoutes.onboardingQuestionsExplain);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _FeatureItem extends StatelessWidget {
  final Widget text;
  const _FeatureItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: TextStyle(
                  color: AppColors.generalBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Expanded(child: text),
        ],
      ),
    );
  }
}

class _IconDemo extends StatelessWidget {
  final Widget icon;
  final String label;
  final String description;
  const _IconDemo(
      {required this.icon,
      required this.label,
      required this.description});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _SensorIconDemo extends StatelessWidget {
  final Widget icon;
  final String description;
  const _SensorIconDemo({required this.icon, required this.description});

  @override
  Widget build(BuildContext context) {
    // MIGRATION: Expanded is placed by the CALLER (Row children or SizedBox).
    //            This widget is pure content — no intrinsic sizing constraints.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 8),
          Text(description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  color: Colors.white,
                  fontSize: 11,
                  height: 1.3)),
        ],
      ),
    );
  }
}

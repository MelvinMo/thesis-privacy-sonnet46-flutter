// MIGRATION: app/(onboarding)/questions-explanation.tsx → Dart.
//            Informational screen explaining the purpose of the upcoming
//            sleep-quality questions. No state needed → StatelessWidget.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/general_button.dart';
import '../../widgets/onboarding_header.dart';

class QuestionsExplanationScreen extends StatelessWidget {
  const QuestionsExplanationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Help us understand your current sleep quality',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The next few screens will ask you questions about your '
                      'current sleep quality and sleep habits. This will help us '
                      'understand your sleep better and provide personalized insights.',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Since this data is also personal health information, it '
                      'will be encrypted and stored in your device (otherwise '
                      'the cloud if you opted in)',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const Spacer(),
                    // MIGRATION: router.push('/questions') → AppRoutes.onboardingQuestions.
                    GeneralButton(
                      title: 'Continue',
                      onPress: () =>
                          context.go(AppRoutes.onboardingQuestions),
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

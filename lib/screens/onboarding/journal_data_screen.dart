// MIGRATION: app/(onboarding)/journal-data.tsx → Dart.
//            Layout: flex(3) image top half (journal-bg.png) + flex(6) content bottom half.
//            "Journal Data:" section + description + link, "Derived Data:" section + link.
//            justifyContent: space-between → Column with Spacer.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/general_button.dart';
import '../../widgets/onboarding_header.dart';

class JournalDataScreen extends StatelessWidget {
  const JournalDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top: journal background image (flex 3) ────────────────────
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/journal-bg.png'),
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

            // ── Bottom: content (flex 6) ──────────────────────────────────
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Journal Data:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 8),
                        const Text(
                          'Information about your mood, habits, symptoms can help us '
                          'correlate your personal experiences with your sleep patterns. '
                          'You can voluntarily provide us with this data by making diary '
                          'entries and sleep notes in the app\'s Journal section.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => context.push(
                              '${AppRoutes.privacyPolicy}?sectionId=journalData'),
                          child: const Text(
                            'More about collecting journal data',
                            style: TextStyle(
                              color: AppColors.hyperlinkBlue,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.hyperlinkBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text('Derived Data:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 8),
                        const Text(
                          'The app will derive data about you such as sleep quality, '
                          'correlations, insights and recommendations. This will be '
                          'treated as sensitive personal health information.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => context.push(
                              '${AppRoutes.privacyPolicy}?sectionId=derivedData'),
                          child: const Text(
                            'More about derived data',
                            style: TextStyle(
                              color: AppColors.hyperlinkBlue,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.hyperlinkBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GeneralButton(
                      title: 'Continue',
                      onPress: () => context.go(AppRoutes.onboardingCloudStorage),
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

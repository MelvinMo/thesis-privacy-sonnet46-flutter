// MIGRATION: app/(onboarding)/cloud-storage.tsx → Dart.
//            Layout: OnboardingHeader (back button) + "Data Storage" section +
//            description + PermissionsToggle + "Data Access:" section + text +
//            privacy-policy link + Continue button.
//            justifyContent: space-between → Column with Spacer.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../blocs/user_profile/user_profile_cubit.dart';
import '../../blocs/user_profile/user_profile_state.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/general_button.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/permissions_toggle.dart';

class CloudStorageScreen extends StatelessWidget {
  const CloudStorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OnboardingHeader(
              title: 'Your Privacy Matters to Us',
              onBackPress: () => context.pop(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: BlocBuilder<UserProfileCubit, UserProfileState>(
                  builder: (context, _) {
                    final cubit = context.read<UserProfileCubit>();
                    final prefs = cubit.consentPreferences;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Text('Data Storage',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )),
                            const SizedBox(height: 8),
                            const Text(
                              'By default all of your personal health information '
                              '(data collected and derived data) will be stored on your '
                              'mobile device. If you opt in, we will store your personal '
                              'health information in the cloud, allowing us to provide '
                              'more complex sleep analysis. All data will be encrypted '
                              'while in storage and when it is being transmitted.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            PermissionsToggle(
                              value: prefs.cloudStorageEnabled,
                              onValueChange: (v) async {
                                await cubit.setUserConsentPreferences(
                                    prefs.copyWith(cloudStorageEnabled: v));
                              },
                              label:
                                  'Yes, you have my permission to store my personal health information on secure Google Cloud servers',
                            ),
                            const SizedBox(height: 16),
                            const Text('Data Access:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )),
                            const SizedBox(height: 8),
                            const Text(
                              'We are committed to strict limitations on data sharing. '
                              'We do not give your personal information to any third parties '
                              'for marketing, advertising, or any other commercial purposes.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => context.push(
                                  '${AppRoutes.privacyPolicy}?sectionId=cloudVsLocalStorage'),
                              child: const Text(
                                'More about data storage and data access',
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
                          onPress: () => context.go(AppRoutes.onboardingPrivacyPolicy),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

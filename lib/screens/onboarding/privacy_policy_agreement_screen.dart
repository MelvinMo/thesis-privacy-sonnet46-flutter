// MIGRATION: app/(onboarding)/privacy-policy-agreement.tsx → Dart.
//            Custom checkbox (24×24, borderRadius 6, border generalBlue, fill on check).
//            "Read our full Privacy Policy" link preserved.
//            Description text matches RN exactly.
//            backgroundColor: black, header title: "Your Privacy Matters to Us".

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../blocs/user_profile/user_profile_cubit.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/general_button.dart';
import '../../widgets/onboarding_header.dart';

class PrivacyPolicyAgreementScreen extends StatefulWidget {
  const PrivacyPolicyAgreementScreen({super.key});

  @override
  State<PrivacyPolicyAgreementScreen> createState() =>
      _PrivacyPolicyAgreementScreenState();
}

class _PrivacyPolicyAgreementScreenState
    extends State<PrivacyPolicyAgreementScreen> {
  bool _agreed = false;

  Future<void> _proceed() async {
    final cubit = context.read<UserProfileCubit>();
    final current = cubit.consentPreferences;
    await cubit.setUserConsentPreferences(
        current.copyWith(agreedToPrivacyPolicy: true));
    if (mounted) context.go(AppRoutes.onboardingTransparency);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingHeader(
                title: 'Your Privacy Matters to Us',
                onBackPress: () => context.pop(),
              ),
              const SizedBox(height: 32),
              const Text(
                'The previous screens explained the most important parts of the '
                'privacy policy. Before you proceed, please review the full '
                'Privacy Policy to understand in greater detail how we collect, '
                'use, and protect your health data.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // "Read our full Privacy Policy" link — mirrors RN linkText style.
              GestureDetector(
                onTap: () => context.push(AppRoutes.privacyPolicy),
                child: const Text(
                  'Read our full Privacy Policy',
                  style: TextStyle(
                    color: AppColors.hyperlinkBlue,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.hyperlinkBlue,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Custom checkbox — 24×24, borderRadius 6, border generalBlue,
              // filled generalBlue when checked, checkmark "✓" white 16pt bold.
              GestureDetector(
                onTap: () => setState(() => _agreed = !_agreed),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _agreed ? AppColors.generalBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.generalBlue,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: _agreed
                          ? const Text('✓',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'I have read and agree to the Privacy Policy.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GeneralButton(
                title: 'Continue',
                onPress: _agreed ? _proceed : null,
                disabled: !_agreed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

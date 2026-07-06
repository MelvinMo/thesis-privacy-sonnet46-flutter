// MIGRATION: app/(onboarding)/questions.tsx → Dart.
//            Single sleep-duration question with selectable options.
//            OnboardingQuestionOption (RN component) → inline _OptionTile widget.
//            generalSleepDataRepository.createSleepData → ServiceLocator singleton.
//            router.replace('/(tabs)/sleep/') → context.go(AppRoutes.sleep).
//            setHasCompletedAppOnboarding → UserProfileCubit method.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/user_profile/user_profile_cubit.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/models/general_sleep_data.dart';
import '../../widgets/general_button.dart';
import '../../widgets/onboarding_header.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  // MIGRATION: useState<string>() → nullable String field.
  String? _selectedOption;

  // MIGRATION: Source defines these inline as an array literal.
  static const List<String> _sleepOptions = [
    '6 hours or less',
    '6 - 8 hours',
    '8 - 10 hours',
  ];

  // ---------------------------------------------------------------------------
  // saveSelectedOption — mirrors source async function
  // ---------------------------------------------------------------------------
  Future<void> _saveSelectedOption() async {
    // Not required to select — skip save if nothing chosen (source behaviour).
    if (_selectedOption == null) return;

    final authState = context.read<AuthCubit>().state;
    final userId = authState is AuthAuthenticated
        ? authState.user.userId
        : '';

    final sleepData = GeneralSleepData(
      userId: userId,
      currentSleepDuration: _selectedOption!,
      snoring: '',
      tirednessFrequency: '',
      daytimeSleepiness: '',
    );

    try {
      await ServiceLocator.generalSleepDataRepository
          .createSleepData(sleepData);
    } catch (e) {
      // MIGRATION: console.error → debugPrint; non-fatal, swallowed like source.
      debugPrint('Error saving sleep data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            children: [
              // MIGRATION: onBackPress → context.pop() (go_router).
              OnboardingHeader(
                title: '',
                onBackPress: () => context.pop(),
              ),

              // ── Question + options (centred, flex 1) ──────────────────────
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'How much sleep do you usually get at night?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ..._sleepOptions.map((option) => _OptionTile(
                          label: option,
                          isSelected: _selectedOption == option,
                          onTap: () =>
                              setState(() => _selectedOption = option),
                        )),
                  ],
                ),
              ),

              // ── Continue button ────────────────────────────────────────────
              // MIGRATION: source fires save + replace + setCompleted together.
              //            go_router context.go replaces router.replace.
              GeneralButton(
                title: 'Continue',
                onPress: () async {
                  await _saveSelectedOption();
                  final profileCubit = context.read<UserProfileCubit>();
                  await profileCubit.setHasCompletedAppOnboarding(true);
                  if (context.mounted) {
                    // MIGRATION: router.replace('/(tabs)/sleep/') → context.go
                    //            so user cannot back-navigate into onboarding.
                    context.go(AppRoutes.sleep);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _OptionTile — replaces OnboardingQuestionOption component (not in Dart lib).
// MIGRATION: Bordered card with selected highlight using AppColors.generalBlue.
// ---------------------------------------------------------------------------
class _OptionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.generalBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppColors.generalBlue,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.generalBlue,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: Colors.white, size: 24),
            ],
          ],
        ),
      ),
    );
  }
}

// MIGRATION: expo-router _layout.tsx (root Stack) + (tabs)/_layout.tsx → go_router.
//            go_router ShellRoute provides the persistent bottom-tab scaffold,
//            exactly mirroring Expo Router's (tabs) route group.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../blocs/auth/auth_cubit.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/user_profile/user_profile_cubit.dart';
import '../blocs/user_profile/user_profile_state.dart';
import '../core/constants/app_colors.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/onboarding/onboarding_intro_screen.dart';
import '../screens/onboarding/privacy_policy_agreement_screen.dart';
import '../screens/onboarding/cloud_storage_screen.dart';
import '../screens/onboarding/journal_data_screen.dart';
import '../screens/onboarding/accelerometer_consent_screen.dart';
import '../screens/onboarding/light_sensor_consent_screen.dart';
import '../screens/onboarding/questions_screen.dart';
import '../screens/onboarding/questions_explanation_screen.dart';
import '../screens/onboarding/transparency_screen.dart';
import '../screens/tabs/shell_screen.dart';
import '../screens/tabs/sleep/sleep_screen.dart';
import '../screens/tabs/sleep/sleep_mode_screen.dart';
import '../screens/tabs/journal_screen.dart';
import '../screens/tabs/statistics_screen.dart';
import '../screens/tabs/profile/profile_screen.dart';
import '../screens/tabs/profile/consent_preferences_screen.dart';
import '../screens/privacy_policy_screen.dart';

// ---------------------------------------------------------------------------
// Route name constants
// MIGRATION: expo-router uses file-system paths ('/(tabs)/sleep').
//            go_router uses named routes for type-safe navigation.
// ---------------------------------------------------------------------------
abstract class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const onboardingPrivacyPolicy = '/onboarding/privacy-policy';
  static const onboardingCloudStorage = '/onboarding/cloud-storage';
  static const onboardingJournalData = '/onboarding/journal-data';
  static const onboardingAccelerometer = '/onboarding/accelerometer';
  static const onboardingLightSensor = '/onboarding/light-sensor';
  static const onboardingQuestions = '/onboarding/questions';
  static const onboardingQuestionsExplain = '/onboarding/questions-explanation';
  static const onboardingTransparency = '/onboarding/transparency';
  static const tabShell = '/tabs';
  static const sleep = '/tabs/sleep';
  static const sleepMode = '/tabs/sleep/mode';
  static const journal = '/tabs/journal';
  static const statistics = '/tabs/statistics';
  static const profile = '/tabs/profile';
  static const consentPreferences = '/tabs/profile/consent-preferences';
  static const privacyPolicy = '/privacy-policy';
}

// ---------------------------------------------------------------------------
// Router factory
// ---------------------------------------------------------------------------
// Notifies GoRouter to re-run redirect only when routing-relevant state changes:
//   1. Any auth state change (login / logout).
//   2. Profile transitions from Loading → Loaded once on app start.
//   3. hasCompletedPrivacyOnboarding or hasCompletedAppOnboarding flip to true.
// Consent-preference updates are intentionally ignored — those screens navigate
// explicitly and triggering a redirect there races with context.push calls.
class _RouterRefreshNotifier extends ChangeNotifier {
  late final StreamSubscription<dynamic> _authSub;
  late final StreamSubscription<dynamic> _profileSub;
  bool _profileFirstLoad = false;
  bool _privacyDone = false;
  bool _appDone = false;

  _RouterRefreshNotifier(
      Stream<AuthState> authStream, Stream<UserProfileState> profileStream) {
    _authSub = authStream.listen((_) => notifyListeners());
    _profileSub = profileStream.listen((state) {
      if (state is UserProfileLoaded) {
        // Fire once when profile loads from storage (app start).
        if (!_profileFirstLoad) {
          _profileFirstLoad = true;
          notifyListeners();
          return;
        }
        // Fire when onboarding completion flags flip — screens that set these
        // rely on the redirect to send the user to the correct next segment.
        if (state.hasCompletedPrivacyOnboarding != _privacyDone ||
            state.hasCompletedAppOnboarding != _appDone) {
          _privacyDone = state.hasCompletedPrivacyOnboarding;
          _appDone = state.hasCompletedAppOnboarding;
          notifyListeners();
        }
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    _profileSub.cancel();
    super.dispose();
  }
}

GoRouter buildRouter({
  required AuthCubit authCubit,
  required UserProfileCubit profileCubit,
  required Listenable refreshListenable,
}) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: refreshListenable,
    // MIGRATION: expo-router redirect logic in _layout.tsx → GoRouter redirect.
    //            Auth check + onboarding check mirrors the RN useEffect sequence.
    redirect: (context, state) {
      final authState = authCubit.state;
      final profileState = profileCubit.state;

      final isAuthRoute =
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register');
      final isOnboardingRoute =
          state.matchedLocation.startsWith('/onboarding');

      // Still loading — stay put to avoid flash.
      if (authState is AuthLoading || profileState is UserProfileLoading) {
        return null;
      }

      // Not authenticated → login.
      if (authState is! AuthAuthenticated) {
        return isAuthRoute ? null : AppRoutes.login;
      }

      // Authenticated but privacy onboarding not done → onboarding.
      if (profileState is UserProfileLoaded) {
        if (!profileState.hasCompletedPrivacyOnboarding) {
          return isOnboardingRoute ? null : AppRoutes.onboarding;
        }
        // App onboarding not done → questions.
        if (!profileState.hasCompletedAppOnboarding) {
          return isOnboardingRoute ? null : AppRoutes.onboardingQuestions;
        }
      }

      // All good, authenticated + onboarded → tabs.
      if (isAuthRoute || isOnboardingRoute) {
        return AppRoutes.sleep;
      }
      return null;
    },
    routes: [
      // ── Auth routes ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── Onboarding routes ──────────────────────────────────────────────
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingIntroScreen()),
      GoRoute(path: AppRoutes.onboardingPrivacyPolicy, builder: (_, __) => const PrivacyPolicyAgreementScreen()),
      GoRoute(path: AppRoutes.onboardingCloudStorage, builder: (_, __) => const CloudStorageScreen()),
      GoRoute(path: AppRoutes.onboardingJournalData, builder: (_, __) => const JournalDataScreen()),
      GoRoute(path: AppRoutes.onboardingAccelerometer, builder: (_, __) => const AccelerometerConsentScreen()),
      GoRoute(path: AppRoutes.onboardingLightSensor, builder: (_, __) => const LightSensorConsentScreen()),
      GoRoute(path: AppRoutes.onboardingQuestions, builder: (_, __) => const QuestionsScreen()),
      GoRoute(path: AppRoutes.onboardingQuestionsExplain, builder: (_, __) => const QuestionsExplanationScreen()),
      GoRoute(path: AppRoutes.onboardingTransparency, builder: (_, __) => const TransparencyScreen()),

      // ── Tab shell (persistent bottom nav) ─────────────────────────────
      // MIGRATION: expo-router (tabs)/_layout.tsx with @react-navigation/bottom-tabs
      //            → go_router ShellRoute. ShellRoute keeps the tab scaffold alive
      //            while child routes push onto the inner navigator stack.
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.sleep,
            builder: (_, __) => const SleepScreen(),
            routes: [
              GoRoute(
                path: 'mode', // → /tabs/sleep/mode
                builder: (_, __) => const SleepModeScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.journal,
            builder: (_, __) => const JournalScreen(),
          ),
          GoRoute(
            path: AppRoutes.statistics,
            builder: (_, __) => const StatisticsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'consent-preferences',
                builder: (_, __) => const ConsentPreferencesScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Standalone routes ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) {
          // MIGRATION: expo-router useLocalSearchParams({ sectionId }) →
          //            GoRouter extra or queryParam.
          final sectionId = state.uri.queryParameters['sectionId'];
          return PrivacyPolicyScreen(sectionId: sectionId);
        },
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Root app widget — StatefulWidget so the router is created exactly once.
// MIGRATION: The original RN app recreated navigation on store changes via
//            expo-router's file-based system. GoRouter must NOT be recreated
//            on every BLoC state change or navigation resets. We use
//            refreshListenable instead so GoRouter re-runs redirect() without
//            rebuilding the router itself.
// ---------------------------------------------------------------------------
class SleepTrackerApp extends StatefulWidget {
  const SleepTrackerApp({super.key});

  @override
  State<SleepTrackerApp> createState() => _SleepTrackerAppState();
}

class _SleepTrackerAppState extends State<SleepTrackerApp> {
  late final GoRouter _router;
  late final _RouterRefreshNotifier _notifier;

  @override
  void initState() {
    super.initState();
    final authCubit = context.read<AuthCubit>();
    final profileCubit = context.read<UserProfileCubit>();
    _notifier = _RouterRefreshNotifier(authCubit.stream, profileCubit.stream);
    _router = buildRouter(
      authCubit: authCubit,
      profileCubit: profileCubit,
      refreshListenable: _notifier,
    );
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sleep Tracker',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      // MIGRATION: Colors.ts dark theme (#1A1A2E, #4A90D9) applied globally.
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.background,
          primary: AppColors.generalBlue,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'SpaceMono',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'SpaceMono', color: Colors.white),
          bodySmall: TextStyle(fontFamily: 'SpaceMono', color: Colors.white70),
          titleLarge: TextStyle(fontFamily: 'SpaceMono', color: Colors.white, fontWeight: FontWeight.bold),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.white54, fontFamily: 'SpaceMono'),
        ),
      ),
    );
  }
}

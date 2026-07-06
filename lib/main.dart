// MIGRATION: Expo entry point (expo-router/entry + _layout.tsx) → Flutter main().
//            Flutter's widget tree owns the app lifecycle; no separate "entry" file needed.
//            SplashScreen.preventAutoHideAsync() replaced by FlutterNativeSplash or simply
//            a loading state in the root widget (kept simple here).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'blocs/auth/auth_cubit.dart';
import 'blocs/transparency/transparency_bloc.dart';
import 'blocs/transparency/transparency_event.dart';
import 'blocs/user_profile/user_profile_cubit.dart';
import 'core/di/service_locator.dart';

void main() async {
  // MIGRATION: WidgetsFlutterBinding.ensureInitialized() replaces the implicit
  //            initialization done by Expo's bootstrap process before runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // MIGRATION: Expo sets the status-bar style via expo-status-bar and expo-system-ui.
  //            In Flutter we call SystemChrome directly.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // white icons on dark bg
    ),
  );

  // Portrait-only lock (same implicit behaviour as original RN app).
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize the service locator (singletons: DB, encryption, repositories …).
  // MIGRATION: Replaces services/index.ts singleton pattern.
  await ServiceLocator.init();

  // MIGRATION: expo-splash-screen hide is automatic after runApp() finishes first
  //            frame. No explicit hide call needed in Flutter.
  runApp(
    // ProviderScope wraps the whole tree so Riverpod providers (DI) are accessible.
    // MIGRATION: Zustand global stores → BLoC (reactive) + Riverpod (DI).
    ProviderScope(
      child: MultiBlocProvider(
        providers: [
          // MIGRATION: authStore (Zustand) → AuthCubit (BLoC Cubit).
          //            Cubit chosen over BLoC because auth state transitions are
          //            simple (login/logout/check) with no complex event streams.
          BlocProvider<AuthCubit>(
            create: (_) => ServiceLocator.authCubit..checkAuth(),
          ),
          // MIGRATION: userProfileStore → UserProfileCubit.
          BlocProvider<UserProfileCubit>(
            create: (_) => ServiceLocator.userProfileCubit..loadProfileStatus(),
          ),
          // MIGRATION: transparencyStore (6 Zustand slices) → TransparencyBloc.
          //            Full BLoC (not Cubit) used here because the 6 independent
          //            reactive channels each emit typed Events — matching the
          //            "complex state" criterion in the hard rules (Rule 5).
          BlocProvider<TransparencyBloc>(
            create: (_) => ServiceLocator.transparencyBloc..add(LoadTransparencyEvent()),
          ),
        ],
        child: const SleepTrackerApp(),
      ),
    ),
  );
}

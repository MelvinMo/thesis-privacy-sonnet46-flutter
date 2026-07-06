// MIGRATION: userProfileStore.ts (Zustand) state → BLoC sealed states.

import 'package:flutter/foundation.dart';
import '../../core/models/user_consent_preferences.dart';

@immutable
sealed class UserProfileState {
  const UserProfileState();
}

final class UserProfileLoading extends UserProfileState {
  const UserProfileLoading();
}

final class UserProfileLoaded extends UserProfileState {
  final UserConsentPreferences userConsentPreferences;
  final bool hasCompletedPrivacyOnboarding;
  final bool hasCompletedAppOnboarding;

  const UserProfileLoaded({
    required this.userConsentPreferences,
    required this.hasCompletedPrivacyOnboarding,
    required this.hasCompletedAppOnboarding,
  });

  UserProfileLoaded copyWith({
    UserConsentPreferences? userConsentPreferences,
    bool? hasCompletedPrivacyOnboarding,
    bool? hasCompletedAppOnboarding,
  }) =>
      UserProfileLoaded(
        userConsentPreferences:
            userConsentPreferences ?? this.userConsentPreferences,
        hasCompletedPrivacyOnboarding:
            hasCompletedPrivacyOnboarding ?? this.hasCompletedPrivacyOnboarding,
        hasCompletedAppOnboarding:
            hasCompletedAppOnboarding ?? this.hasCompletedAppOnboarding,
      );
}

final class UserProfileError extends UserProfileState {
  final String message;
  const UserProfileError(this.message);
}

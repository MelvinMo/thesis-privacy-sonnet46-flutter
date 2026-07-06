// MIGRATION: userProfileStore.ts (Zustand) → UserProfileCubit (flutter_bloc ^8).
//
//            WHY CUBIT: Profile state is a simple value object; mutations are
//            direct setter calls with no complex async event chain.
//
//            Persistence: AsyncStorage → SharedPreferences.

import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/user_consent_preferences.dart';
import 'user_profile_state.dart';

class UserProfileCubit extends Cubit<UserProfileState> {
  final SharedPreferences _prefs;

  // MIGRATION: AsyncStorage keys preserved from source.
  static const _privacyOnboardingKey = 'hasCompletedPrivacyOnboarding';
  static const _appOnboardingKey = 'hasCompletedAppOnboarding';
  static const _consentPrefsKey = 'userConsentPreferences';

  UserProfileCubit({required SharedPreferences prefs})
      : _prefs = prefs,
        super(const UserProfileLoading());

  // ---------------------------------------------------------------------------
  // loadProfileStatus — mirrors userProfileStore.loadProfileStatus()
  // ---------------------------------------------------------------------------
  Future<void> loadProfileStatus() async {
    try {
      final privacyDone = _prefs.getBool(_privacyOnboardingKey) ?? false;
      final appDone = _prefs.getBool(_appOnboardingKey) ?? false;
      final prefsJson = _prefs.getString(_consentPrefsKey);
      final prefs = prefsJson != null
          ? UserConsentPreferences.fromJson(
              jsonDecode(prefsJson) as Map<String, dynamic>)
          : UserConsentPreferences.defaults;

      emit(UserProfileLoaded(
        userConsentPreferences: prefs,
        hasCompletedPrivacyOnboarding: privacyDone,
        hasCompletedAppOnboarding: appDone,
      ));
    } catch (e) {
      emit(UserProfileError(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // setHasCompletedPrivacyOnboarding
  // ---------------------------------------------------------------------------
  Future<void> setHasCompletedPrivacyOnboarding(bool value) async {
    await _prefs.setBool(_privacyOnboardingKey, value);
    _updateLoaded((s) => s.copyWith(hasCompletedPrivacyOnboarding: value));
  }

  // ---------------------------------------------------------------------------
  // setHasCompletedAppOnboarding
  // ---------------------------------------------------------------------------
  Future<void> setHasCompletedAppOnboarding(bool value) async {
    await _prefs.setBool(_appOnboardingKey, value);
    _updateLoaded((s) => s.copyWith(hasCompletedAppOnboarding: value));
  }

  // ---------------------------------------------------------------------------
  // setUserConsentPreferences
  // ---------------------------------------------------------------------------
  Future<void> setUserConsentPreferences(
      UserConsentPreferences preferences) async {
    await _prefs.setString(
        _consentPrefsKey, jsonEncode(preferences.toJson()));
    _updateLoaded((s) => s.copyWith(userConsentPreferences: preferences));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  void _updateLoaded(UserProfileLoaded Function(UserProfileLoaded) updater) {
    final s = state;
    if (s is UserProfileLoaded) emit(updater(s));
  }

  /// Convenience getter used by repositories to check cloud storage consent.
  bool get cloudStorageEnabled {
    final s = state;
    return s is UserProfileLoaded
        ? s.userConsentPreferences.cloudStorageEnabled
        : false;
  }

  UserConsentPreferences get consentPreferences {
    final s = state;
    return s is UserProfileLoaded
        ? s.userConsentPreferences
        : UserConsentPreferences.defaults;
  }
}

// MIGRATION: authStore.ts (Zustand) → AuthCubit (flutter_bloc ^8).
//
//            WHY CUBIT over BLOC: Auth has simple, direct state transitions
//            (login → authenticated, logout → unauthenticated). No complex
//            event streams or side-effects that would justify full BLoC.
//            Cubit methods map 1:1 to Zustand actions.
//
//            Storage mapping:
//              AsyncStorage user object  → SharedPreferences JSON string
//              expo-secure-store token   → flutter_secure_storage

import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/models/user.dart';
import '../../services/http_client.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AppHttpClient _httpClient;
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  // MIGRATION: SharedPreferences keys match AsyncStorage keys from source.
  static const _userKey = 'user';
  static const _tokenKey = 'authToken'; // SecureStorage key

  AuthCubit({
    required AppHttpClient httpClient,
    required FlutterSecureStorage secureStorage,
    required SharedPreferences prefs,
  })  : _httpClient = httpClient,
        _secureStorage = secureStorage,
        _prefs = prefs,
        super(const AuthLoading());

  // ---------------------------------------------------------------------------
  // checkAuth — mirrors authStore.checkAuth()
  // ---------------------------------------------------------------------------
  Future<void> checkAuth() async {
    // MIGRATION: Zustand `isCheckingAuth = true` → AuthLoading state.
    emit(const AuthLoading());
    try {
      final userJson = _prefs.getString(_userKey);
      final token = await _secureStorage.read(key: _tokenKey);
      if (userJson != null && token != null) {
        final user = AppUser.fromJson(
            jsonDecode(userJson) as Map<String, dynamic>);
        emit(AuthAuthenticated(user: user, token: token));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  // ---------------------------------------------------------------------------
  // login — mirrors authStore.login()
  // ---------------------------------------------------------------------------
  Future<void> login(String email, String password) async {
    emit(const AuthActionLoading());
    try {
      final response = await _httpClient.post('/api/auth/login', {
        'email': email,
        'password': password,
      });
      final user = AppUser.fromJson(response['user'] as Map<String, dynamic>);
      final token = response['token'] as String;
      await _persist(user, token);
      emit(AuthAuthenticated(user: user, token: token));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // register — mirrors authStore.register()
  // ---------------------------------------------------------------------------
  Future<void> register(
      String firstName, String lastName, String email, String password) async {
    emit(const AuthActionLoading());
    try {
      final response = await _httpClient.post('/api/auth/register', {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      });
      final user = AppUser.fromJson(response['user'] as Map<String, dynamic>);
      final token = response['token'] as String;
      await _persist(user, token);
      emit(AuthAuthenticated(user: user, token: token));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // logout — mirrors authStore.logout()
  // ---------------------------------------------------------------------------
  Future<void> logout() async {
    await _prefs.remove(_userKey);
    await _secureStorage.delete(key: _tokenKey);
    emit(const AuthUnauthenticated());
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  Future<void> _persist(AppUser user, String token) async {
    // MIGRATION: Zustand stores user in AsyncStorage, token in SecureStore.
    //            Same split here: SharedPreferences (user) + SecureStorage (token).
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  /// Convenience getter for auth token — used by repositories.
  String? get currentToken {
    final s = state;
    return s is AuthAuthenticated ? s.token : null;
  }

  /// Convenience getter for current user.
  AppUser? get currentUser {
    final s = state;
    return s is AuthAuthenticated ? s.user : null;
  }
}

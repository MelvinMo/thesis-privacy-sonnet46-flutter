// MIGRATION: authStore (Zustand) state shape → Flutter BLoC sealed states.
//            Sealed classes give exhaustive pattern-matching at call sites.
//            isLoading + isCheckingAuth booleans → separate state subclasses.

import 'package:flutter/foundation.dart';
import '../../core/models/user.dart';

@immutable
sealed class AuthState {
  const AuthState();
}

/// Initial / auth check in progress.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// No authenticated user.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Authenticated user present.
final class AuthAuthenticated extends AuthState {
  final AppUser user;
  final String token;
  const AuthAuthenticated({required this.user, required this.token});
}

/// Action in progress (login / register call).
final class AuthActionLoading extends AuthState {
  const AuthActionLoading();
}

/// Auth action failed.
final class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/auth_form_validators.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';

/// Sealed class representing the authentication status
sealed class AuthStatus {
  const AuthStatus();
}

/// Initial state on app startup before first stream event
class AuthInitial extends AuthStatus {
  const AuthInitial();
}

/// Loading state during an authentication action (signIn, signUp, etc.)
class AuthLoading extends AuthStatus {
  const AuthLoading();
}

/// User is successfully authenticated with a valid profile
class Authenticated extends AuthStatus {
  final UserModel user;
  const Authenticated(this.user);
}

/// User is not logged in
class Unauthenticated extends AuthStatus {
  const Unauthenticated();
}

/// An error occurred during authentication or stream listening
class AuthError extends AuthStatus {
  final String message;
  const AuthError(this.message);
}

/// Exception thrown when authentication fails
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Provider for the AuthService
final authServiceProvider = Provider((ref) {
  return AuthService();
});

/// AuthNotifier handles authentication actions and manages the status stream.
/// It is driven by the AuthService.userStateStream which combines Firebase Auth
/// and Firestore user document updates.
class AuthNotifier extends StateNotifier<AuthStatus> {
  final AuthService _authService;
  StreamSubscription<UserModel?>? _subscription;

  AuthNotifier(this._authService) : super(const AuthInitial()) {
    _init();
  }

  void _init() {
    _subscription = _authService.userStateStream.listen(
      (user) {
        if (user == null) {
          state = const Unauthenticated();
        } else {
          state = Authenticated(user);
        }
      },
      onError: (error) {
        final msg = error.toString().replaceFirst('Exception: ', '');
        state = AuthError(msg);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // --- Authentication Actions ---
  // All actions return a Future that throws on error, allowing UI to handle
  // errors via try/catch or AsyncValue.


  Future<void> signIn({required String email, required String password}) async {
    final emailErr = AuthFormValidators.validateEmail(email);
    if (emailErr != null) throw AuthException(emailErr);

    final passErr = AuthFormValidators.validatePassword(password);
    if (passErr != null) throw AuthException(passErr);

    state = const AuthLoading();
    try {
      await _authService.signIn(email: email, password: password);
    } catch (e) {
      state = const Unauthenticated();
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    required String displayName,
  }) async {
    final emailErr = AuthFormValidators.validateEmail(email);
    if (emailErr != null) throw AuthException(emailErr);

    final passErr = AuthFormValidators.validatePassword(password);
    if (passErr != null) throw AuthException(passErr);

    final matchErr = AuthFormValidators.validateConfirmPassword(confirmPassword, password);
    if (matchErr != null) throw AuthException(matchErr);

    final nameErr = AuthFormValidators.validateDisplayName(displayName);
    if (nameErr != null) throw AuthException(nameErr);

    state = const AuthLoading();
    try {
      await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
    } catch (e) {
      state = const Unauthenticated();
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AuthLoading();
    try {
      await _authService.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    _validateEmail(email);
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      state = const Unauthenticated();
      rethrow;
    }
  }

  Future<void> deleteAccount({required String password}) async {
    state = const AuthLoading();
    try {
      await _authService.deleteAccountWithPassword(password: password);
    } catch (e) {
      rethrow;
    }
  }

  // --- Validation Methods ---

  void _validateEmail(String email) {
    if (email.isEmpty) throw AuthException('البريد الإلكتروني مطلوب');
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) throw AuthException('صيغة البريد الإلكتروني غير صحيحة');
  }

}

// --- Exposed Providers ---

/// The main auth provider that manages the AuthNotifier.
final authProvider = StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

/// Exposes the current AuthStatus (Initial, Loading, Authenticated, Unauthenticated, Error)
final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider);
});

/// Exposes the current UserModel if authenticated, otherwise null.
final currentUserProvider = Provider<UserModel?>((ref) {
  final status = ref.watch(authProvider);
  return status is Authenticated ? status.user : null;
});

/// Exposes whether the current user has the admin role.
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role == UserRole.admin;
});

/// Exposes check for authentication.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is Authenticated;
});

/// Exposes check for loading state.
final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is AuthLoading;
});

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/auth_form_validators.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';
import '../../checkout/providers/order_providers.dart';
import '../../profile/usecases/delete_account_usecase.dart';

// ---------------------------------------------------------------------------
// Auth status sealed class
// ---------------------------------------------------------------------------

sealed class AuthStatus {
  const AuthStatus();
}

/// Initial state on app startup before the first stream event.
class AuthInitial extends AuthStatus {
  const AuthInitial();
}

/// Loading state during an auth action (signIn, signUp, etc.).
class AuthLoading extends AuthStatus {
  const AuthLoading();
}

/// User is authenticated with a valid profile.
class Authenticated extends AuthStatus {
  final UserModel user;
  const Authenticated(this.user);
}

/// User is not logged in.
class Unauthenticated extends AuthStatus {
  const Unauthenticated();
}

/// An error occurred during authentication or stream listening.
class AuthError extends AuthStatus {
  final String message;
  const AuthError(this.message);
}

/// Exception thrown when client-side validation fails.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final authServiceProvider = Provider((ref) => AuthService());

// ---------------------------------------------------------------------------
// AuthNotifier
// ---------------------------------------------------------------------------

/// Manages auth state driven by [AuthService.userStateStream].
/// Validation is delegated entirely to [AuthFormValidators].
class AuthNotifier extends StateNotifier<AuthStatus> {
  final AuthService _authService;
  StreamSubscription<UserModel?>? _subscription;

  AuthNotifier(this._authService) : super(const AuthInitial()) {
    _init();
  }

  void _init() {
    _subscription = _authService.userStateStream.listen(
          (user) {
        state = user == null ? const Unauthenticated() : Authenticated(user);
      },
      onError: (error) {
        state = AuthError(error.toString());
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Auth actions — throw on error so UI can handle via try/catch
  // ---------------------------------------------------------------------------

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
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

    final matchErr =
    AuthFormValidators.validateConfirmPassword(confirmPassword, password);
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
      state = const Unauthenticated();
    } catch (e) {
      state = AuthError(e.toString());
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    final emailErr = AuthFormValidators.validateEmail(email);
    if (emailErr != null) throw AuthException(emailErr);
    await _authService.sendPasswordResetEmail(email);
  }

  Future<String> startPhoneSignIn({required String phoneNumberE164}) async {
    state = const AuthLoading();
    try {
      return await _authService.startPhoneSignIn(
        phoneNumberE164: phoneNumberE164,
      );
    } catch (e) {
      state = const Unauthenticated();
      rethrow;
    }
  }

  Future<void> confirmPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    state = const AuthLoading();
    try {
      await _authService.confirmPhoneOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );
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
      state = AuthError(e.toString());
      rethrow;
    }
  }
}

// ---------------------------------------------------------------------------
// Exposed providers
// ---------------------------------------------------------------------------

/// Main auth provider.
final authProvider = StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

/// Current [UserModel] if authenticated, otherwise null.
final currentUserProvider = Provider<UserModel?>((ref) {
  final status = ref.watch(authProvider);
  return status is Authenticated ? status.user : null;
});

/// Whether the current user has the admin role.
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.role == UserRole.admin;
});

/// Whether a user is currently authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is Authenticated;
});

/// Whether an auth action is in progress.
final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is AuthLoading;
});

final deleteAccountUseCaseProvider = Provider((ref) => DeleteAccountUseCase(
  auth: ref.watch(authServiceProvider),
  orders: ref.watch(orderRepositoryProvider),
));
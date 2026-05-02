import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  StreamSubscription<User?>? _authSub;

  AuthNotifier(this._repository) : super(const AuthInitial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final user = await _repository.getCurrentUser();
      state = user == null
          ? const AuthUnauthenticated()
          : AuthAuthenticated(user);
    } catch (_) {
      state = const AuthUnauthenticated();
    }

    _listenToAuthChanges();
  }

  // ── Stream listener ───────────────────────────────────────────────────────

  void _listenToAuthChanges() {
    _authSub = _repository.authStateChanges.listen(
      (user) {
        state = user == null
            ? const AuthUnauthenticated()
            : AuthAuthenticated(user);
      },
      onError: (Object e) {
        state = AuthError(_toMessage(e));
      },
    );
  }

  // ── Auth actions ──────────────────────────────────────────────────────────

  Future<void> login({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      await _repository.login(email: email, password: password);
      // State update is driven by the stream — no manual setState here.
    } catch (e) {
      state = AuthError(_toMessage(e));
      rethrow; // Let UI show a snackbar / dialog if needed.
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AuthLoading();
    try {
      await _repository.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      // State update driven by stream.
    } catch (e) {
      state = AuthError(_toMessage(e));
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    try {
      await _repository.logout();
      // Stream emits null → state becomes AuthUnauthenticated.
    } catch (e) {
      state = AuthError(_toMessage(e));
      rethrow;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _toMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('user-not-found')) return 'User not found';
    if (msg.contains('wrong-password')) return 'Wrong password';
    if (msg.contains('email-already-in-use')) return 'Email already in use';
    return 'حدث خطأ غير متوقع';
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

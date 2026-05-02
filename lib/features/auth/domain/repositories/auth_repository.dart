/// Abstract contract — the domain declares what it needs.
/// The data layer fulfills it. Domain never sees the implementation.

import '../entities/user.dart';

abstract interface class AuthRepository {
  /// Returns the currently signed-in user, or null if no session exists.
  Future<User?> getCurrentUser();

  /// Emits the user on login and null on logout.
  Stream<User?> get authStateChanges;

  Future<User> login({
    required String email,
    required String password,
  });

  Future<User> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> logout();
}
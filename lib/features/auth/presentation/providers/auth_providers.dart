import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final authDataSourceProvider = Provider<AuthRemoteDataSource>(
  (_) => FirebaseAuthDataSource(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authDataSourceProvider)),
);

// ── Use cases ─────────────────────────────────────────────────────────────────

final loginUseCaseProvider = Provider(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

final registerUseCaseProvider = Provider(
  (ref) => RegisterUseCase(ref.watch(authRepositoryProvider)),
);

final logoutUseCaseProvider = Provider(
  (ref) => LogoutUseCase(ref.watch(authRepositoryProvider)),
);

final getCurrentUserUseCaseProvider = Provider(
  (ref) => GetCurrentUserUseCase(ref.watch(authRepositoryProvider)),
);

// ── Auth state ────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);

// ── Derived convenience providers ─────────────────────────────────────────────

/// The signed-in user, or null.
final currentUserProvider = Provider<User?>((ref) {
  final state = ref.watch(authProvider);
  return state is AuthAuthenticated ? state.user : null;
});

/// True while any auth action is in progress.
final authLoadingProvider = Provider<bool>(
  (ref) => ref.watch(authProvider) is AuthLoading,
);

/// True when a user session is active.
final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authProvider) is AuthAuthenticated,
);

/// True when the current user has the admin role.
final isAdminProvider = Provider<bool>(
  (ref) => ref.watch(currentUserProvider)?.role == UserRole.admin,
);

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Implements the domain contract using [AuthRemoteDataSource].
/// Maps exceptions → domain-legible errors.
/// No Firebase types cross this boundary.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  const AuthRepositoryImpl(this._dataSource);

  @override
  Future<User?> getCurrentUser() => _dataSource.getCurrentUser();

  @override
  Stream<User?> get authStateChanges => _dataSource.authStateChanges;

  @override
  Future<User> login({required String email, required String password}) =>
      _dataSource.login(email: email, password: password);

  @override
  Future<User> register({
    required String email,
    required String password,
    required String displayName,
  }) => _dataSource.register(
    email: email,
    password: password,
    displayName: displayName,
  );

  @override
  Future<void> logout() => _dataSource.logout();
}

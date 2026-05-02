/// Pure domain entity — no Firebase, no Flutter, no external deps.
/// Represents an authenticated user within the application boundary.

enum UserRole {
  customer,
  admin;

  static UserRole fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'admin' => UserRole.admin,
      _ => UserRole.customer,
    };
  }
}

class User {
  final String id;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final UserRole role;
  final bool emailVerified;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.role,
    required this.emailVerified,
    required this.createdAt,
    this.displayName,
    this.phoneNumber,
  });

  User copyWith({
    String? displayName,
    String? phoneNumber,
    bool? emailVerified,
    UserRole? role,
  }) {
    return User(
      id: id,
      email: email,
      role: role ?? this.role,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is User &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              email == other.email &&
              role == other.role &&
              emailVerified == other.emailVerified;

  @override
  int get hashCode =>
      id.hashCode ^ email.hashCode ^ role.hashCode ^ emailVerified.hashCode;

  @override
  String toString() =>
      'User(id: $id, email: $email, role: $role, emailVerified: $emailVerified)';
}
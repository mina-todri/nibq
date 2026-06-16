// lib/core/models/user_model.dart

/// User model following Clean Architecture principles.
library;

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

/// The role assigned to a user account.
///
/// Changes vs original:
/// - [CRITICAL FIX] Removed custom `.name` getter — it shadowed Dart's
///   built-in `Enum.name` (available since Dart 2.15), causing serialisation
///   bugs in environments that rely on the built-in.
enum UserRole {
  customer,
  admin;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'customer':
      case 'user':
      default:
        return UserRole.customer;
    }
  }
  // Use built-in `role.name` for serialisation (e.g. 'admin', 'customer').
}

/// Immutable user profile.
///
/// Changes vs original:
/// - [CRITICAL FIX] `UserRole.name` custom getter removed (see enum above).
/// - [MAJOR FIX] `copyWith` for all nullable String fields (`displayName`,
///   `phoneNumber`, `profilePicture`, `address`, `birthDate`) now uses the
///   sentinel pattern so callers can explicitly clear them to `null`.
/// - [FIX] `fromFirebaseUser` now accepts an optional `role` parameter so
///   the repository can inject the role fetched from Firestore instead of
///   always defaulting to `customer`.
/// - [FIX] `hashCode` uses `Object.hash()`.
/// - [IMPROVEMENT] `isAdmin` convenience getter added.
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? profilePicture;
  final String? address;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastUpdatedAt;
  final bool emailVerified;
  final Map<String, dynamic>? preferences;
  final DateTime? birthDate;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.profilePicture,
    this.address,
    this.preferences,
    this.role = UserRole.customer,
    required this.createdAt,
    this.lastUpdatedAt,
    this.emailVerified = false,
    this.birthDate,
  });

  bool get isAdmin => role == UserRole.admin;

  // Sentinel for nullable copyWith fields.
  static const Object _sentinel = Object();

  UserModel copyWith({
    String? uid,
    String? email,
    Object? displayName = _sentinel,
    Object? phoneNumber = _sentinel,
    Object? profilePicture = _sentinel,
    Object? address = _sentinel,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    Object? lastUpdatedAt = _sentinel,
    bool? emailVerified,
    UserRole? role,
    Object? birthDate = _sentinel,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: identical(displayName, _sentinel)
          ? this.displayName
          : displayName as String?,
      phoneNumber: identical(phoneNumber, _sentinel)
          ? this.phoneNumber
          : phoneNumber as String?,
      profilePicture: identical(profilePicture, _sentinel)
          ? this.profilePicture
          : profilePicture as String?,
      address:
      identical(address, _sentinel) ? this.address : address as String?,
      preferences: preferences ?? this.preferences,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: identical(lastUpdatedAt, _sentinel)
          ? this.lastUpdatedAt
          : lastUpdatedAt as DateTime?,
      emailVerified: emailVerified ?? this.emailVerified,
      birthDate: identical(birthDate, _sentinel)
          ? this.birthDate
          : birthDate as DateTime?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
      'address': address,
      'preferences': preferences,
      'role': role.name, // built-in Enum.name
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt':
      lastUpdatedAt != null ? Timestamp.fromDate(lastUpdatedAt!) : null,
      'emailVerified': emailVerified,
    };
    if (birthDate != null) {
      map['birthDate'] = Timestamp.fromDate(birthDate!);
    }
    return map;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return UserModel(
      uid: map['uid']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      displayName: map['displayName']?.toString(),
      phoneNumber: map['phoneNumber']?.toString(),
      profilePicture: map['profilePicture']?.toString(),
      address: map['address']?.toString(),
      preferences: map['preferences'] as Map<String, dynamic>?,
      role: UserRole.fromString(map['role']?.toString()),
      createdAt: parseDate(map['createdAt']),
      lastUpdatedAt:
      map['lastUpdatedAt'] != null ? parseDate(map['lastUpdatedAt']) : null,
      emailVerified:
      map['emailVerified'] is bool ? map['emailVerified'] as bool : false,
      birthDate: map['birthDate'] != null
          ? (map['birthDate'] as Timestamp).toDate()
          : null,
    );
  }

  /// Creates a [UserModel] from a Firebase [firebase_auth.User] object.
  ///
  /// [role] can be supplied when the caller has already fetched the user's
  /// Firestore profile (e.g. in an auth state change handler). Defaults to
  /// [UserRole.customer] when not provided.
  factory UserModel.fromFirebaseUser(
      firebase_auth.User firebaseUser, {
        UserRole role = UserRole.customer,
      }) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      phoneNumber: firebaseUser.phoneNumber,
      profilePicture: firebaseUser.photoURL,
      role: role,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastUpdatedAt: firebaseUser.metadata.lastSignInTime,
      emailVerified: firebaseUser.emailVerified,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is UserModel &&
              runtimeType == other.runtimeType &&
              uid == other.uid &&
              email == other.email &&
              role == other.role &&
              emailVerified == other.emailVerified &&
              birthDate == other.birthDate;

  @override
  int get hashCode =>
      Object.hash(uid, email, role, emailVerified, birthDate);

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, displayName: $displayName, role: $role)';
}
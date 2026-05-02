/// User Model following Clean Architecture principles.
/// This model represents a user in the application with essential fields.
library;

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

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

  String get name => toString().split('.').last;
}

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? profilePicture;
  final String? address;
  final UserRole role; // customer or admin
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

  /// Create a copy of the UserModel with optional replacements
  /// Useful for immutable state updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? profilePicture,
    String? address,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    bool? emailVerified,
    UserRole? role,
    DateTime? birthDate,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      address: address ?? this.address,
      preferences: preferences ?? this.preferences,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      emailVerified: emailVerified ?? this.emailVerified,
      birthDate: birthDate ?? this.birthDate,
    );
  }

  /// Convert UserModel to a Map for Firestore storage
  /// This is used when saving user data to Firestore
  Map<String, dynamic> toMap() {
    final map = {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
      'address': address,
      'preferences': preferences,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': lastUpdatedAt != null ? Timestamp.fromDate(lastUpdatedAt!) : null,
      'emailVerified': emailVerified,
    };
    if (birthDate != null) {
      map['birthDate'] = Timestamp.fromDate(birthDate!);
    }
    return map;
  }

  /// Create UserModel from a Map (from Firestore)
  /// This is used when retrieving user data from Firestore
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
      lastUpdatedAt: map['lastUpdatedAt'] != null ? parseDate(map['lastUpdatedAt']) : null,
      emailVerified: map['emailVerified'] is bool ? map['emailVerified'] as bool : false,
      birthDate: map['birthDate'] != null ? (map['birthDate'] as Timestamp).toDate() : null,
    );
  }

  /// Create UserModel from Firebase User object
  /// This is used after Firebase Authentication
  factory UserModel.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      phoneNumber: firebaseUser.phoneNumber,
      profilePicture: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastUpdatedAt: firebaseUser.metadata.lastSignInTime,
      emailVerified: firebaseUser.emailVerified,
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, displayName: $displayName, role: $role)';

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
  int get hashCode => uid.hashCode ^ email.hashCode ^ role.hashCode ^ emailVerified.hashCode ^ (birthDate?.hashCode ?? 0);
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/user.dart';

/// Data-layer model — knows about Firebase & Firestore serialization.
/// Domain entity [User] knows nothing about this class.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.role,
    required super.emailVerified,
    required super.createdAt,
    super.displayName,
    super.phoneNumber,
  });

  // ── Firestore ────────────────────────────────────────────────────────────

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime _parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return UserModel(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      displayName: map['displayName']?.toString(),
      phoneNumber: map['phoneNumber']?.toString(),
      role: UserRole.fromString(map['role']?.toString()),
      emailVerified: map['emailVerified'] is bool
          ? map['emailVerified'] as bool
          : false,
      createdAt: _parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'phoneNumber': phoneNumber,
    'role': role.name,
    'emailVerified': emailVerified,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  // ── Firebase Auth ────────────────────────────────────────────────────────

  factory UserModel.fromFirebaseUser(fb.User firebaseUser) => UserModel(
    id: firebaseUser.uid,
    email: firebaseUser.email ?? '',
    displayName: firebaseUser.displayName,
    phoneNumber: firebaseUser.phoneNumber,
    role: UserRole.customer,
    emailVerified: firebaseUser.emailVerified,
    createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
  );
}
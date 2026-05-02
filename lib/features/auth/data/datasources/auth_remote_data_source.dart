import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user.dart';
import '../models/user_model.dart';

/// Handles all raw Firebase calls.
/// Returns [UserModel]; never throws domain types.
abstract interface class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  });
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
}

class FirebaseAuthDataSource implements AuthRemoteDataSource {
  final firebase.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthDataSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  static const _users = 'users';

  // ── Firestore helpers ────────────────────────────────────────────────────

  Future<UserModel> _fetchOrCreate(User firebaseUser) async {
    final doc =
    await _firestore.collection(_users).doc(firebaseUser.uid).get();

    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }

    // First time (phone-auth, migration): create the doc from Firebase identity.
    final model = UserModel.fromFirebaseUser(firebaseUser);
    await _firestore
        .collection(_users)
        .doc(firebaseUser.uid)
        .set(model.toMap());
    return model;
  }

  // ── Auth actions ─────────────────────────────────────────────────────────

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _fetchOrCreate(cred.user!);
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await cred.user?.updateDisplayName(displayName);
    await cred.user?.reload();

    // SECURITY: role is always 'customer' on register.
    // Promote to admin only via Firestore console or a Cloud Function.
    final model = UserModel(
      id: cred.user!.uid,
      email: email,
      displayName: displayName,
      role: UserRole.customer, // imported from domain entity
      emailVerified: false,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(_users)
        .doc(cred.user!.uid)
        .set(model.toMap());

    return model;
  }

  @override
  Future<void> logout() => _auth.signOut();

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return _fetchOrCreate(firebaseUser);
  }

  /// Real-time stream: reacts to sign-in/sign-out AND Firestore doc changes
  /// (e.g. role promotion by an admin).
  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);
      return _firestore
          .collection(_users)
          .doc(firebaseUser.uid)
          .snapshots()
          .map((doc) => doc.exists
          ? UserModel.fromMap(doc.data()!)
          : UserModel.fromFirebaseUser(firebaseUser));
    });
  }
}
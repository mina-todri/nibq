// lib/core/services/auth_service.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'order_repository.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  // ---------------------------------------------------------------------------
  // Internal helper — single place that reads a user doc from Firestore.
  // ---------------------------------------------------------------------------
  Future<UserModel> _fetchOrCreateUserDoc(User firebaseUser) async {
    final doc =
    await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    // Fallback for migrated / phone-auth accounts that have no Firestore doc yet.
    final userModel = UserModel.fromFirebaseUser(firebaseUser);
    await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set(userModel.toMap());
    return userModel;
  }

  // ---------------------------------------------------------------------------
  // Auth actions
  // ---------------------------------------------------------------------------

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await userCredential.user?.updateDisplayName(displayName);
    await userCredential.user?.reload();

    // SECURITY: Always assign 'customer' on signup.
    // Admin role must be set manually in Firestore or via a secure Cloud Function.
    final userModel = UserModel(
      uid: userCredential.user!.uid,
      email: email,
      displayName: displayName,
      role: UserRole.customer,
      createdAt: DateTime.now(),
      emailVerified: false,
    );

    await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .set(userModel.toMap());

    return userModel;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _fetchOrCreateUserDoc(userCredential.user!);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    DateTime? birthDate,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }
    await user.reload();

    final updateData = <String, dynamic>{
      'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (displayName != null) updateData['displayName'] = displayName;
    if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
    if (birthDate != null) {
      updateData['birthDate'] = Timestamp.fromDate(birthDate);
    }

    await _firestore.collection('users').doc(user.uid).update(updateData);
  }

  Future<String> startPhoneSignIn({
    required String phoneNumberE164,
  }) async {
    final completer = Completer<String>();

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumberE164,
      verificationCompleted: (credential) async {
        try {
          await _firebaseAuth.signInWithCredential(credential);
          if (!completer.isCompleted) completer.complete('');
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
    );

    return completer.future;
  }

  Future<UserModel> confirmPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential =
    await _firebaseAuth.signInWithCredential(credential);
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) throw StateError('Phone sign-in failed');
    return _fetchOrCreateUserDoc(firebaseUser);
  }

  Future<void> deleteAccountWithPassword({required String password}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError('No authenticated user');

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw StateError('Re-authentication requires email/password');
    }

    final credential =
    EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(credential);
    await _firestore.collection('users').doc(user.uid).delete();
    await user.delete();
  }

  /// Combined stream of Auth state + Firestore user document.
  /// Reacts to both login/logout and role/profile updates.
  Stream<UserModel?> get userStateStream {
    return _firebaseAuth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);
      return _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
        return UserModel.fromFirebaseUser(firebaseUser);
      });
    });
  }
}
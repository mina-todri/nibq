// lib/core/services/auth_service.dart
// FIXED: Removed hardcoded admin email role assignment (CRITICAL SECURITY BUG)

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nibq/features/auth/providers/auth_provider.dart';
import '../models/user_model.dart';
import 'order_repository.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OrderRepository _orders = OrderRepository();

  AuthService();

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();

      // FIX: NEVER assign admin role based on email during signup.
      // Admin role must ONLY be set manually in Firestore by an existing admin,
      // OR via a secure Firebase Function. Client-side role assignment is a
      // critical security vulnerability.
      final userModel = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        role: UserRole.customer, // Always 'customer' on signup — period.
        createdAt: DateTime.now(),
        emailVerified: false,
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      throw AuthException("حدث خطأ أثناء إنشاء الحساب: $msg");
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        // FIX: Trust role from Firestore only, never from email comparison.
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      } else {
        // New user logging in for the first time (e.g. migrated account)
        // Always default to 'user' — admin role must be set via Firestore console.
        final userModel = UserModel.fromFirebaseUser(userCredential.user!);
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toMap());
        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      throw AuthException("حدث خطأ أثناء تسجيل الدخول: $msg");
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      } else {
        return UserModel.fromFirebaseUser(firebaseUser);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      throw AuthException("حدث خطأ أثناء إرسال رابط إعادة تعيين كلمة المرور: $msg");
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw AuthException('تم إلغاء تسجيل الدخول بجوجل');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      } else {
        final userModel = UserModel.fromFirebaseUser(firebaseUser);
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(userModel.toMap());
        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      throw AuthException("حدث خطأ أثناء تسجيل الدخول بجوجل: $msg");
    }
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    DateTime? birthDate,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        await user.reload();

        final updateData = <String, dynamic>{
          'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
        };
        if (displayName != null) updateData['displayName'] = displayName;
        if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
        if (birthDate != null) updateData['birthDate'] = Timestamp.fromDate(birthDate);

        await _firestore.collection('users').doc(user.uid).update(updateData);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isUserLoggedIn() async {
    try {
      return _firebaseAuth.currentUser != null;
    } catch (e) {
      return false;
    }
  }

  Stream<UserModel> userDocStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            throw StateError('User document not found for uid: $uid');
          }
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        });
  }

  Future<void> deleteAccountWithPassword({
    required String password,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user');
    }
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw StateError('Re-authentication requires email/password');
    }

    final credential =
    EmailAuthProvider.credential(email: email, password: password);
try {
  await user.reauthenticateWithCredential(credential);
  await _orders.deleteOrdersForUser(user.uid);
  await _firestore.collection('users').doc(user.uid).delete();
  await user.delete();
}on FirebaseAuthException catch (e) {
  throw AuthException(_mapFirebaseError(e));
} catch (e) {
  final msg = e.toString().replaceFirst('Exception: ', '');
  throw AuthException("حدث خطأ أثناء حذف الحساب: $msg");
}

}

  /// Combined stream of Auth state changes and Firestore user document snapshots.
  /// This ensures the app reacts to both login/logout and role/profile updates.
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
          })
          .handleError((error) {
            // If we get a permission-denied error, it usually means the user 
            // has been logged out or their session is invalid.
            // We return null to trigger Unauthenticated state instead of an error crash.
            if (error.toString().contains('permission-denied')) {
              return null;
            }
            throw error;
          });
    });
  }


  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مستخدم بالفعل';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً، استخدم 6 أحرف على الأقل';
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case 'user-disabled':
        return 'هذا الحساب موقوف، تواصل مع الدعم';
      case 'too-many-requests':
        return 'محاولات كثيرة جداً، انتظر قليلاً وحاول مرة أخرى';
      case 'network-request-failed':
        return 'تحقق من اتصالك بالإنترنت';
      case 'requires-recent-login':
        return 'يرجى تسجيل الدخول مرة أخرى لإتمام هذا الإجراء';
      case 'credential-already-in-use':
        return 'هذا الحساب مرتبط بمستخدم آخر';
      default:
        return 'حدث خطأ غير متوقع، حاول مرة أخرى';
    }
  }
}

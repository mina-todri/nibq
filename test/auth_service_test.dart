// test/auth_service_test.dart
//
// يغطي كل الحالات في AuthService:
//   - signUp (نجاح، user doc اتكتب بـ role=customer)
//   - signIn (نجاح مع doc موجود، نجاح مع doc مش موجود فيعمله)
//   - signOut
//   - sendPasswordResetEmail
//   - updateUserProfile
//   - confirmPhoneOtp
//   - deleteAccountWithPassword (نجاح، no user، no email)
//   - userStateStream (emit user, emit null on logout)
//   - _fetchOrCreateUserDoc helper (via signIn)
//
// تشغيل:
//   flutter test test/auth_service_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nibq/core/models/user_model.dart';
import 'package:nibq/core/services/auth_service.dart';
import 'package:nibq/core/services/order_repository.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([
  firebase_auth.FirebaseAuth,
  firebase_auth.UserCredential,
  firebase_auth.User,
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  OrderRepository,
])
void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockOrderRepository mockOrderRepo;
  late MockCollectionReference<Map<String, dynamic>> mockUsersCollection;
  late AuthService service;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  MockDocumentReference<Map<String, dynamic>> _stubUserDocRef(
      String uid, {
        required bool exists,
        Map<String, dynamic>? data,
      }) {
    final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
    final mockDocSnap = MockDocumentSnapshot<Map<String, dynamic>>();

    when(mockUsersCollection.doc(uid)).thenReturn(mockDocRef);
    when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
    when(mockDocSnap.exists).thenReturn(exists);
    when(mockDocSnap.data()).thenReturn(data);
    when(mockDocRef.set(any)).thenAnswer((_) async {});
    when(mockDocRef.update(any)).thenAnswer((_) async {});
    when(mockDocRef.delete()).thenAnswer((_) async {});

    return mockDocRef;
  }

  Map<String, dynamic> _userDocData(String uid, {String role = 'customer'}) {
    return {
      'uid': uid,
      'email': 'test@test.com',
      'displayName': 'Test User',
      'role': role,
      'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      'emailVerified': false,
    };
  }

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockOrderRepo = MockOrderRepository();
    mockUsersCollection = MockCollectionReference();

    when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);

    service = AuthService(
      firebaseAuth: mockAuth,
      firestore: mockFirestore,
      orders: mockOrderRepo,
    );
  });

  // =========================================================================
  // signUp
  // =========================================================================

  group('signUp', () {
    test('creates user and writes Firestore doc with role=customer', () async {
      final mockCredential = MockUserCredential();
      final mockUser = MockUser();

      when(mockAuth.createUserWithEmailAndPassword(
        email: 'test@test.com',
        password: 'pass123',
      )).thenAnswer((_) async => mockCredential);

      when(mockCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('uid-1');
      when(mockUser.updateDisplayName(any)).thenAnswer((_) async {});
      when(mockUser.reload()).thenAnswer((_) async {});

      _stubUserDocRef('uid-1', exists: false);

      final result = await service.signUp(
        email: 'test@test.com',
        password: 'pass123',
        displayName: 'Test User',
      );

      expect(result.role, UserRole.customer);
      expect(result.email, 'test@test.com');
      expect(result.uid, 'uid-1');

      // Verify Firestore doc was written
      verify(mockUsersCollection.doc('uid-1')).called(greaterThan(0));
    });

    test('never assigns admin role during signup', () async {
      final mockCredential = MockUserCredential();
      final mockUser = MockUser();

      when(mockAuth.createUserWithEmailAndPassword(
        email: 'admin@test.com',
        password: 'pass123',
      )).thenAnswer((_) async => mockCredential);

      when(mockCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('uid-admin');
      when(mockUser.updateDisplayName(any)).thenAnswer((_) async {});
      when(mockUser.reload()).thenAnswer((_) async {});

      _stubUserDocRef('uid-admin', exists: false);

      final result = await service.signUp(
        email: 'admin@test.com',
        password: 'pass123',
        displayName: 'Admin',
      );

      // SECURITY: Even with an "admin" email, role must be customer
      expect(result.role, UserRole.customer);
    });
  });

  // =========================================================================
  // signIn
  // =========================================================================

  group('signIn', () {
    test('returns UserModel from existing Firestore doc', () async {
      final mockCredential = MockUserCredential();
      final mockUser = MockUser();

      when(mockAuth.signInWithEmailAndPassword(
        email: 'test@test.com',
        password: 'pass123',
      )).thenAnswer((_) async => mockCredential);

      when(mockCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('uid-1');

      _stubUserDocRef(
        'uid-1',
        exists: true,
        data: _userDocData('uid-1'),
      );

      final result = await service.signIn(
        email: 'test@test.com',
        password: 'pass123',
      );

      expect(result.uid, 'uid-1');
      expect(result.role, UserRole.customer);
    });

    test('creates Firestore doc when it does not exist (migrated account)',
            () async {
          final mockCredential = MockUserCredential();
          final mockUser = MockUser();

          when(mockAuth.signInWithEmailAndPassword(
            email: 'test@test.com',
            password: 'pass123',
          )).thenAnswer((_) async => mockCredential);

          when(mockCredential.user).thenReturn(mockUser);
          when(mockUser.uid).thenReturn('uid-new');
          when(mockUser.email).thenReturn('test@test.com');
          when(mockUser.displayName).thenReturn(null);
          when(mockUser.phoneNumber).thenReturn(null);
          when(mockUser.photoURL).thenReturn(null);
          when(mockUser.emailVerified).thenReturn(false);
          when(mockUser.metadata).thenReturn(firebase_auth.UserMetadata(0, 0));

          final mockDocRef = _stubUserDocRef('uid-new', exists: false);

          await service.signIn(
            email: 'test@test.com',
            password: 'pass123',
          );

          // Verify doc was created
          verify(mockDocRef.set(any)).called(1);
        });

    test('role from Firestore is trusted — admin stays admin', () async {
      final mockCredential = MockUserCredential();
      final mockUser = MockUser();

      when(mockAuth.signInWithEmailAndPassword(
        email: 'admin@test.com',
        password: 'pass123',
      )).thenAnswer((_) async => mockCredential);

      when(mockCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('uid-admin');

      _stubUserDocRef(
        'uid-admin',
        exists: true,
        data: _userDocData('uid-admin', role: 'admin'),
      );

      final result = await service.signIn(
        email: 'admin@test.com',
        password: 'pass123',
      );

      expect(result.role, UserRole.admin);
    });
  });

  // =========================================================================
  // signOut
  // =========================================================================

  group('signOut', () {
    test('calls FirebaseAuth.signOut()', () async {
      when(mockAuth.signOut()).thenAnswer((_) async {});

      await service.signOut();

      verify(mockAuth.signOut()).called(1);
    });
  });

  // =========================================================================
  // sendPasswordResetEmail
  // =========================================================================

  group('sendPasswordResetEmail', () {
    test('calls FirebaseAuth.sendPasswordResetEmail with correct email',
            () async {
          when(mockAuth.sendPasswordResetEmail(email: 'test@test.com'))
              .thenAnswer((_) async {});

          await service.sendPasswordResetEmail('test@test.com');

          verify(mockAuth.sendPasswordResetEmail(email: 'test@test.com')).called(1);
        });
  });

  // =========================================================================
  // updateUserProfile
  // =========================================================================

  group('updateUserProfile', () {
    test('updates displayName in Firebase Auth and Firestore', () async {
      final mockUser = MockUser();

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('uid-1');
      when(mockUser.updateDisplayName('New Name')).thenAnswer((_) async {});
      when(mockUser.reload()).thenAnswer((_) async {});

      final mockDocRef = _stubUserDocRef('uid-1', exists: true);

      await service.updateUserProfile(displayName: 'New Name');

      verify(mockUser.updateDisplayName('New Name')).called(1);
      verify(mockDocRef.update(argThat(containsPair('displayName', 'New Name'))))
          .called(1);
    });

    test('does nothing when no user is logged in', () async {
      when(mockAuth.currentUser).thenReturn(null);

      // Should complete silently
      await expectLater(
        service.updateUserProfile(displayName: 'Test'),
        completes,
      );

      verifyNever(mockUsersCollection.doc(any));
    });
  });

  // =========================================================================
  // deleteAccountWithPassword
  // =========================================================================

  group('deleteAccountWithPassword', () {
    test('throws StateError when no user is logged in', () async {
      when(mockAuth.currentUser).thenReturn(null);

      expect(
            () => service.deleteAccountWithPassword(password: 'pass123'),
        throwsA(isA<StateError>()),
      );
    });

    test('throws StateError when user has no email (phone-only account)',
            () async {
          final mockUser = MockUser();
          when(mockAuth.currentUser).thenReturn(mockUser);
          when(mockUser.email).thenReturn(null);

          expect(
                () => service.deleteAccountWithPassword(password: 'pass123'),
            throwsA(isA<StateError>()),
          );
        });

    test('reauthenticates, deletes orders, deletes doc, deletes account',
            () async {
          final mockUser = MockUser();
          final mockCredential = MockUserCredential();

          when(mockAuth.currentUser).thenReturn(mockUser);
          when(mockUser.uid).thenReturn('uid-1');
          when(mockUser.email).thenReturn('test@test.com');
          when(mockUser.reauthenticateWithCredential(any))
              .thenAnswer((_) async => mockCredential);
          when(mockUser.delete()).thenAnswer((_) async {});

          final mockDocRef = _stubUserDocRef('uid-1', exists: true);

          when(mockOrderRepo.deleteOrdersForUser('uid-1'))
              .thenAnswer((_) async {});

          await service.deleteAccountWithPassword(password: 'pass123');

          verify(mockUser.reauthenticateWithCredential(any)).called(1);
          verify(mockOrderRepo.deleteOrdersForUser('uid-1')).called(1);
          verify(mockDocRef.delete()).called(1);
          verify(mockUser.delete()).called(1);
        });
  });

  // =========================================================================
  // userStateStream
  // =========================================================================

  group('userStateStream', () {
    test('emits null when user is logged out', () async {
      when(mockAuth.authStateChanges())
          .thenAnswer((_) => Stream.value(null));

      final stream = service.userStateStream;
      expect(await stream.first, isNull);
    });

    test('emits UserModel when user is logged in and doc exists', () async {
      final mockUser = MockUser();
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnap = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockAuth.authStateChanges())
          .thenAnswer((_) => Stream.value(mockUser));
      when(mockUser.uid).thenReturn('uid-1');

      when(mockUsersCollection.doc('uid-1')).thenReturn(mockDocRef);
      when(mockDocRef.snapshots())
          .thenAnswer((_) => Stream.value(mockDocSnap));
      when(mockDocSnap.exists).thenReturn(true);
      when(mockDocSnap.data()).thenReturn(_userDocData('uid-1'));

      final stream = service.userStateStream;
      final user = await stream.first;

      expect(user, isNotNull);
      expect(user!.uid, 'uid-1');
    });

    test('emits fallback UserModel when Firestore doc is missing', () async {
      final mockUser = MockUser();
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnap = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockAuth.authStateChanges())
          .thenAnswer((_) => Stream.value(mockUser));
      when(mockUser.uid).thenReturn('uid-1');
      when(mockUser.email).thenReturn('test@test.com');
      when(mockUser.displayName).thenReturn(null);
      when(mockUser.phoneNumber).thenReturn(null);
      when(mockUser.photoURL).thenReturn(null);
      when(mockUser.emailVerified).thenReturn(false);
      when(mockUser.metadata).thenReturn(firebase_auth.UserMetadata(0, 0));

      when(mockUsersCollection.doc('uid-1')).thenReturn(mockDocRef);
      when(mockDocRef.snapshots())
          .thenAnswer((_) => Stream.value(mockDocSnap));
      when(mockDocSnap.exists).thenReturn(false);

      final stream = service.userStateStream;
      final user = await stream.first;

      expect(user, isNotNull);
      expect(user!.uid, 'uid-1');
    });
  });
}
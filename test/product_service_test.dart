// test/product_service_test.dart
//
// يغطي كل الحالات في ProductService:
//   - streamProducts
//   - addProduct (بدون صورة، مع صورة)
//   - updateProduct (بدون صورة جديدة، مع صورة جديدة)
//   - deleteProduct (نجاح، فشل)
//   - _resolveImageUrl helper (implicitly via add/update)
//
// تشغيل:
//   flutter test test/product_service_test.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nibq/core/models/product_model.dart';
import 'package:nibq/core/services/product_service.dart';

import 'product_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  QueryDocumentSnapshot,
  CloudinaryPublic,
  CloudinaryResponse,
  File,
])
void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCloudinaryPublic mockCloudinary;
  late MockCollectionReference<Map<String, dynamic>> mockProductsCollection;
  late ProductService service;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  ProductModel _makeProduct({String id = 'prod-1'}) {
    return ProductModel(
      id: id,
      name: 'Test Product',
      description: 'Desc',
      price: 100.0,
      category: 'Category',
      imageUrl: 'https://old-image.com/img.jpg',
      variants: [],
      rating: 0.0,
      reviewCount: 0,
    );
  }

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCloudinary = MockCloudinaryPublic();
    mockProductsCollection = MockCollectionReference();

    when(mockFirestore.collection('products'))
        .thenReturn(mockProductsCollection);

    service = ProductService(
      firestore: mockFirestore,
      cloudinary: mockCloudinary,
    );
  });

  // =========================================================================
  // streamProducts
  // =========================================================================

  group('streamProducts', () {
    test('returns a stream of ProductModel list', () async {
      final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockProductsCollection.snapshots())
          .thenAnswer((_) => Stream.value(mockQuerySnapshot));
      when(mockQuerySnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('prod-1');
      when(mockDoc.data()).thenReturn({
        'name': 'Test Product',
        'description': 'Desc',
        'price': 100.0,
        'category': 'Category',
        'imageUrl': 'https://img.com/img.jpg',
        'variants': [],
        'rating': 0.0,
        'reviewCount': 0,
      });

      final stream = service.streamProducts();
      final products = await stream.first;

      expect(products.length, 1);
      expect(products.first.id, 'prod-1');
      expect(products.first.name, 'Test Product');
    });

    test('returns empty list when no products exist', () async {
      final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      when(mockProductsCollection.snapshots())
          .thenAnswer((_) => Stream.value(mockQuerySnapshot));
      when(mockQuerySnapshot.docs).thenReturn([]);

      final stream = service.streamProducts();
      final products = await stream.first;

      expect(products, isEmpty);
    });
  });

  // =========================================================================
  // addProduct
  // =========================================================================

  group('addProduct', () {
    test('adds product without uploading image when imageFile is null',
            () async {
          final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
          when(mockProductsCollection.add(any))
              .thenAnswer((_) async => mockDocRef);

          final product = _makeProduct();
          await service.addProduct(product, null);

          // Cloudinary should NOT be called
          verifyNever(mockCloudinary.uploadFile(any));

          // Firestore add should be called with existing imageUrl
          final captured =
          verify(mockProductsCollection.add(captureAny)).captured.single
          as Map<String, dynamic>;
          expect(captured['imageUrl'], 'https://old-image.com/img.jpg');
        });

    test('uploads image to Cloudinary then adds product', () async {
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockFile = MockFile();
      final mockResponse = MockCloudinaryResponse();

      when(mockFile.path).thenReturn('/tmp/test.jpg');
      when(mockResponse.secureUrl).thenReturn('https://cloudinary.com/new.jpg');
      when(mockCloudinary.uploadFile(any))
          .thenAnswer((_) async => mockResponse);
      when(mockProductsCollection.add(any))
          .thenAnswer((_) async => mockDocRef);

      final product = _makeProduct();
      await service.addProduct(product, mockFile);

      verify(mockCloudinary.uploadFile(any)).called(1);

      final captured =
      verify(mockProductsCollection.add(captureAny)).captured.single
      as Map<String, dynamic>;
      expect(captured['imageUrl'], 'https://cloudinary.com/new.jpg');
    });

    test('throws ProductException when Firestore add fails', () async {
      when(mockProductsCollection.add(any))
          .thenThrow(Exception('Firestore error'));

      expect(
            () => service.addProduct(_makeProduct(), null),
        throwsA(isA<ProductException>()),
      );
    });

    test('throws ProductException with code add-failed on error', () async {
      when(mockProductsCollection.add(any))
          .thenThrow(Exception('network error'));

      try {
        await service.addProduct(_makeProduct(), null);
        fail('Should have thrown');
      } on ProductException catch (e) {
        expect(e.code, 'add-failed');
      }
    });
  });

  // =========================================================================
  // updateProduct
  // =========================================================================

  group('updateProduct', () {
    test('updates product without new image — keeps existing imageUrl',
            () async {
          final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
          when(mockProductsCollection.doc('prod-1')).thenReturn(mockDocRef);
          when(mockDocRef.update(any)).thenAnswer((_) async {});

          await service.updateProduct(_makeProduct(), null);

          verifyNever(mockCloudinary.uploadFile(any));

          final captured =
          verify(mockDocRef.update(captureAny)).captured.single
          as Map<String, dynamic>;
          expect(captured['imageUrl'], 'https://old-image.com/img.jpg');
        });

    test('uploads new image then updates product', () async {
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockFile = MockFile();
      final mockResponse = MockCloudinaryResponse();

      when(mockProductsCollection.doc('prod-1')).thenReturn(mockDocRef);
      when(mockDocRef.update(any)).thenAnswer((_) async {});
      when(mockFile.path).thenReturn('/tmp/new.jpg');
      when(mockResponse.secureUrl).thenReturn('https://cloudinary.com/new.jpg');
      when(mockCloudinary.uploadFile(any))
          .thenAnswer((_) async => mockResponse);

      await service.updateProduct(_makeProduct(), mockFile);

      verify(mockCloudinary.uploadFile(any)).called(1);

      final captured =
      verify(mockDocRef.update(captureAny)).captured.single
      as Map<String, dynamic>;
      expect(captured['imageUrl'], 'https://cloudinary.com/new.jpg');
    });

    test('throws ProductException with code update-failed on error', () async {
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      when(mockProductsCollection.doc('prod-1')).thenReturn(mockDocRef);
      when(mockDocRef.update(any)).thenThrow(Exception('Firestore error'));

      try {
        await service.updateProduct(_makeProduct(), null);
        fail('Should have thrown');
      } on ProductException catch (e) {
        expect(e.code, 'update-failed');
      }
    });
  });

  // =========================================================================
  // deleteProduct
  // =========================================================================

  group('deleteProduct', () {
    test('deletes document from Firestore', () async {
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      when(mockProductsCollection.doc('prod-1')).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});

      await service.deleteProduct('prod-1');

      verify(mockDocRef.delete()).called(1);
    });

    test('throws ProductException with code delete-failed on error', () async {
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      when(mockProductsCollection.doc('prod-1')).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenThrow(Exception('permission denied'));

      try {
        await service.deleteProduct('prod-1');
        fail('Should have thrown');
      } on ProductException catch (e) {
        expect(e.code, 'delete-failed');
      }
    });
  });

  // =========================================================================
  // uploadImageToCloudinary
  // =========================================================================

  group('uploadImageToCloudinary', () {
    test('returns secureUrl from Cloudinary on success', () async {
      final mockFile = MockFile();
      final mockResponse = MockCloudinaryResponse();

      when(mockFile.path).thenReturn('/tmp/img.jpg');
      when(mockResponse.secureUrl).thenReturn('https://cloudinary.com/img.jpg');
      when(mockCloudinary.uploadFile(any))
          .thenAnswer((_) async => mockResponse);

      final url = await service.uploadImageToCloudinary(mockFile);

      expect(url, 'https://cloudinary.com/img.jpg');
    });

    test('throws ProductException with code upload-failed on error', () async {
      final mockFile = MockFile();

      when(mockFile.path).thenReturn('/tmp/img.jpg');
      when(mockCloudinary.uploadFile(any))
          .thenThrow(Exception('upload failed'));

      try {
        await service.uploadImageToCloudinary(mockFile);
        fail('Should have thrown');
      } on ProductException catch (e) {
        expect(e.code, 'upload-failed');
      }
    });
  });

  group('Cloudinary missing credentials - graceful handling', () {
    test('service constructs without crashing when credentials are missing', () {
      expect(
        () => ProductService(firestore: mockFirestore),
        returnsNormally,
      );
    });

    test('streamProducts works without Cloudinary', () async {
      final svc = ProductService(firestore: mockFirestore);
      final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      when(mockProductsCollection.snapshots())
          .thenAnswer((_) => Stream.value(mockQuerySnapshot));
      when(mockQuerySnapshot.docs).thenReturn([]);

      final stream = svc.streamProducts();
      expect(await stream.first, isEmpty);
    });

    test('addProduct with null imageFile works without Cloudinary', () async {
      final svc = ProductService(firestore: mockFirestore);
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      when(mockProductsCollection.add(any))
          .thenAnswer((_) async => mockDocRef);

      final product = _makeProduct();
      await svc.addProduct(product, null);

      verify(mockProductsCollection.add(any)).called(1);
    });

    test('deleteProduct works without Cloudinary', () async {
      final svc = ProductService(firestore: mockFirestore);
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      when(mockProductsCollection.doc('prod-1')).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});

      await svc.deleteProduct('prod-1');

      verify(mockDocRef.delete()).called(1);
    });

    test('uploadImageToCloudinary throws ProductException when not configured', () async {
      final svc = ProductService(firestore: mockFirestore);
      final mockFile = MockFile();
      when(mockFile.path).thenReturn('/tmp/img.jpg');

      expect(
        () => svc.uploadImageToCloudinary(mockFile),
        throwsA(isA<ProductException>().having(
          (e) => e.code,
          'code',
          'cloudinary-not-configured',
        )),
      );
    });

    test('addProduct with imageFile throws ProductException when not configured', () async {
      final svc = ProductService(firestore: mockFirestore);
      final mockFile = MockFile();
      when(mockFile.path).thenReturn('/tmp/img.jpg');

      expect(
        () => svc.addProduct(_makeProduct(), mockFile),
        throwsA(isA<ProductException>().having(
          (e) => e.code,
          'code',
          'cloudinary-not-configured',
        )),
      );
    });
  });
}
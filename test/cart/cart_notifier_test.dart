import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nibq/core/models/cart_item_model.dart';
import 'package:nibq/core/models/product_model.dart';
import 'package:nibq/features/cart/providers/cart_provider.dart';
import 'package:nibq/features/product/providers/product_provider.dart';

import 'cart_notifier_test.mocks.dart';

/// Minimal fake Ref that only implements what CartNotifier needs
class FakeRef implements Ref {
  FakeRef({this.products = const []});

  final List<ProductModel> products;

  @override
  T read<T>(ProviderListenable<T> provider) {
    if (provider == productsStreamProvider) {
      return AsyncValue.data(products) as T;
    }
    if (provider == cartErrorProvider) {
      return null as T;
    }
    return _FakeErrorController() as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class _FakeErrorController implements StateController<String?> {
  String? _state;

  @override
  String? get state => _state;

  @override
  set state(String? value) {
    _state = value;
  }

  @override
  String? call([String? value]) {
    if (value != null) state = value;
    return _state;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class _FakeSubscription<T> implements ProviderSubscription<T> {
  @override
  void close() {}

  @override
  T read() => null as T;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  DocumentSnapshot,
  WriteBatch,
])
void main() {
  ProductModel _makeProduct({
    String id = 'prod-1',
    String name = 'Test Product',
    String category = 'Test',
    double price = 100.0,
    List<ProductVariant> variants = const [
      ProductVariant(name: 'Large', stock: 10),
      ProductVariant(name: 'Small', stock: 5),
    ],
    double? discount,
  }) {
    return ProductModel(
      id: id,
      name: name,
      description: 'Test',
      price: price,
      category: category,
      variants: variants,
      rating: 0.0,
      reviewCount: 0,
      discount: discount,
    );
  }

  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockCartCollection;
  late MockDocumentReference<Map<String, dynamic>> mockCartDoc;
  late MockWriteBatch mockBatch;
  late StreamController<QuerySnapshot<Map<String, dynamic>>> cartStreamController;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCartCollection = MockCollectionReference();
    mockCartDoc = MockDocumentReference();
    mockBatch = MockWriteBatch();
    cartStreamController =
        StreamController<QuerySnapshot<Map<String, dynamic>>>();

    when(mockFirestore.collection('carts')).thenReturn(mockCartCollection);
    when(mockFirestore.collection('products'))
        .thenReturn(MockCollectionReference());
    when(mockFirestore.batch()).thenReturn(mockBatch);
    when(mockBatch.delete(any)).thenReturn(null);
    when(mockBatch.commit()).thenAnswer((_) async {});

    when(mockCartCollection.doc(any)).thenReturn(mockCartDoc);
    when(mockCartDoc.collection(any)).thenReturn(mockCartCollection);
    when(mockCartDoc.set(any, any)).thenAnswer((_) async {});
    when(mockCartDoc.update(any)).thenAnswer((_) async {});
    when(mockCartDoc.delete()).thenAnswer((_) async {});

    final emptySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
    when(emptySnapshot.docs).thenReturn([]);
    when(mockCartCollection.snapshots())
        .thenAnswer((_) => cartStreamController.stream);
  });

  tearDown(() {
    cartStreamController.close();
  });

  FakeRef _createRef({List<ProductModel> products = const []}) {
    return FakeRef(products: products);
  }

  CartNotifier _createNotifier({
    String? uid = 'user-1',
    List<ProductModel> products = const [],
  }) {
    return CartNotifier(uid, _createRef(products: products), firestore: mockFirestore);
  }

  group('CartNotifier - addItem', () {
    test('adds new item with correct ID format (productId::variantName)',
        () async {
      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 10),
          ]),
        ],
      );

      expect(notifier.state, isEmpty);

      await notifier.addItem('prod-1', 'Large');

      expect(notifier.state.length, 1);
      expect(notifier.state[0].productId, 'prod-1');
      expect(notifier.state[0].selectedVariant, 'Large');
      expect(notifier.state[0].quantity, 1);
    });

    test('increments quantity when same product+variant exists', () async {
      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 10),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'Large');
      await notifier.addItem('prod-1', 'Large');

      expect(notifier.state.length, 1);
      expect(notifier.state[0].quantity, 2);
    });

    test('adds same product with different variant as separate item', () async {
      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 10),
            ProductVariant(name: 'Small', stock: 5),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'Large');
      await notifier.addItem('prod-1', 'Small');

      expect(notifier.state.length, 2);
      expect(notifier.state[0].selectedVariant, 'Large');
      expect(notifier.state[1].selectedVariant, 'Small');
    });

    test('rolls back state when stock is zero', () async {
      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 0),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'Large');

      expect(notifier.state, isEmpty);
    });

    test('rolls back state when quantity exceeds stock', () async {
      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 3),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'Large');
      await notifier.addItem('prod-1', 'Large');
      await notifier.addItem('prod-1', 'Large');

      expect(notifier.state[0].quantity, 3);

      await notifier.addItem('prod-1', 'Large');

      expect(notifier.state[0].quantity, 3);
    });

    test('handles default variant correctly', () async {
      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'default', stock: 10),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'default');

      expect(notifier.state.length, 1);
      expect(notifier.state[0].quantity, 1);
    });

    test('does nothing when uid is null', () async {
      final notifier = _createNotifier(
        uid: null,
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 10),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'Large');

      expect(notifier.state, isEmpty);
    });
  });

  group('CartNotifier - removeItem', () {
    test('removes item from state', () async {
      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 10),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'Large');
      expect(notifier.state.length, 1);

      await notifier.removeItem('prod-1', 'Large');
      expect(notifier.state, isEmpty);
    });

    test('rolls back state when Firestore delete fails', () async {
      when(mockCartDoc.delete()).thenThrow(Exception('Firestore error'));

      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 10),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'Large');
      expect(notifier.state.length, 1);

      await notifier.removeItem('prod-1', 'Large');

      expect(notifier.state.length, 1);
    });

    test('does nothing when uid is null', () async {
      final notifier = _createNotifier(
        uid: null,
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 10),
          ]),
        ],
      );

      await notifier.removeItem('prod-1', 'Large');

      expect(notifier.state, isEmpty);
    });
  });

  group('CartNotifier - updateQuantity', () {
    test('clamps quantity to available stock', () async {
      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 5),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'Large');
      expect(notifier.state[0].quantity, 1);

      await notifier.updateQuantity('prod-1', 'Large', 10);

      expect(notifier.state[0].quantity, 5);
    });

    test('removes item when quantity is 0', () async {
      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 10),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'Large');
      expect(notifier.state.length, 1);

      await notifier.updateQuantity('prod-1', 'Large', 0);

      expect(notifier.state, isEmpty);
    });

    test('removes item when quantity is negative', () async {
      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 10),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'Large');
      expect(notifier.state.length, 1);

      await notifier.updateQuantity('prod-1', 'Large', -5);

      expect(notifier.state, isEmpty);
    });
  });

  group('CartNotifier - clearCart', () {
    test('clears all items from state', () async {
      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 10),
            ProductVariant(name: 'Small', stock: 5),
          ]),
          _makeProduct(id: 'prod-2', variants: [
            ProductVariant(name: 'Red', stock: 8),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'Large');
      await notifier.addItem('prod-1', 'Small');
      await notifier.addItem('prod-2', 'Red');

      expect(notifier.state.length, 3);

      await notifier.clearCart();

      expect(notifier.state, isEmpty);
    });

    test('rolls back state when batch commit fails', () async {
      when(mockBatch.commit()).thenThrow(Exception('Batch failed'));

      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 10),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'Large');
      expect(notifier.state.length, 1);

      await notifier.clearCart();

      expect(notifier.state.length, 1);
    });

    test('does nothing when uid is null', () async {
      final notifier = _createNotifier(
        uid: null,
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 10),
          ]),
        ],
      );

      await notifier.clearCart();

      expect(notifier.state, isEmpty);
    });
  });

  group('CartNotifier - _getLiveStock edge cases', () {
    test('returns 0 when products are not loaded (empty list)', () async {
      final notifier = _createNotifier(products: []);

      await notifier.addItem('prod-1', 'Large');

      expect(notifier.state, isEmpty);
    });

    test('handles missing product gracefully (no crash)', () async {
      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-2', variants: [
            ProductVariant(name: 'Large', stock: 10),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'Large');

      expect(notifier.state, isEmpty);
    });
  });

  group('CartItemEntity - ID format safety', () {
    test('handles variant name containing underscore correctly', () async {
      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large_Red', stock: 10),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'Large_Red');

      expect(notifier.state.length, 1);
      expect(notifier.state[0].selectedVariant, 'Large_Red');
      expect(notifier.state[0].quantity, 1);
    });
  });

  group('CartNotifier - Firestore interactions', () {
    test('addItem calls Firestore set with correct data', () async {
      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 10),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'Large');

      verify(mockCartDoc.set({
        'productId': 'prod-1',
        'selectedVariant': 'Large',
        'quantity': 1,
      }, any)).called(1);
    });

    test('removeItem calls Firestore delete with correct ID', () async {
      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 10),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'Large');
      await notifier.removeItem('prod-1', 'Large');

      verify(mockCartCollection.doc('prod-1::Large')).called(greaterThan(0));
      verify(mockCartDoc.delete()).called(1);
    });

    test('updateQuantity calls Firestore update with correct data', () async {
      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 10),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'Large');
      await notifier.updateQuantity('prod-1', 'Large', 5);

      verify(mockCartCollection.doc('prod-1::Large')).called(greaterThan(0));
      verify(mockCartDoc.update({'quantity': 5})).called(1);
    });

    test('clearCart uses batch delete for all items', () async {
      final notifier = _createNotifier(
        products: [
          _makeProduct(id: 'prod-1', variants: [
            ProductVariant(name: 'Large', stock: 10),
            ProductVariant(name: 'Small', stock: 5),
          ]),
        ],
      );

      await notifier.addItem('prod-1', 'Large');
      await notifier.addItem('prod-1', 'Small');

      await notifier.clearCart();

      verify(mockFirestore.batch()).called(1);
      verify(mockBatch.commit()).called(1);
    });
  });
}

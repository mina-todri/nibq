import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nibq/core/models/cart_item_model.dart';
import 'package:nibq/core/models/product_model.dart';
import 'package:nibq/features/cart/repositories/cart_repository.dart';
import 'package:nibq/features/cart/usecases/cart_usecases.dart';
import 'package:nibq/features/cart/usecases/get_live_stock_usecase.dart';
import 'package:nibq/features/product/providers/product_provider.dart';

import 'cart_notifier_test.mocks.dart' hide MockRef;
import 'cart_usecases_test.mocks.dart';

// Provide dummy value for AsyncValue<List<ProductModel>>
final _dummyAsyncValue = const AsyncLoading<List<ProductModel>>();

@GenerateMocks([
  Ref,
  CartRepository,
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

  setUpAll(() {
    provideDummy<AsyncValue<List<ProductModel>>>(_dummyAsyncValue);
  });

  late MockRef mockRef;

  setUp(() {
    mockRef = MockRef();
  });

  group('GetLiveStockUseCase', () {
    test('returns stock for specific variant', () {
      when(mockRef.read(productsStreamProvider)).thenReturn(
        AsyncValue.data([
          _makeProduct(
            variants: [ProductVariant(name: 'Large', stock: 7)],
          ),
        ]),
      );

      final useCase = GetLiveStockUseCase(mockRef);
      final result = useCase('prod-1', 'Large');

      expect(result, 7);
    });

    test('returns total stock for default variant', () {
      when(mockRef.read(productsStreamProvider)).thenReturn(
        AsyncValue.data([
          _makeProduct(
            variants: [
              ProductVariant(name: 'Large', stock: 10),
              ProductVariant(name: 'Small', stock: 5),
            ],
          ),
        ]),
      );

      final useCase = GetLiveStockUseCase(mockRef);
      final result = useCase('prod-1', 'default');

      expect(result, 15);
    });

    test('returns 0 when products are empty', () {
      when(mockRef.read(productsStreamProvider))
          .thenReturn(AsyncValue.data([]));

      final useCase = GetLiveStockUseCase(mockRef);
      final result = useCase('prod-1', 'Large');

      expect(result, 0);
    });

    test('returns 0 when products are null', () {
      when(mockRef.read(productsStreamProvider))
          .thenReturn(const AsyncLoading<List<ProductModel>>());

      final useCase = GetLiveStockUseCase(mockRef);
      final result = useCase('prod-1', 'Large');

      expect(result, 0);
    });

    test('throws when product not found', () {
      when(mockRef.read(productsStreamProvider)).thenReturn(
        AsyncValue.data([
          _makeProduct(id: 'prod-2'),
        ]),
      );

      final useCase = GetLiveStockUseCase(mockRef);

      expect(() => useCase('prod-1', 'Large'), throwsA(isA<String>()));
    });

    test('throws when variant not found', () {
      when(mockRef.read(productsStreamProvider)).thenReturn(
        AsyncValue.data([
          _makeProduct(
            variants: [ProductVariant(name: 'Large', stock: 10)],
          ),
        ]),
      );

      final useCase = GetLiveStockUseCase(mockRef);

      expect(() => useCase('prod-1', 'XL'), throwsA(isA<String>()));
    });
  });

  group('CartUseCases', () {
    late MockCartRepository mockRepository;
    late GetLiveStockUseCase getLiveStock;
    late CartUseCases useCases;

    setUp(() {
      mockRepository = MockCartRepository();
      when(mockRepository.watchCartItems(any))
          .thenAnswer((_) => Stream.value([]));

      getLiveStock = GetLiveStockUseCase(mockRef);
      useCases = CartUseCases(
        repository: mockRepository,
        getLiveStock: getLiveStock,
      );
    });

    group('getAvailableStock', () {
      test('delegates to GetLiveStockUseCase', () {
        when(mockRef.read(productsStreamProvider)).thenReturn(
          AsyncValue.data([
            _makeProduct(
              variants: [ProductVariant(name: 'Large', stock: 8)],
            ),
          ]),
        );

        final result = useCases.getAvailableStock('prod-1', 'Large');

        expect(result, 8);
      });
    });

    group('isStockAvailable', () {
      test('returns true when stock > 0', () {
        when(mockRef.read(productsStreamProvider)).thenReturn(
          AsyncValue.data([
            _makeProduct(
              variants: [ProductVariant(name: 'Large', stock: 5)],
            ),
          ]),
        );

        expect(useCases.isStockAvailable('prod-1', 'Large'), isTrue);
      });

      test('returns false when stock is 0', () {
        when(mockRef.read(productsStreamProvider)).thenReturn(
          AsyncValue.data([
            _makeProduct(
              variants: [ProductVariant(name: 'Large', stock: 0)],
            ),
          ]),
        );

        expect(useCases.isStockAvailable('prod-1', 'Large'), isFalse);
      });
    });

    group('clampQuantity', () {
      test('clamps to stock when quantity exceeds stock', () {
        when(mockRef.read(productsStreamProvider)).thenReturn(
          AsyncValue.data([
            _makeProduct(
              variants: [ProductVariant(name: 'Large', stock: 3)],
            ),
          ]),
        );

        final result = useCases.clampQuantity('prod-1', 'Large', 10);

        expect(result, 3);
      });

      test('returns quantity when within stock', () {
        when(mockRef.read(productsStreamProvider)).thenReturn(
          AsyncValue.data([
            _makeProduct(
              variants: [ProductVariant(name: 'Large', stock: 10)],
            ),
          ]),
        );

        final result = useCases.clampQuantity('prod-1', 'Large', 5);

        expect(result, 5);
      });

      test('returns quantity when stock is 0', () {
        when(mockRef.read(productsStreamProvider)).thenReturn(
          AsyncValue.data([
            _makeProduct(
              variants: [ProductVariant(name: 'Large', stock: 0)],
            ),
          ]),
        );

        final result = useCases.clampQuantity('prod-1', 'Large', 5);

        expect(result, 5);
      });
    });

    group('addItemToState', () {
      test('creates new item when not in state', () {
        final result = useCases.addItemToState(
          currentState: [],
          productId: 'prod-1',
          variantName: 'Large',
        );

        expect(result.productId, 'prod-1');
        expect(result.selectedVariant, 'Large');
        expect(result.quantity, 1);
      });

      test('increments quantity when item exists', () {
        final existingState = [
          const CartItemEntity(
            productId: 'prod-1',
            selectedVariant: 'Large',
            quantity: 3,
          ),
        ];

        final result = useCases.addItemToState(
          currentState: existingState,
          productId: 'prod-1',
          variantName: 'Large',
        );

        expect(result.quantity, 4);
      });
    });

    group('removeItemFromState', () {
      test('removes matching item', () {
        final state = [
          const CartItemEntity(
            productId: 'prod-1',
            selectedVariant: 'Large',
            quantity: 1,
          ),
          const CartItemEntity(
            productId: 'prod-2',
            selectedVariant: 'Small',
            quantity: 2,
          ),
        ];

        final result = useCases.removeItemFromState(
          currentState: state,
          productId: 'prod-1',
          variantName: 'Large',
        );

        expect(result.length, 1);
        expect(result[0].productId, 'prod-2');
      });

      test('returns empty list when all items removed', () {
        final state = [
          const CartItemEntity(
            productId: 'prod-1',
            selectedVariant: 'Large',
            quantity: 1,
          ),
        ];

        final result = useCases.removeItemFromState(
          currentState: state,
          productId: 'prod-1',
          variantName: 'Large',
        );

        expect(result, isEmpty);
      });
    });

    group('updateQuantityInState', () {
      test('updates quantity for matching item', () {
        final state = [
          const CartItemEntity(
            productId: 'prod-1',
            selectedVariant: 'Large',
            quantity: 1,
          ),
        ];

        final result = useCases.updateQuantityInState(
          currentState: state,
          productId: 'prod-1',
          variantName: 'Large',
          quantity: 5,
        );

        expect(result[0].quantity, 5);
      });

      test('leaves other items unchanged', () {
        final state = [
          const CartItemEntity(
            productId: 'prod-1',
            selectedVariant: 'Large',
            quantity: 1,
          ),
          const CartItemEntity(
            productId: 'prod-2',
            selectedVariant: 'Small',
            quantity: 3,
          ),
        ];

        final result = useCases.updateQuantityInState(
          currentState: state,
          productId: 'prod-1',
          variantName: 'Large',
          quantity: 5,
        );

        expect(result[0].quantity, 5);
        expect(result[1].quantity, 3);
      });
    });

    group('buildItemId', () {
      test('creates ID with :: separator', () {
        final result = useCases.buildItemId('prod-1', 'Large');

        expect(result, 'prod-1::Large');
      });

      test('handles variant name with underscores', () {
        final result = useCases.buildItemId('prod-1', 'Large_Red');

        expect(result, 'prod-1::Large_Red');
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nibq/core/models/cart_item_model.dart';
import 'package:nibq/core/models/product_model.dart';
import 'package:nibq/features/checkout/usecases/validate_checkout_usecase.dart';

void main() {
  ProductModel _makeProduct({
    String id = 'prod-1',
    String name = 'Test Product',
    String category = 'Test',
    double price = 100.0,
    List<ProductVariant> variants = const [
      ProductVariant(name: 'Large', stock: 10),
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

  group('ValidateCheckoutUseCase', () {
    test('passes when cart has valid items with sufficient stock', () {
      final products = [
        _makeProduct(
          id: 'prod-1',
          price: 100.0,
          variants: [ProductVariant(name: 'Large', stock: 10)],
        ),
      ];
      final cartItems = [
        CartItem(
          product: products[0],
          selectedVariant: 'Large',
          quantity: 2,
        ),
      ];

      final useCase = ValidateCheckoutUseCase(getProducts: () => products);

      expect(() => useCase(cartItems), returnsNormally);
    });

    test('passes when cart has items with default variant', () {
      final products = [
        _makeProduct(
          id: 'prod-1',
          price: 100.0,
          variants: [
            ProductVariant(name: 'Large', stock: 5),
            ProductVariant(name: 'Small', stock: 5),
          ],
        ),
      ];
      final cartItems = [
        CartItem(
          product: products[0],
          selectedVariant: 'default',
          quantity: 3,
        ),
      ];

      final useCase = ValidateCheckoutUseCase(getProducts: () => products);

      expect(() => useCase(cartItems), returnsNormally);
    });

    test('throws when cart is empty', () {
      final useCase = ValidateCheckoutUseCase(getProducts: () => []);

      expect(
        () => useCase([]),
        throwsA(isA<CheckoutValidationError>().having(
          (e) => e.message,
          'message',
          contains('السلة فارغة'),
        )),
      );
    });

    test('throws when products list is empty', () {
      final cartItems = [
        CartItem(
          product: _makeProduct(id: 'prod-1', price: 100.0),
          selectedVariant: 'Large',
          quantity: 1,
        ),
      ];

      final useCase = ValidateCheckoutUseCase(getProducts: () => []);

      expect(
        () => useCase(cartItems),
        throwsA(isA<CheckoutValidationError>().having(
          (e) => e.message,
          'message',
          contains('المنتجات غير متاحة'),
        )),
      );
    });

    test('throws when product is deleted from catalog', () {
      final cartItems = [
        CartItem(
          product: _makeProduct(id: 'prod-1', name: 'Deleted Product'),
          selectedVariant: 'Large',
          quantity: 1,
        ),
      ];

      final useCase = ValidateCheckoutUseCase(
        getProducts: () => [
          _makeProduct(id: 'prod-2', name: 'Other Product'),
        ],
      );

      expect(
        () => useCase(cartItems),
        throwsA(isA<CheckoutValidationError>().having(
          (e) => e.message,
          'message',
          contains('لم يعد متوفراً'),
        )),
      );
    });

    test('throws when product price changed (higher)', () {
      final cartProduct = _makeProduct(
        id: 'prod-1',
        price: 100.0,
        variants: [ProductVariant(name: 'Large', stock: 10)],
      );
      final currentProduct = _makeProduct(
        id: 'prod-1',
        price: 120.0,
        variants: [ProductVariant(name: 'Large', stock: 10)],
      );
      final cartItems = [
        CartItem(
          product: cartProduct,
          selectedVariant: 'Large',
          quantity: 1,
        ),
      ];

      final useCase = ValidateCheckoutUseCase(
        getProducts: () => [currentProduct],
      );

      expect(
        () => useCase(cartItems),
        throwsA(isA<CheckoutValidationError>().having(
          (e) => e.message,
          'message',
          contains('تغير'),
        )),
      );
    });

    test('throws when product price changed (lower)', () {
      final cartProduct = _makeProduct(
        id: 'prod-1',
        price: 100.0,
        variants: [ProductVariant(name: 'Large', stock: 10)],
      );
      final currentProduct = _makeProduct(
        id: 'prod-1',
        price: 80.0,
        variants: [ProductVariant(name: 'Large', stock: 10)],
      );
      final cartItems = [
        CartItem(
          product: cartProduct,
          selectedVariant: 'Large',
          quantity: 1,
        ),
      ];

      final useCase = ValidateCheckoutUseCase(
        getProducts: () => [currentProduct],
      );

      expect(
        () => useCase(cartItems),
        throwsA(isA<CheckoutValidationError>().having(
          (e) => e.message,
          'message',
          contains('تغير'),
        )),
      );
    });

    test('passes when price difference is negligible (rounding)', () {
      final cartProduct = _makeProduct(
        id: 'prod-1',
        price: 100.005,
        variants: [ProductVariant(name: 'Large', stock: 10)],
      );
      final currentProduct = _makeProduct(
        id: 'prod-1',
        price: 100.0,
        variants: [ProductVariant(name: 'Large', stock: 10)],
      );
      final cartItems = [
        CartItem(
          product: cartProduct,
          selectedVariant: 'Large',
          quantity: 1,
        ),
      ];

      final useCase = ValidateCheckoutUseCase(
        getProducts: () => [currentProduct],
      );

      expect(() => useCase(cartItems), returnsNormally);
    });

    test('throws when stock insufficient for specific variant', () {
      final products = [
        _makeProduct(
          id: 'prod-1',
          price: 100.0,
          variants: [ProductVariant(name: 'Large', stock: 2)],
        ),
      ];
      final cartItems = [
        CartItem(
          product: products[0],
          selectedVariant: 'Large',
          quantity: 5,
        ),
      ];

      final useCase = ValidateCheckoutUseCase(getProducts: () => products);

      expect(
        () => useCase(cartItems),
        throwsA(isA<CheckoutValidationError>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('غير كافية'),
            contains('2'),
          ),
        )),
      );
    });

    test('throws when stock insufficient for default variant', () {
      final products = [
        _makeProduct(
          id: 'prod-1',
          price: 100.0,
          variants: [
            ProductVariant(name: 'Large', stock: 1),
            ProductVariant(name: 'Small', stock: 1),
          ],
        ),
      ];
      final cartItems = [
        CartItem(
          product: products[0],
          selectedVariant: 'default',
          quantity: 5,
        ),
      ];

      final useCase = ValidateCheckoutUseCase(getProducts: () => products);

      expect(
        () => useCase(cartItems),
        throwsA(isA<CheckoutValidationError>().having(
          (e) => e.message,
          'message',
          contains('غير كافية'),
        )),
      );
    });

    test('throws when variant no longer exists', () {
      final cartProduct = _makeProduct(
        id: 'prod-1',
        price: 100.0,
        variants: [ProductVariant(name: 'XL', stock: 10)],
      );
      final currentProduct = _makeProduct(
        id: 'prod-1',
        price: 100.0,
        variants: [ProductVariant(name: 'Large', stock: 10)],
      );
      final cartItems = [
        CartItem(
          product: cartProduct,
          selectedVariant: 'XL',
          quantity: 1,
        ),
      ];

      final useCase = ValidateCheckoutUseCase(
        getProducts: () => [currentProduct],
      );

      expect(
        () => useCase(cartItems),
        throwsA(isA<CheckoutValidationError>().having(
          (e) => e.message,
          'message',
          contains('لم يعد متوفراً'),
        )),
      );
    });

    test('validates multiple cart items', () {
      final products = [
        _makeProduct(
          id: 'prod-1',
          price: 100.0,
          variants: [ProductVariant(name: 'Large', stock: 5)],
        ),
        _makeProduct(
          id: 'prod-2',
          price: 50.0,
          variants: [ProductVariant(name: 'Red', stock: 3)],
        ),
      ];
      final cartItems = [
        CartItem(
          product: products[0],
          selectedVariant: 'Large',
          quantity: 2,
        ),
        CartItem(
          product: products[1],
          selectedVariant: 'Red',
          quantity: 1,
        ),
      ];

      final useCase = ValidateCheckoutUseCase(getProducts: () => products);

      expect(() => useCase(cartItems), returnsNormally);
    });

    test('throws on first invalid item when multiple items in cart', () {
      final cartProducts = [
        _makeProduct(
          id: 'prod-1',
          price: 100.0,
          variants: [ProductVariant(name: 'Large', stock: 5)],
        ),
        _makeProduct(
          id: 'prod-2',
          price: 50.0,
          variants: [ProductVariant(name: 'Red', stock: 10)],
        ),
      ];
      final currentProducts = [
        _makeProduct(
          id: 'prod-1',
          price: 100.0,
          variants: [ProductVariant(name: 'Large', stock: 5)],
        ),
        _makeProduct(
          id: 'prod-2',
          price: 75.0,
          variants: [ProductVariant(name: 'Red', stock: 10)],
        ),
      ];
      final cartItems = [
        CartItem(
          product: cartProducts[0],
          selectedVariant: 'Large',
          quantity: 2,
        ),
        CartItem(
          product: cartProducts[1],
          selectedVariant: 'Red',
          quantity: 1,
        ),
      ];

      final useCase = ValidateCheckoutUseCase(
        getProducts: () => currentProducts,
      );

      expect(
        () => useCase(cartItems),
        throwsA(isA<CheckoutValidationError>().having(
          (e) => e.message,
          'message',
          contains('تغير'),
        )),
      );
    });
  });
}

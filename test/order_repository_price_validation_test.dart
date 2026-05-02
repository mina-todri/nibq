// test/order_repository_price_validation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nibq/core/models/order_model.dart';
import 'package:nibq/core/services/order_repository.dart';

void main() {
  group('OrderRepository Price Validation', () {
    group('_getExpectedPrice', () {
      test('returns base product price when no variant selected', () {
        final productData = <String, dynamic>{
          'id': 'prod_1',
          'name': 'Book',
          'price': 50,
          'variants': <dynamic>[],
        };

        final price = OrderRepository.getExpectedPrice(productData, [], '');
        expect(price, 50.0);
      });

      test('returns base product price when variant is "default"', () {
        final productData = <String, dynamic>{
          'id': 'prod_1',
          'name': 'Book',
          'price': 75.5,
          'variants': [
            {'name': 'default', 'stock': 10},
          ],
        };

        final price = OrderRepository.getExpectedPrice(
          productData,
          productData['variants'],
          'default',
        );
        expect(price, 75.5);
      });

      test('returns variant price when variant has its own price', () {
        final productData = <String, dynamic>{
          'id': 'prod_1',
          'name': 'Shirt',
          'price': 100,
          'variants': [
            {'name': 'XL', 'price': 150, 'stock': 5},
            {'name': 'M', 'price': 120, 'stock': 10},
          ],
        };

        final priceXL = OrderRepository.getExpectedPrice(
          productData,
          productData['variants'],
          'XL',
        );
        expect(priceXL, 150.0);

        final priceM = OrderRepository.getExpectedPrice(
          productData,
          productData['variants'],
          'M',
        );
        expect(priceM, 120.0);
      });

      test('falls back to base price when variant has no price field', () {
        final productData = <String, dynamic>{
          'id': 'prod_1',
          'name': 'Shirt',
          'price': 100,
          'variants': [
            {'name': 'M', 'stock': 10},
          ],
        };

        final price = OrderRepository.getExpectedPrice(
          productData,
          productData['variants'],
          'M',
        );
        expect(price, 100.0);
      });

      test('falls back to base price when variant not found', () {
        final productData = <String, dynamic>{
          'id': 'prod_1',
          'name': 'Shirt',
          'price': 100,
          'variants': [
            {'name': 'M', 'stock': 10},
          ],
        };

        final price = OrderRepository.getExpectedPrice(
          productData,
          productData['variants'],
          'XL',
        );
        expect(price, 100.0);
      });

      test('returns 0 when product has no price field', () {
        final productData = <String, dynamic>{
          'id': 'prod_1',
          'name': 'Free Item',
          'variants': <dynamic>[],
        };

        final price = OrderRepository.getExpectedPrice(productData, [], '');
        expect(price, 0.0);
      });
    });

    group('_validateItemPrice', () {
      test('throws when client price is much lower than Firestore price', () {
        final productData = <String, dynamic>{
          'id': 'prod_1',
          'name': 'Watch',
          'price': 500,
          'variants': [
            {'name': 'Black', 'price': 500, 'stock': 10},
          ],
        };

        final item = OrderItemModel(
          productId: 'prod_1',
          name: 'Watch',
          category: 'Electronics',
          price: 50.0, // Manipulated price
          selectedVariant: 'Black',
          quantity: 1,
        );

        expect(
          () => OrderRepository.validateItemPrice(productData, item),
          throwsA(isA<Exception>()),
        );
      });

      test('throws when client price is higher than Firestore price', () {
        final productData = <String, dynamic>{
          'id': 'prod_1',
          'name': 'Watch',
          'price': 100,
          'variants': <dynamic>[],
        };

        final item = OrderItemModel(
          productId: 'prod_1',
          name: 'Watch',
          category: 'Electronics',
          price: 999.0, // Inflated price
          selectedVariant: '',
          quantity: 1,
        );

        expect(
          () => OrderRepository.validateItemPrice(productData, item),
          throwsA(isA<Exception>()),
        );
      });

      test('passes when price matches exactly', () {
        final productData = <String, dynamic>{
          'id': 'prod_1',
          'name': 'Book',
          'price': 99.5,
          'variants': <dynamic>[],
        };

        final item = OrderItemModel(
          productId: 'prod_1',
          name: 'Book',
          category: 'Books',
          price: 99.5,
          selectedVariant: '',
          quantity: 1,
        );

        expect(
          () => OrderRepository.validateItemPrice(productData, item),
          returnsNormally,
        );
      });

      test('passes when price difference is within tolerance (0.5)', () {
        final productData = <String, dynamic>{
          'id': 'prod_1',
          'name': 'Book',
          'price': 100.0,
          'variants': <dynamic>[],
        };

        final item = OrderItemModel(
          productId: 'prod_1',
          name: 'Book',
          category: 'Books',
          price: 100.4, // Within 0.5 tolerance
          selectedVariant: '',
          quantity: 1,
        );

        expect(
          () => OrderRepository.validateItemPrice(productData, item),
          returnsNormally,
        );
      });

      test('throws when price difference exceeds tolerance', () {
        final productData = <String, dynamic>{
          'id': 'prod_1',
          'name': 'Book',
          'price': 100.0,
          'variants': <dynamic>[],
        };

        final item = OrderItemModel(
          productId: 'prod_1',
          name: 'Book',
          category: 'Books',
          price: 100.6, // Exceeds 0.5 tolerance
          selectedVariant: '',
          quantity: 1,
        );

        expect(
          () => OrderRepository.validateItemPrice(productData, item),
          throwsA(isA<Exception>()),
        );
      });

      test('validates against variant price when variant selected', () {
        final productData = <String, dynamic>{
          'id': 'prod_1',
          'name': 'Shirt',
          'price': 100,
          'variants': [
            {'name': 'XL', 'price': 150, 'stock': 5},
          ],
        };

        final itemCorrect = OrderItemModel(
          productId: 'prod_1',
          name: 'Shirt',
          category: 'Clothing',
          price: 150.0, // Matches variant price
          selectedVariant: 'XL',
          quantity: 1,
        );

        expect(
          () => OrderRepository.validateItemPrice(productData, itemCorrect),
          returnsNormally,
        );

        final itemWrong = OrderItemModel(
          productId: 'prod_1',
          name: 'Shirt',
          category: 'Clothing',
          price: 100.0, // Uses base price, not variant price
          selectedVariant: 'XL',
          quantity: 1,
        );

        expect(
          () => OrderRepository.validateItemPrice(productData, itemWrong),
          throwsA(isA<Exception>()),
        );
      });

      test('throws with Arabic error message mentioning product name', () {
        final productData = <String, dynamic>{
          'id': 'prod_1',
          'name': 'ساعة ذكية',
          'price': 500,
          'variants': <dynamic>[],
        };

        final item = OrderItemModel(
          productId: 'prod_1',
          name: 'ساعة ذكية',
          category: 'إلكترونيات',
          price: 50.0,
          selectedVariant: '',
          quantity: 1,
        );

        expect(
          () => OrderRepository.validateItemPrice(productData, item),
          throwsA(isA<Exception>()
              .having(
                (e) => e.toString(),
                'message',
                contains('سعر'),
              )
              .having(
                (e) => e.toString(),
                'product name',
                contains('ساعة ذكية'),
              )),
        );
      });
    });
  });
}

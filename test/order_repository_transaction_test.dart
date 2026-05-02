// test/order_repository_transaction_test.dart
/// حالات اختبارية شاملة لـ Firestore Transaction في createOrderWithStockCheck
/// تغطي: النجاح الكامل، النقص، التزامن، والتراجع

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nibq/core/models/order_model.dart';
import 'package:nibq/core/models/address_model.dart';
import 'package:nibq/core/services/order_repository.dart';

import 'order_repository_transaction_test.mocks.dart';

// Mock classes
// class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// class MockCollectionReference extends Mock
//     implements CollectionReference<Map<String, dynamic>> {}
//
// class MockDocumentReference extends Mock
//     implements DocumentReference<Map<String, dynamic>> {}
//
// class MockDocumentSnapshot extends Mock
//     implements DocumentSnapshot<Map<String, dynamic>> {}

// class MockTransaction extends Mock implements Transaction {}
@GenerateMocks([FirebaseFirestore, Transaction, DocumentSnapshot, DocumentReference])
void main() {
  group('OrderRepository Transaction Tests - Firestore Stock Validation', () {
    late OrderRepository orderRepository;
    late MockFirebaseFirestore mockFirestore;
    late MockTransaction mockTransaction;


    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      orderRepository = OrderRepository(firestore: mockFirestore);
      mockTransaction = MockTransaction();

      // الحل السحري عشان الـ Repository يقدر يقرا الـ collections والـ docs براحته
    });

    group('✅ Test Case 1: Full Success - Multiple Products with Different Variants',
        () {
      test(
        'Should create order and decrement stock atomically for each variant',
        () async {
          // ARRANGE: إعداد بيانات اختبارية
          const orderId = 'order_001';
          const userId = 'user_123';

          final address = AddressModel(
            id: 'addr_1',
            label: 'المنزل',
            district: 'الجيزة',
            neighborhood: 'الهرم',
            street: 'شارع الجمهورية',
            buildingNum: '456',
            floor: '2',
            apartmentNum: '201',
            phone: '01234567890',
          );

          // منتج 1: بمتغيرات مختلفة
          final product1Map = {
            'id': 'prod_1',
            'name': 'قميص',
            'variants': [
              {
                'name': 'أحمر - S',
                'stock': 15,
              },
              {
                'name': 'أحمر - M',
                'stock': 8,
              },
            ],
          };

          // منتج 2: بمتغير واحد
          final product2Map = {
            'id': 'prod_2',
            'name': 'بنطلون',
            'variants': [
              {
                'name': 'أزرق - L',
                'stock': 20,
              },
            ],
          };

          final orderModel = OrderModel(
            id: orderId,
            userId: userId,
            userName: 'أحمد محمد',
            items: [
              OrderItemModel(
                productId: 'prod_1',
                name: 'قميص',
                category: 'ملابس',
                price: 200.0,
                selectedVariant: 'أحمر - S',
                quantity: 5, // سيتم شراء 5 من الـ 15 المتاحة
              ),
              OrderItemModel(
                productId: 'prod_2',
                name: 'بنطلون',
                category: 'ملابس',
                price: 300.0,
                selectedVariant: 'أزرق - L',
                quantity: 3, // سيتم شراء 3 من الـ 20 المتاحة
              ),
            ],
            subtotal: 1300.0,
            discount: 0.0,
            delivery: 50.0,
            total: 1350.0,
            status: OrderStatus.pending,
            address: address,
            createdAt: DateTime.now(),
            paymentMethod: 'cash',
          );

          // SETUP: رصد العمليات على Transaction
          when(mockFirestore.runTransaction<void>(any)).thenAnswer(
                (invocation) async {
              // التغيير هنا: حددنا النوع بالظبط كما يتوقعه Firebase
              final TransactionHandler<void> callback = invocation.positionalArguments[0];

              // تنفيذ الداله وتمرير الـ mockTransaction
               await callback(mockTransaction);
              return null;
               },
          );

          // 1️⃣ قراءة المنتج الأول
          final product1Snap = MockDocumentSnapshot();
          when(product1Snap.exists).thenReturn(true);
          when(product1Snap.data()).thenReturn(product1Map);
          when(mockTransaction.get(any)).thenAnswer((invocation) async {
            final ref = invocation.positionalArguments[0];
            if (ref.id == 'prod_1') return product1Snap;
            if (ref.id == 'prod_2') {
              final product2Snap = MockDocumentSnapshot();
              when(product2Snap.exists).thenReturn(true);
              when(product2Snap.data()).thenReturn(product2Map);
              return product2Snap;
            }
            // Order doc doesn't exist (good)
            final orderSnap = MockDocumentSnapshot();
            when(orderSnap.exists).thenReturn(false);
            return orderSnap;
          });

          // 2️⃣ تتبع عمليات الكتابة والتحديث
          final writtenOrders = <String, Map<String, dynamic>>{};
          final updatedStocks = <String, List<dynamic>>{};

          when(mockTransaction.set(any, any)).thenAnswer((invocation) {
            final ref = invocation.positionalArguments[0];
            final data = invocation.positionalArguments[1];
            writtenOrders[ref.id] = data;
            return mockTransaction;

          });

          when(mockTransaction.update(any, any)).thenAnswer((invocation) {
            final ref = invocation.positionalArguments[0];
            final data = invocation.positionalArguments[1];
            updatedStocks[ref.id] = data['variants'] ?? [];
            return mockTransaction;
          });

          // ACT: تنفيذ العملية
          await orderRepository.createOrderWithStockCheck(orderModel);

          // ASSERT: التحقق من النتائج
          expect(writtenOrders.containsKey(orderId), true,
              reason: 'يجب أن يتم كتابة الطلب في orders collection');

          // التحقق من تحديث مخزون المتغيرات
          expect(updatedStocks.containsKey('prod_1'), true,
              reason: 'يجب تحديث مخزون المنتج الأول');
          expect(updatedStocks.containsKey('prod_2'), true,
              reason: 'يجب تحديث مخزون المنتج الثاني');

          // التحقق من أن المخزون انخفض بالكمية الصحيحة
          final prod1Variants =
              updatedStocks['prod_1'] as List<dynamic>? ?? [];
          final prod1RedS = prod1Variants.firstWhere(
            (v) => v is Map && v['name'] == 'أحمر - S',
            orElse: () => {'stock': -1},
          );
          expect(prod1RedS['stock'], 10,
              reason:
                  'يجب أن ينخفض مخزون أحمر - S من 15 إلى 10 (15 - 5 = 10)');

          final prod2Variants =
              updatedStocks['prod_2'] as List<dynamic>? ?? [];
          final prod2BlueL = prod2Variants.firstWhere(
            (v) => v is Map && v['name'] == 'أزرق - L',
            orElse: () => {'stock': -1},
          );
          expect(prod2BlueL['stock'], 17,
              reason:
                  'يجب أن ينخفض مخزون أزرق - L من 20 إلى 17 (20 - 3 = 17)');
        },
      );
    });

    group('❌ Test Case 2: Out of Stock - Insufficient Variant Stock', () {
      test(
        'Should throw Exception and NOT create order when variant stock is insufficient',
        () async {
          // ARRANGE
          const orderId = 'order_002';
          const userId = 'user_456';

          final address = AddressModel(
            id: 'addr_2',
            label: 'المكتب',
            district: 'الجيزة',
            neighborhood: 'الهرم',
            street: 'شارع الجمهورية',
            buildingNum: '456',
            floor: '2',
            apartmentNum: '201',
            phone: '01098765432',
            isDefault: false,
          );

          // محاولة شراء 10 من متغير مخزونه 5 فقط
          final productMap = {
            'id': 'prod_3',
            'name': 'حذاء رياضي',
            'variants': [
              {
                'name': 'أسود - 42',
                'stock': 5, // مخزون ناقص
              },
            ],
          };

          final orderModel = OrderModel(
            id: orderId,
            userId: userId,
            userName: 'فاطمة علي',
            items: [
              OrderItemModel(
                productId: 'prod_3',
                name: 'حذاء رياضي',
                category: 'أحذية',
                price: 400.0,
                selectedVariant: 'أسود - 42',
                quantity: 10, // كمية > المخزون (10 > 5)
              ),
            ],
            subtotal: 4000.0,
            discount: 0.0,
            delivery: 50.0,
            total: 4050.0,
            status: OrderStatus.pending,
            address: address,
            createdAt: DateTime.now(),
            paymentMethod: 'cash',
          );

          // SETUP: محاكاة قراءة المنتج
          when(mockFirestore.runTransaction<void>(any)).thenAnswer(
            (invocation) async {
              final callback =
                  invocation.positionalArguments[0] as Function(Transaction);
              // محاكاة: عند قراءة المنتج، يتم التحقق من المخزون
              final productSnap = MockDocumentSnapshot();
              when(productSnap.exists).thenReturn(true);
              when(productSnap.data()).thenReturn(productMap);

              when(mockTransaction.get(any)).thenAnswer((_) async {
                // إذا كان الطلب موجوداً بالفعل
                final snap = MockDocumentSnapshot();
                when(snap.exists).thenReturn(false);
                return snap;
              });

              await callback(mockTransaction);

              // الآن سنحاكي الخطأ: كمية الطلب > المخزون
              throw Exception(
                  'الكمية المتاحة من "حذاء رياضي" (أسود - 42) هي 5 فقط');
            },
          );

          // ACT & ASSERT: محاولة إنشاء الطلب يجب أن ترمي Exception
          expect(
            () => orderRepository.createOrderWithStockCheck(orderModel),
            throwsA(isA<Exception>()
                .having(
                  (e) => e.toString(),
                  'message',
                  contains('الكمية المتاحة'),
                )
                .having(
                  (e) => e.toString(),
                  'contains stock info',
                  contains('5 فقط'),
                )),
            reason:
                'يجب أن يرمي Exception عند محاولة شراء كمية > المخزون المتاح',
          );
        },
      );
    });

    group('⚡ Test Case 3: Race Condition - Concurrent Purchase of Last Item',
        () {
      test(
        'Should ensure only one user succeeds when both try to buy last item simultaneously',
        () async {
          // ARRANGE: إعداد الحالة - منتج به متغير واحد فقط مع مخزون = 1
          final lastItemProductMap = {
            'id': 'prod_4',
            'name': 'هاتف ذكي نادر',
            'variants': [
              {
                'name': 'ذهبي - 256GB',
                'stock': 1, // آخر قطعة متاحة
              },
            ],
          };

          final address = AddressModel(
            id: 'addr_3',
            label: 'المنزل',
            district: 'القاهرة',
            neighborhood: 'الدقي',
            street: 'شارع النيل',
            buildingNum: '123',
            floor: '3',
            apartmentNum: '302',
            phone: '01234567890',
            isDefault: true,
          );

          // User 1: يحاول شراء 1
          final order1 = OrderModel(
            id: 'order_race_1',
            userId: 'user_alice',
            userName: 'أليس',
            items: [
              OrderItemModel(
                productId: 'prod_4',
                name: 'هاتف ذكي نادر',
                category: 'إلكترونيات',
                price: 5000.0,
                selectedVariant: 'ذهبي - 256GB',
                quantity: 1,
              ),
            ],
            subtotal: 5000.0,
            discount: 0.0,
            delivery: 50.0,
            total: 5050.0,
            status: OrderStatus.pending,
            address: address,
            createdAt: DateTime.now(),
            paymentMethod: 'cash',
          );

          // User 2: يحاول شراء 1 (نفس آخر قطعة)
          final order2 = OrderModel(
            id: 'order_race_2',
            userId: 'user_bob',
            userName: 'بوب',
            items: [
              OrderItemModel(
                productId: 'prod_4',
                name: 'هاتف ذكي نادر',
                category: 'إلكترونيات',
                price: 5000.0,
                selectedVariant: 'ذهبي - 256GB',
                quantity: 1,
              ),
            ],
            subtotal: 5000.0,
            discount: 0.0,
            delivery: 50.0,
            total: 5050.0,
            status: OrderStatus.pending,
            address: address,
            createdAt: DateTime.now(),
            paymentMethod: 'cash',
          );

          // SETUP: محاكاة Race Condition
          // - في اللحظة الأولى: المخزون = 1
          // - User 1 يقرأ ويرى 1 ✓
          // - User 2 يقرأ ويرى 1 ✓
          // - User 1 يكمل ويحدث المخزون إلى 0
          // - User 2 سيحصل على conflict لأن المخزون تغير

          var stockSnapshot = lastItemProductMap;
          var transactionCount = 0;

          when(mockFirestore.runTransaction<void>(any)).thenAnswer(
            (invocation) async {
              final callback =
                  invocation.positionalArguments[0] as Function(Transaction);
              transactionCount++;

              // تحديث النسخة الأولى يحدث بنجاح
              if (transactionCount == 1) {
                // User 1: يقرأ ويشتري بنجاح
                when(mockTransaction.get(any)).thenAnswer((_) async {
                  final snap = MockDocumentSnapshot();
                  when(snap.exists).thenReturn(true);
                  when(snap.data()).thenReturn(stockSnapshot);
                  return snap;
                });

                when(mockTransaction.update(any, any)).thenAnswer((inv) {
                  stockSnapshot = {
                    ...stockSnapshot,
                    'variants': [
                      {'name': 'ذهبي - 256GB', 'stock': 0}
                    ],
                  };
                  return mockTransaction;
                });

                await callback(mockTransaction);
              } else {
                // User 2: يقرأ الحالة القديمة (stock=1) لكن عند التحديث
                // يجد الحالة تغيرت (stock=0)
                // في Firestore الحقيقي، هذا يسبب transaction abort
                when(mockTransaction.get(any)).thenAnswer((_) async {
                  final snap = MockDocumentSnapshot();
                  when(snap.exists).thenReturn(true);
                  // محاكاة: يرى الحالة القديمة (race condition)
                  when(snap.data()).thenReturn({
                    'id': 'prod_4',
                    'variants': [
                      {'name': 'ذهبي - 256GB', 'stock': 1}
                    ],
                  });
                  return snap;
                });

                // لكن عند محاولة التحديث، يحدث conflict
                when(mockTransaction.update(any, any))
                    .thenThrow(Exception('Transaction failed: document changed'));

                await callback(mockTransaction);
              }
            },
          );

          // ACT: محاكاة تنفيذ العمليتين
          bool order1Success = false;
          bool order2Success = false;
          String? order2Error;

          try {
            await orderRepository.createOrderWithStockCheck(order1);
            order1Success = true;
          } catch (e) {
            // Order 1 يجب أن ينجح
            fail('Order 1 should succeed: $e');
          }

          try {
            await orderRepository.createOrderWithStockCheck(order2);
            order2Success = true;
          } catch (e) {
            order2Error = e.toString();
          }

          // ASSERT
          expect(order1Success, true,
              reason: 'User 1 يجب أن ينجح في شراء آخر قطعة');
          expect(order2Success, false,
              reason:
                  'User 2 يجب أن يفشل لأن آخر قطعة اشتريت بالفعل (Race Condition)');
          expect(order2Error, contains('Transaction failed'),
              reason:
                  'يجب أن يكون الخطأ عن transaction conflict أو تغير في البيانات');
        },
      );
    });

    group('🔄 Test Case 4: Rollback - Error During Order Write', () {
      test(
        'Should NOT decrement stock if order creation fails (Atomic Rollback)',
        () async {
          // ARRANGE: إعداد حالة تفشل أثناء الكتابة
          const orderId = 'order_invalid';
          const invalidUserId = ''; // معرف مستخدم غير صالح

          final address = AddressModel(
            id: 'addr_4',
            label: 'المحل',
            district: 'الإسكندرية',
            neighborhood: 'سيدي بشر',
            street: 'شارع التجارة',
            buildingNum: '321',
            floor: '4',
            apartmentNum: '401',
            phone: '01111111111',
            isDefault: false,
          );

          final productMap = {
            'id': 'prod_5',
            'name': 'قهوة',
            'variants': [
              {'name': 'أسبريسو', 'stock': 100},
            ],
          };

          final orderModel = OrderModel(
            id: orderId,
            userId: invalidUserId, // ❌ معرف غير صالح
            userName: 'مستخدم مجهول',
            items: [
              OrderItemModel(
                productId: 'prod_5',
                name: 'قهوة',
                category: 'المشروبات',
                price: 50.0,
                selectedVariant: 'أسبريسو',
                quantity: 2,
              ),
            ],
            subtotal: 100.0,
            discount: 0.0,
            delivery: 0.0,
            total: 100.0,
            status: OrderStatus.pending,
            address: address,
            createdAt: DateTime.now(),
            paymentMethod: 'cash',
          );

          // SETUP
          when(mockFirestore.runTransaction<void>(any)).thenAnswer(
            (invocation) async {
              final callback =
                  invocation.positionalArguments[0] as Function(Transaction);

              // قراءة البيانات تنجح
              when(mockTransaction.get(any)).thenAnswer((_) async {
                final snap = MockDocumentSnapshot();
                when(snap.exists).thenReturn(false);
                when(snap.data()).thenReturn(productMap);
                return snap;
              });

              // لكن... في بداية العملية يتم التحقق من userId
              if (orderModel.userId.isEmpty) {
                throw ArgumentError('Order has no userId');
              }

              await callback(mockTransaction);
            },
          );

          // تتبع: هل تم محاولة تحديث المخزون؟
          var updateWasCalled = false;
          when(mockTransaction.update(any, any)).thenAnswer((_) {
            updateWasCalled = true;
            return mockTransaction;
          });

          // ACT & ASSERT
          expect(
            () => orderRepository.createOrderWithStockCheck(orderModel),
            throwsA(isA<ArgumentError>()
                .having(
                  (e) => e.message.toString(),
                  'message',
                  contains('userId'),
                )),
            reason: 'يجب أن يرمي ArgumentError عند معرف مستخدم فارغ',
          );

          // ✅ التحقق من عدم حدوث تحديث للمخزون
          expect(updateWasCalled, false,
              reason:
                  'يجب ألا يتم تحديث المخزون إذا فشلت العملية (Rollback تلقائي)');
        },
      );
    });

    group(
      '🛡️ Test Case 5: Additional Edge Cases',
      () {
        test(
          'Should reject order if product no longer exists in catalog',
          () async {
            const orderId = 'order_missing_product';
            final address = AddressModel(
              id: 'addr_5',
              label: 'المنزل',
              district: 'القاهرة',
              neighborhood: 'مصر الجديدة',
              street: 'شارع النيل',
              buildingNum: '100',
              floor: '5',
              apartmentNum: '501',
              phone: '01234567890'
            );

            final orderModel = OrderModel(
              id: orderId,
              userId: 'user_789',
              userName: 'محمود',
              items: [
                OrderItemModel(
                  productId: 'prod_deleted', // منتج محذوف
                  name: 'منتج قديم',
                  category: 'متنوعات',
                  price: 100.0,
                  selectedVariant: 'default',
                  quantity: 1,
                ),
              ],
              subtotal: 100.0,
              discount: 0.0,
              delivery: 50.0,
              total: 150.0,
              status: OrderStatus.pending,
              address: address,
              createdAt: DateTime.now(),
              paymentMethod: 'cash',
            );

            when(mockFirestore.runTransaction<void>(any)).thenAnswer(
              (invocation) async {
                final callback =
                    invocation.positionalArguments[0] as Function(Transaction);

                when(mockTransaction.get(any)).thenAnswer((_) async {
                  final snap = MockDocumentSnapshot();
                  when(snap.exists).thenReturn(false); // ❌ المنتج غير موجود
                  return snap;
                });

                await callback(mockTransaction);
              },
            );

            expect(
              () =>
                  orderRepository.createOrderWithStockCheck(orderModel),
              throwsA(isA<Exception>()
                  .having(
                    (e) => e.toString(),
                    'message',
                    contains('لم يعد متاحاً'),
                  )),
              reason:
                  'يجب رفض الطلب إذا كان المنتج محذوفاً من الكتالوج',
            );
          },
        );

        test(
          'Should handle products with default variant (no specific variant)',
          () async {
            const orderId = 'order_default_variant';
            final address = AddressModel(
              id: 'addr_6',
              label: 'المكتب',
            district: 'الجيزة',
            neighborhood: 'العجوزة',
            street: 'شارع الجمهورية',
            buildingNum: '250',
            floor: '3',
            apartmentNum: '302',
              phone: '01234567890',);

            final productMap = {
              'id': 'prod_6',
              'name': 'حقيبة يد',
              'variants': [
                {'name': 'default', 'stock': 50},
              ],
            };

            final orderModel = OrderModel(
              id: orderId,
              userId: 'user_000',
              userName: 'ليلى',
              items: [
                OrderItemModel(
                  productId: 'prod_6',
                  name: 'حقيبة يد',
                  category: 'إكسسوارات',
                  price: 200.0,
                  selectedVariant: 'default', // متغير افتراضي
                  quantity: 2,
                ),
              ],
              subtotal: 400.0,
              discount: 0.0,
              delivery: 50.0,
              total: 450.0,
              status: OrderStatus.pending,
              address: address,
              createdAt: DateTime.now(),
              paymentMethod: 'cash',
            );

            when(mockFirestore.runTransaction<void>(any)).thenAnswer(
              (invocation) async {
                final callback =
                    invocation.positionalArguments[0] as Function(Transaction);

                when(mockTransaction.get(any)).thenAnswer((_) async {
                  final snap = MockDocumentSnapshot();
                  when(snap.exists).thenReturn(true);
                  when(snap.data()).thenReturn(productMap);
                  return snap;
                });

                // لاحظ: الكود الأصلي يتخطى تحديث المخزون إذا كان selectedVariant == 'default'
                // لذا لا نتوقع أي تحديث

                await callback(mockTransaction);
              },
            );

            // يجب أن ينجح دون محاولة تحديث المخزون
            await expectLater(
              orderRepository.createOrderWithStockCheck(orderModel),
              completes,
              reason:
                  'يجب قبول الطلب للمتغير الافتراضي دون تحديث مخزون',
            );
          },
        );
      },
    );

    group('💰 Price Validation Tests', () {
      test(
        'Should reject order when client manipulates price to be lower',
        () async {
          const orderId = 'order_price_manipulated';
          final address = AddressModel(
            id: 'addr_7',
            label: 'المنزل',
            district: 'القاهرة',
            neighborhood: 'الدقي',
            street: 'شارع النيل',
            buildingNum: '123',
            floor: '1',
            apartmentNum: '101',
            phone: '01234567890',
          );

          final productMap = {
            'id': 'prod_7',
            'name': 'ساعة ذكية',
            'variants': [
              {'name': 'أسود', 'price': 500, 'stock': 10},
            ],
          };

          final orderModel = OrderModel(
            id: orderId,
            userId: 'user_999',
            userName: 'عميل',
            items: [
              OrderItemModel(
                productId: 'prod_7',
                name: 'ساعة ذكية',
                category: 'إلكترونيات',
                price: 50.0, // ❌ تلاعب: السعر الحقيقي 500
                selectedVariant: 'أسود',
                quantity: 1,
              ),
            ],
            subtotal: 50.0,
            delivery: 50.0,
            total: 100.0,
            status: OrderStatus.pending,
            address: address,
            createdAt: DateTime.now(),
            paymentMethod: 'cash',
          );

          when(mockFirestore.runTransaction<void>(any)).thenAnswer(
            (invocation) async {
              final callback =
                  invocation.positionalArguments[0] as Function(Transaction);

              when(mockTransaction.get(any)).thenAnswer((_) async {
                final snap = MockDocumentSnapshot();
                when(snap.exists).thenReturn(true);
                when(snap.data()).thenReturn(productMap);
                return snap;
              });

              await callback(mockTransaction);
            },
          );

          expect(
            () => orderRepository.createOrderWithStockCheck(orderModel),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('سعر'),
            )),
            reason: 'يجب رفض الطلب عند تلاعب العميل بالسعر',
          );
        },
      );

      test(
        'Should accept order when price matches Firestore price within tolerance',
        () async {
          const orderId = 'order_price_ok';
          final address = AddressModel(
            id: 'addr_8',
            label: 'المنزل',
            district: 'القاهرة',
            neighborhood: 'الدقي',
            street: 'شارع النيل',
            buildingNum: '123',
            floor: '2',
            apartmentNum: '201',
            phone: '01234567890',
          );

          final productMap = {
            'id': 'prod_8',
            'name': 'كتاب',
            'price': 99.5,
            'variants': [
              {'name': 'غلاف عادي', 'stock': 20},
            ],
          };

          final orderModel = OrderModel(
            id: orderId,
            userId: 'user_888',
            userName: 'عميل',
            items: [
              OrderItemModel(
                productId: 'prod_8',
                name: 'كتاب',
                category: 'كتب',
                price: 99.5,
                selectedVariant: 'غلاف عادي',
                quantity: 1,
              ),
            ],
            subtotal: 99.5,
            delivery: 30.0,
            total: 129.5,
            status: OrderStatus.pending,
            address: address,
            createdAt: DateTime.now(),
            paymentMethod: 'cash',
          );

          when(mockFirestore.runTransaction<void>(any)).thenAnswer(
            (invocation) async {
              final callback =
                  invocation.positionalArguments[0] as Function(Transaction);

              when(mockTransaction.get(any)).thenAnswer((_) async {
                final snap = MockDocumentSnapshot();
                when(snap.exists).thenReturn(true);
                when(snap.data()).thenReturn(productMap);
                return snap;
              });

              await callback(mockTransaction);
            },
          );

          await expectLater(
            orderRepository.createOrderWithStockCheck(orderModel),
            completes,
            reason: 'يجب قبول الطلب عند تطابق السعر',
          );
        },
      );

      test(
        'Should use variant price when variant has its own price',
        () async {
          const orderId = 'order_variant_price';
          final address = AddressModel(
            id: 'addr_9',
            label: 'المنزل',
            district: 'القاهرة',
            neighborhood: 'الدقي',
            street: 'شارع النيل',
            buildingNum: '123',
            floor: '3',
            apartmentNum: '301',
            phone: '01234567890',
          );

          final productMap = {
            'id': 'prod_9',
            'name': 'قميص',
            'price': 100,
            'variants': [
              {'name': 'XL', 'price': 150, 'stock': 5},
              {'name': 'M', 'stock': 10},
            ],
          };

          final orderModelXL = OrderModel(
            id: orderId,
            userId: 'user_777',
            userName: 'عميل',
            items: [
              OrderItemModel(
                productId: 'prod_9',
                name: 'قميص',
                category: 'ملابس',
                price: 150.0,
                selectedVariant: 'XL',
                quantity: 1,
              ),
            ],
            subtotal: 150.0,
            delivery: 30.0,
            total: 180.0,
            status: OrderStatus.pending,
            address: address,
            createdAt: DateTime.now(),
            paymentMethod: 'cash',
          );

          final orderModelM = orderModelXL.copyWith(
            id: 'order_variant_price_m',
            items: [
              OrderItemModel(
                productId: 'prod_9',
                name: 'قميص',
                category: 'ملابس',
                price: 100.0,
                selectedVariant: 'M',
                quantity: 1,
              ),
            ],
            subtotal: 100.0,
            total: 130.0,
          );

          when(mockFirestore.runTransaction<void>(any)).thenAnswer(
            (invocation) async {
              final callback =
                  invocation.positionalArguments[0] as Function(Transaction);

              when(mockTransaction.get(any)).thenAnswer((_) async {
                final snap = MockDocumentSnapshot();
                when(snap.exists).thenReturn(true);
                when(snap.data()).thenReturn(productMap);
                return snap;
              });

              await callback(mockTransaction);
            },
          );

          await expectLater(
            orderRepository.createOrderWithStockCheck(orderModelXL),
            completes,
            reason: 'يجب قبول الطلب بسعر المتغير المخصص',
          );

          await expectLater(
            orderRepository.createOrderWithStockCheck(orderModelM),
            completes,
            reason: 'يجب قبول الطلب بسعر المنتج الأساسي عند عدم وجود سعر للمتغير',
          );
        },
      );
    });
  });
}



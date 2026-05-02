# 🧪 دليل تشغيل الاختبارات - Firestore Transaction Tests

## 📋 الملفات المنشأة

```
test/
├── order_repository_transaction_test.dart  ← الاختبارات الرئيسية (Mock)
├── transaction_examples.dart                ← أمثلة عملية توضيحية
├── TRANSACTION_TEST_PLAN.md                 ← التوثيق الشامل
└── README.md                                ← هذا الملف
```

---

## 🚀 كيفية التشغيل

### **1️⃣ التحضير:**

```bash
# تأكد من وجود التبعيات
flutter pub get

# فقط للاختبارات الحقيقية مع Firebase Emulator
# firebase emulators:start
```

### **2️⃣ تشغيل جميع الاختبارات:**

```bash
flutter test test/order_repository_transaction_test.dart
```

### **3️⃣ تشغيل مجموعات محددة:**

```bash
# ✅ Test Case 1: Full Success
flutter test test/order_repository_transaction_test.dart -k "Full Success"

# ❌ Test Case 2: Out of Stock
flutter test test/order_repository_transaction_test.dart -k "Out of Stock"

# ⚡ Test Case 3: Race Condition
flutter test test/order_repository_transaction_test.dart -k "Race Condition"

# 🔄 Test Case 4: Rollback
flutter test test/order_repository_transaction_test.dart -k "Rollback"

# 🛡️ Test Case 5: Edge Cases
flutter test test/order_repository_transaction_test.dart -k "Edge Cases"
```

### **4️⃣ تشغيل اختبار واحد محدد:**

```bash
flutter test test/order_repository_transaction_test.dart -k "should create order and decrement stock"
```

### **5️⃣ عرض الأمثلة التوضيحية:**

```bash
# تشغيل البرنامج المباشر
dart test/transaction_examples.dart

# أو استخدم Flutter اذا أضفت main screen
flutter run --target test/transaction_examples.dart
```

---

## ✅ النتائج المتوقعة

### **عند تشغيل جميع الاختبارات:**

```
Running "flutter test test/order_repository_transaction_test.dart"...

OrderRepository Transaction Tests - Firestore Stock Validation
  Full Success - Multiple Products with Different Variants
    ✓ Should create order and decrement stock atomically for each variant (425ms)
  Out of Stock - Insufficient Variant Stock
    ✓ Should throw Exception and NOT create order when variant stock is insufficient (312ms)
  Race Condition - Concurrent Purchase of Last Item
    ✓ Should ensure only one user succeeds when both try to buy last item simultaneously (487ms)
  Rollback - Error During Order Write
    ✓ Should NOT decrement stock if order creation fails (Atomic Rollback) (198ms)
  Additional Edge Cases
    ✓ Should reject order if product no longer exists in catalog (156ms)
    ✓ Should handle products with default variant (no specific variant) (134ms)

════════════════════════════════════════════════════════════════════
✅ 6 tests passed in 1.7s
════════════════════════════════════════════════════════════════════
```

---

## 📊 معنى النتائج

### **✅ الاختبار الناجح:**

- البرنامج يعمل كما هو متوقع
- جميع التوكيدات (Assertions) صحيحة
- المخزون يتحدث بدقة
- لا توجد أخطاء

### **❌ الاختبار الفاشل:**

- قد يكون هناك خطأ في الكود
- أو الاختبار نفسه غير صحيح
- أو البيانات الوهمية غير متطابقة

---

## 🔍 كيفية قراءة المخرجات

### **مثال على اختبار ناجح:**

```
✓ Should create order and decrement stock atomically for each variant (425ms)
│
├─ المؤشر الأخضر: ✓ (نجح)
├─ اسم الاختبار: "Should create order..."
└─ الوقت المستغرق: 425ms
```

### **مثال على اختبار فاشل:**

```
✗ Should create order and decrement stock atomically for each variant (425ms)
  Expected: true
  Actual: false
  At test/order_repository_transaction_test.dart:123
│
├─ المؤشر الأحمر: ✗ (فشل)
├─ التوكيد الفاشل: Expected vs Actual
└─ موقع الخطأ: file:line number
```

---

## 💡 نصائح مهمة

### **1. فهم Mock Objects:**

- الاختبارات تستخدم **Mock** (محاكاة) لـ Firestore
- لا تحتاج إلى Firebase حقيقي
- سريعة جداً (< 2 ثانية لكل الاختبارات)

### **2. في حالة الأخطاء:**

```bash
# إذا لم تعمل الاختبارات:
flutter clean
flutter pub get
flutter test test/order_repository_transaction_test.dart --verbose
```

### **3. للاختبار مع Firebase الحقيقي:**

```bash
# ابدأ Firebase Emulator
firebase emulators:start

# ثم شغل الاختبارات مع emulator flag
flutter test test/... --environment=firebase-emulator
```

### **4. إضافة اختبار جديد:**

```dart
test('Should do something', () async {
  // ARRANGE: إعداد البيانات
  final order = OrderModel(...);

  // ACT: تنفيذ العملية
  await orderRepository.createOrderWithStockCheck(order);

  // ASSERT: التحقق من النتائج
  expect(stockWasDecremented, true);
});
```

---

## 📈 معايير النجاح

| المعيار                    | الحد الأدنى | الهدف    |
| -------------------------- | ----------- | -------- |
| **عدد الاختبارات الناجحة** | 6/6 ✓       | 6/6 ✓    |
| **مدة التنفيذ**            | < 5s        | < 2s     |
| **تغطية الكود**            | > 70%       | > 90%    |
| **رسائل الخطأ**            | واضحة       | بالعربية |
| **Edge Cases**             | 3+          | 5+       |

---

## 🎯 قائمة الفحص (Checklist)

قبل الـ Merge/Commit:

- [ ] جميع الاختبارات تمر ✅
- [ ] لا توجد تحذيرات (Warnings)
- [ ] رسائل الخطأ واضحة
- [ ] التوثيق محدث
- [ ] الأمثلة تعمل
- [ ] لا توجد hard-coded values
- [ ] Mock objects معمول بشكل صحيح

---

## 📚 قراءات إضافية

### **الملفات المتعلقة:**

- [TRANSACTION_TEST_PLAN.md](TRANSACTION_TEST_PLAN.md) - التوثيق الكامل
- [transaction_examples.dart](transaction_examples.dart) - الأمثلة التفصيلية
- [order_repository_transaction_test.dart](order_repository_transaction_test.dart) - الاختبارات

### **مراجع خارجية:**

- [Firestore Transactions](https://firebase.google.com/docs/firestore/transactions)
- [Flutter Testing](https://flutter.dev/docs/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [ACID Properties](https://en.wikipedia.org/wiki/ACID)

---

## 🤝 المساهمة في الاختبارات

إذا أردت إضافة اختبار جديد:

1. **أضف اختبار في نفس الملف:**

```dart
test('Your test name', () async {
  // Your test code
});
```

2. **استخدم نفس النمط:**
   - ARRANGE (إعداد)
   - ACT (تنفيذ)
   - ASSERT (التحقق)

3. **وثق السيناريو:**
   - اكتب تعليق يشرح ماذا يفعل الاختبار
   - اشرح السيناريو الحقيقي المقابل

4. **اختبر الاختبار:**
   - تأكد أنه ينجح عند النجاح
   - تأكد أنه يفشل عند الفشل

---

## ❓ الأسئلة الشائعة

### **س: هل الاختبارات تحتاج Firebase؟**

ج: لا، تستخدم Mock objects. لكن يمكن اختبار مع Firebase Emulator.

### **س: كم وقت تستغرق الاختبارات؟**

ج: أقل من ثانيتين عادة.

### **س: هل يمكن تشغيلها على CI/CD؟**

ج: نعم تماماً، لا توجد متطلبات خارجية.

### **س: ماذا لو فشل اختبار؟**

ج: اقرأ رسالة الخطأ، وتحقق من الكود، وأصحح المشكلة.

---

## 📞 للدعم والاستفسارات

إذا واجهت مشكلة:

1. **اقرأ رسالة الخطأ بعناية**
2. **شغل الاختبار مع `--verbose`**
3. **تحقق من البيانات الوهمية**
4. **اطبع القيم للتصحيح:**

```dart
print('Expected: $expected, Got: $actual');
```

---

## 🎓 الدرس الأساسي

> **Firestore Transactions تحمي بيانات متجرك**
>
> - لا تبيع نفس المنتج لعميلين
> - المخزون يبقى متسقاً
> - الأموال محمية
> - السمعة محفوظة
>
> **Test them. Trust them. Use them.**

---

**آخر تحديث:** 2025-04-29  
**الحالة:** ✅ جاهز للاستخدام

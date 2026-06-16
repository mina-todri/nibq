import 'package:cloud_firestore/cloud_firestore.dart';

class MockDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedAllData() async {
    await seedSettings();
    await seedCoupons();
    await seedProducts();
  }

  Future<void> seedSettings() async {
    await _db.collection('settings').doc('global').set({
      'deliveryFee': 40.0,
      'freeDelivery': false,
    });
  }

  Future<void> seedCoupons() async {
    final coupons = {
      'WELCOME20': 20.0,
      'NIBQ10': 10.0,
      'ART50': 50.0,
    };

    for (var entry in coupons.entries) {
      await _db.collection('coupons').doc(entry.key).set({
        'percentage': entry.value,
        'active': true,
      });
    }
  }

  Future<void> seedProducts() async {
    final products = [
      {
        'name': 'طقم أقلام رصاص فنية',
        'description': 'طقم مكون من 12 قلم رصاص بدرجات مختلفة من 2H إلى 8B، مثالي للرسم والتظليل الاحترافي.',
        'price': 250.0,
        'category': 'أقلام ورسم',
        'imageUrl': 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?q=80&w=500',
        'rating': 4.8,
        'reviewCount': 120,
        'discount': 10.0,
        'productVariants': [
          {'name': 'علبة معدن', 'stock': 15},
          {'name': 'علبة كرتون', 'stock': 5},
        ],
        'totalStock': 20,
      },
      {
        'name': 'دفتر سكتش A3 فابريانو',
        'description': 'ورق عالي الجودة 200 جرام، مناسب للألوان المائية والماركرز.',
        'price': 450.0,
        'category': 'دفاتر وأوراق',
        'imageUrl': 'https://images.unsplash.com/photo-1544816155-12df9643f363?q=80&w=500',
        'rating': 4.9,
        'reviewCount': 85,
        'discount': 0.0,
        'productVariants': [
          {'name': 'A3', 'stock': 10},
          {'name': 'A4', 'stock': 25},
          {'name': 'A5', 'stock': 0},
        ],
        'totalStock': 35,
      },
      {
        'name': 'ألوان أكريليك رويال',
        'description': 'مجموعة من 24 لون أكريليك سعة 12 مل لكل أنبوبة، ألوان زاهية وقوة تغطية عالية.',
        'price': 850.0,
        'category': 'لوازم فنية',
        'imageUrl': 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?q=80&w=500',
        'rating': 4.7,
        'reviewCount': 45,
        'discount': 15.0,
        'productVariants': [],
        'totalStock': 12,
      },
      {
        'name': 'مسطرة قياس معدنية',
        'description': 'مسطرة ستانلس ستيل 30 سم مع قياسات بالإنش والسنتيمتر، متينة ودقيقة.',
        'price': 75.0,
        'category': 'أدوات قياس',
        'imageUrl': 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?q=80&w=500',
        'rating': 4.5,
        'reviewCount': 200,
        'discount': 0.0,
        'productVariants': [
          {'name': '30 سم', 'stock': 50},
          {'name': '60 سم', 'stock': 30},
        ],
        'totalStock': 80,
      },
    ];

    for (var p in products) {
      await _db.collection('products').add(p);
    }
  }
}

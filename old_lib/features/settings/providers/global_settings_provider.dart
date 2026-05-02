import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GlobalSettings {
  final double deliveryFee;
  final String discountCode;
  final double discountPercentage;
  final bool freeDelivery;

  GlobalSettings({
    required this.deliveryFee,
    required this.discountCode,
    required this.discountPercentage,
    required this.freeDelivery,
  });

  /// Provides centralized default values for the entire app.
  factory GlobalSettings.empty() {
    return GlobalSettings(
      deliveryFee: 30.0,
      discountCode: '',
      discountPercentage: 0.0,
      freeDelivery: false,
    );
  }

  factory GlobalSettings.fromMap(Map<String, dynamic> map) {
    return GlobalSettings(
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 30.0,
      discountCode: map['discountCode'] as String? ?? '',
      discountPercentage: (map['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      freeDelivery: map['freeDelivery'] as bool? ?? false,
    );
  }
}

final globalSettingsProvider = StreamProvider<GlobalSettings>((ref) {
  return FirebaseFirestore.instance
      .collection('settings')
      .doc('global')
      .snapshots()
      .map((doc) {
    final data = doc.data();
    if (data == null) return GlobalSettings.empty();
    return GlobalSettings.fromMap(data);
  });
});

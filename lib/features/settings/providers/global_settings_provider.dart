import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Public store settings that any user can read.
class GlobalSettings {
  final double deliveryFee;
  final bool freeDelivery;

  GlobalSettings({
    required this.deliveryFee,
    required this.freeDelivery,
  });

  factory GlobalSettings.empty() {
    return GlobalSettings(
      deliveryFee: 30.0,
      freeDelivery: false,
    );
  }

  factory GlobalSettings.fromMap(Map<String, dynamic> map) {
    return GlobalSettings(
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 30.0,
      freeDelivery: map['freeDelivery'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deliveryFee': deliveryFee,
      'freeDelivery': freeDelivery,
    };
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

// lib/core/services/global_settings_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/settings/providers/global_settings_provider.dart';

class GlobalSettingsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<GlobalSettings> getSettings() async {
    final doc = await _db.collection('settings').doc('global').get();
    if (!doc.exists) return GlobalSettings.empty();
    return GlobalSettings.fromMap(doc.data()!);
  }

  Future<void> updateSettings(GlobalSettings settings) async {
    // Only update existing fields, removing old coupon fields if they exist in Firestore
    await _db.collection('settings').doc('global').set(
      settings.toMap(), 
      SetOptions(merge: false), // False to effectively "clean up" unknown fields in this doc
    );
  }
}

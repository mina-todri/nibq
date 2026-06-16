import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address_model.dart';

class AddressRepository {
  final FirebaseFirestore _firestore;

  AddressRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userAddresses(String userId) =>
      _firestore.collection('users').doc(userId).collection('addresses');

  Stream<List<AddressModel>> watchAddresses(String userId) {
    return _userAddresses(userId).snapshots().map((snap) => snap.docs
        .map((doc) => AddressModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList());
  }

  Future<void> addAddress(String userId, AddressModel address, bool isDefault) async {
    await _userAddresses(userId).add({
      ...address.toMap(),
      'isDefault': isDefault,
    });
  }

  Future<void> updateAddress(String userId, AddressModel address) async {
    if (address.id.isEmpty) throw Exception('Address ID missing');
    await _userAddresses(userId).doc(address.id).update(address.toMap());
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    await _userAddresses(userId).doc(addressId).delete();
  }

  Future<void> setDefaultAddress(String userId, String addressId, List<String> allAddressIds) async {
    final batch = _firestore.batch();
    final col = _userAddresses(userId);
    for (final id in allAddressIds) {
      batch.update(col.doc(id), {'isDefault': id == addressId});
    }
    await batch.commit();
  }
}

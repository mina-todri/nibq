import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/address_repository.dart';
import '../../../core/models/address_model.dart';
import '../../auth/providers/auth_provider.dart';

final addressRepositoryProvider = Provider((ref) => AddressRepository());

final addressesStreamProvider = StreamProvider.autoDispose<List<AddressModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(addressRepositoryProvider)
      .watchAddresses(user.uid)
      .handleError((error) {
        if (error.toString().contains('permission-denied')) {
          return [];
        }
        throw error;
      });
});

final defaultAddressProvider = Provider.autoDispose<AddressModel?>((ref) {
  final addresses = ref.watch(addressesStreamProvider).value ?? [];
  if (addresses.isEmpty) return null;
  return addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
});

class SelectedAddressNotifier extends StateNotifier<AddressModel?> {
  SelectedAddressNotifier() : super(null);
  void select(AddressModel address) => state = address;
  void clear() => state = null;
}

final manualSelectedAddressProvider = StateNotifierProvider<SelectedAddressNotifier, AddressModel?>((ref) {
  return SelectedAddressNotifier();
});

final activeAddressProvider = Provider.autoDispose<AddressModel?>((ref) {
  final manual = ref.watch(manualSelectedAddressProvider);
  if (manual != null) return manual;
  return ref.watch(defaultAddressProvider);
});

import '../../../core/models/product_model.dart';
import '../../product/providers/product_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GetLiveStockUseCase {
  final Ref ref;

  GetLiveStockUseCase(this.ref);

  int call(String productId, String variantName) {
    final products = ref.read(productsStreamProvider).value;
    if (products == null || products.isEmpty) return 0;

    final product = products.firstWhere(
          (p) => p.id == productId,
      orElse: () => throw Exception('المنتج غير موجود أو لم يتم تحميله'),
    );

    if (variantName.isNotEmpty && variantName != 'default') {
      return product.stockForVariant(variantName);
    }
    return product.totalStock;
  }
}
import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import 'product_state.dart';

class ProductNotifier extends StateNotifier<ProductState> {
  final ProductRepository _repository;
  StreamSubscription<List<Product>>? _streamSub;

  ProductNotifier(this._repository) : super(const ProductInitial()) {
    _listen();
  }

  // ── Stream ────────────────────────────────────────────────────────────────

  void _listen() {
    state = const ProductLoading();
    _streamSub = _repository.watchAll().listen(
      (products) => state = ProductLoaded(products),
      onError: (Object e) => state = ProductError(e.toString()),
    );
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<void> add(Product product, {File? imageFile}) async {
    try {
      await _repository.add(product, imageFile: imageFile);
    } catch (e) {
      state = ProductError(e.toString());
      rethrow;
    }
  }

  Future<void> update(Product product, {File? imageFile}) async {
    try {
      await _repository.update(product, imageFile: imageFile);
    } catch (e) {
      state = ProductError(e.toString());
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repository.delete(id);
    } catch (e) {
      state = ProductError(e.toString());
      rethrow;
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/product_model.dart';

abstract interface class ProductRemoteDataSource {
  Stream<List<ProductModel>> watchAll();
  Future<ProductModel?> getById(String id);
  Future<void> add(ProductModel product, {File? imageFile});
  Future<void> update(ProductModel product, {File? imageFile});
  Future<void> delete(String id);
}

class FirebaseProductDataSource implements ProductRemoteDataSource {
  final FirebaseFirestore _firestore;
  final CloudinaryPublic? _cloudinary;

  static const _collection = 'products';

  FirebaseProductDataSource({
    FirebaseFirestore? firestore,
    CloudinaryPublic? cloudinary,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cloudinary = cloudinary ?? _buildCloudinary();

  static CloudinaryPublic? _buildCloudinary() {
    final cloudName = AppConstants.cloudinaryCloudName;
    final preset = AppConstants.cloudinaryUploadPreset;
    if (cloudName.isEmpty || preset.isEmpty) return null;
    return CloudinaryPublic(cloudName, preset, cache: false);
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  @override
  Stream<List<ProductModel>> watchAll() {
    return _firestore.collection(_collection).snapshots().map(
          (snap) => snap.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  @override
  Future<ProductModel?> getById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return ProductModel.fromMap(doc.data()!, doc.id);
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  @override
  Future<void> add(ProductModel product, {File? imageFile}) async {
    final imageUrl = await _resolveImageUrl(product.imageUrl, imageFile);
    final data = product.toMap()..['imageUrl'] = imageUrl;
    await _firestore.collection(_collection).add(data);
  }

  @override
  Future<void> update(ProductModel product, {File? imageFile}) async {
    final imageUrl = await _resolveImageUrl(product.imageUrl, imageFile);
    final data = product.toMap()..['imageUrl'] = imageUrl;
    await _firestore.collection(_collection).doc(product.id).update(data);
  }

  @override
  Future<void> delete(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // ── Image upload ──────────────────────────────────────────────────────────

  Future<String?> _resolveImageUrl(String? existing, File? file) async {
    if (file == null) return existing;
    return _uploadImage(file);
  }

  Future<String> _uploadImage(File file) async {
    final cloudinary = _cloudinary;
    if (cloudinary == null) {
      throw Exception(
        'Cloudinary is not configured. Set cloudinaryCloudName and cloudinaryUploadPreset in AppConstants.',
      );
    }
    final response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        resourceType: CloudinaryResourceType.Image,
      ),
    );
    return response.secureUrl;
  }
}
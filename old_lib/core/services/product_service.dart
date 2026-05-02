// lib/core/services/product_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../models/product_model.dart';
import '../constants/app_constants.dart';

class ProductException implements Exception {
  final String message;
  final String code;
  ProductException(this.message, this.code);

  @override
  String toString() => 'ProductException($code): $message';
}

class ProductService {
  final FirebaseFirestore _firestore;
  final CloudinaryPublic? _cloudinary;

  static const _collection = 'products';

  ProductService({
    FirebaseFirestore? firestore,
    CloudinaryPublic? cloudinary,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cloudinary = cloudinary ?? _buildCloudinary();

  static CloudinaryPublic? _buildCloudinary() {
    final cloudName = AppConstants.cloudinaryCloudName;
    final uploadPreset = AppConstants.cloudinaryUploadPreset;
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      return null;
    }
    return CloudinaryPublic(cloudName, uploadPreset, cache: false);
  }

  // ---------------------------------------------------------------------------
  // Internal helper — resolves the final image URL before writing to Firestore.
  // If a new file is provided it uploads it first, otherwise keeps the existing URL.
  // ---------------------------------------------------------------------------
  Future<String?> _resolveImageUrl(String? existingUrl, File? imageFile) async {
    if (imageFile == null) return existingUrl;
    return uploadImageToCloudinary(imageFile);
  }

  Stream<List<ProductModel>> streamProducts() {
    return _firestore.collection(_collection).snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  Future<void> addProduct(ProductModel product, File? imageFile) async {
    try {
      final imageUrl = await _resolveImageUrl(product.imageUrl, imageFile);
      final data = product.toMap()..['imageUrl'] = imageUrl;
      await _firestore.collection(_collection).add(data);
    } catch (e) {
      if (e is ProductException) rethrow;
      throw ProductException('فشل إضافة المنتج: $e', 'add-failed');
    }
  }

  Future<void> updateProduct(ProductModel product, [File? imageFile]) async {
    try {
      final imageUrl = await _resolveImageUrl(product.imageUrl, imageFile);
      final data = product.toMap()..['imageUrl'] = imageUrl;
      await _firestore.collection(_collection).doc(product.id).update(data);
    } catch (e) {
      if (e is ProductException) rethrow;
      throw ProductException('فشل تحديث المنتج: $e', 'update-failed');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw ProductException('فشل حذف المنتج: $e', 'delete-failed');
    }
  }

  /// Uploads an image to Cloudinary and returns the secure URL.
  /// Throws ProductException if Cloudinary is not configured.
  Future<String> uploadImageToCloudinary(File image) async {
    if (_cloudinary == null) {
      throw ProductException(
        'رفع الصور غير متاح حالياً. يرجى ضبط إعدادات التخزين السحابي.',
        'cloudinary-not-configured',
      );
    }
    try {
      final response = await _cloudinary!.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      if (e is ProductException) rethrow;
      throw ProductException('فشل رفع الصورة: $e', 'upload-failed');
    }
  }
}
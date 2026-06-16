// lib/core/services/product_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../models/product_model.dart';
import '../config/app_config.dart';

class ProductException implements Exception {
  final String message;
  final String code;
  ProductException(this.message, this.code);
  @override
  String toString() => 'ProductException($code): $message';
}

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';
  
  // Cloudinary config using environment variables
  final _cloudinary = CloudinaryPublic(
    AppConfig.cloudinaryCloudName,
    AppConfig.cloudinaryUploadPreset,
    cache: false,
  );

  Stream<List<ProductModel>> streamProducts() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProductModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<ProductModel> getProductById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) throw Exception('Product not found');
    return ProductModel.fromMap(doc.data()!, id);
  }

  Future<void> addProduct(ProductModel product, File? imageFile) async {
    try {
      String? imageUrl = product.imageUrl;
      
      if (imageFile != null) {
        imageUrl = await uploadImageToCloudinary(imageFile);
      }

      final data = product.toMap();
      data['imageUrl'] = imageUrl;
      
      await _firestore.collection(_collection).add(data);
    } catch (e) {
      throw ProductException('فشل إضافة المنتج: $e', 'add-failed');
    }
  }

  Future<void> updateProduct(ProductModel product, [File? imageFile]) async {
    try {
      String? imageUrl = product.imageUrl;
      
      if (imageFile != null) {
        imageUrl = await uploadImageToCloudinary(imageFile);
      }

      final data = product.toMap();
      data['imageUrl'] = imageUrl;
      
      await _firestore.collection(_collection).doc(product.id).update(data);
    } catch (e) {
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

  /// Updates stock for a product or a specific variant.
  /// Handles both the new variant system and backward compatibility.
  Future<void> updateProductStock({
    required String productId,
    required int delta,
    String? variantName,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection(_collection).doc(productId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception('المنتج غير موجود');

        final product = ProductModel.fromMap(snapshot.data()!, productId);
        final newTotalStock = product.totalStock + delta;

        if (newTotalStock < 0) throw Exception('المخزون لا يمكن أن يكون أقل من صفر');

        if (product.productVariants.isEmpty || variantName == null) {
          // No variants or updating base stock
          transaction.update(docRef, {
            'totalStock': newTotalStock,
            'stock': newTotalStock, // backward compat
          });
        } else {
          // Update specific variant
          final updatedVariants = product.productVariants.map((v) {
            if (v.name == variantName) {
              final newVariantStock = v.stock + delta;
              if (newVariantStock < 0) throw Exception('مخزون الخيار لا يمكن أن يكون أقل من صفر');
              return v.copyWith(stock: newVariantStock).toMap();
            }
            return v.toMap();
          }).toList();

          transaction.update(docRef, {
            'productVariants': updatedVariants,
            'totalStock': newTotalStock,
          });
        }
      });
    } catch (e) {
      throw Exception('فشل تحديث المخزون: $e');
    }
  }

  /// Uploads an image to Cloudinary using Unsigned Upload.
  /// 
  /// NOTE: For production security with Unsigned Upload, you MUST:
  /// 1. Use a specific 'upload_preset' in Cloudinary dashboard.
  /// 2. Restrict that preset to only allow 'Upload' (no deletes/overwrites).
  /// 3. Ideally, restrict the preset to a specific folder.
  /// This prevents attackers from filling up your storage even if they find the preset.
  Future<String> uploadImageToCloudinary(File image) async {
    if (!AppConfig.isCloudinaryConfigured) {
      throw Exception('برجاء تهيئة إعدادات Cloudinary (CLOUDINARY_CLOUD_NAME & CLOUDINARY_UPLOAD_PRESET)');
    }
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      throw Exception('فشل رفع الصورة إلى Cloudinary: $e');
    }
  }
}

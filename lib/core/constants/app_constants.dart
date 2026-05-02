class AppConstants {
  AppConstants._();

  // App
  static const appName = 'Nibq';
  static const appVersion = '1.0.0';

  // Firebase
  static const firebaseProjectId = 'nibq';

  // Cloudinary
  static const cloudinaryCloudName = '';
  static const cloudinaryUploadPreset = '';

  // Firestore Collections
  static const usersCollection = 'users';
  static const productsCollection = 'products';
  static const cartCollection = 'carts';
  static const ordersCollection = 'orders';

  // UI
  static const defaultPadding = 16.0;
  static const defaultBorderRadius = 12.0;
  static const maxImageSizeMB = 5;

  // Validation
  static const maxPasswordLength = 50;
  static const minPasswordLength = 6;
  static const maxNameLength = 50;
  static const maxEmailLength = 100;
}

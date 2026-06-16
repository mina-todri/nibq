/// Application configuration management using environment variables.
///
/// Run using:
/// flutter run --dart-define=CLOUDINARY_CLOUD_NAME=your_name --dart-define=CLOUDINARY_UPLOAD_PRESET=your_preset
class AppConfig {
  AppConfig._();

  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );

  static const String cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );
  
  static bool get isCloudinaryConfigured => 
      cloudinaryCloudName.isNotEmpty && cloudinaryUploadPreset.isNotEmpty;
}

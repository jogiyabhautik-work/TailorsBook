import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageHelper {
  static SupabaseClient get _supabase => Supabase.instance.client;
  static const String _bucketName = 'shop-logos';
  static const int _maxFileSize = 2 * 1024 * 1024; // 2MB

  static Future<String?> uploadShopLogo(File imageFile, String userId) async {
    try {
      final fileSize = await imageFile.length();
      if (fileSize > _maxFileSize) {
        throw Exception('Image too large. Maximum size is 2MB.');
      }

      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(fileExtension)) {
        throw Exception('Invalid image type. Only JPG, PNG, and WebP are allowed.');
      }

      final fileName = '$userId/logo.$fileExtension';
      
      final existingFiles = await _supabase.storage.from(_bucketName).list(path: userId);
      if (existingFiles.isNotEmpty) {
        final existingPaths = existingFiles.map((f) => '$userId/${f.name}').toList();
        await _supabase.storage.from(_bucketName).remove(existingPaths);
      }

      await _supabase.storage.from(_bucketName).upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      final publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(fileName);
      debugPrint('StorageHelper: Logo uploaded successfully: $publicUrl');
      return publicUrl;
    } on StorageException catch (e) {
      debugPrint('StorageHelper Upload Error: ${e.message}');
      debugPrint('StorageHelper Upload Error Details: ${e.statusCode}');
      if (e.message.contains('bucket') || e.statusCode == 400) {
        debugPrint('StorageHelper: Storage bucket "$_bucketName" does not exist. Please create it in Supabase dashboard.');
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('StorageHelper Upload Error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<bool> deleteShopLogo(String userId) async {
    try {
      final files = await _supabase.storage.from(_bucketName).list(path: userId);
      if (files.isEmpty) return true;

      final paths = files.map((f) => '$userId/${f.name}').toList();
      await _supabase.storage.from(_bucketName).remove(paths);
      debugPrint('StorageHelper: Logo deleted for user: $userId');
      return true;
    } catch (e) {
      debugPrint('StorageHelper Delete Error: $e');
      return false;
    }
  }

  static String? getLogoUrl(String? logoUrl) {
    if (logoUrl == null || logoUrl.trim().isEmpty) return null;
    try {
      Uri.parse(logoUrl);
      return logoUrl;
    } catch (e) {
      debugPrint('StorageHelper: Invalid logo URL: $logoUrl');
      return null;
    }
  }
}

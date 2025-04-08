// lib/services/image_storage_service.dart

// Description :
// This file contains the ImageStorageService class which is responsible for :
// - Saving images to the device.
// - Cleaning up old images.

// Importing Dart IO & Typed Data Packages.
import 'dart:io';
import 'dart:typed_data';

// Importing Path Provider Package.
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

// Image Storage Service Class.
class ImageStorageService {
  // Private Constructor.
  static final ImageStorageService _instance = ImageStorageService._internal();
  factory ImageStorageService() => _instance;
  ImageStorageService._internal();

  // Save Image.
  Future<String> saveImage(Uint8List imageBytes, String logId) async {
    try {
      // Get The Image Directory.
      final directory = await _getImageDirectory();

      // Create The File Name.
      final fileName = 'detection_$logId.jpg';

      // Create The File.
      final file = File('${directory.path}/$fileName');
      
      // Write The Image To The File.
      await file.writeAsBytes(imageBytes);

      // Debug Print The Image Saved.
      debugPrint('Image saved successfully at: ${file.path}');
      
      return file.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      rethrow;
    }
  }

  // Load Image.
  Future<Uint8List?> loadImage(String path) async {
    try {
      // Get The File.
      final file = File(path);

      // If The File Exists.
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint('Error loading image: $e');
      return null;
    }
  }

  // Delete Image.
  Future<void> deleteImage(String path) async {
    try {
      // Get The File.
      final file = File(path);

      // If The File Exists.
      if (await file.exists()) {
        await file.delete();
        debugPrint('Image deleted successfully: $path');
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  // Cleanup Old Images.
  Future<void> cleanupOldImages(List<String> activePaths) async {
    try {
      // Get The Image Directory.
      final directory = await _getImageDirectory();

      // Get The Files.
      final files = directory.listSync();
      
      // For Each File.
      for (var file in files) {
        // If The File Is A File And Not In The Active Paths.
        if (file is File && !activePaths.contains(file.path)) {
          await file.delete();
          debugPrint('Cleaned up old image: ${file.path}');
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old images: $e');
    }
  }

  // Get Image Directory.
  Future<Directory> _getImageDirectory() async {
    // Get The Application Documents Directory.
    final appDir = await getApplicationDocumentsDirectory();

    // Create The Image Directory.
    final imageDir = Directory('${appDir.path}/detection_images');
    
    // If The Image Directory Does Not Exist.
    if (!await imageDir.exists()) {
      // Create The Image Directory.
      await imageDir.create(recursive: true);
    }
    
    return imageDir;
  }
} 
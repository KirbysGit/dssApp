import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class ImageStorageService {
  static final ImageStorageService _instance = ImageStorageService._internal();
  factory ImageStorageService() => _instance;
  ImageStorageService._internal();

  Future<String> saveImage(Uint8List imageBytes, String logId) async {
    try {
      final directory = await _getImageDirectory();
      final fileName = 'detection_$logId.jpg';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(imageBytes);
      debugPrint('Image saved successfully at: ${file.path}');
      
      return file.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      rethrow;
    }
  }

  Future<Uint8List?> loadImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint('Error loading image: $e');
      return null;
    }
  }

  Future<void> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Image deleted successfully: $path');
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  Future<void> cleanupOldImages(List<String> activePaths) async {
    try {
      final directory = await _getImageDirectory();
      final files = directory.listSync();
      
      for (var file in files) {
        if (file is File && !activePaths.contains(file.path)) {
          await file.delete();
          debugPrint('Cleaned up old image: ${file.path}');
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old images: $e');
    }
  }

  Future<Directory> _getImageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/detection_images');
    
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    
    return imageDir;
  }
} 
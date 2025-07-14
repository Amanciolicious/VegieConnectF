// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class ImageStorageService {
  static const String _productImagesFolder = 'product_images';
  
  /// Get the local directory for storing product images
  static Future<Directory> get _productImagesDirectory async {
    if (kIsWeb) {
      throw UnsupportedError('Local file storage is not supported on web');
    }
    
    final appDir = await getApplicationDocumentsDirectory();
    final productImagesDir = Directory(path.join(appDir.path, _productImagesFolder));
    
    if (!await productImagesDir.exists()) {
      await productImagesDir.create(recursive: true);
    }
    
    return productImagesDir;
  }

  /// Save image from file to local storage
  static Future<String> saveImageFromFile(File imageFile, String productId) async {
    if (kIsWeb) {
      throw UnsupportedError('Local file storage is not supported on web');
    }
    
    final directory = await _productImagesDirectory;
    final fileName = '${productId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = File(path.join(directory.path, fileName));
    
    await imageFile.copy(savedFile.path);
    return savedFile.path;
  }

  /// Save image from bytes to local storage
  static Future<String> saveImageFromBytes(Uint8List imageBytes, String productId) async {
    if (kIsWeb) {
      throw UnsupportedError('Local file storage is not supported on web');
    }
    
    final directory = await _productImagesDirectory;
    final fileName = '${productId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = File(path.join(directory.path, fileName));
    
    await savedFile.writeAsBytes(imageBytes);
    return savedFile.path;
  }

  /// Pick image from gallery or camera
  static Future<File?> pickImageFromGallery() async {
    if (kIsWeb) {
      throw UnsupportedError('Use pickImageFromWeb for web platform');
    }
    
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    
    if (picked != null) {
      return File(picked.path);
    }
    return null;
  }

  /// Pick image from web
  static Future<Uint8List?> pickImageFromWeb() async {
    if (!kIsWeb) {
      throw UnsupportedError('Use pickImageFromGallery for mobile platforms');
    }
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    
    if (result != null && result.files.single.bytes != null) {
      return result.files.single.bytes;
    }
    return null;
  }

  /// Load image from local path
  static File? loadImageFromPath(String imagePath) {
    if (kIsWeb) {
      return null; // Web doesn't support local file access
    }
    
    if (imagePath.isEmpty) return null;
    
    final file = File(imagePath);
    if (file.existsSync()) {
      return file;
    }
    return null;
  }

  /// Delete image from local storage
  static Future<bool> deleteImage(String imagePath) async {
    if (kIsWeb) {
      return false; // Web doesn't support local file deletion
    }
    
    if (imagePath.isEmpty) return false;
    
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
    return false;
  }

  /// Get all product images for a specific product
  static Future<List<String>> getProductImages(String productId) async {
    if (kIsWeb) {
      return [];
    }
    
    try {
      final directory = await _productImagesDirectory;
      final files = directory.listSync();
      
      return files
          .where((file) => file is File && path.basename(file.path).startsWith('${productId}_'))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      print('Error getting product images: $e');
      return [];
    }
  }

  /// Clear all product images (useful for cleanup)
  static Future<void> clearAllProductImages() async {
    if (kIsWeb) {
      return;
    }
    
    try {
      final directory = await _productImagesDirectory;
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (e) {
      print('Error clearing product images: $e');
    }
  }

  /// Check if image path is a local path
  static bool isLocalPath(String imagePath) {
    if (kIsWeb) return false;
    return imagePath.isNotEmpty && !imagePath.startsWith('http');
  }

  /// Check if image path is a network URL
  static bool isNetworkUrl(String imagePath) {
    return imagePath.isNotEmpty && imagePath.startsWith('http');
  }
} 
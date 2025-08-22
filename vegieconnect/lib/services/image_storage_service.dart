// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImageStorageService {
  static const String _productImagesFolder = 'product_images';
  static const String _profileImagesFolder = 'profile_images';
  static const String _cloudProfileFolder = 'avatars';
  
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

  /// Upload a profile image to Firebase Storage and return the public download URL.
  /// On web, pass [bytes]. On mobile/desktop, pass [file]. Exactly one must be provided.
  static Future<String> uploadProfileImage({
    File? file,
    Uint8List? bytes,
    required String userId,
  }) async {
    final storage = FirebaseStorage.instance;
    final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = storage.ref().child('$_cloudProfileFolder/$userId/$fileName');

    final metadata = SettableMetadata(contentType: 'image/jpeg');
    if (kIsWeb) {
      if (bytes == null) {
        throw ArgumentError('bytes must not be null on web');
      }
      await ref.putData(bytes, metadata);
    } else {
      if (file == null) {
        throw ArgumentError('file must not be null on mobile');
      }
      await ref.putFile(file, metadata);
    }

    return await ref.getDownloadURL();
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

  // PROFILE IMAGE METHODS

  /// Get the local directory for storing profile images
  static Future<Directory> get _profileImagesDirectory async {
    if (kIsWeb) {
      throw UnsupportedError('Local file storage is not supported on web');
    }
    
    final appDir = await getApplicationDocumentsDirectory();
    final profileImagesDir = Directory(path.join(appDir.path, _profileImagesFolder));
    
    if (!await profileImagesDir.exists()) {
      await profileImagesDir.create(recursive: true);
    }
    
    return profileImagesDir;
  }

  /// Save profile image from file to local storage
  static Future<String> saveProfileImageFromFile(File imageFile, String userId) async {
    if (kIsWeb) {
      throw UnsupportedError('Local file storage is not supported on web');
    }
    
    final directory = await _profileImagesDirectory;
    final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = File(path.join(directory.path, fileName));
    
    await imageFile.copy(savedFile.path);
    return savedFile.path;
  }

  /// Save profile image from bytes to local storage
  static Future<String> saveProfileImageFromBytes(Uint8List imageBytes, String userId) async {
    if (kIsWeb) {
      throw UnsupportedError('Local file storage is not supported on web');
    }
    
    final directory = await _profileImagesDirectory;
    final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = File(path.join(directory.path, fileName));
    
    await savedFile.writeAsBytes(imageBytes);
    return savedFile.path;
  }

  /// Get profile image for a specific user
  static Future<String?> getProfileImage(String userId) async {
    if (kIsWeb) {
      return null;
    }
    
    try {
      final directory = await _profileImagesDirectory;
      final files = directory.listSync();
      
      final profileFiles = files
          .where((file) => file is File && path.basename(file.path).startsWith('profile_${userId}_'))
          .map((file) => file.path)
          .toList();
      
      if (profileFiles.isNotEmpty) {
        // Return the most recent profile image
        profileFiles.sort((a, b) => b.compareTo(a));
        return profileFiles.first;
      }
    } catch (e) {
      print('Error getting profile image: $e');
    }
    return null;
  }

  /// Delete old profile images for a user (keep only the latest)
  static Future<void> deleteOldProfileImages(String userId) async {
    if (kIsWeb) {
      return;
    }
    
    try {
      final directory = await _profileImagesDirectory;
      final files = directory.listSync();
      
      final profileFiles = files
          .where((file) => file is File && path.basename(file.path).startsWith('profile_${userId}_'))
          .map((file) => file.path)
          .toList();
      
      if (profileFiles.length > 1) {
        // Sort by name (which includes timestamp) and keep only the latest
        profileFiles.sort((a, b) => b.compareTo(a));
        
        // Delete all except the first (latest) one
        for (int i = 1; i < profileFiles.length; i++) {
          await File(profileFiles[i]).delete();
        }
      }
    } catch (e) {
      print('Error deleting old profile images: $e');
    }
  }

  /// Pick profile image with camera option
  static Future<File?> pickProfileImage({bool fromCamera = false}) async {
    if (kIsWeb) {
      throw UnsupportedError('Use pickImageFromWeb for web platform');
    }
    
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 512,
      maxHeight: 512,
    );
    
    if (picked != null) {
      return File(picked.path);
    }
    return null;
  }
} 
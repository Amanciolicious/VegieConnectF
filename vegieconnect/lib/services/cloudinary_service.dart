import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:vegieconnect/config/cloudinary_config.dart';

class CloudinaryService {
  // Configure via config constants; you can override these at runtime if needed.
  static String cloudName = kCloudinaryCloudName; // e.g., 'mycloud'
  static String unsignedUploadPreset = kCloudinaryUploadPreset;
  static String defaultFolder = kCloudinaryFolder;

  static Uri _endpoint() => Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  static bool get isConfigured => cloudName.isNotEmpty && unsignedUploadPreset.isNotEmpty;

  /// Upload bytes (web-friendly). Returns secure_url.
  static Future<String> uploadBytes(Uint8List bytes, {String? fileName, String? folder}) async {
    if (!isConfigured) {
      throw StateError('Cloudinary not configured. Set cloudName and unsignedUploadPreset.');
    }
    final req = http.MultipartRequest('POST', _endpoint())
      ..fields['upload_preset'] = unsignedUploadPreset
      ..fields['folder'] = folder ?? defaultFolder
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName ?? 'avatar.jpg'));

    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode != 200) {
      throw Exception('Cloudinary upload failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }

  /// Upload a local file (mobile/desktop). Returns secure_url.
  static Future<String> uploadFile(File file, {String? folder}) async {
    if (!isConfigured) {
      throw StateError('Cloudinary not configured. Set cloudName and unsignedUploadPreset.');
    }
    final req = http.MultipartRequest('POST', _endpoint())
      ..fields['upload_preset'] = unsignedUploadPreset
      ..fields['folder'] = folder ?? defaultFolder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode != 200) {
      throw Exception('Cloudinary upload failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }
}

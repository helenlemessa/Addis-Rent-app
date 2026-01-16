// lib/core/services/cloudinary_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';

class CloudinaryService {
  // Replace with your actual Cloudinary credentials
  static const String _cloudName = 'dpgz6oni0'; // Your cloud name
  static const String _uploadPreset = 'addis_rent'; // Your upload preset
  
  static Future<List<String>> uploadImages(List<String> imageSources) async {
    print('📤 Uploading ${imageSources.length} images to Cloudinary...');
    
    final List<String> uploadedUrls = [];
    
    for (int i = 0; i < imageSources.length; i++) {
      try {
        print('🔄 Uploading image ${i + 1}/${imageSources.length}');
        final url = await _uploadSingleImage(imageSources[i]);
        uploadedUrls.add(url);
        print('✅ Image ${i + 1} uploaded: $url');
      } catch (e) {
        print('❌ Failed to upload image ${i + 1}: $e');
        rethrow;
      }
    }
    
    print('🎉 All images uploaded to Cloudinary!');
    return uploadedUrls;
  }
  
static Future<String> _uploadSingleImage(String imageSource) async {
  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
    );

    request.fields['upload_preset'] = _uploadPreset;

    // ✅ CASE 1: Already uploaded URL
    if (imageSource.startsWith('http')) {
      return imageSource;
    }

    // ✅ CASE 2: Mobile file path (Android / iOS)
    if (!kIsWeb && File(imageSource).existsSync()) {
      final file = File(imageSource);

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: 'property_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
    }

    // ✅ CASE 3: Base64 (web or camera)
    else if (imageSource.startsWith('data:image')) {
      final base64Data = imageSource.split(',').last;
      final bytes = base64.decode(base64Data);

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'property_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
    }

    // ❌ Unsupported
    else {
      throw Exception('Unsupported image source: $imageSource');
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);
      return jsonData['secure_url'];
    } else {
      final error = await response.stream.bytesToString();
      throw Exception(
          'Cloudinary upload failed: ${response.statusCode} - $error');
    }
  } catch (e) {
    print('❌ Cloudinary upload error: $e');
    rethrow;
  }
}

  
  static Future<String> _convertBlobToBase64(String blobUrl) async {
    // For web only
    final response = await http.get(Uri.parse(blobUrl));
    final bytes = response.bodyBytes;
    return base64.encode(bytes);
  }
  
  // Check if image is already a Cloudinary URL
  static bool isCloudinaryUrl(String url) {
    return url.contains('cloudinary.com');
  }
}
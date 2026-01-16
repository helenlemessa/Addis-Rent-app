// lib/core/services/image_upload_service.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

class ImageUploadService {
  static Future<List<String>> uploadPropertyImages(List<String> imageSources) async {
    final List<String> uploadedUrls = [];
    
    print('📤 Starting to upload ${imageSources.length} images...');
    
    for (int i = 0; i < imageSources.length; i++) {
      try {
        print('🔄 Uploading image ${i + 1}/${imageSources.length}');
        final url = await _uploadImage(imageSources[i], i);
        uploadedUrls.add(url);
        print('✅ Image ${i + 1} uploaded: ${url.substring(0, 50)}...');
      } catch (e) {
        print('❌ Failed to upload image ${i + 1}: $e');
        // Don't fail the whole process if one image fails
        rethrow; // Or continue without this image
      }
    }
    
    print('🎉 All images uploaded successfully. Total: ${uploadedUrls.length}');
    return uploadedUrls;
  }
  
  static Future<String> _uploadImage(String imageSource, int index) async {
    Uint8List bytes;
    String contentType = 'image/jpeg';
    
    if (kIsWeb) {
      print('🌐 Web platform detected for image upload');
      
      if (imageSource.startsWith('blob:')) {
        // Handle blob URLs on web
        print('📝 Processing blob URL...');
        bytes = await _convertBlobToBytes(imageSource);
      } else if (imageSource.startsWith('data:image')) {
        // Handle data URLs (from camera)
        print('📝 Processing data URL...');
        final parts = imageSource.split(',');
        if (parts[0].contains('png')) {
          contentType = 'image/png';
        }
        bytes = base64.decode(parts[1]);
      } else if (imageSource.startsWith('http')) {
        // Already a URL, just return it
        print('🌐 Image is already a URL, skipping upload');
        return imageSource;
      } else {
        throw Exception('Unsupported image source on web: $imageSource');
      }
    } else {
      // Mobile platform - handle file path
      print('📱 Mobile platform detected for image upload');
      final file = File(imageSource);
      bytes = await file.readAsBytes();
      
      // Detect content type from file extension
      if (imageSource.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (imageSource.toLowerCase().endsWith('.gif')) {
        contentType = 'image/gif';
      }
    }
    
    // Generate unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'properties/$timestamp-$index.${contentType.split('/')[1]}';
    
    // Upload to Firebase Storage
    final ref = FirebaseStorage.instance.ref().child(fileName);
    
    print('🚀 Uploading to Firebase Storage: $fileName');
    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    
    print('✅ Upload complete. Download URL: ${downloadUrl.substring(0, 50)}...');
    return downloadUrl;
  }
  
  static Future<Uint8List> _convertBlobToBytes(String blobUrl) async {
    try {
      print('🔧 Converting blob URL to bytes...');
      final response = await html.HttpRequest.request(
        blobUrl,
        responseType: 'arraybuffer',
      );
      
      final arrayBuffer = response.response;
      if (arrayBuffer == null) {
        throw Exception('No data received from blob URL');
      }
      
      // Convert ArrayBuffer to Uint8List
      final bytes = Uint8List.fromList(
        List<int>.from(arrayBuffer as List<dynamic>),
      );
      
      print('✅ Blob converted to bytes: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      print('❌ Failed to convert blob to bytes: $e');
      throw Exception('Failed to convert blob to bytes: $e');
    }
  }
  
  // REMOVED the duplicate isImageUrl method - use the one in Helpers class
}
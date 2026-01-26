// lib/core/utils/helpers.dart
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:convert';

class Helpers {
  static String formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'ETB ',
      decimalDigits: 0,
    ).format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  static Future<void> launchPhone(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  static Future<void> launchEmail(String email) async {
  try {
    final url = 'mailto:$email';
    final uri = Uri.parse(url);
    
    // First check if we can launch it
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // If can't launch mailto, try to copy email to clipboard
      print('⚠️ Cannot launch email app. No email app found.');
      
      // Fallback: Copy email to clipboard and show a message
      await Clipboard.setData(ClipboardData(text: email));
      
      // Show a dialog or snackbar suggesting to use email app manually
      // You'll need to pass BuildContext or use a different approach
      // For now, just show in console
      print('📋 Email copied to clipboard: $email');
      print('📱 Please open your email app and paste this address');
      
      // You can also try opening Gmail/Outlook web
      final gmailUrl = 'https://mail.google.com/mail/?view=cm&to=$email';
      final outlookUrl = 'https://outlook.live.com/mail/0/deeplink/compose?to=$email';
      
      if (await canLaunchUrl(Uri.parse(gmailUrl))) {
        print('📨 Try opening Gmail instead...');
      }
    }
  } catch (e) {
    print('❌ Error launching email: $e');
    rethrow;
  }
}

  static Future<void> launchMap(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  static void showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static Future<void> showLoadingDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }

  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color confirmColor = Colors.red,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  static String truncateText(String text, {int maxLength = 100}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending Review';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  static String getPropertyTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'apartment':
        return '🏢';
      case 'house':
        return '🏠';
      case 'room':
        return '🛏️';
      case 'commercial':
        return '🏪';
      case 'villa':
        return '🏡';
      case 'studio':
        return '🎨';
      default:
        return '🏠';
    }
  }

  static String getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return '📶';
      case 'parking':
        return '🅿️';
      case 'water 24/7':
        return '💧';
      case 'electricity 24/7':
        return '⚡';
      case 'security':
        return '👮';
      case 'furnished':
        return '🛋️';
      case 'garden':
        return '🌳';
      case 'gym':
        return '💪';
      case 'swimming pool':
        return '🏊';
      case 'backup generator':
        return '🔋';
      default:
        return '✅';
    }
  }

  // ================== IMAGE HELPER METHODS ==================

  static bool isImageUrl(String path) {
    return path.startsWith('http://') || 
           path.startsWith('https://') ||
           path.startsWith('gs://') ||
           path.startsWith('blob:') ||
           path.startsWith('data:image');
  }

  static Widget buildPropertyImage(String imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    // Safety check for null or empty URLs
    if (imageUrl.isEmpty) {
      return _buildErrorPlaceholder();
    }

    print('🖼️ Loading image: ${imageUrl.length > 50 ? '${imageUrl.substring(0, 50)}...' : imageUrl}');
    
    // Check if it's a Cloudinary URL for optimization
    if (imageUrl.contains('cloudinary.com')) {
      // Cloudinary URL - can add optimizations
      final optimizedUrl = _optimizeCloudinaryUrl(imageUrl);
      
      return CachedNetworkImage(
        imageUrl: optimizedUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) {
          print('❌ Failed to load Cloudinary image: $url');
          return _buildErrorPlaceholder();
        },
      );
    } else if (imageUrl.startsWith('http')) {
      // Regular HTTP URL
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => _buildErrorPlaceholder(),
      );
    } else if (imageUrl.startsWith('data:image')) {
      // Base64 image (fallback)
      try {
        final base64Data = imageUrl.split(',').last;
        final bytes = base64.decode(base64Data);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Failed to load base64 image');
            return _buildErrorPlaceholder();
          },
        );
      } catch (e) {
        print('❌ Error decoding base64 image: $e');
        return _buildErrorPlaceholder();
      }
    } else {
      // Local file path (mobile only)
      if (kIsWeb) {
        print('⚠️ Cannot load local file on web: $imageUrl');
        return _buildErrorPlaceholder();
      } else {
        return Image.file(
          File(imageUrl),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Failed to load local image: $imageUrl');
            return _buildErrorPlaceholder();
          },
        );
      }
    }
  }

  static String _optimizeCloudinaryUrl(String url) {
    // Add Cloudinary transformations for better performance
    if (url.contains('upload/')) {
      try {
        // Insert optimizations before the filename
        final parts = url.split('upload/');
        if (parts.length == 2) {
          return '${parts[0]}upload/w_800,h_600,c_fill,q_auto,f_auto/${parts[1]}';
        }
      } catch (e) {
        print('⚠️ Error optimizing Cloudinary URL: $e');
      }
    }
    return url;
  }

  static Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.home, size: 40, color: Colors.grey),
      ),
    );
  }
}
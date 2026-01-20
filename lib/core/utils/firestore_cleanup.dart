import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:addis_rent/data/models/user_model.dart';
import 'package:addis_rent/core/constants/app_constants.dart';

class FirestoreCleanup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> fixAllUserDocuments() async {
    print('\n🧹 ========== FIXING ALL USER DOCUMENTS ==========');
    
    try {
      final usersSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .get();
      
      print('📊 Found ${usersSnapshot.docs.length} users');
      
      int fixedCount = 0;
      int errorCount = 0;
      
      for (final doc in usersSnapshot.docs) {
        try {
          final data = doc.data();
          final updateData = <String, dynamic>{};
          bool needsUpdate = false;
          
          // Check required fields
          if (data['fullName'] == null) {
            updateData['fullName'] = 'Unknown User';
            needsUpdate = true;
          }
          
          if (data['email'] == null) {
            // Can't fix email - skip
            print('⚠️ User ${doc.id} missing email, skipping');
            errorCount++;
            continue;
          }
          
          if (data['role'] == null) {
            updateData['role'] = 'tenant';
            needsUpdate = true;
          }
          
          if (data['isVerified'] == null) {
            updateData['isVerified'] = false;
            needsUpdate = true;
          }
          
          if (data['isSuspended'] == null) {
            updateData['isSuspended'] = false;
            needsUpdate = true;
          }
          
          if (data['createdAt'] == null) {
            updateData['createdAt'] = FieldValue.serverTimestamp();
            needsUpdate = true;
          }
          
          // Normalize role to lowercase
          if (data['role'] != null && data['role'] is String) {
            final role = data['role'].toString().toLowerCase();
            if (role != data['role']) {
              updateData['role'] = role;
              needsUpdate = true;
            }
          }
          
          // Normalize email to lowercase
          if (data['email'] != null && data['email'] is String) {
            final email = data['email'].toString().toLowerCase().trim();
            if (email != data['email']) {
              updateData['email'] = email;
              needsUpdate = true;
            }
          }
          
          if (needsUpdate) {
            updateData['updatedAt'] = FieldValue.serverTimestamp();
            await doc.reference.update(updateData);
            fixedCount++;
            print('✅ Fixed user: ${data['email'] ?? doc.id}');
          }
          
        } catch (e) {
          print('❌ Error fixing user ${doc.id}: $e');
          errorCount++;
        }
      }
      
      print('\n🎉 CLEANUP COMPLETE:');
      print('   ✅ Fixed: $fixedCount users');
      print('   ❌ Errors: $errorCount users');
      print('   📊 Total: ${usersSnapshot.docs.length} users');
      
    } catch (e) {
      print('❌ Cleanup error: $e');
    }
    
    print('================================================\n');
  }
  
  static Future<void> checkSpecificUser(String email) async {
    print('\n🔍 CHECKING USER: $email');
    
    try {
      final query = await _firestore
          .collection(AppConstants.usersCollection)
          .where('email', isEqualTo: email.toLowerCase())
          .get();
      
      if (query.docs.isEmpty) {
        print('❌ No user found with email: $email');
        return;
      }
      
      for (final doc in query.docs) {
        final data = doc.data();
        print('\n📄 Document ID: ${doc.id}');
        print('📧 Email: ${data['email']}');
        print('👤 Name: ${data['fullName'] ?? "MISSING"}');
        print('🎭 Role: ${data['role'] ?? "MISSING"}');
        print('✅ Verified: ${data['isVerified'] ?? "MISSING"}');
        print('⏸️ Suspended: ${data['isSuspended'] ?? "MISSING"}');
        print('📅 Created: ${data['createdAt'] ?? "MISSING"}');
        
        // Check for potential issues
        final issues = <String>[];
        if (data['fullName'] == null) issues.add('fullName');
        if (data['role'] == null) issues.add('role');
        if (data['isVerified'] == null) issues.add('isVerified');
        if (data['isSuspended'] == null) issues.add('isSuspended');
        if (data['createdAt'] == null) issues.add('createdAt');
        
        if (issues.isNotEmpty) {
          print('⚠️ MISSING FIELDS: ${issues.join(", ")}');
        }
      }
      
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}
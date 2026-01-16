import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:addis_rent/data/models/user_model.dart';
import 'package:addis_rent/core/constants/app_constants.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserModel>> getUsers({
    String? role,
    bool? isVerified,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.usersCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (role != null) {
        query = query.where('role', isEqualTo: role);
      }

      if (isVerified != null) {
        query = query.where('isVerified', isEqualTo: isVerified);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) =>
              UserModel.fromMap(doc.data()! as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserVerification({
    required String userId,
    required bool isVerified,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'isVerified': isVerified,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? profileImage,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updateData['fullName'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (profileImage != null) updateData['profileImage'] = profileImage;

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(updateData);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getUsersCount({String? role}) async {
    try {
      Query query = _firestore.collection(AppConstants.usersCollection);

      if (role != null) {
        query = query.where('role', isEqualTo: role);
      }

      final snapshot = await query.get();
      return snapshot.size;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final users = await getUsers();
      return users.where((user) {
        return user.fullName.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase()) ||
            user.phone.contains(query);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}

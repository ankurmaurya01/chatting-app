import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of user model
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!, doc.id) : null);
  }

  // Fetch single user by ID
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore.collection(AppConstants.usersCollection).doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  // Update Online / Offline Presence
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // Update Profile Info
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required String bio,
    required DateTime dob,
  }) async {
    await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
      'fullName': fullName.trim(),
      'bio': bio.trim(),
      'dob': Timestamp.fromDate(dob),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Contact Discovery: Search users by username, email, or mobile
  Future<List<UserModel>> searchUsers(String query, String currentUserId) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    final cleanLower = clean.toLowerCase();
    final results = <String, UserModel>{};

    // 1. Search by Username Prefix
    final usernameQuery = await _firestore
        .collection(AppConstants.usersCollection)
        .where('username', isGreaterThanOrEqualTo: cleanLower)
        .where('username', isLessThanOrEqualTo: '$cleanLower\uf8ff')
        .limit(15)
        .get();

    for (var doc in usernameQuery.docs) {
      if (doc.id != currentUserId) {
        results[doc.id] = UserModel.fromMap(doc.data(), doc.id);
      }
    }

    // 2. Exact match by Mobile
    final mobileQuery = await _firestore
        .collection(AppConstants.usersCollection)
        .where('mobile', '==', clean)
        .limit(5)
        .get();

    for (var doc in mobileQuery.docs) {
      if (doc.id != currentUserId) {
        results[doc.id] = UserModel.fromMap(doc.data(), doc.id);
      }
    }

    // 3. Exact match by Email
    final emailQuery = await _firestore
        .collection(AppConstants.usersCollection)
        .where('email', '==', cleanLower)
        .limit(5)
        .get();

    for (var doc in emailQuery.docs) {
      if (doc.id != currentUserId) {
        results[doc.id] = UserModel.fromMap(doc.data(), doc.id);
      }
    }

    return results.values.toList();
  }

  // Get all users (for initial contacts list)
  Future<List<UserModel>> getRecentContacts(String currentUserId) async {
    final query = await _firestore
        .collection(AppConstants.usersCollection)
        .orderBy('fullName')
        .limit(50)
        .get();

    return query.docs
        .where((doc) => doc.id != currentUserId)
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}

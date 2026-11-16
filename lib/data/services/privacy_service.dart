import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class PrivacyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Block a user
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
    required String blockedUsername,
  }) async {
    final blockDocId = "${blockerId}_$blockedId";
    await _firestore.collection(AppConstants.userBlocksCollection).doc(blockDocId).set({
      'id': blockDocId,
      'blockerId': blockerId,
      'blockedId': blockedId,
      'blockedUsername': blockedUsername,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. Unblock a user
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    final blockDocId = "${blockerId}_$blockedId";
    await _firestore.collection(AppConstants.userBlocksCollection).doc(blockDocId).delete();
  }

  // 3. Stream of blocked user IDs for a user
  Stream<List<String>> getBlockedUserIdsStream(String blockerId) {
    return _firestore
        .collection(AppConstants.userBlocksCollection)
        .where('blockerId', '==', blockerId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()['blockedId'] as String).toList());
  }

  // 4. Report a user
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? details,
  }) async {
    await _firestore.collection(AppConstants.userReportsCollection).add({
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'details': details ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  // 5. Update user privacy settings
  Future<void> updatePrivacySettings({
    required String userId,
    required PrivacySettings settings,
  }) async {
    await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
      'privacySettings': settings.toMap(),
    });
  }
}

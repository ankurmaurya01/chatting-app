import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/security/encryption_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Stream of user conversations (sorted by last message)
  Stream<List<ConversationModel>> getConversationsStream(String userId) {
    return _firestore
        .collection(AppConstants.conversationsCollection)
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ConversationModel.fromMap(doc.data(), doc.id))
          .where((conv) => !conv.deletedBy.contains(userId))
          .toList();
    });
  }

  // 2. Stream of messages for a conversation
  Stream<List<MessageModel>> getMessagesStream(String conversationId, String currentUserId) {
    return _firestore
        .collection(AppConstants.conversationsCollection)
        .doc(conversationId)
        .collection(AppConstants.messagesCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final model = MessageModel.fromMap(doc.data(), doc.id);
            // Decrypt message text client-side
            final decryptedText = EncryptionService.decryptMessage(model.text, conversationId);
            return model.copyWith(text: decryptedText);
          })
          .where((msg) => !msg.deletedForUsers.contains(currentUserId))
          .toList();
    });
  }

  // 3. Get or Create 1-on-1 Conversation
  Future<ConversationModel> getOrCreatePrivateConversation({
    required String currentUserId,
    required String currentUserName,
    required String targetUserId,
    required String targetUserName,
  }) async {
    // Generate deterministic 1-on-1 conversation ID
    final sortedIds = [currentUserId, targetUserId]..sort();
    final convId = "conv_${sortedIds[0]}_${sortedIds[1]}";

    final docRef = _firestore.collection(AppConstants.conversationsCollection).doc(convId);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      // If previously deleted by user, remove from deletedBy
      final conv = ConversationModel.fromMap(docSnap.data()!, convId);
      if (conv.deletedBy.contains(currentUserId)) {
        await docRef.update({
          'deletedBy': FieldValue.arrayRemove([currentUserId])
        });
      }
      return conv;
    }

    // Create new conversation document
    final newConv = ConversationModel(
      id: convId,
      type: ConversationType.private,
      participantIds: sortedIds,
      participantNames: {
        currentUserId: currentUserName,
        targetUserId: targetUserName,
      },
      unreadCounts: {
        currentUserId: 0,
        targetUserId: 0,
      },
    );

    await docRef.set(newConv.toMap());
    return newConv;
  }

  // 4. Create Group Conversation
  Future<ConversationModel> createGroupConversation({
    required String groupName,
    required String description,
    required String creatorId,
    required String creatorName,
    required List<String> memberIds,
    required Map<String, String> memberNames,
  }) async {
    final allParticipants = [creatorId, ...memberIds].toSet().toList();
    final docRef = _firestore.collection(AppConstants.conversationsCollection).doc();

    final groupConv = ConversationModel(
      id: docRef.id,
      type: ConversationType.group,
      participantIds: allParticipants,
      participantNames: memberNames,
      groupName: groupName.trim(),
      groupDescription: description.trim(),
      groupCreatedBy: creatorId,
      groupAdminIds: [creatorId],
      unreadCounts: {for (var id in allParticipants) id: 0},
    );

    final batch = _firestore.batch();
    batch.set(docRef, groupConv.toMap());

    // Also register group entry in groups collection
    batch.set(_firestore.collection(AppConstants.groupsCollection).doc(docRef.id), {
      'id': docRef.id,
      'name': groupName.trim(),
      'description': description.trim(),
      'createdBy': creatorId,
      'adminIds': [creatorId],
      'memberIds': allParticipants,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return groupConv;
  }

  // 5. Send Text Message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String plainText,
    MessageReply? replyTo,
    bool isForwarded = false,
    int disappearingSeconds = 0,
  }) async {
    final msgRef = _firestore
        .collection(AppConstants.conversationsCollection)
        .doc(conversationId)
        .collection(AppConstants.messagesCollection)
        .doc();

    // Encrypt client-side using AES-256
    final cipherText = EncryptionService.encryptMessage(plainText.trim(), conversationId);

    // Calculate expiration if disappearing messages enabled
    DateTime? expiresAt;
    if (disappearingSeconds > 0) {
      expiresAt = DateTime.now().add(Duration(seconds: disappearingSeconds));
    }

    final message = MessageModel(
      id: msgRef.id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      text: cipherText,
      replyTo: replyTo,
      isForwarded: isForwarded,
      expiresAt: expiresAt,
    );

    final batch = _firestore.batch();
    batch.set(msgRef, message.toMap());

    // Update conversation metadata
    batch.update(
      _firestore.collection(AppConstants.conversationsCollection).doc(conversationId),
      {
        'lastMessage': plainText.trim(),
        'lastMessageSenderId': senderId,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  // 6. Edit Message
  Future<void> editMessage({
    required String conversationId,
    required String messageId,
    required String newPlainText,
  }) async {
    final cipherText = EncryptionService.encryptMessage(newPlainText.trim(), conversationId);
    await _firestore
        .collection(AppConstants.conversationsCollection)
        .doc(conversationId)
        .collection(AppConstants.messagesCollection)
        .doc(messageId)
        .update({
      'text': cipherText,
      'isEdited': true,
    });
  }

  // 7. Delete Message for Everyone
  Future<void> deleteMessageForEveryone({
    required String conversationId,
    required String messageId,
  }) async {
    await _firestore
        .collection(AppConstants.conversationsCollection)
        .doc(conversationId)
        .collection(AppConstants.messagesCollection)
        .doc(messageId)
        .update({
      'isDeletedForEveryone': true,
      'text': '[This message was deleted]',
    });
  }

  // 8. Delete Message for Me
  Future<void> deleteMessageForMe({
    required String conversationId,
    required String messageId,
    required String currentUserId,
  }) async {
    await _firestore
        .collection(AppConstants.conversationsCollection)
        .doc(conversationId)
        .collection(AppConstants.messagesCollection)
        .doc(messageId)
        .update({
      'deletedForUsers': FieldValue.arrayUnion([currentUserId]),
    });
  }

  // 9. Pin / Unpin Message
  Future<void> togglePinMessage({
    required String conversationId,
    required String messageId,
    required bool currentPinnedStatus,
  }) async {
    await _firestore
        .collection(AppConstants.conversationsCollection)
        .doc(conversationId)
        .collection(AppConstants.messagesCollection)
        .doc(messageId)
        .update({
      'isPinned': !currentPinnedStatus,
    });
  }

  // 10. Star / Unstar Message
  Future<void> toggleStarMessage({
    required String conversationId,
    required String messageId,
    required String currentUserId,
    required bool isCurrentlyStarred,
  }) async {
    final ref = _firestore
        .collection(AppConstants.conversationsCollection)
        .doc(conversationId)
        .collection(AppConstants.messagesCollection)
        .doc(messageId);

    if (isCurrentlyStarred) {
      await ref.update({'starredByUsers': FieldValue.arrayRemove([currentUserId])});
    } else {
      await ref.update({'starredByUsers': FieldValue.arrayUnion([currentUserId])});
    }
  }

  // 11. Toggle Message Reaction
  Future<void> toggleReaction({
    required String conversationId,
    required String messageId,
    required String currentUserId,
    required String emoji,
  }) async {
    final ref = _firestore
        .collection(AppConstants.conversationsCollection)
        .doc(conversationId)
        .collection(AppConstants.messagesCollection)
        .doc(messageId);

    final doc = await ref.get();
    if (!doc.exists) return;

    final reactions = Map<String, dynamic>.from(doc.data()?['reactions'] ?? {});
    if (reactions[currentUserId] == emoji) {
      reactions.remove(currentUserId);
    } else {
      reactions[currentUserId] = emoji;
    }

    await ref.update({'reactions': reactions});
  }

  // 12. Mark Conversation Messages as Read
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String currentUserId,
  }) async {
    final convRef = _firestore.collection(AppConstants.conversationsCollection).doc(conversationId);

    // Reset unread counter for current user and remove from markedUnreadBy
    await convRef.update({
      'unreadCounts.$currentUserId': 0,
      'markedUnreadBy': FieldValue.arrayRemove([currentUserId]),
    });

    // Update unread messages sent by others
    final unreadMsgs = await convRef
        .collection(AppConstants.messagesCollection)
        .where('senderId', isNotEqualTo: currentUserId)
        .where('status', isNotEqualTo: MessageStatus.read.name)
        .limit(50)
        .get();

    if (unreadMsgs.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (var doc in unreadMsgs.docs) {
        batch.update(doc.reference, {'status': MessageStatus.read.name});
      }
      await batch.commit();
    }
  }

  // 13. Typing Indicator
  Future<void> setTypingStatus({
    required String conversationId,
    required String currentUserId,
    required bool isTyping,
  }) async {
    final convRef = _firestore.collection(AppConstants.conversationsCollection).doc(conversationId);
    if (isTyping) {
      await convRef.update({'typingUserIds': FieldValue.arrayUnion([currentUserId])});
    } else {
      await convRef.update({'typingUserIds': FieldValue.arrayRemove([currentUserId])});
    }
  }

  // 14. Conversation Actions: Pin, Archive, Mute, Mark Unread, Clear Chat, Delete
  Future<void> togglePinConversation(String conversationId, String userId, bool isPinned) async {
    final ref = _firestore.collection(AppConstants.conversationsCollection).doc(conversationId);
    await ref.update({
      'pinnedBy': isPinned ? FieldValue.arrayRemove([userId]) : FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> toggleArchiveConversation(String conversationId, String userId, bool isArchived) async {
    final ref = _firestore.collection(AppConstants.conversationsCollection).doc(conversationId);
    await ref.update({
      'archivedBy': isArchived ? FieldValue.arrayRemove([userId]) : FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> toggleMuteConversation(String conversationId, String userId, bool isMuted) async {
    final ref = _firestore.collection(AppConstants.conversationsCollection).doc(conversationId);
    await ref.update({
      'mutedBy': isMuted ? FieldValue.arrayRemove([userId]) : FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> toggleMarkUnreadConversation(String conversationId, String userId, bool isMarked) async {
    final ref = _firestore.collection(AppConstants.conversationsCollection).doc(conversationId);
    await ref.update({
      'markedUnreadBy': isMarked ? FieldValue.arrayRemove([userId]) : FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> clearChat(String conversationId, String userId) async {
    final ref = _firestore.collection(AppConstants.conversationsCollection).doc(conversationId);
    await ref.update({
      'clearedChatTimestamps.$userId': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteConversation(String conversationId, String userId) async {
    final ref = _firestore.collection(AppConstants.conversationsCollection).doc(conversationId);
    await ref.update({
      'deletedBy': FieldValue.arrayUnion([userId]),
    });
  }

  // 15. Set Disappearing Messages Timer
  Future<void> setDisappearingDuration({
    required String conversationId,
    required int seconds,
  }) async {
    await _firestore.collection(AppConstants.conversationsCollection).doc(conversationId).update({
      'disappearingDurationSeconds': seconds,
    });
  }

  // 16. Search Messages
  Future<List<MessageModel>> searchMessages({
    required String conversationId,
    required String query,
    DateTime? searchDate,
  }) async {
    Query q = _firestore
        .collection(AppConstants.conversationsCollection)
        .doc(conversationId)
        .collection(AppConstants.messagesCollection)
        .orderBy('timestamp', descending: true);

    if (searchDate != null) {
      final startOfDay = DateTime(searchDate.year, searchDate.month, searchDate.day);
      final endOfDay = DateTime(searchDate.year, searchDate.month, searchDate.day, 23, 59, 59);
      q = q.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
           .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }

    final snap = await q.limit(100).get();
    final cleanQuery = query.toLowerCase().trim();

    final List<MessageModel> results = [];
    for (var doc in snap.docs) {
      final model = MessageModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      final decryptedText = EncryptionService.decryptMessage(model.text, conversationId);
      if (cleanQuery.isEmpty || decryptedText.toLowerCase().contains(cleanQuery)) {
        results.add(model.copyWith(text: decryptedText));
      }
    }
    return results;
  }
}

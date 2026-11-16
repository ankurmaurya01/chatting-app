import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus { sent, delivered, read }

class MessageReply {
  final String messageId;
  final String senderId;
  final String senderName;
  final String text;

  const MessageReply({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.text,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
    };
  }

  factory MessageReply.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const MessageReply(messageId: '', senderId: '', senderName: '', text: '');
    return MessageReply(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;
  final MessageReply? replyTo;
  final bool isForwarded;
  final bool isEdited;
  final bool isDeletedForEveryone;
  final List<String> deletedForUsers;
  final bool isPinned;
  final List<String> starredByUsers;
  final Map<String, String> reactions; // userId -> emoji
  final DateTime? expiresAt; // Disappearing messages

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.text,
    DateTime? timestamp,
    this.status = MessageStatus.sent,
    this.replyTo,
    this.isForwarded = false,
    this.isEdited = false,
    this.isDeletedForEveryone = false,
    this.deletedForUsers = const [],
    this.isPinned = false,
    this.starredByUsers = const [],
    this.reactions = const {},
    this.expiresAt,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
      'replyTo': replyTo?.toMap(),
      'isForwarded': isForwarded,
      'isEdited': isEdited,
      'isDeletedForEveryone': isDeletedForEveryone,
      'deletedForUsers': deletedForUsers,
      'isPinned': isPinned,
      'starredByUsers': starredByUsers,
      'reactions': reactions,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    MessageStatus parseStatus(String? val) {
      if (val == 'read') return MessageStatus.read;
      if (val == 'delivered') return MessageStatus.delivered;
      return MessageStatus.sent;
    }

    return MessageModel(
      id: docId,
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      timestamp: parseTime(map['timestamp']),
      status: parseStatus(map['status']),
      replyTo: map['replyTo'] != null ? MessageReply.fromMap(Map<String, dynamic>.from(map['replyTo'])) : null,
      isForwarded: map['isForwarded'] ?? false,
      isEdited: map['isEdited'] ?? false,
      isDeletedForEveryone: map['isDeletedForEveryone'] ?? false,
      deletedForUsers: List<String>.from(map['deletedForUsers'] ?? []),
      isPinned: map['isPinned'] ?? false,
      starredByUsers: List<String>.from(map['starredByUsers'] ?? []),
      reactions: Map<String, String>.from(map['reactions'] ?? {}),
      expiresAt: map['expiresAt'] != null ? parseTime(map['expiresAt']) : null,
    );
  }

  MessageModel copyWith({
    String? text,
    MessageStatus? status,
    bool? isEdited,
    bool? isDeletedForEveryone,
    List<String>? deletedForUsers,
    bool? isPinned,
    List<String>? starredByUsers,
    Map<String, String>? reactions,
  }) {
    return MessageModel(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      text: text ?? this.text,
      timestamp: timestamp,
      status: status ?? this.status,
      replyTo: replyTo,
      isForwarded: isForwarded,
      isEdited: isEdited ?? this.isEdited,
      isDeletedForEveryone: isDeletedForEveryone ?? this.isDeletedForEveryone,
      deletedForUsers: deletedForUsers ?? this.deletedForUsers,
      isPinned: isPinned ?? this.isPinned,
      starredByUsers: starredByUsers ?? this.starredByUsers,
      reactions: reactions ?? this.reactions,
      expiresAt: expiresAt,
    );
  }
}

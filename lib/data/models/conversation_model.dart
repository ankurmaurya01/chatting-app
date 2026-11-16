import 'package:cloud_firestore/cloud_firestore.dart';

enum ConversationType { private, group }

class ConversationModel {
  final String id;
  final ConversationType type;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageTimestamp;
  final Map<String, int> unreadCounts;
  final List<String> pinnedBy;
  final List<String> archivedBy;
  final List<String> mutedBy;
  final List<String> markedUnreadBy;
  final List<String> deletedBy;
  final Map<String, DateTime> clearedChatTimestamps;
  final int disappearingDurationSeconds;
  final List<String> typingUserIds;

  // Group specific properties
  final String? groupName;
  final String? groupDescription;
  final String? groupCreatedBy;
  final List<String> groupAdminIds;

  ConversationModel({
    required this.id,
    required this.type,
    required this.participantIds,
    this.participantNames = const {},
    this.lastMessage = '',
    this.lastMessageSenderId = '',
    DateTime? lastMessageTimestamp,
    this.unreadCounts = const {},
    this.pinnedBy = const [],
    this.archivedBy = const [],
    this.mutedBy = const [],
    this.markedUnreadBy = const [],
    this.deletedBy = const [],
    this.clearedChatTimestamps = const {},
    this.disappearingDurationSeconds = 0,
    this.typingUserIds = const [],
    this.groupName,
    this.groupDescription,
    this.groupCreatedBy,
    this.groupAdminIds = const [],
  }) : lastMessageTimestamp = lastMessageTimestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    Map<String, Timestamp> clearedMap = {};
    clearedChatTimestamps.forEach((key, val) {
      clearedMap[key] = Timestamp.fromDate(val);
    });

    return {
      'id': id,
      'type': type.name,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTimestamp': Timestamp.fromDate(lastMessageTimestamp),
      'unreadCounts': unreadCounts,
      'pinnedBy': pinnedBy,
      'archivedBy': archivedBy,
      'mutedBy': mutedBy,
      'markedUnreadBy': markedUnreadBy,
      'deletedBy': deletedBy,
      'clearedChatTimestamps': clearedMap,
      'disappearingDurationSeconds': disappearingDurationSeconds,
      'typingUserIds': typingUserIds,
      'groupName': groupName,
      'groupDescription': groupDescription,
      'groupCreatedBy': groupCreatedBy,
      'groupAdminIds': groupAdminIds,
    };
  }

  factory ConversationModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    Map<String, DateTime> clearedMap = {};
    if (map['clearedChatTimestamps'] is Map) {
      (map['clearedChatTimestamps'] as Map).forEach((k, v) {
        clearedMap[k.toString()] = parseTime(v);
      });
    }

    return ConversationModel(
      id: docId,
      type: map['type'] == 'group' ? ConversationType.group : ConversationType.private,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      lastMessageTimestamp: parseTime(map['lastMessageTimestamp']),
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      pinnedBy: List<String>.from(map['pinnedBy'] ?? []),
      archivedBy: List<String>.from(map['archivedBy'] ?? []),
      mutedBy: List<String>.from(map['mutedBy'] ?? []),
      markedUnreadBy: List<String>.from(map['markedUnreadBy'] ?? []),
      deletedBy: List<String>.from(map['deletedBy'] ?? []),
      clearedChatTimestamps: clearedMap,
      disappearingDurationSeconds: map['disappearingDurationSeconds'] ?? 0,
      typingUserIds: List<String>.from(map['typingUserIds'] ?? []),
      groupName: map['groupName'],
      groupDescription: map['groupDescription'],
      groupCreatedBy: map['groupCreatedBy'],
      groupAdminIds: List<String>.from(map['groupAdminIds'] ?? []),
    );
  }
}

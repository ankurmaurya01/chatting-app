import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final List<String> adminIds;
  final List<String> memberIds;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.createdBy,
    required this.adminIds,
    required this.memberIds,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name.trim(),
      'description': description.trim(),
      'createdBy': createdBy,
      'adminIds': adminIds,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return GroupModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      adminIds: List<String>.from(map['adminIds'] ?? []),
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdAt: parseTime(map['createdAt']),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacySettings {
  final bool hideOnline;
  final bool hideLastSeen;
  final bool readReceipts;
  final bool typingIndicators;

  const PrivacySettings({
    this.hideOnline = false,
    this.hideLastSeen = false,
    this.readReceipts = true,
    this.typingIndicators = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'hideOnline': hideOnline,
      'hideLastSeen': hideLastSeen,
      'readReceipts': readReceipts,
      'typingIndicators': typingIndicators,
    };
  }

  factory PrivacySettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PrivacySettings();
    return PrivacySettings(
      hideOnline: map['hideOnline'] ?? false,
      hideLastSeen: map['hideLastSeen'] ?? false,
      readReceipts: map['readReceipts'] ?? true,
      typingIndicators: map['typingIndicators'] ?? true,
    );
  }

  PrivacySettings copyWith({
    bool? hideOnline,
    bool? hideLastSeen,
    bool? readReceipts,
    bool? typingIndicators,
  }) {
    return PrivacySettings(
      hideOnline: hideOnline ?? this.hideOnline,
      hideLastSeen: hideLastSeen ?? this.hideLastSeen,
      readReceipts: readReceipts ?? this.readReceipts,
      typingIndicators: typingIndicators ?? this.typingIndicators,
    );
  }
}

class UserModel {
  final String id;
  final String username;
  final String fullName;
  final String mobile;
  final String email;
  final DateTime dob;
  final bool isEmailVerified;
  final bool isMobileVerified;
  final bool isOnline;
  final DateTime? lastSeen;
  final String bio;
  final String? fcmToken;
  final PrivacySettings privacySettings;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.dob,
    this.isEmailVerified = false,
    this.isMobileVerified = false,
    this.isOnline = false,
    this.lastSeen,
    this.bio = "Hey there! I am using Whisper.",
    this.fcmToken,
    this.privacySettings = const PrivacySettings(),
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username.toLowerCase().trim(),
      'fullName': fullName.trim(),
      'mobile': mobile.trim(),
      'email': email.toLowerCase().trim(),
      'dob': Timestamp.fromDate(dob),
      'isEmailVerified': isEmailVerified,
      'isMobileVerified': isMobileVerified,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'bio': bio,
      'fcmToken': fcmToken,
      'privacySettings': privacySettings.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return UserModel(
      id: docId,
      username: map['username'] ?? '',
      fullName: map['fullName'] ?? '',
      mobile: map['mobile'] ?? '',
      email: map['email'] ?? '',
      dob: parseTimestamp(map['dob']),
      isEmailVerified: map['isEmailVerified'] ?? false,
      isMobileVerified: map['isMobileVerified'] ?? false,
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null ? parseTimestamp(map['lastSeen']) : null,
      bio: map['bio'] ?? "Hey there! I am using Whisper.",
      fcmToken: map['fcmToken'],
      privacySettings: PrivacySettings.fromMap(map['privacySettings']),
      createdAt: parseTimestamp(map['createdAt']),
    );
  }

  UserModel copyWith({
    String? username,
    String? fullName,
    String? mobile,
    String? email,
    DateTime? dob,
    bool? isEmailVerified,
    bool? isMobileVerified,
    bool? isOnline,
    DateTime? lastSeen,
    String? bio,
    String? fcmToken,
    PrivacySettings? privacySettings,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isMobileVerified: isMobileVerified ?? this.isMobileVerified,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      bio: bio ?? this.bio,
      fcmToken: fcmToken ?? this.fcmToken,
      privacySettings: privacySettings ?? this.privacySettings,
      createdAt: createdAt,
    );
  }
}

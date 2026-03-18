import 'package:cloud_firestore/cloud_firestore.dart';

class UserMandaliMembership {
  final String mandaliId;
  final String displayName;
  final String category;
  final String description;
  final String inviteCode;
  final String createdBy;
  final String role;
  final String status;
  final int contributionCount;
  final int challengeContributionCount;
  final bool isSelectedActiveMandali;
  final String joinedAtIso;
  final String? lastContributionAtIso;

  const UserMandaliMembership({
    required this.mandaliId,
    required this.displayName,
    required this.category,
    required this.description,
    required this.inviteCode,
    required this.createdBy,
    required this.role,
    required this.status,
    required this.contributionCount,
    required this.challengeContributionCount,
    required this.isSelectedActiveMandali,
    required this.joinedAtIso,
    this.lastContributionAtIso,
  });

  bool get isActive => status.trim().toLowerCase() == 'active';

  DateTime? get joinedAt => _parseDate(joinedAtIso);
  DateTime? get lastContributionAt => _parseDate(lastContributionAtIso);

  factory UserMandaliMembership.fromMap(Map<String, dynamic> map) {
    final displayName = (map['displayName'] ?? '').toString().trim();

    return UserMandaliMembership(
      mandaliId: (map['mandaliId'] ?? '').toString().trim(),
      displayName: displayName.isEmpty ? 'Bhakta Mandali' : displayName,
      category: (map['category'] ?? '').toString().trim(),
      description: (map['description'] ?? '').toString().trim(),
      inviteCode: (map['inviteCode'] ?? '').toString().trim(),
      createdBy: (map['createdBy'] ?? '').toString().trim(),
      role: (map['role'] ?? 'member').toString().trim(),
      status: (map['status'] ?? 'active').toString().trim(),
      contributionCount: (map['contributionCount'] as num?)?.toInt() ?? 0,
      challengeContributionCount:
      (map['challengeContributionCount'] as num?)?.toInt() ?? 0,
      isSelectedActiveMandali: map['isSelectedActiveMandali'] == true,
      joinedAtIso: (map['joinedAt'] ?? '').toString().trim(),
      lastContributionAtIso: map['lastContributionAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mandaliId': mandaliId,
      'displayName': displayName,
      'category': category,
      'description': description,
      'inviteCode': inviteCode,
      'createdBy': createdBy,
      'role': role,
      'status': status,
      'contributionCount': contributionCount,
      'challengeContributionCount': challengeContributionCount,
      'isSelectedActiveMandali': isSelectedActiveMandali,
      'joinedAt': joinedAtIso,
      'lastContributionAt': lastContributionAtIso,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
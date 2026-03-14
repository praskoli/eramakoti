import 'package:cloud_firestore/cloud_firestore.dart';

class BhaktaMandaliMember {
  final String uid;
  final String displayName;
  final String photoUrl;
  final String role;
  final String status;
  final int contributionCount;
  final int challengeContributionCount;
  final String joinedAtIso;
  final String? lastContributionAtIso;

  const BhaktaMandaliMember({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.role,
    required this.status,
    required this.contributionCount,
    required this.challengeContributionCount,
    required this.joinedAtIso,
    this.lastContributionAtIso,
  });

  bool get isCreator => role.trim().toLowerCase() == 'creator';
  bool get isActive => status.trim().toLowerCase() == 'active';

  DateTime? get joinedAt => _parseDate(joinedAtIso);
  DateTime? get lastContributionAt => _parseDate(lastContributionAtIso);

  factory BhaktaMandaliMember.fromMap(Map<String, dynamic> map) {
    return BhaktaMandaliMember(
      uid: (map['uid'] ?? '').toString(),
      displayName: (map['displayName'] ?? '').toString(),
      photoUrl: (map['photoUrl'] ?? '').toString(),
      role: (map['role'] ?? 'member').toString(),
      status: (map['status'] ?? 'active').toString(),
      contributionCount: (map['contributionCount'] as num?)?.toInt() ?? 0,
      challengeContributionCount:
      (map['challengeContributionCount'] as num?)?.toInt() ?? 0,
      joinedAtIso: (map['joinedAt'] ?? '').toString(),
      lastContributionAtIso: map['lastContributionAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'status': status,
      'contributionCount': contributionCount,
      'challengeContributionCount': challengeContributionCount,
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

import 'package:cloud_firestore/cloud_firestore.dart';

import 'bhakta_mandali_challenge.dart';

class BhaktaMandali {
  final String mandaliId;
  final String name;
  final String displayName;
  final String normalizedName;
  final String category;
  final String description;
  final bool isPublic;
  final String inviteCode;
  final String createdBy;
  final String createdByName;
  final int memberCount;
  final int totalCount;
  final String activeChallengeId;
  final BhaktaMandaliChallenge? activeChallenge;
  final String createdAtIso;
  final String updatedAtIso;
  final String? lastContributionAtIso;
  final String? lastContributionBy;

  const BhaktaMandali({
    required this.mandaliId,
    required this.name,
    required this.displayName,
    required this.normalizedName,
    required this.category,
    required this.description,
    required this.isPublic,
    required this.inviteCode,
    required this.createdBy,
    required this.createdByName,
    required this.memberCount,
    required this.totalCount,
    required this.activeChallengeId,
    required this.activeChallenge,
    required this.createdAtIso,
    required this.updatedAtIso,
    this.lastContributionAtIso,
    this.lastContributionBy,
  });

  DateTime? get createdAt => _parseDate(createdAtIso);
  DateTime? get updatedAt => _parseDate(updatedAtIso);
  DateTime? get lastContributionAt => _parseDate(lastContributionAtIso);

  factory BhaktaMandali.fromMap(Map<String, dynamic> map) {
    final activeChallengeRaw = map['activeChallenge'];
    return BhaktaMandali(
      mandaliId: (map['mandaliId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      displayName: (map['displayName'] ?? '').toString(),
      normalizedName: (map['normalizedName'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      isPublic: map['isPublic'] == true,
      inviteCode: (map['inviteCode'] ?? '').toString(),
      createdBy: (map['createdBy'] ?? '').toString(),
      createdByName: (map['createdByName'] ?? '').toString(),
      memberCount: (map['memberCount'] as num?)?.toInt() ?? 0,
      totalCount: (map['totalCount'] as num?)?.toInt() ?? 0,
      activeChallengeId: (map['activeChallengeId'] ?? '').toString(),
      activeChallenge: activeChallengeRaw is Map<String, dynamic>
          ? BhaktaMandaliChallenge.fromMap(activeChallengeRaw)
          : null,
      createdAtIso: (map['createdAt'] ?? '').toString(),
      updatedAtIso: (map['updatedAt'] ?? '').toString(),
      lastContributionAtIso: map['lastContributionAt']?.toString(),
      lastContributionBy: map['lastContributionBy']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mandaliId': mandaliId,
      'name': name,
      'displayName': displayName,
      'normalizedName': normalizedName,
      'category': category,
      'description': description,
      'isPublic': isPublic,
      'inviteCode': inviteCode,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'memberCount': memberCount,
      'totalCount': totalCount,
      'activeChallengeId': activeChallengeId,
      'activeChallenge': activeChallenge?.toMap(),
      'createdAt': createdAtIso,
      'updatedAt': updatedAtIso,
      'lastContributionAt': lastContributionAtIso,
      'lastContributionBy': lastContributionBy,
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

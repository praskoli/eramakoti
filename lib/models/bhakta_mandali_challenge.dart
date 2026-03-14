import 'package:cloud_firestore/cloud_firestore.dart';

class BhaktaMandaliChallenge {
  final String challengeId;
  final String title;
  final int target;
  final int progressCount;
  final String status;
  final String startDateIso;
  final String endDateIso;
  final String createdBy;
  final String createdAtIso;
  final String updatedAtIso;
  final String? completedAtIso;

  const BhaktaMandaliChallenge({
    required this.challengeId,
    required this.title,
    required this.target,
    required this.progressCount,
    required this.status,
    required this.startDateIso,
    required this.endDateIso,
    required this.createdBy,
    required this.createdAtIso,
    required this.updatedAtIso,
    this.completedAtIso,
  });

  bool get isActive => status.trim().toLowerCase() == 'active';
  bool get isCompleted => status.trim().toLowerCase() == 'completed';

  DateTime? get startDate => _parseDate(startDateIso);
  DateTime? get endDate => _parseDate(endDateIso);
  DateTime? get createdAt => _parseDate(createdAtIso);
  DateTime? get updatedAt => _parseDate(updatedAtIso);
  DateTime? get completedAt => _parseDate(completedAtIso);

  double get progressPercent {
    if (target <= 0) return 0;
    final percent = progressCount / target;
    if (percent < 0) return 0;
    if (percent > 1) return 1;
    return percent;
  }

  int get remainingCount {
    final remaining = target - progressCount;
    return remaining < 0 ? 0 : remaining;
  }

  factory BhaktaMandaliChallenge.fromMap(Map<String, dynamic> map) {
    return BhaktaMandaliChallenge(
      challengeId: (map['challengeId'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      target: (map['target'] as num?)?.toInt() ?? 0,
      progressCount: (map['progressCount'] as num?)?.toInt() ?? 0,
      status: (map['status'] ?? 'active').toString(),
      startDateIso: (map['startDate'] ?? '').toString(),
      endDateIso: (map['endDate'] ?? '').toString(),
      createdBy: (map['createdBy'] ?? '').toString(),
      createdAtIso: (map['createdAt'] ?? '').toString(),
      updatedAtIso: (map['updatedAt'] ?? '').toString(),
      completedAtIso: map['completedAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'title': title,
      'target': target,
      'progressCount': progressCount,
      'status': status,
      'startDate': startDateIso,
      'endDate': endDateIso,
      'createdBy': createdBy,
      'createdAt': createdAtIso,
      'updatedAt': updatedAtIso,
      'completedAt': completedAtIso,
    };
  }

  BhaktaMandaliChallenge copyWith({
    String? challengeId,
    String? title,
    int? target,
    int? progressCount,
    String? status,
    String? startDateIso,
    String? endDateIso,
    String? createdBy,
    String? createdAtIso,
    String? updatedAtIso,
    String? completedAtIso,
  }) {
    return BhaktaMandaliChallenge(
      challengeId: challengeId ?? this.challengeId,
      title: title ?? this.title,
      target: target ?? this.target,
      progressCount: progressCount ?? this.progressCount,
      status: status ?? this.status,
      startDateIso: startDateIso ?? this.startDateIso,
      endDateIso: endDateIso ?? this.endDateIso,
      createdBy: createdBy ?? this.createdBy,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      updatedAtIso: updatedAtIso ?? this.updatedAtIso,
      completedAtIso: completedAtIso ?? this.completedAtIso,
    );
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

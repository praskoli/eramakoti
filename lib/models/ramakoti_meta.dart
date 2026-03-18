import 'package:cloud_firestore/cloud_firestore.dart';

class RamakotiMeta {
  static const int batchSize = 108;

  final String uid;

  // Core counters
  final int totalCount;
  final int todayCount;
  final int currentRunCount;

  // Current active run
  final String currentRunId;

  // Stored batch summary fields
  final int storedCurrentBatchNumber;
  final int storedCurrentBatchProgress;
  final int storedCompletedBatchCount;

  // Writer / run config
  final String language;
  final int targetCount;

  // Optional future summary fields
  final int completedRunsCount;
  final int certificatesCount;
  final int milestoneCount;

  // Personal devotion counters
  final int manualWritingCount;
  final int japaCount;
  final int additionalDevotionCount;
  final int devotionTotalCount;

  // Devotion consent
  final bool devotionConsentAccepted;
  final String devotionConsentVersion;
  final DateTime? devotionConsentAcceptedAt;

  // Active Bhakta Mandali context
  final String activeMandaliId;
  final String activeMandaliName;
  final String activeMandaliChallengeId;
  final DateTime? lastMandaliContributionAt;

  // Timestamps
  final DateTime? lastWrittenAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RamakotiMeta({
    required this.uid,
    required this.totalCount,
    required this.todayCount,
    required this.currentRunCount,
    required this.currentRunId,
    required this.storedCurrentBatchNumber,
    required this.storedCurrentBatchProgress,
    required this.storedCompletedBatchCount,
    required this.language,
    required this.targetCount,
    required this.completedRunsCount,
    required this.certificatesCount,
    required this.milestoneCount,
    required this.manualWritingCount,
    required this.japaCount,
    required this.additionalDevotionCount,
    required this.devotionTotalCount,
    required this.devotionConsentAccepted,
    required this.devotionConsentVersion,
    required this.devotionConsentAcceptedAt,
    required this.activeMandaliId,
    required this.activeMandaliName,
    required this.activeMandaliChallengeId,
    required this.lastMandaliContributionAt,
    required this.lastWrittenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RamakotiMeta.fromMap(Map<String, dynamic> map) {
    final totalCount = (map['totalCount'] as num?)?.toInt() ?? 0;
    final manualWritingCount =
        (map['manualWritingCount'] as num?)?.toInt() ?? 0;
    final japaCount = (map['japaCount'] as num?)?.toInt() ?? 0;
    final additionalDevotionCount =
        (map['additionalDevotionCount'] as num?)?.toInt() ?? 0;

    final computedDevotionTotal = totalCount +
        manualWritingCount +
        japaCount +
        additionalDevotionCount;

    return RamakotiMeta(
      uid: map['uid'] as String? ?? '',
      totalCount: totalCount,
      todayCount: (map['todayCount'] as num?)?.toInt() ?? 0,
      currentRunCount: (map['currentRunCount'] as num?)?.toInt() ?? 0,
      currentRunId: map['currentRunId'] as String? ?? '',
      storedCurrentBatchNumber:
      (map['currentBatchNumber'] as num?)?.toInt() ?? 1,
      storedCurrentBatchProgress:
      (map['currentBatchProgress'] as num?)?.toInt() ?? 0,
      storedCompletedBatchCount:
      (map['completedBatchCount'] as num?)?.toInt() ?? 0,
      language: map['language'] as String? ?? '',
      targetCount: (map['targetCount'] as num?)?.toInt() ?? 0,
      completedRunsCount: (map['completedRunsCount'] as num?)?.toInt() ?? 0,
      certificatesCount: (map['certificatesCount'] as num?)?.toInt() ?? 0,
      milestoneCount: (map['milestoneCount'] as num?)?.toInt() ?? 0,
      manualWritingCount: manualWritingCount,
      japaCount: japaCount,
      additionalDevotionCount: additionalDevotionCount,
      devotionTotalCount:
      (map['devotionTotalCount'] as num?)?.toInt() ?? computedDevotionTotal,
      devotionConsentAccepted:
      (map['devotionConsentAccepted'] as bool?) ?? false,
      devotionConsentVersion:
      (map['devotionConsentVersion'] as String? ?? '').trim(),
      devotionConsentAcceptedAt:
      _parseDate(map['devotionConsentAcceptedAt']),
      activeMandaliId: map['activeMandaliId'] as String? ?? '',
      activeMandaliName: map['activeMandaliName'] as String? ?? '',
      activeMandaliChallengeId:
      map['activeMandaliChallengeId'] as String? ?? '',
      lastMandaliContributionAt:
      _parseDate(map['lastMandaliContributionAt']),
      lastWrittenAt: _parseDate(map['lastWrittenAt']),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static RamakotiMeta empty(String uid) {
    return RamakotiMeta(
      uid: uid,
      totalCount: 0,
      todayCount: 0,
      currentRunCount: 0,
      currentRunId: '',
      storedCurrentBatchNumber: 1,
      storedCurrentBatchProgress: 0,
      storedCompletedBatchCount: 0,
      language: '',
      targetCount: 0,
      completedRunsCount: 0,
      certificatesCount: 0,
      milestoneCount: 0,
      manualWritingCount: 0,
      japaCount: 0,
      additionalDevotionCount: 0,
      devotionTotalCount: 0,
      devotionConsentAccepted: false,
      devotionConsentVersion: '',
      devotionConsentAcceptedAt: null,
      activeMandaliId: '',
      activeMandaliName: '',
      activeMandaliChallengeId: '',
      lastMandaliContributionAt: null,
      lastWrittenAt: null,
      createdAt: null,
      updatedAt: null,
    );
  }

  RamakotiMeta copyWith({
    String? uid,
    int? totalCount,
    int? todayCount,
    int? currentRunCount,
    String? currentRunId,
    int? storedCurrentBatchNumber,
    int? storedCurrentBatchProgress,
    int? storedCompletedBatchCount,
    String? language,
    int? targetCount,
    int? completedRunsCount,
    int? certificatesCount,
    int? milestoneCount,
    int? manualWritingCount,
    int? japaCount,
    int? additionalDevotionCount,
    int? devotionTotalCount,
    bool? devotionConsentAccepted,
    String? devotionConsentVersion,
    DateTime? devotionConsentAcceptedAt,
    String? activeMandaliId,
    String? activeMandaliName,
    String? activeMandaliChallengeId,
    DateTime? lastMandaliContributionAt,
    DateTime? lastWrittenAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RamakotiMeta(
      uid: uid ?? this.uid,
      totalCount: totalCount ?? this.totalCount,
      todayCount: todayCount ?? this.todayCount,
      currentRunCount: currentRunCount ?? this.currentRunCount,
      currentRunId: currentRunId ?? this.currentRunId,
      storedCurrentBatchNumber:
      storedCurrentBatchNumber ?? this.storedCurrentBatchNumber,
      storedCurrentBatchProgress:
      storedCurrentBatchProgress ?? this.storedCurrentBatchProgress,
      storedCompletedBatchCount:
      storedCompletedBatchCount ?? this.storedCompletedBatchCount,
      language: language ?? this.language,
      targetCount: targetCount ?? this.targetCount,
      completedRunsCount: completedRunsCount ?? this.completedRunsCount,
      certificatesCount: certificatesCount ?? this.certificatesCount,
      milestoneCount: milestoneCount ?? this.milestoneCount,
      manualWritingCount: manualWritingCount ?? this.manualWritingCount,
      japaCount: japaCount ?? this.japaCount,
      additionalDevotionCount:
      additionalDevotionCount ?? this.additionalDevotionCount,
      devotionTotalCount: devotionTotalCount ?? this.devotionTotalCount,
      devotionConsentAccepted:
      devotionConsentAccepted ?? this.devotionConsentAccepted,
      devotionConsentVersion:
      devotionConsentVersion ?? this.devotionConsentVersion,
      devotionConsentAcceptedAt:
      devotionConsentAcceptedAt ?? this.devotionConsentAcceptedAt,
      activeMandaliId: activeMandaliId ?? this.activeMandaliId,
      activeMandaliName: activeMandaliName ?? this.activeMandaliName,
      activeMandaliChallengeId:
      activeMandaliChallengeId ?? this.activeMandaliChallengeId,
      lastMandaliContributionAt:
      lastMandaliContributionAt ?? this.lastMandaliContributionAt,
      lastWrittenAt: lastWrittenAt ?? this.lastWrittenAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get completedBatchCount {
    if (storedCompletedBatchCount > 0 || currentRunCount == 0) {
      return storedCompletedBatchCount;
    }
    return currentRunCount ~/ batchSize;
  }

  int get currentBatchNumber {
    if (storedCurrentBatchNumber > 0) {
      return storedCurrentBatchNumber;
    }
    if (currentRunCount <= 0) return 1;
    return ((currentRunCount - 1) ~/ batchSize) + 1;
  }

  int get currentBatchProgress {
    if (storedCurrentBatchProgress > 0 || currentRunCount == 0) {
      return storedCurrentBatchProgress;
    }
    if (currentRunCount <= 0) return 0;
    final remainder = currentRunCount % batchSize;
    return remainder == 0 ? batchSize : remainder;
  }

  int get remainingInCurrentBatch {
    if (currentBatchProgress <= 0) return batchSize;
    if (currentBatchProgress >= batchSize) return 0;
    return batchSize - currentBatchProgress;
  }

  bool get hasCompletedCurrentBatch =>
      currentRunCount > 0 && currentBatchProgress == batchSize;

  double get currentBatchProgressPercent {
    if (currentBatchProgress <= 0) return 0;
    return (currentBatchProgress / batchSize).clamp(0, 1).toDouble();
  }

  bool get hasTarget => targetCount > 0;

  int get remainingToTarget {
    if (!hasTarget) return 0;
    final remaining = targetCount - currentRunCount;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isTargetCompleted => hasTarget && currentRunCount >= targetCount;

  double get targetProgressPercent {
    if (!hasTarget || targetCount <= 0) return 0;
    final progress = currentRunCount / targetCount;
    return progress.clamp(0, 1).toDouble();
  }

  double get croreProgress => totalCount / 10000000;

  int get currentCroreNumber {
    if (totalCount <= 0) return 1;
    return ((totalCount - 1) ~/ 10000000) + 1;
  }

  String get languageLabel =>
      language.trim().isEmpty ? 'Not selected' : language.trim();

  String get targetLabel {
    if (targetCount <= 0) return 'Not selected';
    if (targetCount == 10) return '10';
    if (targetCount == 108) return '108';
    if (targetCount == 10000000) return '1 Crore';
    if (targetCount == 1000000) return '10 Lakh';
    if (targetCount == 100000) return '1 Lakh';
    if (targetCount == 10000) return '10,000';
    if (targetCount == 1000) return '1,000';
    return targetCount.toString();
  }
}
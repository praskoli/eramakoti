import 'package:cloud_firestore/cloud_firestore.dart';

class RamakotiRun {
  final String runId;
  final String uid;
  final String language;
  final int targetCount;
  final int currentRunCount;
  final int finalRunCount;
  final int completedBatchCount;
  final int currentBatchNumber;
  final int currentBatchProgress;
  final String status;
  final DateTime? startedAt;
  final DateTime? lastWrittenAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RamakotiRun({
    required this.runId,
    required this.uid,
    required this.language,
    required this.targetCount,
    required this.currentRunCount,
    required this.finalRunCount,
    required this.completedBatchCount,
    required this.currentBatchNumber,
    required this.currentBatchProgress,
    required this.status,
    required this.startedAt,
    required this.lastWrittenAt,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RamakotiRun.fromMap(Map<String, dynamic> map, {String? docId}) {
    return RamakotiRun(
      runId: (map['runId'] as String?)?.trim().isNotEmpty == true
          ? map['runId'] as String
          : (docId ?? ''),
      uid: map['uid'] as String? ?? '',
      language: map['language'] as String? ?? '',
      targetCount: (map['targetCount'] as num?)?.toInt() ?? 0,
      currentRunCount: (map['currentRunCount'] as num?)?.toInt() ?? 0,
      finalRunCount: (map['finalRunCount'] as num?)?.toInt() ?? 0,
      completedBatchCount: (map['completedBatchCount'] as num?)?.toInt() ?? 0,
      currentBatchNumber: (map['currentBatchNumber'] as num?)?.toInt() ?? 1,
      currentBatchProgress: (map['currentBatchProgress'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'active',
      startedAt: _parseDate(map['startedAt']),
      lastWrittenAt: _parseDate(map['lastWrittenAt']),
      completedAt: _parseDate(map['completedAt']),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);

    return null;
  }

  static RamakotiRun empty(String uid) {
    return RamakotiRun(
      runId: '',
      uid: uid,
      language: '',
      targetCount: 0,
      currentRunCount: 0,
      finalRunCount: 0,
      completedBatchCount: 0,
      currentBatchNumber: 1,
      currentBatchProgress: 0,
      status: 'active',
      startedAt: null,
      lastWrittenAt: null,
      completedAt: null,
      createdAt: null,
      updatedAt: null,
    );
  }

  RamakotiRun copyWith({
    String? runId,
    String? uid,
    String? language,
    int? targetCount,
    int? currentRunCount,
    int? finalRunCount,
    int? completedBatchCount,
    int? currentBatchNumber,
    int? currentBatchProgress,
    String? status,
    DateTime? startedAt,
    DateTime? lastWrittenAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RamakotiRun(
      runId: runId ?? this.runId,
      uid: uid ?? this.uid,
      language: language ?? this.language,
      targetCount: targetCount ?? this.targetCount,
      currentRunCount: currentRunCount ?? this.currentRunCount,
      finalRunCount: finalRunCount ?? this.finalRunCount,
      completedBatchCount: completedBatchCount ?? this.completedBatchCount,
      currentBatchNumber: currentBatchNumber ?? this.currentBatchNumber,
      currentBatchProgress: currentBatchProgress ?? this.currentBatchProgress,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      lastWrittenAt: lastWrittenAt ?? this.lastWrittenAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isCompleted =>
      status.trim().toLowerCase() == 'completed' || completedAt != null;

  bool get isActive => !isCompleted;

  double get targetProgressPercent {
    if (targetCount <= 0) return 0;
    return (currentRunCount / targetCount).clamp(0, 1).toDouble();
  }

  int get remainingToTarget {
    if (targetCount <= 0) return 0;
    final remaining = targetCount - currentRunCount;
    return remaining < 0 ? 0 : remaining;
  }

  String get statusLabel {
    if (isCompleted) return 'Completed';
    return 'Active';
  }
}
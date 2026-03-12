import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ramakoti_meta.dart';

class RamakotiWriteResult {
  final int totalCount;
  final int todayCount;
  final int currentRunCount;
  final bool batchCompleted;
  final int completedBatchNumber;
  final int batchProgress;

  const RamakotiWriteResult({
    required this.totalCount,
    required this.todayCount,
    required this.currentRunCount,
    required this.batchCompleted,
    required this.completedBatchNumber,
    required this.batchProgress,
  });
}

class RamakotiService {
  RamakotiService._();

  static final RamakotiService instance = RamakotiService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _summaryRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('ramakoti_meta')
        .doc('summary');
  }

  DocumentReference<Map<String, dynamic>> _runRef(String uid, String runId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('ramakotiRuns')
        .doc(runId);
  }

  DocumentReference<Map<String, dynamic>> _historyRef(String uid, String runId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('ramakotiHistory')
        .doc(runId);
  }

  String _newRunId() => 'run_${DateTime.now().millisecondsSinceEpoch}';

  Stream<RamakotiMeta> watchSummary(String uid) {
    return _summaryRef(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return RamakotiMeta.empty(uid);
      }
      return RamakotiMeta.fromMap(data);
    });
  }

  Future<RamakotiMeta> getSummary(String uid) async {
    final snapshot = await _summaryRef(uid).get();
    final data = snapshot.data();
    if (data == null) {
      return RamakotiMeta.empty(uid);
    }
    return RamakotiMeta.fromMap(data);
  }

  Future<void> saveLanguageAndTarget({
    required String uid,
    required String language,
    required int targetCount,
  }) async {
    final summaryRef = _summaryRef(uid);

    await _firestore.runTransaction((tx) async {
      final summarySnap = await tx.get(summaryRef);
      final summary = summarySnap.data() ?? <String, dynamic>{};

      final previousRunId = (summary['currentRunId'] as String?)?.trim();
      final previousLanguage = (summary['language'] as String?)?.trim() ?? '';
      final previousTarget = (summary['targetCount'] as num?)?.toInt() ?? 0;
      final previousRunCount =
          (summary['currentRunCount'] as num?)?.toInt() ?? 0;
      final previousTotal = (summary['totalCount'] as num?)?.toInt() ?? 0;
      final previousToday = (summary['todayCount'] as num?)?.toInt() ?? 0;
      final previousCompletedBatchCount =
          (summary['completedBatchCount'] as num?)?.toInt() ?? 0;
      final previousCompletedRunsCount =
          (summary['completedRunsCount'] as num?)?.toInt() ?? 0;
      final previousCertificatesCount =
          (summary['certificatesCount'] as num?)?.toInt() ?? 0;
      final previousMilestoneCount =
          (summary['milestoneCount'] as num?)?.toInt() ?? 0;

      final hadPreviousJourney =
          previousLanguage.isNotEmpty || previousTarget > 0 || previousRunCount > 0;

      final previousWasCompleted =
          previousTarget > 0 && previousRunCount >= previousTarget;

      // If old data has no currentRunId, generate one so we can archive it properly.
      final effectivePreviousRunId = (previousRunId != null && previousRunId.isNotEmpty)
          ? previousRunId
          : (hadPreviousJourney ? _newRunId() : null);

      if (hadPreviousJourney && effectivePreviousRunId != null) {
        final archiveData = <String, dynamic>{
          'uid': uid,
          'runId': effectivePreviousRunId,
          'language': previousLanguage,
          'targetCount': previousTarget,
          'finalRunCount': previousRunCount,
          'completedBatchCount': previousCompletedBatchCount,
          'status': previousWasCompleted ? 'completed' : 'replaced',
          'archivedAt': FieldValue.serverTimestamp(),
          'completedAt': previousWasCompleted ? FieldValue.serverTimestamp() : null,
          'updatedAt': FieldValue.serverTimestamp(),
        }..removeWhere((key, value) => value == null);

        tx.set(
          _historyRef(uid, effectivePreviousRunId),
          archiveData,
          SetOptions(merge: true),
        );

        tx.set(
          _runRef(uid, effectivePreviousRunId),
          {
            'uid': uid,
            'runId': effectivePreviousRunId,
            'language': previousLanguage,
            'targetCount': previousTarget,
            'finalRunCount': previousRunCount,
            'completedBatchCount': previousCompletedBatchCount,
            'status': previousWasCompleted ? 'completed' : 'replaced',
            'completedAt': previousWasCompleted ? FieldValue.serverTimestamp() : null,
            'updatedAt': FieldValue.serverTimestamp(),
          }..removeWhere((key, value) => value == null),
          SetOptions(merge: true),
        );
      }

      final newRunId = _newRunId();

      tx.set(
        _runRef(uid, newRunId),
        {
          'uid': uid,
          'runId': newRunId,
          'language': language,
          'targetCount': targetCount,
          'currentRunCount': 0,
          'currentBatchNumber': 1,
          'currentBatchProgress': 0,
          'completedBatchCount': 0,
          'status': 'active',
          'startedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      tx.set(
        summaryRef,
        {
          'uid': uid,
          'currentRunId': newRunId,
          'language': language,
          'targetCount': targetCount,
          'currentRunCount': 0,
          'currentBatchNumber': 1,
          'currentBatchProgress': 0,
          'completedBatchCount': 0,
          'totalCount': previousTotal,
          'todayCount': previousToday,
          'completedRunsCount': previousWasCompleted
              ? previousCompletedRunsCount + 1
              : previousCompletedRunsCount,
          'certificatesCount': previousCertificatesCount,
          'milestoneCount': previousMilestoneCount,
          'lastWrittenAt': null,
          'updatedAt': FieldValue.serverTimestamp(),
          if (!summarySnap.exists) 'createdAt': FieldValue.serverTimestamp(),
        }..removeWhere((key, value) => value == null),
        SetOptions(merge: true),
      );
    });
  }

  Future<RamakotiWriteResult> writeOne(String uid) async {
    final summaryRef = _summaryRef(uid);

    return await _firestore.runTransaction((tx) async {
      final summarySnap = await tx.get(summaryRef);
      final summary = summarySnap.data() ?? <String, dynamic>{};

      final previousRun = (summary['currentRunCount'] as num?)?.toInt() ?? 0;
      final previousTotal = (summary['totalCount'] as num?)?.toInt() ?? 0;
      final previousToday = (summary['todayCount'] as num?)?.toInt() ?? 0;
      final currentRunId =
      (summary['currentRunId'] as String?)?.trim().isNotEmpty == true
          ? (summary['currentRunId'] as String).trim()
          : _newRunId();

      final language = (summary['language'] as String?)?.trim() ?? '';
      final targetCount = (summary['targetCount'] as num?)?.toInt() ?? 0;

      final run = previousRun + 1;
      final total = previousTotal + 1;
      final today = previousToday + 1;

      final batchNumber = ((run - 1) ~/ 108) + 1;
      final batchProgress = run % 108 == 0 ? 108 : run % 108;
      final completedBatchCount = run ~/ 108;
      final batchCompleted = run % 108 == 0;

      tx.set(
        summaryRef,
        {
          'uid': uid,
          'currentRunId': currentRunId,
          'language': language,
          'targetCount': targetCount,
          'totalCount': total,
          'todayCount': today,
          'currentRunCount': run,
          'currentBatchNumber': batchNumber,
          'currentBatchProgress': batchProgress,
          'completedBatchCount': completedBatchCount,
          'lastWrittenAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          if (!summarySnap.exists) 'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      tx.set(
        _runRef(uid, currentRunId),
        {
          'uid': uid,
          'runId': currentRunId,
          'language': language,
          'targetCount': targetCount,
          'currentRunCount': run,
          'currentBatchNumber': batchNumber,
          'currentBatchProgress': batchProgress,
          'completedBatchCount': completedBatchCount,
          'status': (targetCount > 0 && run >= targetCount) ? 'completed' : 'active',
          'lastWrittenAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          if (run == 1) 'startedAt': FieldValue.serverTimestamp(),
          if (targetCount > 0 && run >= targetCount)
            'completedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return RamakotiWriteResult(
        totalCount: total,
        todayCount: today,
        currentRunCount: run,
        batchCompleted: batchCompleted,
        completedBatchNumber: completedBatchCount,
        batchProgress: batchProgress,
      );
    });
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../models/certificate_input.dart';
import '../../models/ramakoti_meta.dart';
import '../../models/ramakoti_run.dart';

class RamakotiService {
  RamakotiService._();

  static final RamakotiService instance = RamakotiService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _users() =>
      _firestore.collection('users');

  DocumentReference<Map<String, dynamic>> _summaryRef(String uid) =>
      _users().doc(uid).collection('ramakoti_meta').doc('summary');

  CollectionReference<Map<String, dynamic>> _runsRef(String uid) =>
      _users().doc(uid).collection('ramakotiRuns');

  DocumentReference<Map<String, dynamic>> _certificateRef({
    required String uid,
    required String runId,
  }) =>
      _users().doc(uid).collection('certificates').doc(runId);

  CollectionReference<Map<String, dynamic>> _mandalis() =>
      _firestore.collection('bhaktaMandalis');

  DocumentReference<Map<String, dynamic>> _mandaliRef(String mandaliId) =>
      _mandalis().doc(mandaliId);

  CollectionReference<Map<String, dynamic>> _mandaliMembersRef(String mandaliId) =>
      _mandaliRef(mandaliId).collection('members');

  DocumentReference<Map<String, dynamic>> _userMandaliRef(
      String uid,
      String mandaliId,
      ) =>
      _users().doc(uid).collection('bhaktaMandalis').doc(mandaliId);

  DocumentReference<Map<String, dynamic>> _mandaliChallengeRef(
      String mandaliId,
      String challengeId,
      ) =>
      _mandaliRef(mandaliId).collection('challenges').doc(challengeId);

  Future<Map<String, dynamic>?> getCertificateMetadata({
    required String uid,
    required String runId,
  }) async {
    final doc = await _certificateRef(uid: uid, runId: runId).get();
    return doc.data();
  }

  Future<CertificateInput> getOrCreateCertificateInput({
    required String uid,
    required String runId,
    required String devoteeName,
    required int completedCount,
    required DateTime completedAt,
    required String certificateLanguage,
  }) async {
    final ref = _certificateRef(uid: uid, runId: runId);
    final existing = await ref.get();

    if (existing.exists && existing.data() != null) {
      final data = existing.data()!;
      return CertificateInput(
        certificateId: (data['certificateId'] ?? '').toString(),
        runId: runId,
        uid: uid,
        devoteeName: (data['devoteeName'] ?? devoteeName).toString(),
        completedCount:
        (data['completedCount'] as num?)?.toInt() ?? completedCount,
        completedAt: _parseDate(data['completedAt']) ?? completedAt,
        certificateLanguage:
        (data['certificateLanguage'] ?? certificateLanguage).toString(),
      );
    }

    final certificateId = const Uuid().v4().replaceAll('-', '');

    final input = CertificateInput(
      certificateId: certificateId,
      runId: runId,
      uid: uid,
      devoteeName: devoteeName,
      completedCount: completedCount,
      completedAt: completedAt,
      certificateLanguage: certificateLanguage,
    );

    await ref.set({
      'certificateId': certificateId,
      'runId': runId,
      'uid': uid,
      'devoteeName': devoteeName,
      'completedCount': completedCount,
      'completedAt': completedAt.toIso8601String(),
      'certificateLanguage': certificateLanguage,
      'generatedAt': null,
      'storagePath': '',
      'downloadUrl': '',
      'fileName': input.fileName,
    }, SetOptions(merge: true));

    return input;
  }

  Future<void> saveCertificateMetadata({
    required String uid,
    required String runId,
    required String certificateId,
    required String devoteeName,
    required int completedCount,
    required DateTime completedAt,
    required String certificateLanguage,
    required String storagePath,
    required String downloadUrl,
  }) async {
    final certRef = _certificateRef(uid: uid, runId: runId);
    final summaryRef = _summaryRef(uid);

    await _firestore.runTransaction((tx) async {
      final certSnap = await tx.get(certRef);
      final existing = certSnap.data();

      final alreadyGenerated =
          existing != null &&
              (existing['generatedAt'] != null) &&
              ((existing['downloadUrl'] ?? '').toString().trim().isNotEmpty);

      final summarySnap = await tx.get(summaryRef);
      final summaryData = summarySnap.data() ?? <String, dynamic>{};
      final currentCertificatesCount =
          (summaryData['certificatesCount'] as num?)?.toInt() ?? 0;

      tx.set(certRef, {
        'certificateId': certificateId,
        'runId': runId,
        'uid': uid,
        'devoteeName': devoteeName,
        'completedCount': completedCount,
        'completedAt': completedAt.toIso8601String(),
        'certificateLanguage': certificateLanguage,
        'generatedAt': DateTime.now().toIso8601String(),
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'fileName': '${certificateId}_$certificateLanguage.pdf',
      }, SetOptions(merge: true));

      if (!alreadyGenerated) {
        tx.set(summaryRef, {
          'certificatesCount': currentCertificatesCount + 1,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
    });
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  DocumentReference<Map<String, dynamic>> _globalRamCountRef() =>
      _firestore.collection('global_stats').doc('ram_count_total');

  Stream<RamakotiMeta> watchSummary(String uid) {
    return _summaryRef(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return RamakotiMeta.empty(uid);
      return RamakotiMeta.fromMap(data);
    });
  }

  Future<RamakotiMeta> getSummary(String uid) async {
    final doc = await _summaryRef(uid).get();
    final data = doc.data();
    if (data == null) return RamakotiMeta.empty(uid);
    return RamakotiMeta.fromMap(data);
  }

  Stream<List<RamakotiRun>> watchRuns(String uid) {
    return _runsRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => RamakotiRun.fromMap(doc.data(), docId: doc.id))
          .toList(),
    );
  }

  Future<List<RamakotiRun>> getRuns(String uid) async {
    final snapshot =
    await _runsRef(uid).orderBy('createdAt', descending: true).get();

    return snapshot.docs
        .map((doc) => RamakotiRun.fromMap(doc.data(), docId: doc.id))
        .toList();
  }

  Future<RamakotiRun?> getRunById(String uid, String runId) async {
    final doc = await _runsRef(uid).doc(runId).get();
    if (!doc.exists || doc.data() == null) return null;
    return RamakotiRun.fromMap(doc.data()!, docId: doc.id);
  }

  Stream<int> watchGlobalRamCount() {
    return _globalRamCountRef().snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return 0;
      return (data['total'] as num?)?.toInt() ?? 0;
    });
  }

  Future<int> getGlobalRamCount() async {
    final doc = await _globalRamCountRef().get();
    final data = doc.data();
    if (data == null) return 0;
    return (data['total'] as num?)?.toInt() ?? 0;
  }

  Future<void> saveLanguageAndTarget({
    required String uid,
    required String language,
    required int targetCount,
  }) async {
    final summary = await getSummary(uid);

    final hasActiveRun = summary.currentRunId.trim().isNotEmpty &&
        !summary.isTargetCompleted &&
        summary.hasTarget;

    if (hasActiveRun) {
      await _summaryRef(uid).set(
        {
          'uid': uid,
          'language': language,
          'targetCount': targetCount,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );

      await _runsRef(uid).doc(summary.currentRunId).set(
        {
          'language': language,
          'targetCount': targetCount,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );

      return;
    }

    await startNewRun(
      uid: uid,
      language: language,
      targetCount: targetCount,
    );
  }

  Future<String> startNewRun({
    required String uid,
    required String language,
    required int targetCount,
  }) async {
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final runId = 'run_${now.millisecondsSinceEpoch}';

    final summary = await getSummary(uid);

    await _firestore.runTransaction((tx) async {
      final summaryDoc = await tx.get(_summaryRef(uid));
      final existing = summaryDoc.data() ?? <String, dynamic>{};

      tx.set(
        _runsRef(uid).doc(runId),
        {
          'runId': runId,
          'uid': uid,
          'language': language,
          'targetCount': targetCount,
          'currentRunCount': 0,
          'finalRunCount': 0,
          'completedBatchCount': 0,
          'currentBatchNumber': 1,
          'currentBatchProgress': 0,
          'status': 'active',
          'startedAt': nowIso,
          'lastWrittenAt': null,
          'completedAt': null,
          'createdAt': nowIso,
          'updatedAt': nowIso,
        },
      );

      tx.set(
        _summaryRef(uid),
        {
          'uid': uid,
          'language': language,
          'targetCount': targetCount,
          'currentRunId': runId,
          'currentRunCount': 0,
          'currentBatchNumber': 1,
          'currentBatchProgress': 0,
          'completedBatchCount': 0,
          'totalCount': summary.totalCount,
          'todayCount': summary.todayCount,
          'completedRunsCount':
          (existing['completedRunsCount'] as num?)?.toInt() ??
              summary.completedRunsCount,
          'certificatesCount':
          (existing['certificatesCount'] as num?)?.toInt() ??
              summary.certificatesCount,
          'milestoneCount':
          (existing['milestoneCount'] as num?)?.toInt() ??
              summary.milestoneCount,
          'lastWrittenAt': existing['lastWrittenAt'],
          'createdAt': existing['createdAt'] ?? nowIso,
          'updatedAt': nowIso,
        },
        SetOptions(merge: true),
      );
    });

    return runId;
  }

  Future<WriteOneResult> writeOne(String uid) async {
    final summaryDoc = await _summaryRef(uid).get();
    final summaryData = summaryDoc.data();

    if (summaryData == null) {
      throw Exception('Ramakoti summary not found. Please create a journey.');
    }

    final currentRunId = (summaryData['currentRunId'] as String? ?? '').trim();
    if (currentRunId.isEmpty) {
      throw Exception('No active Ramakoti run found. Please create a journey.');
    }

    final currentRunCount =
        (summaryData['currentRunCount'] as num?)?.toInt() ?? 0;
    final targetCount = (summaryData['targetCount'] as num?)?.toInt() ?? 0;
    final totalCount = (summaryData['totalCount'] as num?)?.toInt() ?? 0;
    final todayCount = (summaryData['todayCount'] as num?)?.toInt() ?? 0;
    final completedRunsCount =
        (summaryData['completedRunsCount'] as num?)?.toInt() ?? 0;

    final activeMandaliId =
    (summaryData['activeMandaliId'] as String? ?? '').trim();
    final activeMandaliName =
    (summaryData['activeMandaliName'] as String? ?? '').trim();
    final activeMandaliChallengeId =
    (summaryData['activeMandaliChallengeId'] as String? ?? '').trim();

    if (targetCount > 0 && currentRunCount >= targetCount) {
      throw Exception('Current Ramakoti target is already completed.');
    }

    final newRunCount = currentRunCount + 1;
    final newTotalCount = totalCount + 1;
    final newTodayCount = todayCount + 1;

    final newCompletedBatchCount = newRunCount ~/ RamakotiMeta.batchSize;
    final newCurrentBatchNumber =
    newRunCount <= 0 ? 1 : ((newRunCount - 1) ~/ RamakotiMeta.batchSize) + 1;
    final remainder = newRunCount % RamakotiMeta.batchSize;
    final newCurrentBatchProgress =
    remainder == 0 ? RamakotiMeta.batchSize : remainder;

    final batchCompleted = newRunCount > 0 &&
        newCurrentBatchProgress == RamakotiMeta.batchSize;

    final runCompleted = targetCount > 0 && newRunCount >= targetCount;

    final nowIso = DateTime.now().toIso8601String();

    final batch = _firestore.batch();

    final runDocRef = _runsRef(uid).doc(currentRunId);
    final globalDocRef = _globalRamCountRef();

    batch.set(
      runDocRef,
      {
        'currentRunCount': newRunCount,
        'finalRunCount': newRunCount,
        'completedBatchCount': newCompletedBatchCount,
        'currentBatchNumber': newCurrentBatchNumber,
        'currentBatchProgress': newCurrentBatchProgress,
        'lastWrittenAt': nowIso,
        'updatedAt': nowIso,
        if (runCompleted) 'status': 'completed',
        if (runCompleted) 'completedAt': nowIso,
      },
      SetOptions(merge: true),
    );

    batch.set(
      _summaryRef(uid),
      {
        'currentRunCount': newRunCount,
        'totalCount': newTotalCount,
        'todayCount': newTodayCount,
        'completedBatchCount': newCompletedBatchCount,
        'currentBatchNumber': newCurrentBatchNumber,
        'currentBatchProgress': newCurrentBatchProgress,
        'lastWrittenAt': nowIso,
        'updatedAt': nowIso,
        if (runCompleted) 'completedRunsCount': completedRunsCount + 1,
      },
      SetOptions(merge: true),
    );

    batch.set(
      globalDocRef,
      {
        'total': FieldValue.increment(1),
        'updatedAt': nowIso,
      },
      SetOptions(merge: true),
    );

    if (activeMandaliId.isNotEmpty) {
      final mandaliRef = _mandaliRef(activeMandaliId);
      final memberRef = _mandaliMembersRef(activeMandaliId).doc(uid);
      final userMandaliRef = _userMandaliRef(uid, activeMandaliId);

      String resolvedMandaliChallengeId = activeMandaliChallengeId;
      bool challengeCompleted = false;

      if (resolvedMandaliChallengeId.isNotEmpty) {
        final challengeRef =
        _mandaliChallengeRef(activeMandaliId, resolvedMandaliChallengeId);
        final challengeDoc = await challengeRef.get();
        final challengeData = challengeDoc.data();

        if (challengeData != null) {
          final challengeProgress =
              (challengeData['progressCount'] as num?)?.toInt() ?? 0;
          final challengeTarget =
              (challengeData['target'] as num?)?.toInt() ?? 0;
          final newChallengeProgress = challengeProgress + 1;
          challengeCompleted =
              challengeTarget > 0 && newChallengeProgress >= challengeTarget;

          batch.set(
            challengeRef,
            {
              'progressCount': FieldValue.increment(1),
              'updatedAt': nowIso,
              if (challengeCompleted) 'status': 'completed',
              if (challengeCompleted) 'completedAt': nowIso,
            },
            SetOptions(merge: true),
          );

          batch.set(
            mandaliRef,
            {
              'totalCount': FieldValue.increment(1),
              'lastContributionAt': nowIso,
              'lastContributionBy': uid,
              'updatedAt': nowIso,
              'activeChallenge.progressCount': FieldValue.increment(1),
              'activeChallenge.updatedAt': nowIso,
              if (challengeCompleted) 'activeChallenge.status': 'completed',
              if (challengeCompleted) 'activeChallenge.completedAt': nowIso,
            },
            SetOptions(merge: true),
          );

          batch.set(
            _summaryRef(uid),
            {
              'lastMandaliContributionAt': nowIso,
              'activeMandaliChallengeId': resolvedMandaliChallengeId,
            },
            SetOptions(merge: true),
          );
        } else {
          batch.set(
            mandaliRef,
            {
              'totalCount': FieldValue.increment(1),
              'lastContributionAt': nowIso,
              'lastContributionBy': uid,
              'updatedAt': nowIso,
            },
            SetOptions(merge: true),
          );

          batch.set(
            _summaryRef(uid),
            {
              'lastMandaliContributionAt': nowIso,
            },
            SetOptions(merge: true),
          );
        }
      } else {
        batch.set(
          mandaliRef,
          {
            'totalCount': FieldValue.increment(1),
            'lastContributionAt': nowIso,
            'lastContributionBy': uid,
            'updatedAt': nowIso,
          },
          SetOptions(merge: true),
        );

        batch.set(
          _summaryRef(uid),
          {
            'lastMandaliContributionAt': nowIso,
          },
          SetOptions(merge: true),
        );
      }

      batch.set(
        memberRef,
        {
          'contributionCount': FieldValue.increment(1),
          'challengeContributionCount': FieldValue.increment(1),
          'lastContributionAt': nowIso,
        },
        SetOptions(merge: true),
      );

      batch.set(
        userMandaliRef,
        {
          'contributionCount': FieldValue.increment(1),
          'challengeContributionCount': FieldValue.increment(1),
          'lastContributionAt': nowIso,
          'isSelectedActiveMandali': true,
          'displayName': activeMandaliName,
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();

    return WriteOneResult(
      currentRunCount: newRunCount,
      totalCount: newTotalCount,
      todayCount: newTodayCount,
      batchCompleted: batchCompleted,
      runCompleted: runCompleted,
    );
  }

  Future<void> activateRun({
    required String uid,
    required RamakotiRun run,
  }) async {
    final summary = await getSummary(uid);

    await _summaryRef(uid).set(
      {
        'uid': uid,
        'language': run.language,
        'targetCount': run.targetCount,
        'currentRunId': run.runId,
        'currentRunCount': run.currentRunCount,
        'currentBatchNumber': run.currentBatchNumber,
        'currentBatchProgress': run.currentBatchProgress,
        'completedBatchCount': run.completedBatchCount,
        'totalCount': summary.totalCount,
        'todayCount': summary.todayCount,
        'completedRunsCount': summary.completedRunsCount,
        'certificatesCount': summary.certificatesCount,
        'milestoneCount': summary.milestoneCount,
        'lastWrittenAt': run.lastWrittenAt?.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> refreshSummaryFromRun({
    required String uid,
    required String runId,
  }) async {
    final run = await getRunById(uid, runId);
    if (run == null) return;

    final summary = await getSummary(uid);

    await _summaryRef(uid).set(
      {
        'uid': uid,
        'language': run.language,
        'targetCount': run.targetCount,
        'currentRunId': run.runId,
        'currentRunCount': run.currentRunCount,
        'currentBatchNumber': run.currentBatchNumber,
        'currentBatchProgress': run.currentBatchProgress,
        'completedBatchCount': run.completedBatchCount,
        'totalCount': summary.totalCount,
        'todayCount': summary.todayCount,
        'completedRunsCount': summary.completedRunsCount,
        'certificatesCount': summary.certificatesCount,
        'milestoneCount': summary.milestoneCount,
        'lastWrittenAt': run.lastWrittenAt?.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }
}

class WriteOneResult {
  final int currentRunCount;
  final int totalCount;
  final int todayCount;
  final bool batchCompleted;
  final bool runCompleted;

  const WriteOneResult({
    required this.currentRunCount,
    required this.totalCount,
    required this.todayCount,
    required this.batchCompleted,
    required this.runCompleted,
  });
}
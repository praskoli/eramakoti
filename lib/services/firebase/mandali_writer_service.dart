import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/mandali_writer_state.dart';

class MandaliWriteResult {
  final int contributionCount;
  final int challengeContributionCount;
  final int currentBatchProgress;
  final int completedBatchCount;
  final int mandaliTotalCount;
  final int challengeProgressCount;
  final bool batchCompleted;
  final bool challengeCompleted;

  const MandaliWriteResult({
    required this.contributionCount,
    required this.challengeContributionCount,
    required this.currentBatchProgress,
    required this.completedBatchCount,
    required this.mandaliTotalCount,
    required this.challengeProgressCount,
    required this.batchCompleted,
    required this.challengeCompleted,
  });
}

class MandaliWriterService {
  MandaliWriterService._();

  static final MandaliWriterService instance = MandaliWriterService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _mandaliRef(String mandaliId) =>
      _firestore.collection('bhaktaMandalis').doc(mandaliId);

  DocumentReference<Map<String, dynamic>> _memberRef(String mandaliId, String uid) =>
      _mandaliRef(mandaliId).collection('members').doc(uid);

  DocumentReference<Map<String, dynamic>> _challengeRef(String mandaliId, String challengeId) =>
      _mandaliRef(mandaliId).collection('challenges').doc(challengeId);

  DocumentReference<Map<String, dynamic>> _userMirrorRef(String uid, String mandaliId) =>
      _firestore.collection('users').doc(uid).collection('bhaktaMandalis').doc(mandaliId);

  DocumentReference<Map<String, dynamic>> _globalCountRef() =>
      _firestore.collection('global_stats').doc('ram_count_total');

  Future<MandaliWriteResult> writeForMandali({
    required String mandaliId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final nowIso = DateTime.now().toIso8601String();

    return _firestore.runTransaction((tx) async {
      final mandaliSnap = await tx.get(_mandaliRef(mandaliId));
      final mandaliData = mandaliSnap.data();
      if (mandaliData == null) {
        throw Exception('Mandali not found');
      }

      final challengeId = (mandaliData['activeChallengeId'] ?? '').toString();
      if (challengeId.isEmpty) {
        throw Exception('No active challenge found for this Mandali');
      }

      final memberSnap = await tx.get(_memberRef(mandaliId, user.uid));
      final memberData = memberSnap.data();
      if (memberData == null || (memberData['status'] ?? '').toString() != 'active') {
        throw Exception('You are not an active member of this Mandali');
      }

      final challengeSnap = await tx.get(_challengeRef(mandaliId, challengeId));
      final challengeData = challengeSnap.data();
      if (challengeData == null) {
        throw Exception('Active challenge record not found');
      }

      final contributionCount = (memberData['contributionCount'] as num?)?.toInt() ?? 0;
      final challengeContributionCount = (memberData['challengeContributionCount'] as num?)?.toInt() ?? 0;
      final currentBatchProgress = (memberData['currentBatchProgress'] as num?)?.toInt() ?? 0;
      final completedBatchCount = (memberData['completedBatchCount'] as num?)?.toInt() ?? 0;
      final mandaliTotal = (mandaliData['totalCount'] as num?)?.toInt() ?? 0;
      final challengeProgress = (challengeData['progressCount'] as num?)?.toInt() ?? 0;
      final challengeTarget = (challengeData['target'] as num?)?.toInt() ?? 0;

      final nextContributionCount = contributionCount + 1;
      final nextChallengeContributionCount = challengeContributionCount + 1;
      final nextBatchProgressRaw = currentBatchProgress + 1;
      final batchCompleted = nextBatchProgressRaw >= 108;
      final storedCurrentBatchProgress = batchCompleted ? 0 : nextBatchProgressRaw;
      final storedCompletedBatchCount = batchCompleted ? completedBatchCount + 1 : completedBatchCount;
      final nextMandaliTotal = mandaliTotal + 1;
      final nextChallengeProgress = challengeProgress + 1;
      final challengeCompleted = challengeTarget > 0 && nextChallengeProgress >= challengeTarget;

      tx.set(_memberRef(mandaliId, user.uid), {
        'contributionCount': nextContributionCount,
        'challengeContributionCount': nextChallengeContributionCount,
        'currentBatchProgress': storedCurrentBatchProgress,
        'completedBatchCount': storedCompletedBatchCount,
        'lastContributionAt': nowIso,
        'updatedAt': nowIso,
      }, SetOptions(merge: true));

      tx.set(_userMirrorRef(user.uid, mandaliId), {
        'contributionCount': nextContributionCount,
        'challengeContributionCount': nextChallengeContributionCount,
        'lastContributionAt': nowIso,
        'updatedAt': nowIso,
      }, SetOptions(merge: true));

      tx.set(_mandaliRef(mandaliId), {
        'totalCount': nextMandaliTotal,
        'lastContributionAt': nowIso,
        'lastContributionBy': user.uid,
        'updatedAt': nowIso,
        'activeChallenge.progressCount': nextChallengeProgress,
        'activeChallenge.updatedAt': nowIso,
        if (challengeCompleted) 'activeChallenge.status': 'completed',
        if (challengeCompleted) 'activeChallenge.completedAt': nowIso,
      }, SetOptions(merge: true));

      tx.set(_challengeRef(mandaliId, challengeId), {
        'progressCount': nextChallengeProgress,
        'updatedAt': nowIso,
        if (challengeCompleted) 'status': 'completed',
        if (challengeCompleted) 'completedAt': nowIso,
      }, SetOptions(merge: true));

      tx.set(_globalCountRef(), {
        'total': FieldValue.increment(1),
        'updatedAt': nowIso,
      }, SetOptions(merge: true));

      return MandaliWriteResult(
        contributionCount: nextContributionCount,
        challengeContributionCount: nextChallengeContributionCount,
        currentBatchProgress: storedCurrentBatchProgress,
        completedBatchCount: storedCompletedBatchCount,
        mandaliTotalCount: nextMandaliTotal,
        challengeProgressCount: nextChallengeProgress,
        batchCompleted: batchCompleted,
        challengeCompleted: challengeCompleted,
      );
    });
  }

  Stream<MandaliWriterState?> watchWriterState({
    required String mandaliId,
    required String uid,
  }) {
    return _memberRef(mandaliId, uid).snapshots().asyncMap((memberSnap) async {
      final memberData = memberSnap.data();
      if (memberData == null) return null;

      final mandaliSnap = await _mandaliRef(mandaliId).get();
      final mandaliData = mandaliSnap.data();
      if (mandaliData == null) return null;

      final challengeId = (mandaliData['activeChallengeId'] ?? '').toString();
      if (challengeId.isEmpty) return null;

      final challengeSnap = await _challengeRef(mandaliId, challengeId).get();
      final challengeData = challengeSnap.data();
      if (challengeData == null) return null;

      return MandaliWriterState(
        mandaliId: mandaliId,
        mandaliName: (mandaliData['displayName'] ?? '').toString(),
        challengeId: challengeId,
        challengeName: (challengeData['title'] ?? '').toString(),
        challengeTarget: (challengeData['target'] as num?)?.toInt() ?? 0,
        challengeProgress: (challengeData['progressCount'] as num?)?.toInt() ?? 0,
        mandaliTotal: (mandaliData['totalCount'] as num?)?.toInt() ?? 0,
        userContribution: (memberData['contributionCount'] as num?)?.toInt() ?? 0,
        currentBatchProgress: (memberData['currentBatchProgress'] as num?)?.toInt() ?? 0,
        completedBatchCount: (memberData['completedBatchCount'] as num?)?.toInt() ?? 0,
      );
    });
  }
}

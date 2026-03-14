import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/mandali_writer_state.dart';
import '../auth/auth_service.dart';

class MandaliWriteResult {
  final bool batchCompleted;
  final bool challengeCompleted;
  final int currentBatchProgress;
  final int challengeProgress;

  const MandaliWriteResult({
    required this.batchCompleted,
    required this.challengeCompleted,
    required this.currentBatchProgress,
    required this.challengeProgress,
  });
}

class MandaliWriterService {
  MandaliWriterService._();

  static final MandaliWriterService instance = MandaliWriterService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Watch writer state
  Stream<MandaliWriterState?> watchWriterState({
    required String mandaliId,
    required String uid,
  }) {
    final mandaliRef = _firestore.collection('bhaktaMandalis').doc(mandaliId);
    final memberRef = mandaliRef.collection('members').doc(uid);

    return memberRef.snapshots().asyncMap((memberSnap) async {
      final memberData = memberSnap.data();
      if (memberData == null) return null;

      final mandaliSnap = await mandaliRef.get();
      final mandaliData = mandaliSnap.data();
      if (mandaliData == null) return null;

      final challengeId = (mandaliData['activeChallengeId'] ?? '').toString();
      if (challengeId.isEmpty) return null;

      final challengeSnap = await mandaliRef
          .collection('challenges')
          .doc(challengeId)
          .get();

      final challengeData = challengeSnap.data();
      if (challengeData == null) return null;

      final userContribution =
          (memberData['contributionCount'] as num?)?.toInt() ?? 0;

      final currentBatch =
          (memberData['currentBatchProgress'] as num?)?.toInt() ?? 0;

      final completedBatch =
          (memberData['completedBatchCount'] as num?)?.toInt() ?? 0;

      final challengeProgress =
          (challengeData['progressCount'] as num?)?.toInt() ?? 0;

      final challengeTarget =
          (challengeData['target'] as num?)?.toInt() ?? 0;

      final challengeStatus =
      (challengeData['status'] ?? 'active').toString();

      return MandaliWriterState(
        mandaliId: mandaliId,
        mandaliName:
        (mandaliData['displayName'] ?? mandaliData['name'] ?? '').toString(),
        challengeId: challengeId,
        challengeName: (challengeData['title'] ?? '').toString(),
        challengeTarget: challengeTarget,
        challengeProgress: challengeProgress,
        challengeStatus: challengeStatus,
        mandaliTotal: (mandaliData['totalCount'] as num?)?.toInt() ?? 0,
        userContribution: userContribution,
        currentBatchProgress: currentBatch,
        completedBatchCount: completedBatch,
      );
    });
  }

  /// Write Jai Shri Ram
  Future<MandaliWriteResult> writeForMandali({
    required String mandaliId,
    required String challengeId,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    final nowIso = DateTime.now().toIso8601String();

    final mandaliRef =
    _firestore.collection('bhaktaMandalis').doc(mandaliId);

    final memberRef =
    mandaliRef.collection('members').doc(user.uid);

    final challengeRef =
    mandaliRef.collection('challenges').doc(challengeId);

    /// 1️⃣ Update challenge progress FIRST
    await challengeRef.set({
      'progressCount': FieldValue.increment(1),
      'updatedAt': nowIso,
    }, SetOptions(merge: true));

    /// 2️⃣ Update Mandali total SECOND
    await mandaliRef.set({
      'totalCount': FieldValue.increment(1),
      'lastContributionBy': user.uid,
      'lastContributionAt': nowIso,
      'updatedAt': nowIso,
    }, SetOptions(merge: true));

    /// 3️⃣ Update member grid LAST
    /// This triggers the UI stream
    await memberRef.set({
      'contributionCount': FieldValue.increment(1),
      'challengeContributionCount': FieldValue.increment(1),
      'currentBatchProgress': FieldValue.increment(1),
      'lastContributionAt': nowIso,
      'updatedAt': nowIso,
    }, SetOptions(merge: true));

    return const MandaliWriteResult(
      batchCompleted: false,
      challengeCompleted: false,
      currentBatchProgress: 0,
      challengeProgress: 0,
    );
  }
}
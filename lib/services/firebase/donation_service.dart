import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationService {
  DonationService._();

  static final DonationService instance = DonationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _userDonations =>
      _db
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('donations');

  CollectionReference<Map<String, dynamic>> get _supportWall =>
      _db.collection('support_wall');

  Future<String> createDonation({
    required int amount,
    required String source,
    required String note,
    bool anonymous = false,
    String supporterName = '',
    String supporterMessage = '',
    String supportType = 'individual',
    String? sourceMandaliId,
    String? sourceMandaliName,
    String? sourceChallengeId,
  }) async {
    final user = _auth.currentUser!;
    final uid = user.uid;
    final fallbackDisplayName = (user.displayName ?? '').trim();

    final resolvedSupporterName =
    supporterName.trim().isNotEmpty ? supporterName.trim() : fallbackDisplayName;

    final doc = _userDonations.doc();

    await doc.set({
      'donationId': doc.id,
      'uid': uid,
      'amount': amount,
      'note': note,
      'source': source,
      'supportType': supportType,
      'sourceMandaliId': sourceMandaliId,
      'sourceMandaliName': sourceMandaliName,
      'sourceChallengeId': sourceChallengeId,
      'userDisplayName': fallbackDisplayName,
      'supporterName': resolvedSupporterName,
      'supporterMessage': supporterMessage.trim(),
      'anonymous': anonymous,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<void> markDonationReturned({
    required String donationId,
  }) async {
    final ref = _userDonations.doc(donationId);

    await ref.update({
      'status': 'returned',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSupportWall({
    int limit = 8,
  }) {
    return _supportWall
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyDonations() {
    return _userDonations
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSupportHistory({
    int limit = 50,
  }) {
    return _userDonations
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }
}
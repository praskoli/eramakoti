import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationService {
  DonationService._();

  static final DonationService instance = DonationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// USER DONATIONS COLLECTION
  CollectionReference<Map<String, dynamic>> get _userDonations =>
      _db
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('donations');

  /// GLOBAL SUPPORT WALL
  CollectionReference<Map<String, dynamic>> get _supportWall =>
      _db.collection('support_wall');

  /// CREATE DONATION
  Future<String> createDonation({
    required int amount,
    required String source,
    required String note,
    bool anonymous = false,
    String supporterName = '',
    String supporterMessage = '',

    /// INDIVIDUAL | MANDALI
    String supportType = 'individual',

    /// OPTIONAL MANDALI CONTEXT
    String? sourceMandaliId,
    String? sourceMandaliName,
    String? sourceChallengeId,
  }) async {
    final uid = _auth.currentUser!.uid;

    final doc = _userDonations.doc();

    await doc.set({
      'donationId': doc.id,
      'uid': uid,

      'amount': amount,
      'note': note,
      'source': source,

      /// SUPPORT TYPE
      'supportType': supportType,

      /// Mandali context
      'sourceMandaliId': sourceMandaliId,
      'sourceMandaliName': sourceMandaliName,
      'sourceChallengeId': sourceChallengeId,

      'supporterName': supporterName,
      'supporterMessage': supporterMessage,
      'anonymous': anonymous,

      /// pending → returned → verified
      'status': 'pending',

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  /// MARK DONATION RETURNED AFTER UPI APP
  Future<void> markDonationReturned({
    required String donationId,
  }) async {
    final ref = _userDonations.doc(donationId);

    await ref.update({
      'status': 'returned',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// WATCH SUPPORT WALL (GLOBAL)
  Stream<QuerySnapshot<Map<String, dynamic>>> watchSupportWall({
    int limit = 20,
  }) {
    return _supportWall
        .where('verified', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// USER DONATION HISTORY
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyDonations() {
    return _userDonations
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// SUPPORT HISTORY (ALIAS USED BY SUPPORT SCREEN)
  Stream<QuerySnapshot<Map<String, dynamic>>> watchSupportHistory({
    int limit = 50,
  }) {
    return _userDonations
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }
}
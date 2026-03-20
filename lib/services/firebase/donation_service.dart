import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationService {
  DonationService._();

  static final DonationService instance = DonationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _userDonations =>
      _db.collection('users').doc(_auth.currentUser!.uid).collection('donations');

  CollectionReference<Map<String, dynamic>> get _supportWall =>
      _db.collection('support_wall');

  bool get isLoggedIn => _auth.currentUser != null;

  String get currentUid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User not logged in');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> donationRef(String donationId) {
    if (donationId.trim().isEmpty) {
      throw ArgumentError('donationId cannot be empty');
    }
    return _userDonations.doc(donationId.trim());
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDonation(
      String donationId,
      ) async {
    return donationRef(donationId).get();
  }

  Future<Map<String, dynamic>?> getDonationData(
      String donationId,
      ) async {
    final snap = await getDonation(donationId);
    return snap.data();
  }

  Future<bool> donationExists(String donationId) async {
    final snap = await getDonation(donationId);
    return snap.exists;
  }

  Future<void> markDonationReturned({
    required String donationId,
  }) async {
    final ref = donationRef(donationId);

    await ref.set({
      'status': 'returned',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markDonationLocallyCancelled({
    required String donationId,
    String reason = 'payment_cancelled',
  }) async {
    final ref = donationRef(donationId);

    await ref.set({
      'status': 'failed',
      'failureReason': reason.trim().isEmpty ? 'payment_cancelled' : reason.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> attachClientContextToDonation({
    required String donationId,
    String? note,
    String? source,
    String? supportType,
    String? sourceMandaliId,
    String? sourceMandaliName,
    String? sourceChallengeId,
    String? supporterName,
    String? supporterMessage,
    bool? anonymous,
  }) async {
    final ref = donationRef(donationId);

    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (note != null) {
      payload['note'] = note.trim();
    }
    if (source != null) {
      payload['source'] = source.trim();
    }
    if (supportType != null) {
      payload['supportType'] =
      supportType.trim().isEmpty ? 'individual' : supportType.trim();
    }
    if (sourceMandaliId != null) {
      payload['sourceMandaliId'] = sourceMandaliId.trim().isEmpty
          ? null
          : sourceMandaliId.trim();
    }
    if (sourceMandaliName != null) {
      payload['sourceMandaliName'] = sourceMandaliName.trim().isEmpty
          ? null
          : sourceMandaliName.trim();
    }
    if (sourceChallengeId != null) {
      payload['sourceChallengeId'] = sourceChallengeId.trim().isEmpty
          ? null
          : sourceChallengeId.trim();
    }
    if (supporterName != null) {
      payload['supporterName'] = supporterName.trim();
    }
    if (supporterMessage != null) {
      payload['supporterMessage'] = supporterMessage.trim();
    }
    if (anonymous != null) {
      payload['anonymous'] = anonymous;
    }

    await ref.set(payload, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchDonation(
      String donationId,
      ) {
    return donationRef(donationId).snapshots();
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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationService {
  DonationService._();

  static final DonationService instance = DonationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> _userDonationsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('donations');
  }

  CollectionReference<Map<String, dynamic>> get _donationsRef {
    final user = _currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'no-current-user',
        message: 'No authenticated user found.',
      );
    }
    return _userDonationsRef(user.uid);
  }

  Future<String> createDonation({
    required int amount,
    required String source,
    required String note,
    required bool anonymous,
    required String supporterName,
    required String supporterMessage,
    required String supportType,
    String? sourceMandaliId,
    String? sourceMandaliName,
    String? sourceChallengeId,
    String? transactionRef,
    String? paymentMethod,
    String? paymentStatus,
    String? upiUrl,
  }) async {
    final user = _currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'no-current-user',
        message: 'No authenticated user found.',
      );
    }

    final doc = _donationsRef.doc();
    final now = FieldValue.serverTimestamp();

    final cleanName = supporterName.trim();
    final cleanMessage = supporterMessage.trim();

    await doc.set({
      'donationId': doc.id,
      'uid': user.uid,
      'amount': amount <= 0 ? 1 : amount,
      'status': (paymentStatus ?? 'initiated').trim(),
      'source': source.trim(),
      'note': note.trim(),
      'anonymous': anonymous,
      'supportType': supportType.trim(),
      'name': anonymous
          ? 'Anonymous'
          : (cleanName.isEmpty ? 'Devotee' : cleanName),
      'message': cleanMessage,
      'supporterName': cleanName,
      'supporterMessage': cleanMessage,
      'sourceMandaliId': (sourceMandaliId ?? '').trim(),
      'sourceMandaliName': (sourceMandaliName ?? '').trim(),
      'sourceChallengeId': (sourceChallengeId ?? '').trim(),
      'transactionRef': (transactionRef ?? '').trim(),
      'paymentMethod': (paymentMethod ?? 'upi').trim(),
      'upiUrl': (upiUrl ?? '').trim(),
      'adminNote': '',
      'createdAt': now,
      'updatedAt': now,
      'timestamp': now,
    });

    return doc.id;
  }

  Future<void> updateDonationStatus({
    required String donationId,
    required String status,
    String? source,
    String? adminNote,
    String? transactionRef,
    String? paymentMethod,
    String? upiUrl,
  }) async {
    final update = <String, dynamic>{
      'status': status.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (source != null && source.trim().isNotEmpty) {
      update['source'] = source.trim();
    }
    if (adminNote != null) {
      update['adminNote'] = adminNote.trim();
    }
    if (transactionRef != null && transactionRef.trim().isNotEmpty) {
      update['transactionRef'] = transactionRef.trim();
    }
    if (paymentMethod != null && paymentMethod.trim().isNotEmpty) {
      update['paymentMethod'] = paymentMethod.trim();
    }
    if (upiUrl != null && upiUrl.trim().isNotEmpty) {
      update['upiUrl'] = upiUrl.trim();
    }

    await _donationsRef.doc(donationId).update(update);
  }

  Future<void> markUserConfirmedPayment({
    required String donationId,
    String? source,
  }) async {
    await updateDonationStatus(
      donationId: donationId,
      status: 'returned_from_upi',
      source: source,
    );
  }

  Future<void> markReturnedFromUpi({
    required String donationId,
    String? source,
  }) async {
    await updateDonationStatus(
      donationId: donationId,
      status: 'returned_from_upi',
      source: source,
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSupportHistory() {
    return _donationsRef.orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSupportWall({
    int limit = 8,
  }) {
    return _firestore
        .collectionGroup('donations')
        .where('status', whereIn: ['returned_from_upi', 'verified'])
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }
}
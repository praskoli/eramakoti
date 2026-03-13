import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationService {
  DonationService._();

  static final DonationService instance = DonationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _supportWallRef() =>
      _firestore.collection('support_wall');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSupportHistory() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('donations')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSupportWall({
    int limit = 10,
  }) {
    return _supportWallRef()
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<String> createDonation({
    required int amount,
    required String source,
    String note = 'Support eRamakoti',
    bool anonymous = false,
    String supporterName = '',
    String supporterMessage = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('donations')
        .doc();

    final displayName = (user.displayName ?? '').trim();
    final resolvedName = supporterName.trim().isNotEmpty
        ? supporterName.trim()
        : (displayName.isNotEmpty ? displayName : 'Devotee');

    await docRef.set({
      'donationId': docRef.id,
      'uid': user.uid,
      'userDisplayName': user.displayName ?? '',
      'userEmail': user.email ?? '',
      'userPhone': user.phoneNumber ?? '',
      'amount': amount,
      'status': 'initiated',
      'upiId': '9121011887@pthdfc',
      'payeeName': 'Koli Prasanth',
      'note': note,
      'source': source,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'verifiedAt': null,
      'verifiedBy': null,
      'adminNote': '',
      'anonymous': anonymous,
      'supporterName': resolvedName,
      'supporterMessage': supporterMessage.trim(),
    });

    return docRef.id;
  }

  Future<void> markDonationReturned({
    required String donationId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('donations')
        .doc(donationId)
        .update({
      'status': 'returned_from_upi',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
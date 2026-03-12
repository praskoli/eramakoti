import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _userProfiles =>
      _firestore.collection('userProfiles');

  Future<void> bootstrapUser(User user) async {
    final userProfileRef = _userProfiles.doc(user.uid);
    final userRootRef = _users.doc(user.uid);
    final metaRef = userRootRef.collection('ramakoti_meta').doc('summary');

    final now = DateTime.now().toIso8601String();
    final providerId =
    user.providerData.isNotEmpty ? user.providerData.first.providerId : 'unknown';

    try {
      debugPrint('BOOTSTRAP: start for uid=${user.uid}');
      debugPrint('BOOTSTRAP: writing userProfiles/${user.uid}');
      debugPrint('BOOTSTRAP: writing users/${user.uid}');
      debugPrint('BOOTSTRAP: writing users/${user.uid}/ramakoti_meta/summary');

      await _firestore.runTransaction((transaction) async {
        final profileSnap = await transaction.get(userProfileRef);
        final userRootSnap = await transaction.get(userRootRef);
        final metaSnap = await transaction.get(metaRef);

        debugPrint('BOOTSTRAP: profile exists = ${profileSnap.exists}');
        debugPrint('BOOTSTRAP: user root exists = ${userRootSnap.exists}');
        debugPrint('BOOTSTRAP: meta exists = ${metaSnap.exists}');

        if (!profileSnap.exists) {
          transaction.set(userProfileRef, {
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoUrl': user.photoURL,
            'provider': providerId,
            'createdAt': now,
            'updatedAt': now,
          });
        } else {
          transaction.set(userProfileRef, {
            'email': user.email,
            'displayName': user.displayName,
            'photoUrl': user.photoURL,
            'provider': providerId,
            'updatedAt': now,
          }, SetOptions(merge: true));
        }

        if (!userRootSnap.exists) {
          transaction.set(userRootRef, {
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoUrl': user.photoURL,
            'provider': providerId,
            'createdAt': now,
            'updatedAt': now,
          });
        } else {
          transaction.set(userRootRef, {
            'email': user.email,
            'displayName': user.displayName,
            'photoUrl': user.photoURL,
            'provider': providerId,
            'updatedAt': now,
          }, SetOptions(merge: true));
        }

        if (!metaSnap.exists) {
          transaction.set(metaRef, {
            'uid': user.uid,
            'totalCount': 0,
            'todayCount': 0,
            'currentRunCount': 0,
            'lastWrittenAt': null,
            'createdAt': now,
            'updatedAt': now,
          });
        } else {
          transaction.set(metaRef, {
            'updatedAt': now,
          }, SetOptions(merge: true));
        }
      });

      debugPrint('BOOTSTRAP: success');
    } catch (e, st) {
      debugPrint('BOOTSTRAP ERROR: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Future<void> writeOneRamakoti() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final userRootRef = _users.doc(user.uid);
    final metaRef = userRootRef.collection('ramakoti_meta').doc('summary');
    final now = DateTime.now().toIso8601String();

    try {
      debugPrint('WRITE: start for uid=${user.uid}');

      await _firestore.runTransaction((transaction) async {
        final userRootSnap = await transaction.get(userRootRef);
        final metaSnap = await transaction.get(metaRef);

        if (!userRootSnap.exists) {
          transaction.set(userRootRef, {
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoUrl': user.photoURL,
            'provider': user.providerData.isNotEmpty
                ? user.providerData.first.providerId
                : 'unknown',
            'createdAt': now,
            'updatedAt': now,
          });
        }

        final data = metaSnap.data() ?? <String, dynamic>{};

        final totalCount = (data['totalCount'] as num?)?.toInt() ?? 0;
        final todayCount = (data['todayCount'] as num?)?.toInt() ?? 0;
        final currentRunCount = (data['currentRunCount'] as num?)?.toInt() ?? 0;

        transaction.set(
          metaRef,
          {
            'uid': user.uid,
            'totalCount': totalCount + 1,
            'todayCount': todayCount + 1,
            'currentRunCount': currentRunCount + 1,
            'lastWrittenAt': now,
            'updatedAt': now,
            'createdAt': data['createdAt'] ?? now,
          },
          SetOptions(merge: true),
        );
      });

      debugPrint('WRITE: success');
    } catch (e, st) {
      debugPrint('WRITE ERROR: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSummary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final metaRef = _users.doc(user.uid).collection('ramakoti_meta').doc('summary');

    try {
      final snap = await metaRef.get();
      final data = snap.data();

      if (data == null) {
        return {
          'totalCount': 0,
          'todayCount': 0,
          'currentRunCount': 0,
          'lastWrittenAt': null,
        };
      }

      return {
        'totalCount': (data['totalCount'] as num?)?.toInt() ?? 0,
        'todayCount': (data['todayCount'] as num?)?.toInt() ?? 0,
        'currentRunCount': (data['currentRunCount'] as num?)?.toInt() ?? 0,
        'lastWrittenAt': data['lastWrittenAt'],
      };
    } catch (e, st) {
      debugPrint('GET SUMMARY ERROR: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Stream<Map<String, dynamic>> summaryStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    final metaRef = _users.doc(user.uid).collection('ramakoti_meta').doc('summary');

    return metaRef.snapshots().map((snap) {
      final data = snap.data() ?? <String, dynamic>{};
      return {
        'totalCount': (data['totalCount'] as num?)?.toInt() ?? 0,
        'todayCount': (data['todayCount'] as num?)?.toInt() ?? 0,
        'currentRunCount': (data['currentRunCount'] as num?)?.toInt() ?? 0,
        'lastWrittenAt': data['lastWrittenAt'],
      };
    });
  }
}
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/bhakta_mandali.dart';
import '../../models/bhakta_mandali_challenge.dart';
import '../../models/bhakta_mandali_member.dart';
import '../../models/user_mandali_membership.dart';
import '../auth/auth_service.dart';

class BhaktaMandaliService {
  BhaktaMandaliService._();

  static final BhaktaMandaliService instance = BhaktaMandaliService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random.secure();

  CollectionReference<Map<String, dynamic>> _mandalis() =>
      _firestore.collection('bhaktaMandalis');

  String _normalizeRequiredId(String value, String fieldName) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw Exception('$fieldName cannot be empty');
    }
    return normalized;
  }

  DocumentReference<Map<String, dynamic>> _mandaliRef(String mandaliId) =>
      _mandalis().doc(_normalizeRequiredId(mandaliId, 'mandaliId'));

  CollectionReference<Map<String, dynamic>> _membersRef(String mandaliId) =>
      _mandaliRef(mandaliId).collection('members');

  CollectionReference<Map<String, dynamic>> _challengesRef(String mandaliId) =>
      _mandaliRef(mandaliId).collection('challenges');

  CollectionReference<Map<String, dynamic>> _inviteCodes() =>
      _firestore.collection('mandaliInviteCodes');

  DocumentReference<Map<String, dynamic>> _userRoot(String uid) =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _userMandalisRef(String uid) =>
      _userRoot(uid).collection('bhaktaMandalis');

  DocumentReference<Map<String, dynamic>> _summaryRef(String uid) =>
      _userRoot(uid).collection('ramakoti_meta').doc('summary');

  Stream<List<UserMandaliMembership>> watchMyMandalis(String uid) {
    return _userMandalisRef(uid).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) {
        final data = Map<String, dynamic>.from(doc.data());

        final storedMandaliId =
        (data['mandaliId'] ?? '').toString().trim();
        if (storedMandaliId.isEmpty) {
          data['mandaliId'] = doc.id;
        }

        return UserMandaliMembership.fromMap(data);
      })
          .where((item) => item.mandaliId.trim().isNotEmpty)
          .where((item) => item.status.trim().toLowerCase() != 'left')
          .toList();

      items.sort((a, b) {
        if (a.isSelectedActiveMandali && !b.isSelectedActiveMandali) return -1;
        if (!a.isSelectedActiveMandali && b.isSelectedActiveMandali) return 1;
        return a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      });

      return items;
    });
  }

  Stream<List<BhaktaMandali>> watchDiscoverMandalis({String query = ''}) {
    final normalizedQuery = query.trim().toLowerCase();

    return _mandalis()
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        final storedMandaliId = (data['mandaliId'] ?? '').toString().trim();
        if (storedMandaliId.isEmpty) {
          data['mandaliId'] = doc.id;
        }
        return BhaktaMandali.fromMap(data);
      })
          .toList();

      items.sort((a, b) {
        final byCount = b.totalCount.compareTo(a.totalCount);
        if (byCount != 0) return byCount;
        return a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      });

      if (normalizedQuery.isEmpty) {
        return items;
      }

      return items.where((item) {
        return item.displayName.toLowerCase().contains(normalizedQuery) ||
            item.category.toLowerCase().contains(normalizedQuery) ||
            item.description.toLowerCase().contains(normalizedQuery);
      }).toList();
    });
  }

  Stream<List<BhaktaMandali>> watchGlobalLeaderboard({int limit = 50}) {
    return _mandalis()
        .orderBy('totalCount', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        final storedMandaliId =
        (data['mandaliId'] ?? '').toString().trim();
        if (storedMandaliId.isEmpty) {
          data['mandaliId'] = doc.id;
        }
        return BhaktaMandali.fromMap(data);
      })
          .toList(),
    );
  }

  Stream<BhaktaMandali?> watchMandali(String mandaliId) {
    final normalizedMandaliId = mandaliId.trim();
    if (normalizedMandaliId.isEmpty) {
      return Stream.value(null);
    }

    return _mandaliRef(normalizedMandaliId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;

      final normalizedData = Map<String, dynamic>.from(data);
      final storedMandaliId =
      (normalizedData['mandaliId'] ?? '').toString().trim();
      if (storedMandaliId.isEmpty) {
        normalizedData['mandaliId'] = doc.id;
      }

      return BhaktaMandali.fromMap(normalizedData);
    });
  }

  Stream<List<BhaktaMandaliMember>> watchLeaderboard(String mandaliId) {
    final normalizedMandaliId = mandaliId.trim();
    if (normalizedMandaliId.isEmpty) {
      return Stream.value(const <BhaktaMandaliMember>[]);
    }

    return _membersRef(normalizedMandaliId)
        .orderBy('contributionCount', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => BhaktaMandaliMember.fromMap(doc.data()))
          .toList(),
    );
  }

  Future<BhaktaMandali?> getMandaliByInviteCode(String inviteCode) async {
    final normalizedCode = inviteCode.trim().toUpperCase();
    if (normalizedCode.length != 8) return null;

    final inviteSnap = await _inviteCodes().doc(normalizedCode).get();
    final inviteData = inviteSnap.data();
    if (inviteData == null) return null;

    final mandaliId = (inviteData['mandaliId'] ?? '').toString().trim();
    if (mandaliId.isEmpty) return null;

    final mandaliSnap = await _mandaliRef(mandaliId).get();
    final mandaliData = mandaliSnap.data();
    if (mandaliData == null) return null;

    final normalizedData = Map<String, dynamic>.from(mandaliData);
    final storedMandaliId =
    (normalizedData['mandaliId'] ?? '').toString().trim();
    if (storedMandaliId.isEmpty) {
      normalizedData['mandaliId'] = mandaliSnap.id;
    }

    return BhaktaMandali.fromMap(normalizedData);
  }

  Future<String> createMandali({
    required String baseName,
    required String category,
    required String description,
    required bool isPublic,
    required String challengeTitle,
    required int challengeTarget,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    final trimmedBaseName = baseName.trim();
    if (trimmedBaseName.isEmpty) {
      throw Exception('Mandali name cannot be empty');
    }

    if (challengeTarget <= 0) {
      throw Exception('Challenge target must be greater than zero');
    }

    final displayName = _withSuffix(trimmedBaseName);
    final normalizedName = trimmedBaseName.toLowerCase();
    final nowIso = DateTime.now().toIso8601String();
    final mandaliId = 'mandali_${DateTime.now().millisecondsSinceEpoch}';
    final challengeId = 'challenge_${DateTime.now().millisecondsSinceEpoch}';
    final inviteCode = await _generateUniqueInviteCode();

    final challenge = BhaktaMandaliChallenge(
      challengeId: challengeId,
      title: challengeTitle.trim().isEmpty
          ? 'Rama Nama Challenge'
          : challengeTitle.trim(),
      target: challengeTarget,
      progressCount: 0,
      status: 'active',
      startDateIso: startDate.toIso8601String(),
      endDateIso: endDate.toIso8601String(),
      createdBy: user.uid,
      createdAtIso: nowIso,
      updatedAtIso: nowIso,
    );

    final rootData = {
      'mandaliId': mandaliId,
      'name': trimmedBaseName,
      'displayName': displayName,
      'normalizedName': normalizedName,
      'category': category.trim(),
      'description': description.trim(),
      'isPublic': isPublic,
      'inviteCode': inviteCode,
      'createdBy': user.uid,
      'createdByName': (user.displayName ?? 'Devotee').trim(),
      'memberCount': 1,
      'totalCount': 0,
      'activeChallengeId': challengeId,
      'activeChallenge': challenge.toMap(),
      'createdAt': nowIso,
      'updatedAt': nowIso,
      'lastContributionAt': null,
      'lastContributionBy': null,
    };

    final memberData = {
      'uid': user.uid,
      'displayName': (user.displayName ?? 'Devotee').trim(),
      'photoUrl': (user.photoURL ?? '').trim(),
      'role': 'creator',
      'status': 'active',
      'joinedAt': nowIso,
      'contributionCount': 0,
      'challengeContributionCount': 0,
      'lastContributionAt': null,
    };

    final userMirrorData = {
      'mandaliId': mandaliId,
      'displayName': displayName,
      'category': category.trim(),
      'description': description.trim(),
      'inviteCode': inviteCode,
      'createdBy': user.uid,
      'role': 'creator',
      'status': 'active',
      'joinedAt': nowIso,
      'contributionCount': 0,
      'challengeContributionCount': 0,
      'isSelectedActiveMandali': true,
      'lastContributionAt': null,
    };

    await _firestore.runTransaction((tx) async {
      final summarySnap = await tx.get(_summaryRef(user.uid));

      tx.set(_mandaliRef(mandaliId), rootData);
      tx.set(_challengesRef(mandaliId).doc(challengeId), challenge.toMap());
      tx.set(_membersRef(mandaliId).doc(user.uid), memberData);
      tx.set(_userMandalisRef(user.uid).doc(mandaliId), userMirrorData);
      tx.set(_inviteCodes().doc(inviteCode), {
        'inviteCode': inviteCode,
        'mandaliId': mandaliId,
        'displayName': displayName,
        'createdAt': nowIso,
      });

      tx.set(
        _summaryRef(user.uid),
        {
          'uid': user.uid,
          'activeMandaliId': mandaliId,
          'activeMandaliName': displayName,
          'activeMandaliChallengeId': challengeId,
          'updatedAt': nowIso,
          'createdAt': summarySnap.data()?['createdAt'] ?? nowIso,
        },
        SetOptions(merge: true),
      );
    });

    return mandaliId;
  }

  Future<void> joinMandaliByInviteCode({required String inviteCode}) async {
    final mandali = await getMandaliByInviteCode(inviteCode);
    if (mandali == null) {
      throw Exception('Invite code not found');
    }
    await joinMandaliById(mandaliId: mandali.mandaliId);
  }

  Future<void> joinMandaliById({required String mandaliId}) async {
    final normalizedMandaliId = _normalizeRequiredId(mandaliId, 'mandaliId');

    final user = AuthService.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    final nowIso = DateTime.now().toIso8601String();

    await _firestore.runTransaction((tx) async {
      final mandaliSnap = await tx.get(_mandaliRef(normalizedMandaliId));
      final mandaliData = mandaliSnap.data();
      if (mandaliData == null) {
        throw Exception('Mandali not found');
      }

      final normalizedMandaliData = Map<String, dynamic>.from(mandaliData);
      final storedMandaliId =
      (normalizedMandaliData['mandaliId'] ?? '').toString().trim();
      if (storedMandaliId.isEmpty) {
        normalizedMandaliData['mandaliId'] = mandaliSnap.id;
      }

      final memberRef = _membersRef(normalizedMandaliId).doc(user.uid);
      final memberSnap = await tx.get(memberRef);
      final userMirrorRef = _userMandalisRef(user.uid).doc(normalizedMandaliId);
      final userMirrorSnap = await tx.get(userMirrorRef);

      final mandali = BhaktaMandali.fromMap(normalizedMandaliData);

      if (memberSnap.exists || userMirrorSnap.exists) {
        final existingMemberData = memberSnap.data() ?? <String, dynamic>{};
        final existingMirrorData = userMirrorSnap.data() ?? <String, dynamic>{};

        tx.set(
          memberRef,
          {
            'uid': user.uid,
            'displayName': (user.displayName ?? 'Devotee').trim(),
            'photoUrl': (user.photoURL ?? '').trim(),
            'role': (existingMemberData['role'] ?? 'member').toString(),
            'status': 'active',
            'joinedAt': (existingMemberData['joinedAt'] ?? nowIso).toString(),
            'updatedAt': nowIso,
            'contributionCount':
            (existingMemberData['contributionCount'] as num?)?.toInt() ?? 0,
            'challengeContributionCount':
            (existingMemberData['challengeContributionCount'] as num?)
                ?.toInt() ??
                0,
            'lastContributionAt': existingMemberData['lastContributionAt'],
          },
          SetOptions(merge: true),
        );

        tx.set(
          userMirrorRef,
          {
            'mandaliId': mandali.mandaliId.isNotEmpty
                ? mandali.mandaliId
                : normalizedMandaliId,
            'displayName': mandali.displayName,
            'category': mandali.category,
            'description': mandali.description,
            'inviteCode': mandali.inviteCode,
            'createdBy': mandali.createdBy,
            'role': (existingMirrorData['role'] ?? 'member').toString(),
            'status': 'active',
            'joinedAt': (existingMirrorData['joinedAt'] ?? nowIso).toString(),
            'contributionCount':
            (existingMirrorData['contributionCount'] as num?)?.toInt() ?? 0,
            'challengeContributionCount':
            (existingMirrorData['challengeContributionCount'] as num?)
                ?.toInt() ??
                0,
            'isSelectedActiveMandali':
            existingMirrorData['isSelectedActiveMandali'] == true,
            'lastContributionAt': existingMirrorData['lastContributionAt'],
            'updatedAt': nowIso,
          },
          SetOptions(merge: true),
        );

        return;
      }

      tx.set(
        memberRef,
        {
          'uid': user.uid,
          'displayName': (user.displayName ?? 'Devotee').trim(),
          'photoUrl': (user.photoURL ?? '').trim(),
          'role': 'member',
          'status': 'active',
          'joinedAt': nowIso,
          'contributionCount': 0,
          'challengeContributionCount': 0,
          'lastContributionAt': null,
        },
      );

      tx.set(
        userMirrorRef,
        {
          'mandaliId': mandali.mandaliId.isNotEmpty
              ? mandali.mandaliId
              : normalizedMandaliId,
          'displayName': mandali.displayName,
          'category': mandali.category,
          'description': mandali.description,
          'inviteCode': mandali.inviteCode,
          'createdBy': mandali.createdBy,
          'role': 'member',
          'status': 'active',
          'joinedAt': nowIso,
          'contributionCount': 0,
          'challengeContributionCount': 0,
          'isSelectedActiveMandali': false,
          'lastContributionAt': null,
        },
      );

      tx.update(_mandaliRef(normalizedMandaliId), {
        'memberCount': FieldValue.increment(1),
        'updatedAt': nowIso,
      });
    });
  }

  Future<void> leaveMandali({required String mandaliId}) async {
    final normalizedMandaliId = _normalizeRequiredId(mandaliId, 'mandaliId');

    final user = AuthService.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    final nowIso = DateTime.now().toIso8601String();

    await _firestore.runTransaction((tx) async {
      final memberRef = _membersRef(normalizedMandaliId).doc(user.uid);
      final mirrorRef = _userMandalisRef(user.uid).doc(normalizedMandaliId);
      final summaryRef = _summaryRef(user.uid);

      final memberSnap = await tx.get(memberRef);
      final mirrorSnap = await tx.get(mirrorRef);
      final summarySnap = await tx.get(summaryRef);

      final memberData = memberSnap.data();
      if (memberData == null) return;
      if ((memberData['role'] ?? '').toString() == 'creator') {
        throw Exception('Creator cannot leave the Mandali in MVP');
      }

      tx.set(
        memberRef,
        {'status': 'left', 'updatedAt': nowIso},
        SetOptions(merge: true),
      );
      tx.set(
        mirrorRef,
        {'status': 'left', 'updatedAt': nowIso},
        SetOptions(merge: true),
      );
      tx.update(_mandaliRef(normalizedMandaliId), {
        'memberCount': FieldValue.increment(-1),
        'updatedAt': nowIso,
      });

      final activeMandaliId =
      (summarySnap.data()?['activeMandaliId'] ?? '').toString().trim();
      if (activeMandaliId == normalizedMandaliId) {
        tx.set(
          summaryRef,
          {
            'activeMandaliId': '',
            'activeMandaliName': '',
            'activeMandaliChallengeId': '',
            'updatedAt': nowIso,
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  Future<void> setActiveMandali({
    required String uid,
    required String mandaliId,
    required String mandaliName,
    required String challengeId,
  }) async {
    final normalizedMandaliId = _normalizeRequiredId(mandaliId, 'mandaliId');
    final nowIso = DateTime.now().toIso8601String();
    final allMyMandalis = await _userMandalisRef(uid).get();

    final batch = _firestore.batch();

    for (final doc in allMyMandalis.docs) {
      batch.set(
        doc.reference,
        {
          'isSelectedActiveMandali': doc.id == normalizedMandaliId,
          'updatedAt': nowIso,
        },
        SetOptions(merge: true),
      );
    }

    batch.set(
      _summaryRef(uid),
      {
        'uid': uid,
        'activeMandaliId': normalizedMandaliId,
        'activeMandaliName': mandaliName,
        'activeMandaliChallengeId': challengeId,
        'updatedAt': nowIso,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> clearActiveMandali({required String uid}) async {
    final nowIso = DateTime.now().toIso8601String();
    final allMyMandalis = await _userMandalisRef(uid).get();
    final batch = _firestore.batch();

    for (final doc in allMyMandalis.docs) {
      batch.set(
        doc.reference,
        {
          'isSelectedActiveMandali': false,
          'updatedAt': nowIso,
        },
        SetOptions(merge: true),
      );
    }

    batch.set(
      _summaryRef(uid),
      {
        'uid': uid,
        'activeMandaliId': '',
        'activeMandaliName': '',
        'activeMandaliChallengeId': '',
        'updatedAt': nowIso,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  String buildInviteMessage(BhaktaMandali mandali) {
    return 'Jai Shri Ram 🙏\n\n'
        'Join ${mandali.displayName} in eRamakoti.\n'
        'Invite code: ${mandali.inviteCode}\n\n'
        'Let us write Sri Rama Nama together.\n\n'
        'Install the app:\n'
        'https://play.google.com/store/apps/details?id=com.hindu.pooja';
  }

  Future<String> _generateUniqueInviteCode() async {
    for (var i = 0; i < 10; i++) {
      final code = _randomCode(8);
      final doc = await _inviteCodes().doc(code).get();
      if (!doc.exists) return code;
    }
    throw Exception('Could not generate unique invite code. Please try again.');
  }

  String _randomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      length,
          (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }

  String _withSuffix(String baseName) {
    final trimmed = baseName.trim();
    if (trimmed.toLowerCase().endsWith('bhakta mandali')) {
      return trimmed;
    }
    return '$trimmed Bhakta Mandali';
  }
}
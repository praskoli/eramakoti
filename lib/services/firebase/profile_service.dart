import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

import '../../models/user_profile.dart';

class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) {
    return _firestore.collection('userProfiles').doc(uid);
  }

  Future<UserProfile> getOrCreateProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No logged in user found.');
    }

    final ref = _profileRef(user.uid);
    final doc = await ref.get();

    if (doc.exists) {
      final profile = UserProfile.fromDoc(doc);
      final ensured = await ensureSystemFields(profile);
      return ensured;
    }

    final initial = UserProfile(
      uid: user.uid,
      displayName: (user.displayName ?? '').trim(),
      email: (user.email ?? '').trim(),
      mobileNumber: (user.phoneNumber ?? '').trim(),
      provider: _resolveProvider(user),
      photoUrl: (user.photoURL ?? '').trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      profileId: null,
    );

    await ref.set({
      'uid': initial.uid,
      'displayName': initial.displayName,
      'email': initial.email,
      'mobileNumber': initial.mobileNumber,
      'provider': initial.provider,
      'photoUrl': initial.photoUrl,
      'profileId': initial.profileId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final createdDoc = await ref.get();
    return UserProfile.fromDoc(createdDoc);
  }

  Future<UserProfile> ensureSystemFields(UserProfile current) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No logged in user found.');
    }

    final resolvedProvider = _resolveProvider(user);
    final authEmail = (user.email ?? '').trim();
    final authPhoto = (user.photoURL ?? '').trim();

    final ref = _profileRef(user.uid);

    final patch = <String, dynamic>{
      'uid': user.uid,
      'provider': resolvedProvider,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (current.email.trim().isEmpty && authEmail.isNotEmpty) {
      patch['email'] = authEmail;
    }

    if (current.photoUrl.trim().isEmpty && authPhoto.isNotEmpty) {
      patch['photoUrl'] = authPhoto;
    }

    if (current.createdAt == null) {
      patch['createdAt'] = FieldValue.serverTimestamp();
    }

    await ref.set(patch, SetOptions(merge: true));

    final refreshed = await ref.get();
    return UserProfile.fromDoc(refreshed);
  }

  Future<UserProfile> saveProfile({
    required String displayName,
    required String mobileNumber,
    String? photoUrlOverride,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No logged in user found.');
    }

    final ref = _profileRef(user.uid);

    await ref.set({
      'uid': user.uid,
      'displayName': displayName.trim(),
      'email': (user.email ?? '').trim(),
      'mobileNumber': mobileNumber.trim(),
      'provider': _resolveProvider(user),
      if (photoUrlOverride != null) 'photoUrl': photoUrlOverride.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final doc = await ref.get();
    return UserProfile.fromDoc(doc);
  }

  Future<String> uploadAvatarBytes(Uint8List originalBytes) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No logged in user found.');
    }

    final processed = _cropAndCompressToSquare(originalBytes);

    final ref = _storage.ref().child('profile_photos/${user.uid}/avatar.jpg');
    await ref.putData(
      processed,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final downloadUrl = await ref.getDownloadURL();

    await _profileRef(user.uid).set({
      'uid': user.uid,
      'photoUrl': downloadUrl,
      'provider': _resolveProvider(user),
      'email': (user.email ?? '').trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return downloadUrl;
  }

  Uint8List _cropAndCompressToSquare(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Unable to read selected image.');
    }

    final side = decoded.width < decoded.height ? decoded.width : decoded.height;
    final offsetX = (decoded.width - side) ~/ 2;
    final offsetY = (decoded.height - side) ~/ 2;

    final cropped = img.copyCrop(
      decoded,
      x: offsetX,
      y: offsetY,
      width: side,
      height: side,
    );

    final resized = img.copyResize(
      cropped,
      width: 640,
      height: 640,
      interpolation: img.Interpolation.average,
    );

    final jpg = img.encodeJpg(resized, quality: 85);
    return Uint8List.fromList(jpg);
  }

  String _resolveProvider(User user) {
    final providers = user.providerData.map((e) => e.providerId).toList();

    if (providers.contains('google.com')) return 'google.com';
    if (providers.contains('facebook.com')) return 'facebook.com';
    return providers.isNotEmpty ? providers.first : '';
  }
}
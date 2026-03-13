import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.mobileNumber,
    required this.provider,
    required this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.profileId,
  });

  final String uid;
  final String displayName;
  final String email;
  final String mobileNumber;
  final String provider;
  final String photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? profileId;

  factory UserProfile.empty(String uid) {
    return UserProfile(
      uid: uid,
      displayName: '',
      email: '',
      mobileNumber: '',
      provider: '',
      photoUrl: '',
      createdAt: null,
      updatedAt: null,
      profileId: null,
    );
  }

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    DateTime? asDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return UserProfile(
      uid: (data['uid'] as String?)?.trim().isNotEmpty == true
          ? (data['uid'] as String).trim()
          : doc.id,
      displayName: (data['displayName'] as String? ?? '').trim(),
      email: (data['email'] as String? ?? '').trim(),
      mobileNumber: (data['mobileNumber'] as String? ?? '').trim(),
      provider: (data['provider'] as String? ?? '').trim(),
      photoUrl: (data['photoUrl'] as String? ?? '').trim(),
      createdAt: asDateTime(data['createdAt']),
      updatedAt: asDateTime(data['updatedAt']),
      profileId: (data['profileId'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'mobileNumber': mobileNumber,
      'provider': provider,
      'photoUrl': photoUrl,
      'profileId': profileId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? mobileNumber,
    String? provider,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profileId,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      provider: provider ?? this.provider,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileId: profileId ?? this.profileId,
    );
  }

  String get resolvedProfileId {
    final trimmed = profileId?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;

    final seed = uid.trim();
    if (seed.isEmpty) return 'ER-USER';

    final short = seed.length >= 6 ? seed.substring(0, 6) : seed;
    return 'ER-${short.toUpperCase()}';
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase/firestore_service.dart';

class GoogleSignInService {
  GoogleSignInService._();

  static final GoogleSignInService instance = GoogleSignInService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signIn() async {
    try {
      UserCredential? credential;

      if (kIsWeb) {
        await _auth.signOut();

        final googleProvider = GoogleAuthProvider()
          ..setCustomParameters({
            'prompt': 'select_account',
          })
          ..addScope('email')
          ..addScope('profile');

        credential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

        final authCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        credential = await _auth.signInWithCredential(authCredential);
      }

      final user = credential.user;
      debugPrint('GOOGLE SIGN-IN SUCCESS: uid=${user?.uid}, email=${user?.email}');

      if (user != null) {
        await FirestoreService.instance.bootstrapUser(user);
      }

      return credential;
    } catch (e, st) {
      debugPrint('GOOGLE SIGN-IN ERROR: $e');
      debugPrint('$st');
      rethrow;
    }
  }
}
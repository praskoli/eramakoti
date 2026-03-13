import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  Future<UserCredential?> signInWithFacebook() async {
    if (kIsWeb) {
      final facebookProvider = FacebookAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'display': 'popup'});
      return await _auth.signInWithPopup(facebookProvider);
    }

    try {
      debugPrint('FB SIGN-IN: start');

      try {
        await FacebookAuth.instance.logOut();
      } catch (_) {}

      final LoginResult result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
        loginBehavior: LoginBehavior.nativeWithFallback,
      );

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken;
        if (accessToken == null) return null;

        final credential =
        FacebookAuthProvider.credential(accessToken.tokenString);

        return await _auth.signInWithCredential(credential);
      }

      if (result.status == LoginStatus.cancelled) {
        return null;
      }

      throw Exception(result.message ?? 'Facebook sign-in failed');
    } catch (e, st) {
      debugPrint('FB SIGN-IN ERROR: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}

    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}

    try {
      if (!kIsWeb) {
        await _googleSignIn.disconnect();
      }
    } catch (_) {}

    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }
}
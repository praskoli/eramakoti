import 'package:eramakoti/screens/donation_transparency_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eramakoti/services/auth/google_sign_in_service.dart';
import 'package:eramakoti/services/auth/auth_service.dart';
import 'package:eramakoti/services/firebase/firestore_service.dart';
import 'package:eramakoti/features/navigation/main_bottom_nav_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const Color bgColor = Color(0xFFF6EBDD);
  static const Color cardColor = Color(0xFFF8F1E8);
  static const Color googleBorder = Color(0xFFD9D0C5);
  static const Color facebookBlue = Color(0xFF1877F2);
  static const Color textDark = Color(0xFF3E2A1F);
  static const Color subText = Color(0xFF6A5546);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;
  bool _hasAcceptedPolicies = false;
  bool _showConsentHelper = false;
  void _openDonationTransparency() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DonationTransparencyScreen(),
      ),
    );
  }
  static const bool _showFacebookLogin = true;

  static const String _privacyAndTermsUrl =
      'https://hindupoojaapp.firebaseapp.com/privacy';
  static const String _deleteAccountUrl =
      'https://hindupoojaapp.firebaseapp.com/delete-account';
  static const String _qtiLabsUrl = 'https://www.qtilabs.com/';
  static const String _termsPopupSeenKey = 'eramakoti_terms_popup_seen';
  static const String _termsVersion = 'v1';

  bool get _isAnyLoading => _isGoogleLoading || _isFacebookLoading;

  @override
  void initState() {
    super.initState();
    _showTermsPopupIfNeeded();
  }

  Future<void> _showTermsPopupIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadySeen = prefs.getBool(_termsPopupSeenKey) ?? false;

    if (alreadySeen || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Privacy & Terms',
              textAlign: TextAlign.center,
            ),
            content: const Text(
              'Please review our Privacy Policy and Terms & Conditions.\n\n'
                  'By continuing to sign in, you agree to them.',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () async {
                  await _openUrl(_privacyAndTermsUrl);
                },
                child: const Text('View'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      await prefs.setBool(_termsPopupSeenKey, true);
    });
  }

  Future<void> _showAccountExistsDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Account Already Exists',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'This email is already linked to an\n'
                'eRamakoti account.\n\n'
                'Please continue using the sign-in\n'
                'method you used earlier.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _ensureConsentAccepted() async {
    if (_hasAcceptedPolicies) return true;

    if (mounted) {
      setState(() => _showConsentHelper = true);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept Privacy Policy and Terms & Conditions to continue.',
          ),
        ),
      );
    }

    return false;
  }

  Future<void> _saveTermsAcceptance(User user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'termsAccepted': true,
      'termsAcceptedAt': FieldValue.serverTimestamp(),
      'termsVersion': _termsVersion,
    }, SetOptions(merge: true));
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isAnyLoading) return;
    if (!await _ensureConsentAccepted()) return;

    setState(() => _isGoogleLoading = true);

    try {
      final cred = await GoogleSignInService.instance.signIn();

      if (!mounted) return;

      final user = cred?.user;
      if (user != null) {
        await FirestoreService.instance.bootstrapUser(user);
        await _saveTermsAcceptance(user);

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainBottomNavScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'account-exists-with-different-credential') {
        await _showAccountExistsDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sign-in failed. Please try again.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google sign-in failed. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _handleFacebookSignIn() async {
    if (_isAnyLoading) return;
    if (!await _ensureConsentAccepted()) return;

    setState(() => _isFacebookLoading = true);

    try {
      final cred = await AuthService.instance.signInWithFacebook();

      if (!mounted) return;

      final user = cred?.user;
      if (user != null) {
        await FirestoreService.instance.bootstrapUser(user);
        await _saveTermsAcceptance(user);

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainBottomNavScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'account-exists-with-different-credential') {
        await _showAccountExistsDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Facebook sign-in failed. Please try again.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Facebook sign-in failed. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isFacebookLoading = false);
      }
    }
  }

  Future<void> _openUrl(String urlString) async {
    final uri = Uri.parse(urlString);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open link. Please try again.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open link. Please try again.'),
        ),
      );
    }
  }

  Future<void> _openQtiLabsWebsite() async {
    await _openUrl(_qtiLabsUrl);
  }

  Future<void> _openPrivacyPolicy() async {
    await _openUrl(_privacyAndTermsUrl);
  }

  Future<void> _openTermsAndConditions() async {
    await _openUrl(_privacyAndTermsUrl);
  }

  Future<void> _openDeleteAccount() async {
    await _openUrl(_deleteAccountUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginScreen.bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  final logoWidth = isWide ? 260.0 : 220.0;
                  final topGap = isWide ? 10.0 : 8.0;
                  final betweenGap = isWide ? 18.0 : 14.0;
                  final largeGap = isWide ? 22.0 : 18.0;
                  final poweredGap = isWide ? 36.0 : 28.0;

                  return ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      scrollbars: false,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: topGap),
                              SizedBox(height: largeGap),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  'assets/images/eramakoti.png',
                                  width: logoWidth,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              SizedBox(height: largeGap),
                              const Text(
                                'eRamakoti',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: LoginScreen.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Digital Sri Rama Nama Writing',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: LoginScreen.subText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: largeGap),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: LoginScreen.cardColor,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x22000000),
                                      blurRadius: 14,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _GoogleLoginButton(
                                      onPressed: _isAnyLoading
                                          ? null
                                          : _handleGoogleSignIn,
                                      isLoading: _isGoogleLoading,
                                    ),
                                    if (_showFacebookLogin) ...[
                                      SizedBox(height: betweenGap),
                                      _FacebookLoginButton(
                                        onPressed: _isAnyLoading
                                            ? null
                                            : _handleFacebookSignIn,
                                        isLoading: _isFacebookLoading,
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Checkbox(
                                          value: _hasAcceptedPolicies,
                                          onChanged: _isAnyLoading
                                              ? null
                                              : (value) {
                                            setState(() {
                                              _hasAcceptedPolicies =
                                                  value ?? false;
                                              if (_hasAcceptedPolicies) {
                                                _showConsentHelper = false;
                                              }
                                            });
                                          },
                                          activeColor:
                                          LoginScreen.facebookBlue,
                                          visualDensity:
                                          VisualDensity.compact,
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding:
                                            const EdgeInsets.only(top: 10),
                                            child: Wrap(
                                              alignment: WrapAlignment.start,
                                              crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                              children: [
                                                const Text(
                                                  'I agree to ',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: LoginScreen.subText,
                                                    height: 1.4,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: _openPrivacyPolicy,
                                                  child: const Text(
                                                    'Privacy Policy',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: LoginScreen
                                                          .facebookBlue,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                      decoration: TextDecoration
                                                          .underline,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ),
                                                const Text(
                                                  ' and ',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: LoginScreen.subText,
                                                    height: 1.4,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap:
                                                  _openTermsAndConditions,
                                                  child: const Text(
                                                    'Terms & Conditions',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: LoginScreen
                                                          .facebookBlue,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                      decoration: TextDecoration
                                                          .underline,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_showConsentHelper)
                                      const Padding(
                                        padding: EdgeInsets.only(
                                          top: 4,
                                          left: 8,
                                          right: 8,
                                        ),
                                        child: Text(
                                          'Please accept the Privacy Policy and Terms & Conditions to continue.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _openDeleteAccount,
                                child: const Text(
                                  'Delete Account',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: LoginScreen.subText,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              GestureDetector(
                                onTap: _openDonationTransparency,
                                child: const Text(
                                  'Offer Support Transparency',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: LoginScreen.subText,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'Login is free. Any support offered in the app is voluntary.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: LoginScreen.subText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(height: poweredGap),
                              const Text(
                                'Powered by',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: _openQtiLabsWebsite,
                                  child: Image.asset(
                                    'assets/images/qtilabs.png',
                                    height: 42,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isAnyLoading)
              AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black.withOpacity(0.12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLoginButton extends StatelessWidget {
  final Future<void> Function()? onPressed;
  final bool isLoading;

  const _GoogleLoginButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(
            color: LoginScreen.googleBorder,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : Row(
          children: const [
            _GoogleGLogo(),
            SizedBox(width: 18),
            Expanded(
              child: Text(
                'Continue with Google',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}

class _FacebookLoginButton extends StatelessWidget {
  final Future<void> Function()? onPressed;
  final bool isLoading;

  const _FacebookLoginButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: LoginScreen.facebookBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          disabledBackgroundColor:
          LoginScreen.facebookBlue.withOpacity(0.75),
        ),
        child: isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Row(
          children: const [
            Text(
              'f',
              style: TextStyle(
                fontSize: 34,
                height: 1,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 18),
            Expanded(
              child: Text(
                'Continue with Facebook',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}

class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eramakoti/services/auth/google_sign_in_service.dart';
import 'package:eramakoti/services/auth/auth_service.dart';
import 'package:eramakoti/services/firebase/firestore_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const Color _bgColor = Color(0xFFF6EBDD);
  static const Color _cardColor = Color(0xFFF8F1E8);
  static const Color _googleBorder = Color(0xFFD9D0C5);
  static const Color _facebookBlue = Color(0xFF1877F2);
  static const Color _textDark = Color(0xFF3E2A1F);
  static const Color _subText = Color(0xFF6A5546);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final logoWidth = isWide ? 260.0 : 220.0;
              final topGap = isWide ? 10.0 : 8.0;
              final betweenGap = isWide ? 18.0 : 14.0;
              final largeGap = isWide ? 22.0 : 18.0;
              final poweredGap = isWide ? 36.0 : 28.0;

              return ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
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
                              color: _textDark,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Digital Sri Rama Nama Writing',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: _subText,
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
                              color: _cardColor,
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
                                  onPressed: () async {
                                    try {
                                      await GoogleSignInService.instance.signIn();
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Google sign-in failed: $e'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                SizedBox(height: betweenGap),
                                _FacebookLoginButton(
                                  onPressed: () async {
                                    try {
                                      final cred = await AuthService.instance
                                          .signInWithFacebook();

                                      final user = cred?.user;

                                      if (user != null) {
                                        await FirestoreService.instance
                                            .bootstrapUser(user);
                                      }
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Facebook sign-in failed: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
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
                              onTap: () async {
                                final url = Uri.parse(
                                  'https://www.qtilabs.com/',
                                );
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
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
      ),
    );
  }
}

class _GoogleLoginButton extends StatelessWidget {
  final Future<void> Function() onPressed;

  const _GoogleLoginButton({required this.onPressed});

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
            color: LoginScreen._googleBorder,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
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
  final Future<void> Function() onPressed;

  const _FacebookLoginButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: LoginScreen._facebookBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: Row(
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
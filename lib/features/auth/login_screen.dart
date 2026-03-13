import 'package:flutter/material.dart';
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

  bool get _isAnyLoading => _isGoogleLoading || _isFacebookLoading;

  Future<void> _handleGoogleSignIn() async {
    if (_isAnyLoading) return;

    setState(() => _isGoogleLoading = true);

    try {
      final cred = await GoogleSignInService.instance.signIn();

      if (!mounted) return;

      if (cred?.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainBottomNavScreen(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _handleFacebookSignIn() async {
    if (_isAnyLoading) return;

    setState(() => _isFacebookLoading = true);

    try {
      final cred = await AuthService.instance.signInWithFacebook();

      if (!mounted) return;

      final user = cred?.user;
      if (user != null) {
        await FirestoreService.instance.bootstrapUser(user);

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainBottomNavScreen(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Facebook sign-in failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isFacebookLoading = false);
      }
    }
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
                                    SizedBox(height: betweenGap),
                                    _FacebookLoginButton(
                                      onPressed: _isAnyLoading
                                          ? null
                                          : _handleFacebookSignIn,
                                      isLoading: _isFacebookLoading,
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
          disabledBackgroundColor: LoginScreen.facebookBlue.withOpacity(0.75),
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
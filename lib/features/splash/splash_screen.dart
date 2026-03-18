import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eramakoti/app/router/route_names.dart';
import 'package:eramakoti/features/auth/auth_gate.dart';
import 'package:eramakoti/services/app_update_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _runStartupChecks();
  }

  Future<void> _runStartupChecks() async {
    debugPrint('SPLASH_CHECK started');

    try {
      final result = await AppUpdateService.check();

      debugPrint(
        'SPLASH_CHECK result force=${result.force} optional=${result.optional} url=${result.url}',
      );

      if (!mounted) return;

      if (result.force && result.url != null && result.url!.isNotEmpty) {
        final encodedUrl = Uri.encodeComponent(result.url!);
        debugPrint('SPLASH_CHECK going to force update');
        context.go('${RouteNames.forceUpdate}?url=$encodedUrl');
        return;
      }

      debugPrint('SPLASH_CHECK going to auth gate');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const AuthGate(),
        ),
      );
    } catch (e, st) {
      debugPrint('SPLASH_CHECK exception=$e');
      debugPrint('SPLASH_CHECK stack=$st');

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const AuthGate(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6EBDD),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/eramakoti.png',
                    width: 180,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'eRamakoti',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3E2A1F),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Digital Sri Rama Nama Writing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6A5546),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
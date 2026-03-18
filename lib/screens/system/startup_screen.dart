import 'package:flutter/material.dart';
import 'package:eramakoti/features/auth/auth_gate.dart';
import 'package:eramakoti/features/intro/devotional_intro_screen.dart';
import 'package:eramakoti/screens/system/force_update_screen.dart';
import 'package:eramakoti/services/app_update_service.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _runStartupChecks();
  }

  Future<void> _runStartupChecks() async {
    try {
      final result = await AppUpdateService.check();

      if (!mounted) return;

      if (result.force && result.url != null && result.url!.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ForceUpdateScreen(playUrl: result.url!),
          ),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const DevotionalIntroScreen(
            nextScreen: AuthGate(),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const DevotionalIntroScreen(
            nextScreen: AuthGate(),
            duration: Duration(milliseconds: 2500),
          ),
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
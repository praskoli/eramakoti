import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../features/auth/login_screen.dart';
import '../../screens/ramakoti/ramakoti_entry_gate.dart';
import '../../screens/system/force_update_screen.dart';
import '../../services/auth/auth_service.dart';
import '../../services/app_update_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  bool _checkingForceUpdate = false;
  bool _navigatedToForceUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForceUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForceUpdate();
    }
  }

  Future<void> _checkForceUpdate() async {
    if (_checkingForceUpdate || _navigatedToForceUpdate) return;

    _checkingForceUpdate = true;

    try {
      final result = await AppUpdateService.check();

      if (!mounted) return;

      if (result.force && result.url != null && result.url!.isNotEmpty) {
        _navigatedToForceUpdate = true;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ForceUpdateScreen(playUrl: result.url!),
          ),
              (route) => false,
        );
      }
    } catch (_) {
      // Ignore here so normal auth flow can continue.
    } finally {
      _checkingForceUpdate = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (_navigatedToForceUpdate) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          return const RamakotiEntryGate();
        }

        return const LoginScreen();
      },
    );
  }
}
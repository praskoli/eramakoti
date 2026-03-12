import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../features/auth/auth_gate.dart';
import '../../features/auth/login_screen.dart';
import '../../screens/ramakoti/ramakoti_entry_gate.dart';
import '../../services/auth/auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges(),
      builder: (context, snapshot) {
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
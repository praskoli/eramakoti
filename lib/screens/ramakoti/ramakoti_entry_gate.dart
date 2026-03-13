import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../../features/navigation/main_bottom_nav_screen.dart';
class RamakotiEntryGate extends StatelessWidget {
  const RamakotiEntryGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No authenticated user')),
      );
    }

    return const MainBottomNavScreen();  }
}
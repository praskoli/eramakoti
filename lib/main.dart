import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:eramakoti/firebase_options.dart';
import 'package:eramakoti/screens/system/force_update_screen.dart';
import 'package:eramakoti/services/notifications/reminder_service.dart';
import 'package:eramakoti/screens/system/startup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await ReminderService.instance.initialize();

  runApp(const ERamakotiBootstrapApp());
}

class ERamakotiBootstrapApp extends StatelessWidget {
  const ERamakotiBootstrapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eRamakoti',
      debugShowCheckedModeBanner: false,
      home: const StartupScreen(),
    );
  }
}
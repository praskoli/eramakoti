import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/system/startup_screen.dart';
import 'services/notifications/reminder_service.dart';
import 'services/temples/temple_context_service.dart';
import 'services/deep_links/deep_link_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await ReminderService.instance.initialize();

  final templeContextService = TempleContextService();
  await templeContextService.initialize();

  final deepLinkService = DeepLinkService(templeContextService);
  await deepLinkService.start();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TempleContextService>.value(
          value: templeContextService,
        ),
        Provider<DeepLinkService>.value(
          value: deepLinkService,
        ),
      ],
      child: const ERamakotiBootstrapApp(),
    ),
  );
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
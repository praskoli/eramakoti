import 'package:flutter/material.dart';
import 'router/app_router.dart';
import '../core/theme/app_theme.dart';

class ERamakotiApp extends StatelessWidget {
  const ERamakotiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'eRamakoti',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
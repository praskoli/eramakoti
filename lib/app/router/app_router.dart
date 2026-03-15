import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eramakoti/features/auth/auth_gate.dart';
import 'package:eramakoti/features/auth/login_screen.dart';
import 'package:eramakoti/features/splash/splash_screen.dart';
import 'package:eramakoti/app/router/route_names.dart';
import 'package:eramakoti/screens/system/force_update_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const AuthGate(),
      ),
      GoRoute(
        path: '/auth-gate',
        builder: (context, state) => const AuthGate(),
      ),
      GoRoute(
        path: RouteNames.forceUpdate,
        builder: (context, state) {
          final playUrl = state.uri.queryParameters['url'] ?? '';
          return ForceUpdateScreen(playUrl: playUrl);
        },
      ),
    ],
  );
}
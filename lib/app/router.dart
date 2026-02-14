import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domains/app/presentation/screens/home_screen.dart';
import '../domains/app/presentation/screens/welcome_screen.dart';
import '../domains/app/presentation/screens/settings_screen.dart';

/// 路由路径常量
abstract final class AppRoutes {
  static const String welcome = '/welcome';
  static const String home = '/';
  static const String settings = '/settings';
}

/// 创建 GoRouter 配置
/// initialLocation 由调用者根据 vault 状态决定
GoRouter createGoRouter({String initialLocation = AppRoutes.welcome}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
    ],
  );
}

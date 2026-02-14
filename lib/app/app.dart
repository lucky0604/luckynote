import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domains/settings/presentation/providers/theme_provider.dart';
import '../domains/notes/presentation/providers/vault_provider.dart';
import 'router.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

/// Router provider - 根据 vault 状态动态创建
final routerProvider = Provider<GoRouter>((ref) {
  // 监听 vault 状态
  final vaultState = ref.watch(vaultProvider);

  // 根据 vault 状态决定初始位置
  String initialLocation = AppRoutes.welcome;

  vaultState.whenData((path) {
    if (path != null && path.isNotEmpty) {
      initialLocation = AppRoutes.home;
    }
  });

  // 创建 router
  return createGoRouter(initialLocation: initialLocation);
});

/// LuckyNote 应用根 Widget
class LuckyNoteApp extends ConsumerWidget {
  const LuckyNoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeNotifierProvider);

    // Derive themeMode from themeType - this will be recalculated on every rebuild
    final themeMode = ref.read(themeNotifierProvider.notifier).getThemeMode();

    // Update AppColors when theme changes
    // The key is that when themeType changes (after async load), this rebuilds
    // and AppColors.setTheme is called with the correct loaded theme
    AppColors.setTheme(themeType);

    // 获取 router
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'LuckyNote',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(themeType),
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

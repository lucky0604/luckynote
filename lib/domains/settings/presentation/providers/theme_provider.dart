import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/models/theme_model.dart';

part 'theme_provider.g.dart';

/// 主题状态
@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  AppThemeType build() {
    _loadTheme();
    return AppThemeType.system;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeTypeString = prefs.getString(AppConstants.keyThemeMode);
    if (themeTypeString != null) {
      state = AppThemeType.values.firstWhere(
        (e) => e.name == themeTypeString,
        orElse: () => AppThemeType.system,
      );
    }
  }

  Future<void> setTheme(AppThemeType themeType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyThemeMode, themeType.name);
    state = themeType;
  }

  ThemeMode getThemeMode() {
    switch (state) {
      case AppThemeType.system:
        return ThemeMode.system;
      case AppThemeType.warmLight:
      case AppThemeType.freshForest:
        return ThemeMode.light;
      case AppThemeType.dark:
        return ThemeMode.dark;
    }
  }
}

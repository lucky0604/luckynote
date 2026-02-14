import 'package:flutter/material.dart';
import 'package:luckynote/domains/settings/data/models/theme_model.dart';

/// LuckyNote 色彩系统
/// 支持 Warm Light、Fresh Forest、Dark 三种主题
abstract final class AppColors {
  static AppThemeType _themeType = AppThemeType.warmLight;

  static AppThemeType get themeType => _themeType;

  static void setTheme(AppThemeType type) {
    _themeType = type;
  }

  // ============ 背景色 ============
  static Color get background {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0xFF1E1E1E);
      case AppThemeType.freshForest:
        return const Color(0xFFFFFFFF);
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return const Color(0xFFFFF9F5);
    }
  }

  static Color get backgroundPure {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0xFF252525);
      case AppThemeType.freshForest:
        return const Color(0xFFF8F9FA);
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return const Color(0xFFFDFDFD);
    }
  }

  static Color get sidebarBackground {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0xFF2D2D2D);
      case AppThemeType.freshForest:
        return const Color(0xFF2B3A42);
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return const Color(0xFF2D2D2D);
    }
  }

  static Color get noteListBackground {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0xFF1A1A1A);
      case AppThemeType.freshForest:
        return const Color(0xFFF5F5F7);
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return const Color(0xFFFAFAFA);
    }
  }

  // ============ 文字色 ============
  static Color get textPrimary {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0xFFE0E0E0);
      case AppThemeType.freshForest:
        return const Color(0xFF2C3E50);
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return const Color(0xFF333333);
    }
  }

  static Color get textSecondary {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0xFFA0A0A0);
      case AppThemeType.freshForest:
        return const Color(0xFF5A6C7D);
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return const Color(0xFF666666);
    }
  }

  static Color get textPlaceholder {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0xFF707070);
      case AppThemeType.freshForest:
        return const Color(0xFF9CA3AF);
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return const Color(0xFF999999);
    }
  }

  static Color get sidebarText {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0xFFE0E0E0);
      case AppThemeType.freshForest:
        return const Color(0xFFE8ECF1);
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return const Color(0xFFE0E0E0);
    }
  }

  static Color get sidebarTextSecondary {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0xFF888888);
      case AppThemeType.freshForest:
        return const Color(0xFF8A9AAA);
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return const Color(0xFF888888);
    }
  }

  // ============ 强调色 ============
  static Color get accent {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0xFFFF6B6B);
      case AppThemeType.freshForest:
        return const Color(0xFF27AE60);
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return const Color(0xFFD75A4A);
    }
  }

  static Color get accentSecondary {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0xFF4ECDC4);
      case AppThemeType.freshForest:
        return const Color(0xFF3498DB);
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return const Color(0xFFE6B325);
    }
  }

  // ============ 链接 ============
  static Color get linkColor {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0xFF3B82F6);
      case AppThemeType.freshForest:
        return const Color(0xFF3B82F6);
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return const Color(0xFF3B82F6);
    }
  }

  static Color get success {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0xFF4CAF50);
      case AppThemeType.freshForest:
        return const Color(0xFF1E8449);
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return const Color(0xFF27AE60);
    }
  }

  static Color get warning {
    return const Color(0xFFF39C12);
  }

  static Color get error {
    return const Color(0xFFE74C3C);
  }

  static Color get onError {
    return const Color(0xFFE74C3C);
  }

  // ============ 边框和分割线 ============
  static Color get border {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0xFF3D3D3D);
      case AppThemeType.freshForest:
        return const Color(0xFFE1E8ED);
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return const Color(0xFFE5E5E5);
    }
  }

  static Color get divider {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0xFF2D2D2D);
      case AppThemeType.freshForest:
        return const Color(0xFFE8ECF1);
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return const Color(0xFFEEEEEE);
    }
  }

  static Color get hoverBackground {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0xFF2A2A2A);
      case AppThemeType.freshForest:
        return const Color(0xFFF0F3F5);
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return const Color(0xFFF5F5F5);
    }
  }

  static Color get selectedBackground {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0xFF3D2A2A);
      case AppThemeType.freshForest:
        return const Color(0xFFE8F5E9);
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return const Color(0xFFFFEDE9);
    }
  }

  // ============ 卡片 ============
  static Color get cardBackground {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0xFF252525);
      case AppThemeType.freshForest:
        return Colors.white;
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return Colors.white;
    }
  }

  static Color get cardShadow {
    switch (_themeType) {
      case AppThemeType.dark:
        return const Color(0x1A000000);
      case AppThemeType.freshForest:
        return const Color(0x0A000000);
      case AppThemeType.warmLight:
      case AppThemeType.system:
        return const Color(0x0A000000);
    }
  }
}

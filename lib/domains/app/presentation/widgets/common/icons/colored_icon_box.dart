import 'package:flutter/material.dart';

/// A box container with an icon and colored background.
///
/// Commonly used in list items to show item types with visual distinction.
/// Based on the pattern from mention_popup.dart and mention_overlay.dart.
class ColoredIconBox extends StatelessWidget {
  const ColoredIconBox({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.size = 28,
    this.iconSize = 14,
    this.borderRadius = 6,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor,
      ),
    );
  }
}

/// Icon color scheme for consistent theming across mention items.
///
/// Provides predefined color pairs for different item types.
class IconColorScheme {
  const IconColorScheme({
    required this.background,
    required this.foreground,
  });

  factory IconColorScheme.note() {
    return const IconColorScheme(
      background: Color(0xFFE3F2FD),
      foreground: Color(0xFF1565C0),
    );
  }

  factory IconColorScheme.folder() {
    return const IconColorScheme(
      background: Color(0xFFFFF8E1),
      foreground: Color(0xFFF57C00),
    );
  }

  factory IconColorScheme.tag() {
    return const IconColorScheme(
      background: Color(0xFFE8F5E9),
      foreground: Color(0xFF2E7D32),
    );
  }

  factory IconColorScheme.database() {
    return const IconColorScheme(
      background: Color(0xFFF3E5F5),
      foreground: Color(0xFF7B1FA2),
    );
  }

  factory IconColorScheme.browse() {
    return const IconColorScheme(
      background: Color(0xFFE0F2F1),
      foreground: Color(0xFF00695C),
    );
  }

  final Color background;
  final Color foreground;
}

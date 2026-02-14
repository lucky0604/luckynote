import 'package:flutter/material.dart';

/// A badge component for displaying numeric counts.
///
/// Commonly used for showing note counts, notification counts, etc.
/// Based on the pattern from file_tree_tile.dart.
class CountBadge extends StatelessWidget {
  const CountBadge({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.fontSize = 11,
    this.fontWeight = FontWeight.w600,
  });

  final int count;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ??
        theme.colorScheme.primary.withValues(alpha: 0.2);
    final txtColor = textColor ?? theme.colorScheme.primary;

    if (count <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: fontSize,
          color: txtColor,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// A chip component for displaying tags.
///
/// Commonly used for showing note tags, categories, labels, etc.
/// Based on the pattern from note_list_item.dart.
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.prefix,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderRadius = 4,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.fontSize = 10,
    this.fontWeight = FontWeight.w500,
    this.borderWidth = 0.5,
    this.onTap,
  });

  final String label;
  final Widget? prefix;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final FontWeight fontWeight;
  final double borderWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ??
        theme.colorScheme.primary.withValues(alpha: 0.1);
    final txtColor = textColor ?? theme.colorScheme.primary;
    final brColor = borderColor ??
        theme.colorScheme.primary.withValues(alpha: 0.3);

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefix != null) ...[
          prefix!,
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            color: txtColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
      ],
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: brColor,
          width: borderWidth,
        ),
      ),
      child: content,
    );
  }
}

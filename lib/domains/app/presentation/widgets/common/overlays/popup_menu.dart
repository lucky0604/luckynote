import 'package:flutter/material.dart';

/// Base popup menu widget with consistent styling.
///
/// Based on the pattern from mention_popup.dart.
/// Provides standard popup appearance with header, content, and optional footer.
class PopupMenu extends StatelessWidget {
  const PopupMenu({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.maxHeight = 320,
    this.maxWidth = 320,
    this.elevation = 8,
    this.borderRadius = 12,
    this.showDivider = true,
  });

  final Widget child;
  final Widget? header;
  final Widget? footer;
  final double maxHeight;
  final double maxWidth;
  final double elevation;
  final double borderRadius;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: elevation,
      borderRadius: BorderRadius.circular(borderRadius),
      color: theme.cardColor,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: maxWidth,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) ...[
                header!,
                if (showDivider) const Divider(height: 1),
              ],
              Flexible(child: child),
              if (footer != null) footer!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Standard popup header with icon and title.
class PopupHeader extends StatelessWidget {
  const PopupHeader({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.backgroundColor,
  });

  final String title;
  final IconData? icon;
  final String? subtitle;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ??
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: bgColor,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard popup footer with keyboard hints.
class PopupFooter extends StatelessWidget {
  const PopupFooter({
    super.key,
    this.hints = const [],
    this.backgroundColor,
  });

  final List<PopupKeyHint> hints;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ??
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);

    if (hints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: bgColor,
      child: Wrap(
        spacing: 12,
        children: hints.map((hint) => _buildHint(context, hint)).toList(),
      ),
    );
  }

  Widget _buildHint(BuildContext context, PopupKeyHint hint) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: theme.dividerColor,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            hint.key,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          hint.label,
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

/// Key hint for popup footer.
class PopupKeyHint {
  const PopupKeyHint({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;
}

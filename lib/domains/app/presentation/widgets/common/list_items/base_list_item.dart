import 'package:flutter/material.dart';

/// Base list item widget with hover state support.
///
/// Provides common hover behavior and selection styling
/// for list items throughout the application.
abstract class BaseListItem extends StatefulWidget {
  const BaseListItem({
    super.key,
    required this.isSelected,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.borderRadius = 8,
  });

  final bool isSelected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  /// Build the content of the list item.
  Widget buildContent(BuildContext context);

  /// Get the background color for unselected hovered state.
  Color getHoverColor(BuildContext context) {
    return Colors.white.withValues(alpha: 0.05);
  }

  /// Get the background color for selected state.
  Color getSelectedColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
  }

  /// Override to provide custom hover color logic.
  Color? getBackgroundColor(BuildContext context, bool isHovered) {
    if (isSelected) return getSelectedColor(context);
    if (isHovered) return getHoverColor(context);
    return Colors.transparent;
  }

  @override
  State<BaseListItem> createState() => _BaseListItemState();
}

class _BaseListItemState extends State<BaseListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: widget.getBackgroundColor(context, _isHovered),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            hoverColor: Colors.white.withValues(alpha: 0.05),
            child: Padding(
              padding: widget.padding,
              child: widget.buildContent(context),
            ),
          ),
        ),
      ),
    );
  }
}

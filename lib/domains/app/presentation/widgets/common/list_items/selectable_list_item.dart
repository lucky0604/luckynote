import 'package:flutter/material.dart';

import 'base_list_item.dart';

/// A list item that supports selection state with visual feedback.
///
/// Extends BaseListItem with explicit selection indicators
/// and customizable selection styles.
class SelectableListItem extends BaseListItem {
  const SelectableListItem({
    super.key,
    required super.isSelected,
    super.onTap,
    super.padding,
    super.borderRadius,
    required this.child,
    this.selectionColor,
    this.showSelectionIndicator = true,
  });

  final Widget child;
  final Color? selectionColor;
  final bool showSelectionIndicator;

  @override
  Widget buildContent(BuildContext context) => child;

  @override
  Color getSelectedColor(BuildContext context) {
    return selectionColor ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
  }
}

/// A list item optimized for hover interactions without selection.
///
/// Useful for menus and action lists where selection is handled externally.
class HoverableListItem extends StatefulWidget {
  const HoverableListItem({
    super.key,
    required this.child,
    this.onTap,
    this.onHover,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.borderRadius = 8,
    this.hoverColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onHover;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? hoverColor;

  @override
  State<HoverableListItem> createState() => _HoverableListItemState();
}

class _HoverableListItemState extends State<HoverableListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHover?.call(true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onHover?.call(false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _isHovered
              ? (widget.hoverColor ?? Colors.white.withValues(alpha: 0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Padding(
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// A wrapper widget for managing overlay entries with composited transforms.
///
/// Based on the pattern from mention_overlay.dart.
/// Provides consistent overlay positioning and lifecycle management.
class OverlayWrapper extends StatefulWidget {
  const OverlayWrapper({
    super.key,
    required this.child,
    required this.overlayBuilder,
    required this.showOverlay,
    this.offset = const Offset(0, -8),
    this.followerAnchor = Alignment.bottomLeft,
    this.targetAnchor = Alignment.topLeft,
    this.overlayWidth,
  });

  final Widget child;
  final Widget Function(BuildContext context) overlayBuilder;
  final bool showOverlay;
  final Offset offset;
  final Alignment followerAnchor;
  final Alignment targetAnchor;
  final double? overlayWidth;

  @override
  State<OverlayWrapper> createState() => _OverlayWrapperState();
}

class _OverlayWrapperState extends State<OverlayWrapper> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void didUpdateWidget(OverlayWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showOverlay != oldWidget.showOverlay) {
      _updateOverlay();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    if (widget.showOverlay && _overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else if (!widget.showOverlay && _overlayEntry != null) {
      _removeOverlay();
    }
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: widget.overlayWidth,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: widget.offset,
          followerAnchor: widget.followerAnchor,
          targetAnchor: widget.targetAnchor,
          child: widget.overlayBuilder(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: widget.child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:luckynote/core/constants/app_constants.dart';
import 'package:luckynote/domains/settings/presentation/providers/layout_settings_provider.dart';

/// 可调整大小的三栏布局
class ResizableLayout extends ConsumerStatefulWidget {
  final Widget sidebar;
  final Widget noteList;
  final Widget editor;

  const ResizableLayout({
    super.key,
    required this.sidebar,
    required this.noteList,
    required this.editor,
  });

  @override
  ConsumerState<ResizableLayout> createState() => _ResizableLayoutState();
}

class _ResizableLayoutState extends ConsumerState<ResizableLayout> {
  bool _isResizingSidebar = false;
  bool _isResizingNoteList = false;

  @override
  Widget build(BuildContext context) {
    final layoutSettings = ref.watch(layoutSettingsNotifierProvider);

    return Row(
      children: [
        _buildSidebar(layoutSettings),
        _buildDivider(
          () => _isResizingSidebar = true,
          () => _isResizingSidebar = false,
          (details) => _handleSidebarResize(layoutSettings, details),
        ),
        _buildNoteList(layoutSettings),
        _buildDivider(
          () => _isResizingNoteList = true,
          () => _isResizingNoteList = false,
          (details) => _handleNoteListResize(layoutSettings, details),
        ),
        Expanded(child: widget.editor),
      ],
    );
  }

  Widget _buildSidebar(LayoutSettings layoutSettings) {
    return MouseRegion(
      cursor: _isResizingSidebar
          ? SystemMouseCursors.resizeColumn
          : MouseCursor.defer,
      child: SizedBox(
        width: layoutSettings.sidebarWidth.clamp(
          AppConstants.sidebarMinWidth,
          AppConstants.sidebarMaxWidth,
        ),
        child: widget.sidebar,
      ),
    );
  }

  Widget _buildNoteList(LayoutSettings layoutSettings) {
    return MouseRegion(
      cursor: _isResizingNoteList
          ? SystemMouseCursors.resizeColumn
          : MouseCursor.defer,
      child: SizedBox(
        width: layoutSettings.noteListWidth.clamp(
          AppConstants.noteListPanelMinWidth,
          AppConstants.noteListPanelMaxWidth,
        ),
        child: widget.noteList,
      ),
    );
  }

  Widget _buildDivider(
    VoidCallback onStart,
    VoidCallback onEnd,
    Function(DragUpdateDetails) onUpdate,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onHorizontalDragStart: (_) => onStart(),
        onHorizontalDragEnd: (_) => onEnd(),
        onHorizontalDragUpdate: onUpdate,
        child: Container(
          width: 4,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 1,
              decoration: BoxDecoration(color: Theme.of(context).dividerColor),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSidebarResize(
    LayoutSettings layoutSettings,
    DragUpdateDetails details,
  ) {
    final delta = details.primaryDelta ?? 0.0;
    final newWidth = layoutSettings.sidebarWidth + delta;
    final clampedWidth = newWidth.clamp(
      AppConstants.sidebarMinWidth,
      AppConstants.sidebarMaxWidth,
    );
    ref
        .read(layoutSettingsNotifierProvider.notifier)
        .setSidebarWidth(clampedWidth.toDouble());
  }

  void _handleNoteListResize(
    LayoutSettings layoutSettings,
    DragUpdateDetails details,
  ) {
    final delta = details.primaryDelta ?? 0.0;
    final newWidth = layoutSettings.noteListWidth + delta;
    final clampedWidth = newWidth.clamp(
      AppConstants.noteListPanelMinWidth,
      AppConstants.noteListPanelMaxWidth,
    );
    ref
        .read(layoutSettingsNotifierProvider.notifier)
        .setNoteListWidth(clampedWidth.toDouble());
  }
}

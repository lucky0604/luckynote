import 'package:flutter/material.dart';

import 'package:luckynote/domains/navigation/data/models/navigation_state.dart';
import 'file_tree/file_tree_view.dart';
import 'note_list/note_list_view.dart';
import 'note_list/tasks_view.dart';

class NavigationContent extends StatelessWidget {
  const NavigationContent({
    super.key,
    required this.navState,
  });

  final NavigationState navState;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _buildContentView(navState),
    );
  }

  Widget _buildContentView(NavigationState navState) {
    if (navState.isTasksView) {
      return const TasksView(key: ValueKey('tasks'));
    }
    if (navState.isListView) {
      return const NoteListView(key: ValueKey('list'));
    }
    return const FileTreeView(key: ValueKey('tree'));
  }
}

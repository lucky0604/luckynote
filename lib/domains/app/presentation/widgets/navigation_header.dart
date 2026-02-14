import 'package:flutter/material.dart';

import 'package:luckynote/domains/navigation/data/models/navigation_state.dart';
import 'note_list/note_list_header.dart';

class NavigationHeader extends StatelessWidget {
  const NavigationHeader({
    super.key,
    required this.navState,
  });

  final NavigationState navState;

  @override
  Widget build(BuildContext context) {
    if (!navState.isListView && !navState.isTasksView) {
      return const SizedBox.shrink();
    }

    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NoteListHeader(),
        SizedBox(height: 8),
      ],
    );
  }
}

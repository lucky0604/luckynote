import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';
import 'package:luckynote/domains/notes/presentation/providers/file_tree_provider.dart';
import 'package:luckynote/domains/notes/presentation/providers/notes_provider.dart';

/// Action handler for creating a new note in a folder.
class CreateNoteAction {
  /// Create a note in the specified folder path.
  static Future<void> execute(
    BuildContext context,
    WidgetRef ref,
    String folderPath,
  ) async {
    final note = await ref.read(notesProvider.notifier).createNote(
      folderPath: folderPath,
    );
    if (note != null && context.mounted) {
      ref.read(editorProvider.notifier).openNote(note);
      // Refresh file tree
      ref.read(fileTreeProvider.notifier).loadTree();
    }
  }
}

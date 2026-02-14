import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';
import 'note_list_item.dart';

class NoteListContent extends ConsumerWidget {
  const NoteListContent({
    super.key,
    required this.notes,
    required this.currentNoteId,
  });

  final List<dynamic> notes;
  final int? currentNoteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: NoteListItem(
            note: note,
            isSelected: note.id == currentNoteId,
            onTap: () => _openNote(ref, note),
          ),
        );
      },
    );
  }

  void _openNote(WidgetRef ref, dynamic note) {
    ref.read(editorProvider.notifier).openNote(note);
  }
}

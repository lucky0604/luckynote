import 'package:super_editor/super_editor.dart';

import '../../../../database/database.dart';

/// Editor view modes.
enum EditorViewMode {
  /// Source mode: displays raw Markdown
  source,

  /// Preview mode: WikiLinks rendered as clickable links
  preview,
}

/// Editor state.
class EditorState {
  const EditorState({
    this.currentNote,
    this.document,
    this.rawMarkdown = '',
    this.isDirty = false,
    this.isSaving = false,
    this.error,
    this.viewMode = EditorViewMode.preview,
    this.scrollRatio = 0.0,
  });

  /// Currently open note
  final Note? currentNote;

  /// Super Editor document
  final MutableDocument? document;

  /// Raw Markdown text in source mode
  final String rawMarkdown;

  /// Whether there are unsaved changes
  final bool isDirty;

  /// Whether currently saving
  final bool isSaving;

  /// Error message
  final String? error;

  /// Current view mode
  final EditorViewMode viewMode;

  /// Scroll position ratio (0.0 ~ 1.0) for mode switching sync
  final double scrollRatio;

  EditorState copyWith({
    Note? currentNote,
    MutableDocument? document,
    String? rawMarkdown,
    bool? isDirty,
    bool? isSaving,
    String? error,
    EditorViewMode? viewMode,
    double? scrollRatio,
    bool clearNote = false,
  }) {
    return EditorState(
      currentNote: clearNote ? null : (currentNote ?? this.currentNote),
      document: clearNote ? null : (document ?? this.document),
      rawMarkdown: rawMarkdown ?? this.rawMarkdown,
      isDirty: isDirty ?? this.isDirty,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      viewMode: viewMode ?? this.viewMode,
      scrollRatio: scrollRatio ?? this.scrollRatio,
    );
  }
}

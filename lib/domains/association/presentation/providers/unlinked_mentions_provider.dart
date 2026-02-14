import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/debouncer.dart';
import '../../../../core/utils/file_utils.dart';
import '../../data/models/mention_candidate.dart';
import '../../../shared_infra/providers/database_provider.dart';
import '../../../editor/presentation/providers/editor_provider.dart';
import '../../../editor/presentation/providers/editor_state.dart';

/// Unlinked Mentions State
class UnlinkedMentionsState {
  const UnlinkedMentionsState({
    this.mentions = const [],
    this.isLoading = false,
    this.error,
  });

  /// List of detected unlinked mentions
  final List<MentionCandidate> mentions;

  /// Whether a scan is in progress
  final bool isLoading;

  /// Error message if scan failed
  final String? error;

  UnlinkedMentionsState copyWith({
    List<MentionCandidate>? mentions,
    bool? isLoading,
    String? error,
  }) {
    return UnlinkedMentionsState(
      mentions: mentions ?? this.mentions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UnlinkedMentionsState &&
        other.mentions.length == mentions.length &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(mentions.length, isLoading, error);
  }

  @override
  String toString() {
    return 'UnlinkedMentionsState(mentions: ${mentions.length}, isLoading: $isLoading, error: $error)';
  }
}

/// Unlinked Mentions Notifier - scans for unlinked note title mentions
class UnlinkedMentionsNotifier extends StateNotifier<UnlinkedMentionsState> {
  UnlinkedMentionsNotifier(this._ref) : super(const UnlinkedMentionsState()) {
    _scanDebouncer = Debouncer(milliseconds: 800);
    _listenToEditorChanges();
  }

  final Ref _ref;
  late final Debouncer _scanDebouncer;

  /// Last scanned content for change detection (direct string comparison)
  String? _lastScannedContent;

  /// Last scanned note title
  String? _lastScannedTitle;

  /// Listen to editor content changes and trigger debounced scans
  void _listenToEditorChanges() {
    _ref.listen<EditorState>(editorProvider, (previous, next) {
      final note = next.currentNote;
      if (note == null) {
        // Clear mentions when no note is open
        state = const UnlinkedMentionsState();
        _lastScannedContent = null;
        _lastScannedTitle = null;
        return;
      }

      // Skip if already scanning
      if (state.isLoading) return;

      // Get current content based on view mode
      final content = _getCurrentContent(next);
      if (content == null) return;

      // Extract title from current content (not note.title which may be stale)
      final currentTitle = FileUtils.extractTitleFromContent(content);

      // Only rescan if content or title actually changed
      final contentChanged = _lastScannedContent != content;
      final titleChanged = _lastScannedTitle != currentTitle;

      if (contentChanged || titleChanged) {
        _lastScannedContent = content;
        _lastScannedTitle = currentTitle;
        _scheduleScan(note.filePath, content, currentTitle);
      }
    });
  }

  /// Get current editor content based on view mode
  String? _getCurrentContent(EditorState editorState) {
    if (editorState.viewMode == EditorViewMode.source) {
      return editorState.rawMarkdown;
    }

    final document = editorState.document;
    if (document == null) return null;

    final serializer = _ref.read(markdownSerializerProvider);
    return serializer.serialize(document);
  }

  /// Schedule a debounced scan for unlinked mentions
  void _scheduleScan(String filePath, String content, String? noteTitle) {
    _scanDebouncer.run(() async {
      await scanForMentions(filePath, content, noteTitle);
    });
  }

  /// Scan for unlinked mentions in the given content
  ///
  /// [filePath] Path to the current note
  /// [content] The markdown content to scan
  /// [noteTitle] Title of current note (for self-mention exclusion)
  Future<void> scanForMentions(
    String filePath,
    String content,
    String? noteTitle,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = _ref.read(associationServiceProvider);
      
      print('[UnlinkedMentions] Scanning with currentTitle: "$noteTitle"');
      print('[UnlinkedMentions] Content preview: "${content.length > 100 ? content.substring(0, 100) : content}"');
      
      final mentions = await service.findUnlinkedMentions(
        content: content,
        currentNotePath: filePath,
        currentNoteTitle: noteTitle,
      );

      print('[UnlinkedMentions] Found ${mentions.length} mentions: ${mentions.map((m) => '"${m.targetNoteTitle}"').toList()}');

      state = state.copyWith(mentions: mentions, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        mentions: const [],
        isLoading: false,
        error: '扫描失败: $e',
      );
    }
  }

  /// Manually refresh the mention scan
  Future<void> refresh() async {
    final editorState = _ref.read(editorProvider);
    final note = editorState.currentNote;

    if (note == null) {
      state = const UnlinkedMentionsState();
      return;
    }

    final content = _getCurrentContent(editorState);
    if (content == null) return;

    // Extract title from current content
    final currentTitle = FileUtils.extractTitleFromContent(content);

    // Force rescan by clearing last scanned values
    _lastScannedContent = null;
    _lastScannedTitle = null;
    await scanForMentions(note.filePath, content, currentTitle);
  }

  @override
  void dispose() {
    _scanDebouncer.dispose();
    super.dispose();
  }
}

/// Unlinked Mentions Provider
final unlinkedMentionsProvider =
    StateNotifierProvider<UnlinkedMentionsNotifier, UnlinkedMentionsState>((ref) {
  return UnlinkedMentionsNotifier(ref);
});

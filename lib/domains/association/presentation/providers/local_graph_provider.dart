import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/graph_node.dart';
import '../../../shared_infra/providers/database_provider.dart';
import '../../../editor/presentation/providers/editor_provider.dart';
import '../../../editor/presentation/providers/editor_state.dart';

/// Local Graph State
class LocalGraphState {
  const LocalGraphState({
    this.graphData,
    this.isLoading = false,
    this.error,
  });

  /// Graph data with nodes and edges
  final GraphData? graphData;

  /// Whether loading is in progress
  final bool isLoading;

  /// Error message if loading failed
  final String? error;

  LocalGraphState copyWith({
    GraphData? graphData,
    bool? isLoading,
    String? error,
  }) {
    return LocalGraphState(
      graphData: graphData ?? this.graphData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LocalGraphState &&
        other.graphData == graphData &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(graphData, isLoading, error);
  }

  @override
  String toString() {
    return 'LocalGraphState(graphData: $graphData, isLoading: $isLoading, error: $error)';
  }
}

/// Local Graph Notifier - loads and caches local graph data
class LocalGraphNotifier extends StateNotifier<LocalGraphState> {
  LocalGraphNotifier(this._ref) : super(const LocalGraphState()) {
    _listenToNoteChanges();
  }

  final Ref _ref;

  /// Cache for loaded graph data per note title
  final Map<String, GraphData> _graphCache = {};

  /// Listen to note changes and load graph data
  void _listenToNoteChanges() {
    _ref.listen<EditorState>(editorProvider, (previous, next) {
      final note = next.currentNote;
      if (note == null) {
        // Clear graph when no note is open
        state = const LocalGraphState();
        return;
      }

      // Check if we need to reload (different note)
      final previousTitle = previous?.currentNote?.title;
      if (previousTitle != note.title) {
        // Check cache first
        if (_graphCache.containsKey(note.title)) {
          state = LocalGraphState(graphData: _graphCache[note.title]);
        } else {
          loadGraph(note.title);
        }
      }
    });
  }

  /// Load graph data for the given note title
  Future<void> loadGraph(String noteTitle) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = _ref.read(associationServiceProvider);
      final graphData = await service.getLocalGraphData(noteTitle);

      // Cache the result
      _graphCache[noteTitle] = graphData;

      state = state.copyWith(graphData: graphData, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        graphData: null,
        isLoading: false,
        error: '加载图谱失败: $e',
      );
    }
  }

  /// Manually refresh the graph data
  Future<void> refresh() async {
    final editorState = _ref.read(editorProvider);
    final note = editorState.currentNote;

    if (note == null) {
      state = const LocalGraphState();
      return;
    }

    // Clear cache for this note and reload
    _graphCache.remove(note.title);
    await loadGraph(note.title);
  }

  /// Clear all cached graph data
  void clearCache() {
    _graphCache.clear();
  }
}

/// Local Graph Provider
final localGraphProvider =
    StateNotifierProvider<LocalGraphNotifier, LocalGraphState>((ref) {
  return LocalGraphNotifier(ref);
});

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/debouncer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../database/database.dart';
import '../../../shared_infra/providers/database_provider.dart';
import 'editor_state.dart';

/// Task index scheduler.
///
/// Manages debounced task indexing for the editor.
class TaskIndexScheduler {
  TaskIndexScheduler({
    required this.ref,
    required this.onStateUpdate,
  }) : _debouncer = Debouncer(milliseconds: AppConstants.autoSaveDelayMs);

  final Ref ref;
  final void Function(EditorState) onStateUpdate;
  final Debouncer _debouncer;
  String? _lastTaskSignature;

  /// Schedule task reindexing from editor content.
  void scheduleReindex({
    required Note note,
    required String content,
  }) {
    final signature = _buildTaskSignature(content);
    if (_lastTaskSignature == signature) return;

    _debouncer.run(() async {
      try {
        final docService = ref.read(documentServiceProvider);
        final noteDoc = await docService.getOrCreateDocument(
          note.filePath,
          note.title,
          File(note.filePath).lastModifiedSync(),
        );

        final taskRepo = ref.read(taskRepositoryProvider);
        await taskRepo.reindexTasks(noteDoc.id, content);
        _lastTaskSignature = signature;
      } catch (e) {
        // Task index failure shouldn't block editing - just report error
        onStateUpdate(EditorState(error: '任务索引更新失败: $e'));
      }
    });
  }

  /// Update the last task signature.
  void updateSignature(String content) {
    _lastTaskSignature = _buildTaskSignature(content);
  }

  /// Clear the last task signature.
  void clearSignature() {
    _lastTaskSignature = null;
  }

  /// Build task signature for change detection.
  String _buildTaskSignature(String content) {
    final taskRegex = RegExp(
      r'^(\s*)[-*+]\s\[([ xX])\]\s+(.*)$',
      multiLine: true,
    );
    final matches = taskRegex.allMatches(content);
    if (matches.isEmpty) return '';

    final buffer = StringBuffer();
    for (final match in matches) {
      buffer.writeln(match.group(0));
    }
    return buffer.toString().trimRight();
  }

  /// Dispose of the debouncer.
  void dispose() {
    _debouncer.dispose();
  }
}

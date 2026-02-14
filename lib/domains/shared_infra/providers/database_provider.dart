import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../database/database.dart';
import '../../search/data/repositories/global_search_repository.dart';
import '../../notes/data/repositories/note_repository.dart';
import '../../rag/data/repositories/rag_repository.dart';
import '../../notes/data/repositories/tag_repository.dart';
import '../../association/data/repositories/wikilink_repository.dart';
import '../../association/data/services/association_service.dart';
import '../../chat/data/services/context_injection_service.dart';
import '../../rag/data/services/document_service.dart';
import '../../notes/data/services/file_watcher_service.dart';
import '../../notes/data/services/folder_manager_service.dart';
import '../../notes/data/indexing/indexer_service.dart';
import '../../rag/data/services/rag_service.dart';
import '../../tasks/data/repositories/task_repository.dart';
import '../../tasks/data/services/task_action_service.dart';
import '../../notes/presentation/providers/file_tree_provider.dart';

/// 数据库 Provider - 单例，在应用生命周期内保持活动
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();

  // 确保数据库在 provider 被销毁时正确关闭
  ref.onDispose(() {
    db.close();
  });

  return db;
});

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return NoteRepository(db);
});

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TagRepository(db);
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskRepository(db);
});

final taskActionServiceProvider = Provider<TaskActionService>((ref) {
  return TaskActionService(
    taskRepository: ref.watch(taskRepositoryProvider),
  );
});

final indexerServiceProvider = Provider<IndexerService>((ref) {
  final noteRepo = ref.watch(noteRepositoryProvider);
  final tagRepo = ref.watch(tagRepositoryProvider);
  final taskRepo = ref.watch(taskRepositoryProvider);
  final db = ref.watch(databaseProvider);
  final documentService = ref.watch(documentServiceProvider);
  return IndexerService(
    noteRepository: noteRepo,
    tagRepository: tagRepo,
    taskRepository: taskRepo,
    database: db,
    documentService: documentService,
  );
});

final fileWatcherServiceProvider = Provider<FileWatcherService>((ref) {
  final indexer = ref.watch(indexerServiceProvider);
  final watcher = FileWatcherService(indexerService: indexer);

  ref.onDispose(() {
    watcher.dispose();
  });

  return watcher;
});

// RAG 相关 Providers

final documentServiceProvider = Provider<DocumentService>((ref) {
  final db = ref.watch(databaseProvider);
  return DocumentService(db);
});

final ragRepositoryProvider = Provider<RAGRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return RAGRepository(db);
});

final ragServiceProvider = Provider<RAGService>((ref) {
  final documentService = ref.watch(documentServiceProvider);
  return RAGService(documentService: documentService);
});

final contextInjectionServiceProvider = Provider<ContextInjectionService>((ref) {
  final documentService = ref.watch(documentServiceProvider);
  return ContextInjectionService(documentService: documentService);
});

// 全局搜索和双向链接相关 Providers

final globalSearchRepositoryProvider = Provider<GlobalSearchRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return GlobalSearchRepository(db);
});

final wikiLinkRepositoryProvider = Provider<WikiLinkRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WikiLinkRepository(db);
});

/// Folder manager service provider
final folderManagerServiceProvider = Provider<FolderManagerService>((ref) {
  return FolderManagerService(
    indexerService: ref.watch(indexerServiceProvider),
    noteRepository: ref.watch(noteRepositoryProvider),
  );
});

/// Selected folder provider (derived from file tree)
/// 如果选中的是文件，则返回其父目录
final selectedFolderProvider = Provider<String?>((ref) {
  final treeState = ref.watch(fileTreeProvider);
  final selectedPath = treeState.value?.selectedPath;

  if (selectedPath == null) return null;

  // 检查选中的是文件还是文件夹
  // 通过扩展名判断（markdown 文件）
  final ext = p.extension(selectedPath).toLowerCase();
  if (ext == '.md' || ext == '.markdown' || ext == '.mdown') {
    // 是文件，返回父目录
    return p.dirname(selectedPath);
  }

  // 是文件夹，直接返回
  return selectedPath;
});

/// Association Service Provider
/// Provides the AssociationService instance for unlinked mention detection
/// and local graph data generation
final associationServiceProvider = Provider<AssociationService>((ref) {
  final db = ref.watch(databaseProvider);
  final documentService = ref.watch(documentServiceProvider);
  return AssociationService(db, documentService);
});

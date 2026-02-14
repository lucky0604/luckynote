/// Notes domain barrel file
/// Exports all public APIs from the notes domain
/// (Core note CRUD operations, file tree, note list)

// Data layer
export 'data/models/file_node.dart';
export 'data/repositories/note_repository.dart';
export 'data/repositories/tag_repository.dart';
export 'data/services/file_system_service.dart';
export 'data/services/file_watcher_service.dart';
export 'data/services/folder_manager_service.dart';
export 'data/services/folder_storage_service.dart';
export 'data/services/image_handler.dart';
export 'data/indexing/indexer_service.dart';
export 'data/indexing/index_result.dart';

// Presentation layer
export 'presentation/providers/file_tree_provider.dart';
export 'presentation/providers/file_watcher_provider.dart';
export 'presentation/providers/image_provider.dart';
export 'presentation/providers/notes_provider.dart';
export 'presentation/providers/tags_provider.dart';
export 'presentation/providers/vault_provider.dart';

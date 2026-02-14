import 'dart:async';
import 'dart:io';

import 'package:watcher/watcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/file_utils.dart';
import '../indexing/indexer_service.dart';
import '../indexing/index_result.dart';

/// 文件变化事件类型
enum FileChangeType { created, modified, deleted }

/// 文件变化事件
class FileChangeEvent {
  const FileChangeEvent({required this.type, required this.path});

  final FileChangeType type;
  final String path;

  @override
  String toString() => 'FileChangeEvent($type, $path)';
}

/// 文件监听服务
/// 监听笔记目录的文件变化，并同步到数据库
class FileWatcherService {
  FileWatcherService({required this.indexerService});

  final IndexerService indexerService;

  DirectoryWatcher? _watcher;
  StreamSubscription<WatchEvent>? _subscription;
  Timer? _debounceTimer;

  /// 待处理的事件队列（用于防抖）
  final _pendingEvents = <String, FileChangeType>{};

  /// 文件变化事件流控制器
  final _eventController = StreamController<FileChangeEvent>.broadcast();

  /// 文件变化事件流
  Stream<FileChangeEvent> get events => _eventController.stream;

  /// 是否正在监听
  bool get isWatching => _subscription != null;

  /// 开始监听目录
  /// [onProgress] 可选的进度回调 (current, total)
  Future<IndexResult> startWatching(
    String vaultPath, {
    void Function(int current, int total)? onProgress,
  }) async {
    // 如果已在监听，先停止
    await stopWatching();

    final directory = Directory(vaultPath);
    if (!await directory.exists()) {
      return IndexResult.empty();
    }

    _watcher = DirectoryWatcher(vaultPath);
    _subscription = _watcher!.events.listen(_onWatchEvent);

    // 启动时进行全量扫描
    final result = await indexerService.fullScan(
      vaultPath,
      onProgress: onProgress,
    );
    return result;
  }

  /// 停止监听
  Future<void> stopWatching() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;

    await _subscription?.cancel();
    _subscription = null;
    _watcher = null;

    _pendingEvents.clear();
  }

  /// 转换事件类型
  FileChangeType? _convertChangeType(ChangeType type) {
    if (type == ChangeType.ADD) return FileChangeType.created;
    if (type == ChangeType.MODIFY) return FileChangeType.modified;
    if (type == ChangeType.REMOVE) return FileChangeType.deleted;
    return null;
  }

  /// 处理监听事件
  void _onWatchEvent(WatchEvent event) {
    // 只处理 markdown 文件
    if (!FileUtils.isMarkdownFile(event.path)) {
      return;
    }

    // 忽略隐藏文件和临时文件
    final fileName = event.path.split(Platform.pathSeparator).last;
    if (fileName.startsWith('.') || fileName.endsWith('.tmp')) {
      return;
    }

    // 转换事件类型
    final changeType = _convertChangeType(event.type);
    if (changeType == null) return;

    // 添加到待处理队列
    _pendingEvents[event.path] = changeType;

    // 防抖处理
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: AppConstants.fileWatcherDebounceMs),
      _processPendingEvents,
    );
  }

  /// 处理待处理的事件
  Future<void> _processPendingEvents() async {
    if (_pendingEvents.isEmpty) return;

    // 复制并清空队列
    final events = Map<String, FileChangeType>.from(_pendingEvents);
    _pendingEvents.clear();

    for (final entry in events.entries) {
      final path = entry.key;
      final type = entry.value;

      await _processEvent(path, type);

      // 发送事件通知
      _eventController.add(FileChangeEvent(type: type, path: path));
    }
  }

  /// 处理单个事件
  Future<void> _processEvent(String path, FileChangeType type) async {
    switch (type) {
      case FileChangeType.created:
      case FileChangeType.modified:
        await indexerService.indexFile(path);
      case FileChangeType.deleted:
        indexerService.removeIndex(path);
    }
  }

  /// 手动触发重新扫描
  /// [forceReindex] 如果为 true，则强制重新索引所有文件（修复 FTS5 索引）
  /// [onProgress] 可选的进度回调 (current, total)
  Future<IndexResult> rescan(
    String vaultPath, {
    bool forceReindex = false,
    void Function(int current, int total)? onProgress,
  }) async {
    return indexerService.fullScan(
      vaultPath,
      forceReindex: forceReindex,
      onProgress: onProgress,
    );
  }

  /// 释放资源
  void dispose() {
    stopWatching();
    _eventController.close();
  }
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/file_watcher_service.dart';
import '../../../shared_infra/providers/database_provider.dart';
import 'index_progress_provider.dart';
import 'vault_provider.dart';

/// 文件监听状态
class FileWatcherState {
  const FileWatcherState({this.isWatching = false, this.lastEvent, this.error});

  /// 是否正在监听
  final bool isWatching;

  /// 最后一个事件
  final FileChangeEvent? lastEvent;

  /// 错误信息
  final String? error;

  FileWatcherState copyWith({
    bool? isWatching,
    FileChangeEvent? lastEvent,
    String? error,
  }) {
    return FileWatcherState(
      isWatching: isWatching ?? this.isWatching,
      lastEvent: lastEvent ?? this.lastEvent,
      error: error,
    );
  }
}

/// 文件监听状态管理器
class FileWatcherNotifier extends StateNotifier<FileWatcherState> {
  FileWatcherNotifier(this._ref) : super(const FileWatcherState()) {
    _init();
  }

  final Ref _ref;
  StreamSubscription<FileChangeEvent>? _eventSubscription;

  void _init() {
    // 监听 vault 路径变化
    _ref.listen(vaultProvider, (previous, next) {
      next.whenData((path) {
        if (path != null) {
          startWatching(path);
        } else {
          stopWatching();
        }
      });
    });

    // 如果已有 vault 路径，立即开始监听
    final vaultPath = _ref
        .read(vaultProvider)
        .maybeWhen(data: (path) => path, orElse: () => null);

    if (vaultPath != null) {
      startWatching(vaultPath);
    }
  }

  /// 开始监听文件变化
  Future<void> startWatching(String vaultPath) async {
    try {
      final watcher = _ref.read(fileWatcherServiceProvider);
      final progressNotifier = _ref.read(indexProgressProvider.notifier);

      // 取消之前的事件订阅
      await _eventSubscription?.cancel();

      // 订阅文件变化事件
      _eventSubscription = watcher.events.listen((event) {
        state = state.copyWith(lastEvent: event);
      });

      // 先设置状态为监听中
      state = state.copyWith(isWatching: true, error: null, lastEvent: null);

      // 启动时进行全量扫描（带进度回调）
      progressNotifier.startIndexing(0);
      await watcher.startWatching(
        vaultPath,
        onProgress: (current, total) {
          if (current == 1) {
            progressNotifier.startIndexing(total);
          }
          progressNotifier.updateProgress(current);
        },
      );
      progressNotifier.completeIndexing();

      // 扫描完成后，触发一个虚拟刷新事件
      state = state.copyWith(
        lastEvent: FileChangeEvent(
          type: FileChangeType.modified,
          path: vaultPath,
        ),
      );
    } catch (e) {
      _ref.read(indexProgressProvider.notifier).completeIndexing();
      state = state.copyWith(isWatching: false, error: '启动文件监听失败: $e');
    }
  }

  /// 停止监听
  Future<void> stopWatching() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;

    try {
      final watcher = _ref.read(fileWatcherServiceProvider);
      await watcher.stopWatching();
      state = state.copyWith(isWatching: false);
    } catch (e) {
      state = state.copyWith(error: '停止文件监听失败: $e');
    }
  }

  /// 手动触发重新扫描
  /// [forceReindex] 如果为 true，则强制重建所有笔记的索引（用于修复搜索问题）
  Future<void> rescan({bool forceReindex = true}) async {
    final vaultPath = _ref
        .read(vaultProvider)
        .maybeWhen(data: (path) => path, orElse: () => null);

    if (vaultPath == null) return;

    try {
      final watcher = _ref.read(fileWatcherServiceProvider);
      // 默认强制重建索引，确保 FTS5 索引正确
      final result = await watcher.rescan(vaultPath, forceReindex: forceReindex);

      // 触发刷新事件
      state = state.copyWith(
        lastEvent: FileChangeEvent(
          type: FileChangeType.modified,
          path: vaultPath,
        ),
      );

      print('[FileWatcherNotifier] 重新扫描完成: ${result.added} 新增, ${result.updated} 更新, ${result.deleted} 删除');
    } catch (e) {
      state = state.copyWith(error: '重新扫描失败: $e');
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}

/// 文件监听 Provider
final fileWatcherProvider =
    StateNotifierProvider<FileWatcherNotifier, FileWatcherState>((ref) {
      return FileWatcherNotifier(ref);
    });

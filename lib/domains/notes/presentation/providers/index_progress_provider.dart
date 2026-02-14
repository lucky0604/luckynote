import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/index_progress.dart';

/// 索引进度状态管理器
class IndexProgressNotifier extends StateNotifier<IndexProgress> {
  IndexProgressNotifier() : super(const IndexProgress());

  /// 开始索引
  void startIndexing(int total) {
    state = IndexProgress(
      current: 0,
      total: total,
      isIndexing: true,
    );
  }

  /// 更新进度
  void updateProgress(int current) {
    state = state.copyWith(current: current);
  }

  /// 完成索引
  void completeIndexing() {
    state = state.copyWith(isIndexing: false);
  }

  /// 重置状态
  void reset() {
    state = const IndexProgress();
  }
}

/// 索引进度 Provider
final indexProgressProvider =
    StateNotifierProvider<IndexProgressNotifier, IndexProgress>(
  (ref) => IndexProgressNotifier(),
);

/// 是否正在索引 Provider
final isIndexingProvider = Provider<bool>((ref) {
  return ref.watch(indexProgressProvider).isIndexing;
});

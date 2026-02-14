import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../data/repositories/wikilink_repository.dart';
import '../../../shared_infra/providers/database_provider.dart';
import '../../../editor/presentation/providers/editor_provider.dart';

/// 反向链接状态
class BacklinksState {
  const BacklinksState({
    this.backlinks = const [],
    this.isLoading = false,
    this.error,
  });

  final List<BacklinkResult> backlinks;
  final bool isLoading;
  final String? error;

  BacklinksState copyWith({
    List<BacklinkResult>? backlinks,
    bool? isLoading,
    String? error,
  }) {
    return BacklinksState(
      backlinks: backlinks ?? this.backlinks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 反向链接 Notifier
class BacklinksNotifier extends StateNotifier<BacklinksState> {
  BacklinksNotifier(this._ref) : super(const BacklinksState());

  final Ref _ref;

  WikiLinkRepository get _repo => _ref.read(wikiLinkRepositoryProvider);

  /// 加载反向链接
  Future<void> loadBacklinks(String noteTitle) async {
    if (noteTitle.isEmpty) {
      state = const BacklinksState();
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final backlinks = await _repo.getBacklinks(noteTitle);
      state = state.copyWith(backlinks: backlinks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 清空反向链接
  void clear() {
    state = const BacklinksState();
  }
}

/// 反向链接 Provider
/// 自动监听当前笔记变化并加载反向链接
final backlinksProvider =
    StateNotifierProvider<BacklinksNotifier, BacklinksState>((ref) {
  final notifier = BacklinksNotifier(ref);

  // 监听当前笔记变化，自动加载反向链接
  ref.listen(currentNoteProvider, (previous, next) {
    if (next != null) {
      notifier.loadBacklinks(next.title);
    } else {
      notifier.clear();
    }
  });

  return notifier;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/global_search_repository.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../shared_infra/providers/database_provider.dart';

/// 全局搜索状态
class GlobalSearchState {
  const GlobalSearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
    this.error,
  });

  final String query;
  final List<UnifiedSearchResult> results;
  final bool isSearching;
  final String? error;

  GlobalSearchState copyWith({
    String? query,
    List<UnifiedSearchResult>? results,
    bool? isSearching,
    String? error,
  }) {
    return GlobalSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      error: error,
    );
  }
}

/// 全局搜索 Notifier
class GlobalSearchNotifier extends StateNotifier<GlobalSearchState> {
  GlobalSearchNotifier(this._ref) : super(const GlobalSearchState()) {
    _debouncer = Debouncer(milliseconds: 300);
  }

  final Ref _ref;
  late final Debouncer _debouncer;

  GlobalSearchRepository get _repo => _ref.read(globalSearchRepositoryProvider);

  /// 执行搜索 (带有 300ms 防抖)
  void search(String query) {
    if (query.trim().isEmpty) {
      state = state.copyWith(query: query, results: []);
      return;
    }

    state = state.copyWith(query: query, isSearching: true);

    _debouncer.run(() async {
      try {
        print('[GlobalSearch] Starting search for: "$query"');
        final results = await _repo.search(query);
        print('[GlobalSearch] Found ${results.length} results');
        for (final r in results) {
          print('[GlobalSearch] - ${r.title} (${r.type})');
        }
        state = state.copyWith(results: results, isSearching: false);
      } catch (e, st) {
        print('[GlobalSearch] Error: $e');
        print('[GlobalSearch] StackTrace: $st');
        state = state.copyWith(isSearching: false, error: e.toString());
      }
    });
  }

  /// 清空搜索状态
  void clear() {
    _debouncer.cancel();
    state = const GlobalSearchState();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}

/// 全局搜索 Provider
final globalSearchProvider =
    StateNotifierProvider<GlobalSearchNotifier, GlobalSearchState>((ref) {
  final notifier = GlobalSearchNotifier(ref);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

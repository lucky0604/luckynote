import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 搜索历史记录 Provider
final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier();
});

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super([]) {
    _loadHistory();
  }

  static const String _key = 'search_history';
  static const int _maxHistory = 10;

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_key) ?? [];
    state = history;
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state);
  }

  /// 添加搜索历史
  void add(String query) {
    if (query.trim().isEmpty) return;

    // 移除已存在的相同项
    final newHistory = state.where((item) => item != query).toList();

    // 添加到开头
    newHistory.insert(0, query);

    // 限制数量
    if (newHistory.length > _maxHistory) {
      newHistory.removeRange(_maxHistory, newHistory.length);
    }

    state = newHistory;
    _saveHistory();
  }

  /// 移除单个历史记录
  void remove(String query) {
    final newHistory = state.where((item) => item != query).toList();
    state = newHistory;
    _saveHistory();
  }

  /// 清空历史记录
  void clear() {
    state = [];
    _saveHistory();
  }
}

/// 快速搜索建议 Provider
final searchSuggestionsProvider = Provider<List<String>>((ref) {
  final history = ref.watch(searchHistoryProvider);
  final query = ref.watch(searchHistoryQueryProvider).toLowerCase();

  if (query.isEmpty) {
    return history.take(5).toList();
  }

  return history.where((item) => item.toLowerCase().contains(query)).take(5).toList();
});

/// 当前搜索框输入 Provider
final searchHistoryQueryProvider = StateProvider<String>((ref) => '');
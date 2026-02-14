import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/wikilink_repository.dart';
import '../../../shared_infra/providers/database_provider.dart';

/// WikiLink 自动补全状态
class WikiLinkAutocompleteState {
  const WikiLinkAutocompleteState({
    this.isVisible = false,
    this.query = '',
    this.suggestions = const [],
    this.selectedIndex = 0,
    this.triggerPosition,
  });

  final bool isVisible;
  final String query;
  final List<String> suggestions;
  final int selectedIndex;
  final Offset? triggerPosition;

  WikiLinkAutocompleteState copyWith({
    bool? isVisible,
    String? query,
    List<String>? suggestions,
    int? selectedIndex,
    Offset? triggerPosition,
  }) {
    return WikiLinkAutocompleteState(
      isVisible: isVisible ?? this.isVisible,
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      triggerPosition: triggerPosition ?? this.triggerPosition,
    );
  }
}

/// WikiLink 自动补全 Notifier
class WikiLinkAutocompleteNotifier extends StateNotifier<WikiLinkAutocompleteState> {
  WikiLinkAutocompleteNotifier(this._ref) : super(const WikiLinkAutocompleteState()) {
    _allTitles = [];
  }

  final Ref _ref;
  late List<String> _allTitles;

  WikiLinkRepository get _repo => _ref.read(wikiLinkRepositoryProvider);

  /// 初始化 - 加载所有笔记标题
  Future<void> init() async {
    _allTitles = await _repo.getAllTitles();
  }

  /// 触发自动补全
  /// [query] 用户输入的查询文本（[[ 后面的内容）
  /// [position] 触发位置，用于显示 Overlay
  Future<void> trigger(String query, Offset position) async {
    if (_allTitles.isEmpty) {
      await init();
    }

    // 过滤匹配的标题
    final filtered = _filterTitles(query);

    state = state.copyWith(
      isVisible: true,
      query: query,
      suggestions: filtered,
      selectedIndex: 0,
      triggerPosition: position,
    );
  }

  /// 过滤标题列表
  List<String> _filterTitles(String query) {
    if (query.isEmpty) {
      return _allTitles.take(10).toList();
    }

    final lowerQuery = query.toLowerCase();
    return _allTitles
        .where((title) => title.toLowerCase().contains(lowerQuery))
        .take(10)
        .toList();
  }

  /// 选择上一个建议
  void selectPrevious() {
    if (!state.isVisible || state.suggestions.isEmpty) return;

    final newIndex = (state.selectedIndex - 1 + state.suggestions.length) %
        state.suggestions.length;
    state = state.copyWith(selectedIndex: newIndex);
  }

  /// 选择下一个建议
  void selectNext() {
    if (!state.isVisible || state.suggestions.isEmpty) return;

    final newIndex = (state.selectedIndex + 1) % state.suggestions.length;
    state = state.copyWith(selectedIndex: newIndex);
  }

  /// 确认选择当前选中的建议
  String? confirmSelection() {
    if (!state.isVisible || state.suggestions.isEmpty) return null;

    final selected = state.suggestions[state.selectedIndex];
    hide();
    return selected;
  }

  /// 取消并隐藏自动补全
  void hide() {
    state = const WikiLinkAutocompleteState();
  }

  /// 刷新标题列表
  Future<void> refreshTitles() async {
    _allTitles = await _repo.getAllTitles();
  }
}

/// WikiLink 自动补全 Provider
final wikiLinkAutocompleteProvider =
    StateNotifierProvider<WikiLinkAutocompleteNotifier, WikiLinkAutocompleteState>(
  (ref) {
    final notifier = WikiLinkAutocompleteNotifier(ref);
    // 自动初始化
    notifier.init();
    return notifier;
  },
);

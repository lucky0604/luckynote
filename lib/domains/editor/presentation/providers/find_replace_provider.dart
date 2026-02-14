import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/find_match.dart';
import '../../domain/usecases/find_in_document_usecase.dart';

/// 查找替换状态
class FindReplaceState {
  const FindReplaceState({
    this.isOpen = false,
    this.searchTerm = '',
    this.replaceTerm = '',
    this.matches = const [],
    this.currentIndex = -1,
    this.caseSensitive = false,
  });

  final bool isOpen;
  final String searchTerm;
  final String replaceTerm;
  final List<FindMatch> matches;
  final int currentIndex;
  final bool caseSensitive;

  FindMatch? get currentMatch =>
      currentIndex >= 0 && currentIndex < matches.length
          ? matches[currentIndex]
          : null;

  bool get hasMatches => matches.isNotEmpty;

  String get countText {
    if (searchTerm.isEmpty) return '';
    if (matches.isEmpty) return '无结果';
    return '${currentIndex + 1}/${matches.length}';
  }

  FindReplaceState copyWith({
    bool? isOpen,
    String? searchTerm,
    String? replaceTerm,
    List<FindMatch>? matches,
    int? currentIndex,
    bool? caseSensitive,
  }) {
    return FindReplaceState(
      isOpen: isOpen ?? this.isOpen,
      searchTerm: searchTerm ?? this.searchTerm,
      replaceTerm: replaceTerm ?? this.replaceTerm,
      matches: matches ?? this.matches,
      currentIndex: currentIndex ?? this.currentIndex,
      caseSensitive: caseSensitive ?? this.caseSensitive,
    );
  }
}

/// 替换回调类型
typedef ReplaceCallback = void Function(String newContent);

/// 查找替换状态管理器
class FindReplaceNotifier extends StateNotifier<FindReplaceState> {
  FindReplaceNotifier() : super(const FindReplaceState());

  final _useCase = const FindInDocumentUseCase();
  String _currentText = '';
  ReplaceCallback? _onReplace;

  /// 设置当前文本和替换回调
  void setContext(String text, {ReplaceCallback? onReplace}) {
    _currentText = text;
    _onReplace = onReplace;
    if (state.searchTerm.isNotEmpty) {
      _performSearch();
    }
  }

  void open() => state = state.copyWith(isOpen: true);

  void close() => state = const FindReplaceState();

  void toggle() => state.isOpen ? close() : open();

  void search(String term) {
    state = state.copyWith(searchTerm: term);
    _performSearch();
  }

  void setReplaceTerm(String term) {
    state = state.copyWith(replaceTerm: term);
  }

  void toggleCaseSensitive() {
    state = state.copyWith(caseSensitive: !state.caseSensitive);
    _performSearch();
  }

  void next() {
    if (state.matches.isEmpty) return;
    final nextIndex = (state.currentIndex + 1) % state.matches.length;
    state = state.copyWith(currentIndex: nextIndex);
  }

  void previous() {
    if (state.matches.isEmpty) return;
    final prevIndex = state.currentIndex <= 0
        ? state.matches.length - 1
        : state.currentIndex - 1;
    state = state.copyWith(currentIndex: prevIndex);
  }

  void replaceCurrent() {
    final match = state.currentMatch;
    if (match == null || _onReplace == null) return;

    final newText = _useCase.replaceMatch(_currentText, match, state.replaceTerm);
    _currentText = newText;
    _onReplace!(newText);
    _performSearch();
  }

  void replaceAll() {
    if (state.matches.isEmpty || _onReplace == null) return;

    final newText = _useCase.replaceAll(
      _currentText,
      state.searchTerm,
      state.replaceTerm,
      caseSensitive: state.caseSensitive,
    );
    _currentText = newText;
    _onReplace!(newText);
    _performSearch();
  }

  void _performSearch() {
    if (_currentText.isEmpty || state.searchTerm.isEmpty) {
      state = state.copyWith(matches: [], currentIndex: -1);
      return;
    }

    final matches = _useCase.execute(
      _currentText,
      state.searchTerm,
      caseSensitive: state.caseSensitive,
    );

    state = state.copyWith(
      matches: matches,
      currentIndex: matches.isEmpty ? -1 : 0,
    );
  }
}

/// 查找替换 Provider
final findReplaceProvider =
    StateNotifierProvider<FindReplaceNotifier, FindReplaceState>(
  (ref) => FindReplaceNotifier(),
);

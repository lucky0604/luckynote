import 'editor_state.dart';

/// 撤销/重做栈的最大容量
const int maxUndoStackSize = 50;

/// 编辑器撤销重做状态
class EditorUndoState {
  const EditorUndoState({
    this.canUndo = false,
    this.canRedo = false,
    this.undoCount = 0,
    this.redoCount = 0,
  });

  final bool canUndo;
  final bool canRedo;
  final int undoCount;
  final int redoCount;
}

/// 撤销栈条目 - 保存编辑器状态的快照
class EditorSnapshot {
  const EditorSnapshot({
    required this.rawMarkdown,
    required this.viewMode,
    required this.scrollRatio,
    required this.timestamp,
  });

  /// Markdown 内容快照
  final String rawMarkdown;

  /// 视图模式快照
  final EditorViewMode viewMode;

  /// 滚动位置快照
  final double scrollRatio;

  /// 时间戳
  final DateTime timestamp;

  /// 检查内容是否有变化
  bool hasContentChanged(String newContent) {
    return rawMarkdown != newContent;
  }
}

/// 编辑器撤销栈管理器
class EditorUndoStack {
  EditorUndoStack();

  final List<EditorSnapshot> _undoStack = [];
  final List<EditorSnapshot> _redoStack = [];

  /// 是否可以撤销
  bool get canUndo => _undoStack.isNotEmpty;

  /// 是否可以重做
  bool get canRedo => _redoStack.isNotEmpty;

  /// 撤销栈中的数量
  int get undoCount => _undoStack.length;

  /// 重做栈中的数量
  int get redoCount => _redoStack.length;

  /// 获取撤销状态
  EditorUndoState get state => EditorUndoState(
        canUndo: canUndo,
        canRedo: canRedo,
        undoCount: undoCount,
        redoCount: redoCount,
      );

  /// 保存当前状态到撤销栈
  /// 返回 true 表示成功保存，false 表示内容没有变化不需要保存
  bool push({
    required String rawMarkdown,
    required EditorViewMode viewMode,
    required double scrollRatio,
  }) {
    // 如果栈不为空且内容相同，不保存
    if (_undoStack.isNotEmpty && _undoStack.last.rawMarkdown == rawMarkdown) {
      return false;
    }

    // 创建新快照
    final snapshot = EditorSnapshot(
      rawMarkdown: rawMarkdown,
      viewMode: viewMode,
      scrollRatio: scrollRatio,
      timestamp: DateTime.now(),
    );

    // 添加到撤销栈
    _undoStack.add(snapshot);

    // 如果超过最大限制，移除最旧的
    while (_undoStack.length > maxUndoStackSize) {
      _undoStack.removeAt(0);
    }

    // 有新操作时，清空重做栈
    _redoStack.clear();

    return true;
  }

  /// 撤销操作
  /// 返回撤销前的状态（用于恢复），null 表示无法撤销
  EditorSnapshot? undo(String currentContent) {
    if (!canUndo) return null;

    // 保存当前状态到重做栈
    final currentSnapshot = EditorSnapshot(
      rawMarkdown: currentContent,
      viewMode: EditorViewMode.preview,
      scrollRatio: 0.0,
      timestamp: DateTime.now(),
    );
    _redoStack.add(currentSnapshot);

    // 弹出撤销栈顶
    return _undoStack.removeLast();
  }

  /// 重做操作
  /// 返回重做前的状态（用于恢复），null 表示无法重做
  EditorSnapshot? redo(String currentContent) {
    if (!canRedo) return null;

    // 保存当前状态到撤销栈
    final currentSnapshot = EditorSnapshot(
      rawMarkdown: currentContent,
      viewMode: EditorViewMode.preview,
      scrollRatio: 0.0,
      timestamp: DateTime.now(),
    );
    _undoStack.add(currentSnapshot);

    // 弹出重做栈顶
    return _redoStack.removeLast();
  }

  /// 清空所有撤销重做历史
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 编辑器键盘快捷键处理
/// 提供统一的快捷键检测和处理逻辑
class EditorKeyboardShortcuts {
  EditorKeyboardShortcuts._();

  /// 检查是否按下了修饰键（Mac 上是 Cmd，其他平台是 Ctrl）
  static bool isModifierPressed(BuildContext context) {
    final isMac = Theme.of(context).platform == TargetPlatform.macOS;
    return isMac
        ? HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.meta)
        : HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.control);
  }

  /// 检查是否按下了 Shift 键
  static bool isShiftPressed(BuildContext context) {
    return HardwareKeyboard.instance.logicalKeysPressed
        .contains(LogicalKeyboardKey.shiftLeft);
  }

  /// 处理键盘事件
  /// 返回 true 表示事件已处理，不需要进一步传播
  static bool handleKeyEvent({
    required BuildContext context,
    required KeyEvent event,
    VoidCallback? onSave,
    VoidCallback? onWikiLinkAutocomplete,
    VoidCallback? onNavigateToWikiLink,
    VoidCallback? onFind,
    VoidCallback? onUndo,
    VoidCallback? onRedo,
    Future<void> Function()? onImagePaste,
  }) {
    if (event is! KeyDownEvent) return false;

    final modifierPressed = isModifierPressed(context);
    final shiftPressed = isShiftPressed(context);

    // Cmd/Ctrl + Z: 撤销
    if (event.logicalKey == LogicalKeyboardKey.keyZ && modifierPressed && !shiftPressed) {
      onUndo?.call();
      return true;
    }

    // Cmd/Ctrl + Shift + Z 或 Cmd/Ctrl + Y: 重做
    if ((event.logicalKey == LogicalKeyboardKey.keyZ && modifierPressed && shiftPressed) ||
        (event.logicalKey == LogicalKeyboardKey.keyY && modifierPressed)) {
      onRedo?.call();
      return true;
    }

    // Cmd/Ctrl + S: 保存
    if (event.logicalKey == LogicalKeyboardKey.keyS && modifierPressed) {
      onSave?.call();
      return true;
    }

    // Cmd/Ctrl + F: 查找
    if (event.logicalKey == LogicalKeyboardKey.keyF && modifierPressed) {
      onFind?.call();
      return true;
    }

    // Cmd/Ctrl + K: WikiLink 自动补全
    if (event.logicalKey == LogicalKeyboardKey.keyK && modifierPressed) {
      onWikiLinkAutocomplete?.call();
      return true;
    }

    // Cmd/Ctrl + Enter: 导航到 WikiLink
    if (event.logicalKey == LogicalKeyboardKey.enter && modifierPressed) {
      onNavigateToWikiLink?.call();
      return true;
    }

    // Cmd/Ctrl + V: 图片粘贴（尝试粘贴剪贴板图片）
    if (event.logicalKey == LogicalKeyboardKey.keyV && modifierPressed) {
      // 异步处理图片粘贴，不阻塞默认的文本粘贴
      onImagePaste?.call();
      // 返回 false 让默认的粘贴行为继续（如果没有图片会粘贴文本）
      return false;
    }

    return false;
  }
}

/// 编辑器键盘监听包装器
/// 封装 KeyboardListener 并提供便捷的快捷键处理
class EditorKeyboardListener extends StatelessWidget {
  const EditorKeyboardListener({
    super.key,
    required this.child,
    this.onSave,
    this.onWikiLinkAutocomplete,
    this.onNavigateToWikiLink,
    this.onFind,
    this.onUndo,
    this.onRedo,
    this.onImagePaste,
  });

  final Widget child;
  final VoidCallback? onSave;
  final VoidCallback? onWikiLinkAutocomplete;
  final VoidCallback? onNavigateToWikiLink;
  final VoidCallback? onFind;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  /// 图片粘贴回调（异步）
  final Future<void> Function()? onImagePaste;

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        EditorKeyboardShortcuts.handleKeyEvent(
          context: context,
          event: event,
          onSave: onSave,
          onWikiLinkAutocomplete: onWikiLinkAutocomplete,
          onNavigateToWikiLink: onNavigateToWikiLink,
          onFind: onFind,
          onUndo: onUndo,
          onRedo: onRedo,
          onImagePaste: onImagePaste,
        );
      },
      child: child,
    );
  }
}

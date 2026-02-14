import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:super_editor/super_editor.dart';

import 'package:luckynote/core/constants/app_constants.dart';
import 'package:luckynote/domains/editor/data/markdown/code_block_node.dart';

/// 代码块组件构建器
/// 匹配 CodeBlockNode 并返回 CodeBlockComponent
class CodeBlockComponentBuilder extends ComponentBuilder {
  CodeBlockComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    if (node is! CodeBlockNode) {
      return null;
    }

    return CodeBlockComponentViewModel(
      nodeId: node.id,
      code: node.code,
      language: node.language,
    );
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! CodeBlockComponentViewModel) {
      return null;
    }

    return CodeBlockComponent(
      key: componentContext.componentKey,
      viewModel: componentViewModel,
    );
  }
}

/// 代码块组件 ViewModel
class CodeBlockComponentViewModel extends SingleColumnLayoutComponentViewModel {
  CodeBlockComponentViewModel({
    required super.nodeId,
    super.createdAt,
    super.maxWidth,
    // 不使用 padding，让组件自己控制边距以实现全宽背景
    super.padding = EdgeInsets.zero,
    super.opacity = 1.0,
    required this.code,
    required this.language,
  });

  final String code;
  final String language;

  @override
  CodeBlockComponentViewModel copy() {
    return CodeBlockComponentViewModel(
      nodeId: nodeId,
      createdAt: createdAt,
      maxWidth: maxWidth,
      padding: padding,
      opacity: opacity,
      code: code,
      language: language,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CodeBlockComponentViewModel &&
        other.nodeId == nodeId &&
        other.code == code &&
        other.language == language;
  }

  @override
  int get hashCode => Object.hash(nodeId, code, language);
}

/// 代码块组件
/// 使用 flutter_highlight 渲染语法高亮
class CodeBlockComponent extends StatelessWidget {
  const CodeBlockComponent({
    super.key,
    required this.viewModel,
  });

  final CodeBlockComponentViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = isDarkMode ? draculaTheme : githubTheme;

    // 背景色：亮色模式使用浅灰色，暗色模式使用深色
    final backgroundColor = isDarkMode
        ? const Color(0xFF282A36) // Dracula 背景色
        : const Color(0xFFF6F8FA); // GitHub 背景色

    // 代码块使用全宽背景，左右边距与其他内容对齐
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: AppConstants.editorHorizontalPadding,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 语言标签（如果有）
          if (viewModel.language != 'plaintext')
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Text(
                viewModel.language,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: AppConstants.sourceModeFontFamily,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ),
          // 代码内容
          Padding(
            padding: const EdgeInsets.all(16),
            child: HighlightView(
              viewModel.code,
              language: _mapLanguage(viewModel.language),
              theme: theme,
              textStyle: TextStyle(
                fontSize: 14,
                fontFamily: AppConstants.sourceModeFontFamily,
                height: 1.5,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  /// 将 Markdown 语言标识映射到 highlight.js 支持的语言
  String _mapLanguage(String language) {
    // highlight.js 支持的常见语言别名映射
    const languageMap = {
      'js': 'javascript',
      'ts': 'typescript',
      'py': 'python',
      'rb': 'ruby',
      'sh': 'bash',
      'shell': 'bash',
      'zsh': 'bash',
      'yml': 'yaml',
      'md': 'markdown',
      'plaintext': 'plaintext',
      'txt': 'plaintext',
      '': 'plaintext',
    };

    final mapped = languageMap[language.toLowerCase()];
    return mapped ?? language.toLowerCase();
  }
}

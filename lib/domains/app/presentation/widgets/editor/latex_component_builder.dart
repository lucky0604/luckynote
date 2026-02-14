import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:super_editor/super_editor.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/core/constants/app_constants.dart';

/// LaTeX 组件构建器
/// 负责渲染带有 LaTeX 元数据的 TextNode
class LatexComponentBuilder extends ComponentBuilder {
  LatexComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    if (node is! TextNode) {
      return null;
    }

    // 检查是否有 LaTeX 元数据
    final isLatex = node.metadata['isLatex'] as bool? ?? false;
    final isBlockLevel = node.metadata['isBlockLevel'] as bool? ?? false;
    final expression = node.metadata['latexExpression'] as String?;

    if (!isLatex || expression == null) {
      return null;
    }

    return _LatexComponentViewModel(
      nodeId: node.id,
      createdAt: node.metadata['createdAt'] as DateTime?,
      expression: expression,
      isBlockLevel: isBlockLevel,
    );
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! _LatexComponentViewModel) {
      return null;
    }

    return _LatexComponent(
      key: componentContext.componentKey,
      viewModel: componentViewModel,
    );
  }
}

/// LaTeX 组件 ViewModel
class _LatexComponentViewModel extends SingleColumnLayoutComponentViewModel {
  _LatexComponentViewModel({
    required super.nodeId,
    super.createdAt,
    super.maxWidth,
    super.padding = const EdgeInsets.symmetric(horizontal: AppConstants.editorHorizontalPadding, vertical: 8),
    super.opacity = 1.0,
    required this.expression,
    required this.isBlockLevel,
  });

  final String expression;
  final bool isBlockLevel;

  @override
  _LatexComponentViewModel copy() {
    return _LatexComponentViewModel(
      nodeId: nodeId,
      createdAt: createdAt,
      maxWidth: maxWidth,
      padding: padding,
      opacity: opacity,
      expression: expression,
      isBlockLevel: isBlockLevel,
    );
  }
}

/// LaTeX 组件
/// 渲染数学公式
class _LatexComponent extends StatelessWidget {
  const _LatexComponent({
    super.key,
    required this.viewModel,
  });

  final _LatexComponentViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final mathWidget = Math.tex(
      viewModel.expression,
      textStyle: TextStyle(
        fontSize: viewModel.isBlockLevel ? 18 : 16,
        color: AppColors.textPrimary,
      ),
    );

    if (viewModel.isBlockLevel) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding:
            EdgeInsets.symmetric(horizontal: AppConstants.editorHorizontalPadding, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.noteListBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: mathWidget),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.editorHorizontalPadding),
      child: mathWidget,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:luckynote/app/theme/app_colors.dart';

/// LaTeX 数学公式渲染组件
class LatexMathWidget extends StatelessWidget {
  const LatexMathWidget({
    super.key,
    required this.expression,
    this.isBlockLevel = false,
    this.onTap,
  });

  final String expression;
  final bool isBlockLevel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mathWidget = Math.tex(
      expression,
      textStyle: TextStyle(
        fontSize: isBlockLevel ? 18 : 16,
        color: AppColors.textPrimary,
      ),
    );

    if (isBlockLevel) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.noteListBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: mathWidget),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: mathWidget,
    );
  }
}

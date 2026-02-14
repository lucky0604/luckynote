import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/core/constants/app_constants.dart';
import '../../../../settings/presentation/providers/editor_layout_provider.dart';

/// 编辑器宽度约束容器
/// 根据窗口大小和用户设置自动调整内容宽度
class EditorWidthContainer extends ConsumerWidget {
  const EditorWidthContainer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutSettings = ref.watch(editorLayoutNotifierProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    // 响应式逻辑：窗口宽度 < 900px 时使用 24px 边距
    final shouldUseMobilePadding = screenWidth < AppConstants.responsiveBreakpoint;
    final effectivePadding = shouldUseMobilePadding
        ? AppConstants.mobilePadding
        : layoutSettings.horizontalPadding;

    // 计算实际的最大宽度
    final actualMaxWidth = layoutSettings.isFullWidth
        ? double.infinity
        : layoutSettings.maxWidth;

    return Container(
      color: AppColors.background,
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: actualMaxWidth,
            minWidth: AppConstants.editorMinWidth,
          ),
          width: screenWidth < AppConstants.responsiveBreakpoint
              ? screenWidth
              : null,
          padding: EdgeInsets.symmetric(horizontal: effectivePadding),
          child: child,
        ),
      ),
    );
  }
}

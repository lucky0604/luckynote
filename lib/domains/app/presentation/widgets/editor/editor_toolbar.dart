import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';
import 'package:luckynote/domains/editor/presentation/providers/editor_state.dart';
import '../../../../settings/presentation/providers/editor_layout_provider.dart';
import 'save_indicator.dart';
import 'toolbar_button.dart';

/// 编辑器工具栏
class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({
    super.key,
    required this.noteTitle,
    required this.isDirty,
    required this.isSaving,
    required this.onSave,
    this.onInsertImage,
    this.getScrollRatio,
    // 格式化回调
    this.onBold,
    this.onItalic,
    this.onStrikethrough,
    this.onHeading1,
    this.onHeading2,
    this.onBulletList,
    this.onOrderedList,
    this.onCode,
    this.onWikiLink,
  });

  final String noteTitle;
  final bool isDirty;
  final bool isSaving;
  final VoidCallback onSave;
  final void Function(String imagePath)? onInsertImage;

  /// 获取当前编辑器滚动比例的回调，用于模式切换时同步滚动位置
  final double Function()? getScrollRatio;

  // 格式化回调
  final VoidCallback? onBold;
  final VoidCallback? onItalic;
  final VoidCallback? onStrikethrough;
  final VoidCallback? onHeading1;
  final VoidCallback? onHeading2;
  final VoidCallback? onBulletList;
  final VoidCallback? onOrderedList;
  final VoidCallback? onCode;
  final VoidCallback? onWikiLink;

  Future<void> _pickAndInsertImage() async {
    const typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
    );

    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      onInsertImage?.call(file.path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final viewMode = editorState.viewMode;
    final isSourceMode = viewMode == EditorViewMode.source;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.background,
      child: Row(
        children: [
          // 笔记标题
          Expanded(
            child: Row(
              children: [
                Icon(
                  LucideIcons.fileText,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    noteTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isDirty) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 保存状态指示器
          _buildSaveIndicator(),

          const SizedBox(width: 8),

          // 模式切换按钮
          _buildModeSwitchButton(isSourceMode, ref),

          const SizedBox(width: 8),

          // 全宽切换按钮
          _buildFullWidthButton(ref),

          const SizedBox(width: 8),
          VerticalDivider(
            width: 1,
            indent: 12,
            endIndent: 12,
            color: AppColors.border,
          ),
          const SizedBox(width: 8),

          // 工具按钮（仅在预览模式显示）
          if (!isSourceMode) ...[
            _buildToolButton(
              icon: LucideIcons.bold,
              tooltip: '粗体 (Cmd+B)',
              onPressed: onBold,
            ),
            _buildToolButton(
              icon: LucideIcons.italic,
              tooltip: '斜体 (Cmd+I)',
              onPressed: onItalic,
            ),
            _buildToolButton(
              icon: LucideIcons.strikethrough,
              tooltip: '删除线',
              onPressed: onStrikethrough,
            ),
            const SizedBox(width: 8),
            VerticalDivider(
              width: 1,
              indent: 12,
              endIndent: 12,
              color: AppColors.border,
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              icon: LucideIcons.heading1,
              tooltip: '一级标题',
              onPressed: onHeading1,
            ),
            _buildToolButton(
              icon: LucideIcons.heading2,
              tooltip: '二级标题',
              onPressed: onHeading2,
            ),
            _buildToolButton(
              icon: LucideIcons.list,
              tooltip: '无序列表',
              onPressed: onBulletList,
            ),
            _buildToolButton(
              icon: LucideIcons.listOrdered,
              tooltip: '有序列表',
              onPressed: onOrderedList,
            ),
            const SizedBox(width: 8),
            VerticalDivider(
              width: 1,
              indent: 12,
              endIndent: 12,
              color: AppColors.border,
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              icon: LucideIcons.link,
              tooltip: '链接 (Cmd+K)',
              onPressed: onWikiLink,
            ),
            _buildToolButton(
              icon: LucideIcons.image,
              tooltip: '插入图片',
              onPressed: onInsertImage != null ? _pickAndInsertImage : null,
            ),
            _buildToolButton(
              icon: LucideIcons.code,
              tooltip: '代码块',
              onPressed: onCode,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeSwitchButton(bool isSourceMode, WidgetRef ref) {
    return _buildToolButton(
      icon: isSourceMode ? LucideIcons.eye : LucideIcons.code,
      tooltip: isSourceMode ? '切换到预览模式' : '切换到源码模式',
      onPressed: () {
        // 获取当前滚动比例，用于切换后同步滚动位置
        final scrollRatio = getScrollRatio?.call() ?? 0.0;
        ref.read(editorProvider.notifier).toggleViewMode(scrollRatio: scrollRatio);
      },
    );
  }

  Widget _buildFullWidthButton(WidgetRef ref) {
    final layoutState = ref.watch(editorLayoutNotifierProvider);
    final isFullWidth = layoutState.isFullWidth;

    return ToolbarButton(
      icon: isFullWidth ? LucideIcons.minimize2 : LucideIcons.maximize2,
      tooltip: isFullWidth ? '切换到居中模式' : '切换到全宽模式',
      onPressed: () {
        ref.read(editorLayoutNotifierProvider.notifier).toggleFullWidth();
      },
      isActive: isFullWidth,
    );
  }

  Widget _buildSaveIndicator() {
    return SaveIndicator(
      isDirty: isDirty,
      isSaving: isSaving,
      onSave: onSave,
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return ToolbarButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

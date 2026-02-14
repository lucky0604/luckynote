import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../data/models/chat_context.dart';
import '../../../data/models/mention_item.dart';
import '../../../../../database/database.dart';
import '../../providers/mention_provider.dart';
import 'file_picker_dialog.dart';
import 'mention_header.dart';
import 'mention_footer.dart';
import 'mention_list.dart';

/// @ 提及弹出菜单
///
/// 显示可选择的上下文列表：
/// - 当前笔记
/// - 浏览文件
/// - 全库检索
/// - 搜索到的笔记
/// - 标签
class MentionPopup extends ConsumerStatefulWidget {
  const MentionPopup({
    super.key,
    required this.onSelect,
    this.onDismiss,
  });

  final void Function(ChatContext context) onSelect;
  final VoidCallback? onDismiss;

  @override
  ConsumerState<MentionPopup> createState() => _MentionPopupState();
}

class _MentionPopupState extends ConsumerState<MentionPopup> {

  @override
  Widget build(BuildContext context) {
    final mentionState = ref.watch(mentionProvider);

    ref.listen(mentionProvider, (prev, next) {
      if (prev?.isVisible == true && !next.isVisible && widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });

    if (!mentionState.isVisible || mentionState.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: AppColors.cardBackground,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 320, maxWidth: 320),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MentionHeader(),
              const Divider(height: 1),
              Flexible(
                child: MentionList(
                  suggestions: mentionState.suggestions,
                  selectedIndex: mentionState.selectedIndex,
                  onSelect: _handleSelect,
                ),
              ),
              const MentionFooter(),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSelect(MentionItem item) {
    final notifier = ref.read(mentionProvider.notifier);

    // 处理浏览文件选项
    if (item.type == MentionType.browseFiles) {
      notifier.hide();
      widget.onDismiss?.call();
      _showFilePicker();
      return;
    }

    final chatContext = notifier.mentionToContext(item);

    if (chatContext != null) {
      widget.onSelect(chatContext);
    }

    notifier.hide();
    widget.onDismiss?.call();
  }

  /// 显示文件选择对话框
  Future<void> _showFilePicker() async {
    final selectedNote = await showDialog<Note>(
      context: context,
      builder: (context) => const FilePickerDialog(),
    );

    if (selectedNote != null) {
      final chatContext = ChatContext.note(
        filePath: selectedNote.filePath,
        title: selectedNote.title,
      );
      widget.onSelect(chatContext);
    }
  }
}

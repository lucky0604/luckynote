import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/chat/data/models/chat_context.dart';
import 'package:luckynote/domains/chat/data/models/mention_item.dart';
import 'package:luckynote/database/database.dart';
import 'package:luckynote/domains/shared_infra/providers/database_provider.dart';
import 'package:luckynote/domains/chat/presentation/providers/mention_provider.dart';
import 'mention_item_tile.dart';

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
              _buildHeader(),
              const Divider(height: 1),
              Flexible(child: _buildSuggestionList(mentionState)),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: AppColors.hoverBackground.withValues(alpha: 0.5),
      child: Row(
        children: [
          Icon(LucideIcons.atSign, size: 14, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            '选择引用',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionList(MentionState mentionState) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: mentionState.suggestions.length,
      itemBuilder: (context, index) {
        final item = mentionState.suggestions[index];
        final isSelected = index == mentionState.selectedIndex;

        return MentionItemTile(
          item: item,
          isSelected: isSelected,
          onTap: () => _handleSelect(item),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.hoverBackground.withValues(alpha: 0.3),
      child: Row(
        children: [
          _buildKeyHint('↑↓', '选择'),
          const SizedBox(width: 12),
          _buildKeyHint('↵', '确认'),
          const SizedBox(width: 12),
          _buildKeyHint('esc', '取消'),
        ],
      ),
    );
  }

  Widget _buildKeyHint(String key, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            key,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppColors.textPlaceholder),
        ),
      ],
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
      builder: (context) => const _FilePickerDialog(),
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

/// 文件选择对话框
class _FilePickerDialog extends ConsumerStatefulWidget {
  const _FilePickerDialog();

  @override
  ConsumerState<_FilePickerDialog> createState() => _FilePickerDialogState();
}

class _FilePickerDialogState extends ConsumerState<_FilePickerDialog> {
  final _searchController = TextEditingController();
  List<Note> _allNotes = [];
  List<Note> _filteredNotes = [];
  int? _selectedNoteId;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final notes = await ref.read(noteRepositoryProvider).getAll();
    if (mounted) {
      setState(() {
        _allNotes = notes;
        _filteredNotes = notes;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNotes = _allNotes.where((note) {
        return note.title.toLowerCase().contains(query) ||
            note.filePath.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _selectNote(Note note) {
    setState(() {
      _selectedNoteId = note.id;
    });
  }

  void _confirm() {
    if (_selectedNoteId == null) return;
    final selectedNote = _filteredNotes.firstWhere(
      (note) => note.id == _selectedNoteId,
    );
    Navigator.of(context).pop(selectedNote);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择文件'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          children: [
            // 搜索框
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索文件...',
                prefixIcon: const Icon(LucideIcons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 文件列表
            Expanded(
              child: _filteredNotes.isEmpty
                  ? const Center(child: Text('没有找到文件'))
                  : ListView.builder(
                      itemCount: _filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = _filteredNotes[index];
                        final isSelected = note.id == _selectedNoteId;
                        return _FileListItem(
                          note: note,
                          isSelected: isSelected,
                          onTap: () => _selectNote(note),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _selectedNoteId == null ? null : _confirm,
          child: const Text('选择'),
        ),
      ],
    );
  }
}

/// 文件列表项
class _FileListItem extends StatelessWidget {
  const _FileListItem({
    required this.note,
    required this.isSelected,
    required this.onTap,
  });

  final Note note;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.selectedBackground : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.fileText,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    note.filePath,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.check,
                size: 16,
                color: AppColors.accent,
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../database/database.dart';
import '../../../../shared_infra/providers/database_provider.dart';

/// 文件选择对话框
class FilePickerDialog extends ConsumerStatefulWidget {
  const FilePickerDialog({super.key});

  @override
  ConsumerState<FilePickerDialog> createState() => _FilePickerDialogState();
}

class _FilePickerDialogState extends ConsumerState<FilePickerDialog> {
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

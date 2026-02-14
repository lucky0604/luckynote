import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/search/data/repositories/global_search_repository.dart';
import 'package:luckynote/domains/search/presentation/providers/global_search_provider.dart';
import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';

/// 全局搜索对话框 (Cmd/Ctrl + P)
class GlobalSearchDialog extends ConsumerStatefulWidget {
  const GlobalSearchDialog({super.key});

  @override
  ConsumerState<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends ConsumerState<GlobalSearchDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    ref.read(globalSearchProvider.notifier).search(_controller.text);
    setState(() => _selectedIndex = 0);
  }

  void _handleKey(KeyEvent event) {
    final state = ref.read(globalSearchProvider);
    final results = state.results;

    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (results.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % results.length;
        });
        _scrollToSelected();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (results.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + results.length) % results.length;
        });
        _scrollToSelected();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (results.isNotEmpty && _selectedIndex < results.length) {
        _openNote(results[_selectedIndex]);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  void _scrollToSelected() {
    if (_selectedIndex >= 0 && _scrollController.hasClients) {
      final position = _selectedIndex * 60.0;
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openNote(UnifiedSearchResult result) {
    ref.read(editorProvider.notifier).openNoteByPath(result.filePath);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKey,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 600,
          height: 400,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSearchInput(),
              Divider(height: 1, color: AppColors.divider),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: '搜索笔记 (标题或内容)...',
          hintStyle: TextStyle(color: AppColors.textPlaceholder),
          prefixIcon: Icon(
            LucideIcons.search,
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildResults() {
    final state = ref.watch(globalSearchProvider);

    if (state.isSearching) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (state.query.isEmpty) {
      return Center(
        child: Text(
          '输入关键词搜索...',
          style: TextStyle(color: AppColors.textPlaceholder),
        ),
      );
    }

    if (state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.searchX,
                size: 48, color: AppColors.textPlaceholder),
            const SizedBox(height: 16),
            Text(
              '未找到结果',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final result = state.results[index];
        final isSelected = index == _selectedIndex;
        return _buildResultTile(result, isSelected);
      },
    );
  }

  Widget _buildResultTile(UnifiedSearchResult result, bool isSelected) {
    return InkWell(
      onTap: () => _openNote(result),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.selectedBackground : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              result.type == SearchResultType.title
                  ? LucideIcons.heading
                  : LucideIcons.fileText,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (result.matchedContent != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      result.matchedContent!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              LucideIcons.arrowRight,
              size: 16,
              color: AppColors.textPlaceholder,
            ),
          ],
        ),
      ),
    );
  }
}

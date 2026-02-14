import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/notes/data/repositories/tag_repository.dart';
import 'package:luckynote/domains/notes/presentation/providers/tags_provider.dart';
import 'package:luckynote/domains/navigation/data/models/navigation_state.dart';
import 'package:luckynote/domains/navigation/presentation/providers/navigation_provider.dart';
import 'tag_list_item.dart';

/// 标签搜索 Provider
final tagSearchQueryProvider = StateProvider<String>((ref) => '');

/// 过滤后的标签列表
final filteredTagsProvider = Provider<List<TagWithCount>>((ref) {
  final query = ref.watch(tagSearchQueryProvider).toLowerCase();
  final activeTags = ref.watch(activeTagsProvider);

  if (query.isEmpty) {
    return activeTags;
  }

  return activeTags
      .where((t) => t.tag.name.toLowerCase().contains(query))
      .toList();
});

/// 标签区域组件
/// 显示在侧边栏中，用于筛选笔记
class TagsSection extends ConsumerStatefulWidget {
  const TagsSection({super.key});

  @override
  ConsumerState<TagsSection> createState() => _TagsSectionState();
}

class _TagsSectionState extends ConsumerState<TagsSection> {
  static const int _defaultVisibleCount = 5;
  bool _isExpanded = false;
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagsState = ref.watch(tagsProvider);
    final filteredTags = ref.watch(filteredTagsProvider);
    final navState = ref.watch(navigationProvider);
    final searchQuery = ref.watch(tagSearchQueryProvider);

    final hasMoreTags = filteredTags.length > _defaultVisibleCount;
    final visibleTags = _isExpanded || !hasMoreTags
        ? filteredTags
        : filteredTags.take(_defaultVisibleCount).toList();
    final hiddenCount = filteredTags.length - _defaultVisibleCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(searchQuery.isNotEmpty),
        if (_isSearching) _buildSearchBar(),
        Flexible(
          child: tagsState.isLoading
              ? _buildLoadingState()
              : filteredTags.isEmpty
                  ? _buildEmptyState(searchQuery.isNotEmpty)
                  : _buildTagList(visibleTags, navState, hiddenCount, hasMoreTags),
        ),
      ],
    );
  }

  Widget _buildHeader(bool hasSearchResult) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (!hasSearchResult) ...[
              IconButton(
                icon: Icon(LucideIcons.search, size: 14),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      ref.read(tagSearchQueryProvider.notifier).state = '';
                    }
                  });
                },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                splashRadius: 12,
                tooltip: '搜索标签',
              ),
              const SizedBox(width: 4),
            ],
            AnimatedRotation(
              turns: _isExpanded ? 0 : -0.25,
              duration: const Duration(milliseconds: 200),
              child: Icon(LucideIcons.chevronDown, size: 14, color: AppColors.sidebarTextSecondary),
            ),
            const SizedBox(width: 8),
            Text('标签', style: TextStyle(color: AppColors.sidebarTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
            if (hasSearchResult) ...[
              const Spacer(),
              IconButton(
                icon: Icon(LucideIcons.x, size: 12),
                onPressed: () {
                  _searchController.clear();
                  ref.read(tagSearchQueryProvider.notifier).state = '';
                  setState(() => _isSearching = false);
                },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                splashRadius: 12,
                tooltip: '清除搜索',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: '搜索标签...',
          hintStyle: TextStyle(color: AppColors.sidebarTextSecondary.withValues(alpha: 0.6), fontSize: 12),
          prefixIcon: Icon(LucideIcons.search, size: 14, color: AppColors.sidebarTextSecondary),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
        ),
        onChanged: (value) => ref.read(tagSearchQueryProvider.notifier).state = value,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sidebarTextSecondary),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(isSearching ? '没有找到匹配的标签' : '暂无标签', style: TextStyle(color: AppColors.sidebarTextSecondary, fontSize: 12)),
    );
  }

  Widget _buildTagList(List<TagWithCount> visibleTags, NavigationState navState, int hiddenCount, bool hasMoreTags) {
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: [
        ...visibleTags.map((tagWithCount) => TagListItem(
          key: ValueKey(tagWithCount.tag.name),
          tag: tagWithCount,
          isSelected: navState.selectedTag == tagWithCount.tag.name,
          onTap: () => ref.read(navigationProvider.notifier).switchToTag(tagWithCount.tag.name),
        )),
        if (hasMoreTags) _buildExpandButton(hiddenCount),
      ],
    );
  }

  Widget _buildExpandButton(int hiddenCount) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(_isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 12, color: AppColors.sidebarTextSecondary),
            const SizedBox(width: 6),
            Text(_isExpanded ? '收起' : '展开更多 ($hiddenCount)', style: TextStyle(color: AppColors.sidebarTextSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
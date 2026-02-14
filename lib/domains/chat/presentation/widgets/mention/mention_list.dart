import 'package:flutter/material.dart';

import '../../../data/models/mention_item.dart';
import 'mention_item_tile.dart';

/// 提及建议列表组件
class MentionList extends StatelessWidget {
  const MentionList({
    super.key,
    required this.suggestions,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<MentionItem> suggestions;
  final int selectedIndex;
  final void Function(MentionItem) onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final item = suggestions[index];
        final isSelected = index == selectedIndex;

        return MentionItemTile(
          item: item,
          isSelected: isSelected,
          onTap: () => onSelect(item),
        );
      },
    );
  }
}

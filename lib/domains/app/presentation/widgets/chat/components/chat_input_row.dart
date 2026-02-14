import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';

class ChatInputRow extends StatelessWidget {
  const ChatInputRow({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hasContent,
    required this.isLoading,
    required this.onInsertAt,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasContent;
  final bool isLoading;
  final VoidCallback onInsertAt;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.hoverBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: IconButton(
              icon: Icon(
                LucideIcons.atSign,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onPressed: onInsertAt,
              tooltip: '引用笔记 (@)',
              iconSize: 18,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: '向 AI 提问... 输入 @ 引用笔记',
                  hintStyle: TextStyle(
                    color: AppColors.textPlaceholder,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                maxLines: 4,
                minLines: 1,
                enabled: !isLoading,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 4),
            child: _SendButton(
              hasContent: hasContent,
              isLoading: isLoading,
              onSend: onSend,
            ),
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.hasContent,
    required this.isLoading,
    required this.onSend,
  });

  final bool hasContent;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Material(
      color: hasContent ? AppColors.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: hasContent ? onSend : null,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            LucideIcons.arrowUp,
            size: 16,
            color: hasContent ? Colors.white : AppColors.textPlaceholder,
          ),
        ),
      ),
    );
  }
}

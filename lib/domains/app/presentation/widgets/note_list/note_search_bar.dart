import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';

/// 笔记搜索框组件
///
/// 提供搜索功能，支持实时过滤笔记列表
class NoteSearchBar extends StatefulWidget {
  const NoteSearchBar({
    super.key,
    this.hint = '搜索笔记...',
    this.onChanged,
    this.onClear,
    this.initialValue,
  });

  /// 提示文本
  final String hint;

  /// 搜索文本变化回调
  final ValueChanged<String>? onChanged;

  /// 清除搜索回调
  final VoidCallback? onClear;

  /// 初始值
  final String? initialValue;

  @override
  State<NoteSearchBar> createState() => _NoteSearchBarState();
}

class _NoteSearchBarState extends State<NoteSearchBar> {
  late final TextEditingController _controller;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _hasFocus = hasFocus);
      },
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
          prefixIcon: _hasFocus || _controller.text.isNotEmpty
              ? Icon(LucideIcons.x, size: 16, color: AppColors.textPlaceholder)
              : Icon(
                  LucideIcons.search,
                  size: 16,
                  color: AppColors.textPlaceholder,
                ),
          suffixIcon: _hasFocus || _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    size: 16,
                    color: AppColors.textPlaceholder,
                  ),
                  onPressed: () {
                    _controller.clear();
                    widget.onClear?.call();
                    widget.onChanged?.call('');
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                )
              : null,
          filled: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: _hasFocus ? AppColors.accent : Colors.transparent,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.accent, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        style: TextStyle(fontSize: 14, color: Colors.black87),
        textInputAction: TextInputAction.search,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:luckynote/app/theme/app_colors.dart';

/// 显示 LaTeX 编辑对话框
/// 返回编辑后的表达式，如果用户取消则返回 null
Future<String?> showLatexEditDialog({
  required BuildContext context,
  required String initialExpression,
  bool isBlockLevel = false,
}) {
  final controller = TextEditingController(text: initialExpression);

  return showDialog<String>(
    context: context,
    builder: (context) => _LatexEditDialog(
      controller: controller,
      isBlockLevel: isBlockLevel,
    ),
  ).then((result) {
    controller.dispose();
    return result;
  });
}

class _LatexEditDialog extends StatefulWidget {
  const _LatexEditDialog({
    required this.controller,
    required this.isBlockLevel,
  });

  final TextEditingController controller;
  final bool isBlockLevel;

  @override
  State<_LatexEditDialog> createState() => _LatexEditDialogState();
}

class _LatexEditDialogState extends State<_LatexEditDialog> {
  bool _showPreview = true;
  String? _errorText;

  void _validateLatex(String value) {
    if (value.trim().isEmpty) {
      setState(() => _errorText = '表达式不能为空');
      return;
    }

    try {
      Math.tex(
        value,
        textStyle: const TextStyle(fontSize: 16),
      );
      setState(() => _errorText = null);
    } catch (e) {
      setState(() => _errorText = 'LaTeX 语法错误: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _validateLatex(widget.controller.text);
    widget.controller.addListener(() {
      _validateLatex(widget.controller.text);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.functions, size: 20),
          const SizedBox(width: 8),
          Text(widget.isBlockLevel ? '编辑块级公式' : '编辑行内公式'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 输入框
            TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                labelText: 'LaTeX 表达式',
                hintText: widget.isBlockLevel ? r'\int_0^\infty x^2 dx' : r'E=mc^2',
                border: const OutlineInputBorder(),
                errorText: _errorText,
              ),
              maxLines: 3,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),

            // 预览切换按钮
            Row(
              children: [
                const Text('预览'),
                const SizedBox(width: 8),
                Switch(
                  value: _showPreview,
                  onChanged: (value) => setState(() => _showPreview = value),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 预览区域
            if (_showPreview && _errorText == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.noteListBackground.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Math.tex(
                      widget.controller.text,
                      textStyle: TextStyle(
                        fontSize: widget.isBlockLevel ? 18 : 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            if (_showPreview && _errorText != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: Center(
                  child: Text(
                    '预览不可用：$_errorText',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),

            const SizedBox(height: 8),
            Text(
              '提示: 使用 ${widget.isBlockLevel ? r'$$...$$' : r'$...$'} 语法',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPlaceholder,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _errorText == null
              ? () => Navigator.pop(context, widget.controller.text)
              : null,
          child: const Text('确定'),
        ),
      ],
    );
  }
}

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path/path.dart' as p;

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/chat/data/models/chat_attachment.dart';
import 'package:luckynote/domains/chat/presentation/providers/chat_provider.dart';
import 'package:luckynote/domains/chat/presentation/widgets/attachment_chip.dart';

/// 聊天输入框组件
class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({super.key});

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasContent = false;
  final List<ChatAttachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasContent = _controller.text.trim().isNotEmpty || _attachments.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;

    // 构建消息内容（包含附件引用）
    final messageText = _buildMessageWithAttachments(text);

    _controller.clear();
    setState(() => _attachments.clear());
    _focusNode.requestFocus();

    await ref.read(chatNotifierProvider.notifier).sendMessage(messageText);
  }

  String _buildMessageWithAttachments(String text) {
    if (_attachments.isEmpty) return text;

    final buffer = StringBuffer(text);
    if (text.isNotEmpty) buffer.write('\n\n');
    buffer.write('附件:\n');
    for (final attachment in _attachments) {
      buffer.write('- ${attachment.name} (${attachment.path})\n');
    }
    return buffer.toString();
  }

  Future<void> _pickImage() async {
    const typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    );

    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      setState(() {
        _attachments.add(ChatAttachment.image(
          path: file.path,
          name: p.basename(file.path),
        ));
        _hasContent = true;
      });
    }
  }

  void _removeAttachment(ChatAttachment attachment) {
    setState(() {
      _attachments.remove(attachment);
      _hasContent = _controller.text.trim().isNotEmpty || _attachments.isNotEmpty;
    });
  }

  Future<void> _summarizeNote() async {
    await ref.read(chatNotifierProvider.notifier).summarizeNote();
  }

  Future<void> _fixGrammar() async {
    await ref.read(chatNotifierProvider.notifier).fixGrammar();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(chatLoadingProvider);
    final hasCurrentNote = ref.watch(chatCurrentNoteProvider) != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // 快捷操作按钮
          if (hasCurrentNote)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: LucideIcons.fileText,
                      label: '总结笔记',
                      onTap: _summarizeNote,
                      isLoading: isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionButton(
                      icon: LucideIcons.edit3,
                      label: '修正语法',
                      onTap: _fixGrammar,
                      isLoading: isLoading,
                    ),
                  ),
                ],
              ),
            ),

          // 附件预览
          if (_attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _attachments
                    .map((a) => AttachmentChip(
                          attachment: a,
                          onRemove: () => _removeAttachment(a),
                        ))
                    .toList(),
              ),
            ),

          // 输入框
          Row(
            children: [
              // 附件按钮
              IconButton(
                icon: const Icon(LucideIcons.paperclip, size: 18),
                color: AppColors.textSecondary,
                onPressed: isLoading ? null : _pickImage,
                tooltip: '添加附件',
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: '向 AI 提问...',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: _hasContent && !isLoading
                        ? IconButton(
                            icon: const Icon(LucideIcons.send, size: 18),
                            color: AppColors.accent,
                            onPressed: _sendMessage,
                          )
                        : null,
                  ),
                  maxLines: 3,
                  minLines: 1,
                  enabled: !isLoading,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
                )
              else if (!_hasContent)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: IconButton(
                    icon: const Icon(LucideIcons.mic, size: 18),
                    color: Colors.grey,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('语音输入功能即将推出')),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 快捷操作按钮
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

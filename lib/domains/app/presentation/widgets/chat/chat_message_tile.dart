import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/chat/data/models/chat_message.dart';

/// 单条聊天消息组件
class ChatMessageTile extends StatelessWidget {
  final ChatMessage message;
  final bool showActions;

  const ChatMessageTile({
    super.key,
    required this.message,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isAI = message.role == MessageRole.assistant;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI 头像
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.accent.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 12),
                ),
                border: Border.all(
                  color: isUser
                      ? AppColors.accent.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 角色标签
                  if (message.role != MessageRole.user)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Lucky Assistant',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),

                  // 消息内容
                  if (isAI && message.content.isEmpty && message.isStreaming)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DotAnimation(),
                        SizedBox(width: 4),
                        _DotAnimation(delay: 100),
                        SizedBox(width: 4),
                        _DotAnimation(delay: 200),
                      ],
                    )
                  else if (isAI)
                    MarkdownBody(
                      data: message.content,
                      selectable: true,
                      styleSheet:
                          MarkdownStyleSheet.fromTheme(
                            Theme.of(context).copyWith(
                              textTheme: Theme.of(context).textTheme.apply(
                                bodyColor: Colors.grey[800],
                                fontSizeFactor: 0.95,
                              ),
                            ),
                          ).copyWith(
                            code: TextStyle(
                              backgroundColor: Colors.grey[200],
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                    )
                  else
                    Text(
                      message.content,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),

                  // 时间戳
                  if (message.timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _formatTime(message.timestamp!),
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            // 用户头像
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LucideIcons.user, size: 16, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// 动画点（用于加载状态）
class _DotAnimation extends StatefulWidget {
  final int delay;

  const _DotAnimation({this.delay = 0});

  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.2), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

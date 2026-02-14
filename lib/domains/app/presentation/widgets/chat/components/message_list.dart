import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:luckynote/domains/chat/presentation/providers/chat_provider.dart';
import 'chat_message_list_view.dart';
import 'empty_state.dart';

/// 聊天消息列表
class ChatMessageList extends ConsumerWidget {
  const ChatMessageList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatMessagesProvider);

    if (messages.isEmpty) {
      return const ChatEmptyState();
    }

    return ChatMessageListView(messages: messages);
  }
}

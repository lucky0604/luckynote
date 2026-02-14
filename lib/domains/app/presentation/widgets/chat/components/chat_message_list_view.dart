import 'package:flutter/material.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import '../chat_message_tile.dart';

class ChatMessageListView extends StatelessWidget {
  const ChatMessageListView({
    super.key,
    required this.messages,
  });

  final List<dynamic> messages;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: ChatMessageTile(message: messages[index]),
        );
      },
      separatorBuilder: (context, index) {
        return Divider(height: 1, color: AppColors.divider);
      },
      itemCount: messages.length,
    );
  }
}

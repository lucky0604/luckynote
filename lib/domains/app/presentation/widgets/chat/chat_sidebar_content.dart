import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/chat/presentation/providers/chat_provider.dart';
import 'components/config_banner.dart';
import 'components/empty_state.dart';
import 'components/error_banner.dart';
import 'components/input_area.dart';
import 'components/message_list.dart';
import 'components/sidebar_header.dart';

class ChatSidebarContent extends ConsumerWidget {
  const ChatSidebarContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatMessagesProvider);

    return Column(
      children: [
        ChatSidebarHeader(
          onClose: () => Navigator.of(context).pop(),
        ),
        Divider(height: 1, color: AppColors.divider),
        const ChatConfigBanner(),
        const ChatErrorBanner(),
        Expanded(
          child: messages.isEmpty
              ? const ChatEmptyState()
              : const ChatMessageList(),
        ),
        Divider(height: 1, color: AppColors.divider),
        const ChatInputArea(),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:luckynote/domains/chat/data/models/chat_context.dart';
import 'context_chip.dart';

class ChatInputContextChips extends StatelessWidget {
  const ChatInputContextChips({
    super.key,
    required this.contexts,
    required this.onRemove,
  });

  final List<ChatContext> contexts;
  final ValueChanged<ChatContext> onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: contexts
            .map((c) => ContextChip(
                  context: c,
                  onRemove: () => onRemove(c),
                ))
            .toList(),
      ),
    );
  }
}

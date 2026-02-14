import '../../data/models/chat_context.dart';
import '../../data/models/chat_message.dart';
import '../../../../database/database.dart';

/// 聊天状态
class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isOpen = false,
    this.isPinned = false,
    this.error,
    this.canRetry = false,
    this.currentNoteContext,
    this.activeContexts = const [],
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isOpen;
  final bool isPinned;
  final String? error;
  final bool canRetry;
  final Note? currentNoteContext;
  final List<ChatContext> activeContexts;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isOpen,
    bool? isPinned,
    String? error,
    bool? canRetry,
    Note? currentNoteContext,
    List<ChatContext>? activeContexts,
    bool clearError = false,
    bool clearCurrentNote = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isOpen: isOpen ?? this.isOpen,
      isPinned: isPinned ?? this.isPinned,
      error: clearError ? null : (error ?? this.error),
      canRetry: clearError ? false : (canRetry ?? this.canRetry),
      currentNoteContext: clearCurrentNote
          ? null
          : (currentNoteContext ?? this.currentNoteContext),
      activeContexts: activeContexts ?? this.activeContexts,
    );
  }

  ChatState addMessage(ChatMessage message) {
    return copyWith(messages: [...messages, message]);
  }

  ChatState addContext(ChatContext context) {
    final newContexts = List<ChatContext>.from(activeContexts);
    newContexts.add(context);
    return copyWith(activeContexts: newContexts);
  }

  ChatState removeContext(ChatContext context) {
    final newContexts = List<ChatContext>.from(activeContexts);
    newContexts.remove(context);
    return copyWith(activeContexts: newContexts);
  }

  ChatState clearContexts() {
    return copyWith(activeContexts: const []);
  }

  ChatState completeStreaming() {
    if (messages.isEmpty) return this;

    final lastMessage = messages.last;
    if (!lastMessage.isStreaming) return this;

    final updatedMessage = lastMessage.copyWith(isStreaming: false);
    final newMessages = List<ChatMessage>.from(messages);
    newMessages[newMessages.length - 1] = updatedMessage;

    return copyWith(messages: newMessages);
  }
}

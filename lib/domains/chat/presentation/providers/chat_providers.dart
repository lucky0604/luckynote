import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat_context.dart';
import '../../data/models/chat_message.dart';
import '../../../../database/database.dart';
import 'chat_notifier.dart';
import 'chat_state.dart';

/// 聊天状态 Provider
final chatNotifierProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) {
    return ChatNotifier(ref);
  },
);

/// 聊天消息列表 Provider
final chatMessagesProvider = Provider<List<ChatMessage>>((ref) {
  return ref.watch(chatNotifierProvider).messages;
});

/// 是否正在加载 Provider
final chatLoadingProvider = Provider<bool>((ref) {
  return ref.watch(chatNotifierProvider).isLoading;
});

/// 错误信息 Provider
final chatErrorProvider = Provider<String?>((ref) {
  return ref.watch(chatNotifierProvider).error;
});

/// 侧边栏是否固定 Provider
final chatIsPinnedProvider = Provider<bool>((ref) {
  return ref.watch(chatNotifierProvider).isPinned;
});

/// 当前笔记上下文 Provider
final chatCurrentNoteProvider = Provider<Note?>((ref) {
  return ref.watch(chatNotifierProvider).currentNoteContext;
});

/// 活动上下文列表 Provider
final chatActiveContextsProvider = Provider<List<ChatContext>>((ref) {
  return ref.watch(chatNotifierProvider).activeContexts;
});

import 'dart:async';

import 'package:luckynote/domains/chat/data/models/chat_message.dart';
import 'package:luckynote/domains/settings/data/models/llm_config.dart';

/// LLM 客户端接口
/// 定义所有 LLM 提供商必须实现的方法
abstract interface class LLMClient {
  /// 测试连接
  /// 返回 true 表示连接成功
  Future<bool> testConnection(LLMConfig config);

  /// 流式聊天
  /// 返回一个字符串流，逐字接收 AI 的回复
  Stream<String> streamChat(
    List<ChatMessage> messages, {
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  });

  /// 获取聊天完成（非流式）
  /// 返回完整的 AI 回复
  Future<String> getChatCompletion(
    List<ChatMessage> messages, {
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  });
}

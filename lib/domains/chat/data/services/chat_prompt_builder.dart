import 'package:luckynote/domains/chat/data/models/chat_message.dart';
import 'context_injection_service.dart';

/// 聊天提示词构建器
///
/// 负责构建发送给 LLM 的消息列表，包括系统提示和用户消息
class ChatPromptBuilder {
  const ChatPromptBuilder();

  /// 构建 API 消息列表（带上下文注入）
  List<Map<String, dynamic>> buildMessagesWithContext({
    required String userContent,
    required ContextInjectionResult contextResult,
    required List<ChatMessage> historyMessages,
    int maxHistoryCount = 10,
  }) {
    final messages = <Map<String, dynamic>>[];

    // 系统提示（根据是否有上下文调整）
    if (contextResult.isNotEmpty) {
      messages.add({
        'role': 'system',
        'content': _buildContextAwareSystemPrompt(),
      });
    } else {
      messages.add({
        'role': 'system',
        'content': '你是一个友好、专业的助手。请用中文回答问题。',
      });
    }

    // 添加历史消息（最多保留最近 N 条）
    final recentHistory = historyMessages.take(maxHistoryCount).toList();
    for (final msg in recentHistory) {
      if (msg.role != MessageRole.system) {
        messages.add({
          'role': msg.role.toApiFormat,
          'content': msg.content,
        });
      }
    }

    // 添加当前用户消息（包含上下文）
    if (contextResult.isNotEmpty) {
      messages.add({
        'role': 'user',
        'content': _buildUserMessageWithContext(userContent, contextResult),
      });
    } else {
      messages.add({
        'role': 'user',
        'content': userContent,
      });
    }

    return messages;
  }

  /// 构建上下文感知的系统提示
  String _buildContextAwareSystemPrompt() {
    return '''你是 LuckyNote AI，一个基于用户笔记的智能助手。

**深度文档分析模式**

你正在对用户指定的完整文档进行深度分析。这些文档包含完整的内容，而非摘要。

规则：
1. 仅基于提供的 <context> 内容回答问题，不要编造信息
2. 深入理解文档内容，提供详细、准确的分析
3. 引用具体的笔记来源和段落
4. 如果 context 中没有相关信息，明确告知用户
5. 使用中文回答
6. 对复杂问题进行结构化分析
7. 可以总结关键观点、提取重要信息、比较不同文档内容''';
  }

  /// 构建包含上下文的用户消息
  String _buildUserMessageWithContext(
    String userContent,
    ContextInjectionResult contextResult,
  ) {
    return '''${contextResult.content}

---
用户问题: $userContent

请基于以上笔记内容回答问题。''';
  }

  /// 构建笔记总结的消息列表
  List<Map<String, dynamic>> buildSummarizeMessages(String noteContent) {
    return [
      {
        'role': 'system',
        'content': '你是一个专业的总结助手。请用中文总结以下笔记内容，保持简洁明了。',
      },
      {
        'role': 'user',
        'content': '请总结以下笔记内容:\n\n$noteContent',
      },
    ];
  }

  /// 构建语法修正的消息列表
  List<Map<String, dynamic>> buildGrammarFixMessages(String noteContent) {
    return [
      {
        'role': 'system',
        'content': '你是一个语法专家。请修正以下文本的语法错误，保持原意不变。只输出修正后的文本。',
      },
      {
        'role': 'user',
        'content': noteContent,
      },
    ];
  }
}

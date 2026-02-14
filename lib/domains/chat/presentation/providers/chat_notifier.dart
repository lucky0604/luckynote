import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat_context.dart';
import '../../data/models/chat_message.dart';
import '../../../rag/data/models/rag_result.dart';
import '../../data/services/chat_prompt_builder.dart';
import '../../data/services/openai_compatible_client.dart';
import '../../../../database/database.dart';
import '../../../shared_infra/providers/database_provider.dart';
import '../../../editor/presentation/providers/editor_provider.dart';
import '../../../settings/presentation/providers/llm_config_provider.dart';
import 'chat_state.dart';

/// 聊天状态管理器
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._ref) : super(const ChatState());

  final Ref _ref;
  final Dio _dio = Dio();
  final ChatPromptBuilder _promptBuilder = const ChatPromptBuilder();

  /// 上一次发送的消息内容，用于重试
  String? _lastSentContent;

  // 侧边栏状态管理
  void openSidebar() => state = state.copyWith(isOpen: true);
  void closeSidebar() => state = state.copyWith(isOpen: false);
  void toggleSidebar() => state = state.copyWith(isOpen: !state.isOpen);
  void togglePin() => state = state.copyWith(isPinned: !state.isPinned);

  /// 设置当前笔记上下文
  void setCurrentNote(Note? note) {
    state = note == null
        ? state.copyWith(clearCurrentNote: true)
        : state.copyWith(currentNoteContext: note);
  }

  // 上下文管理
  void addContext(ChatContext context) => state = state.addContext(context);
  void removeContext(ChatContext context) => state = state.removeContext(context);
  void clearContexts() => state = state.clearContexts();

  // 状态清理
  void clearError() => state = state.copyWith(clearError: true);
  void clearHistory() => state = state.copyWith(messages: const []);

  /// 发送消息
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final config = _ref.read(llmConfigProvider);
    if (config == null || !config.isValid) {
      state = state.copyWith(error: '请先配置 LLM API');
      return;
    }

    // 保存消息内容用于重试
    _lastSentContent = content;

    // 添加用户消息（带上下文信息）
    final userMessage = state.activeContexts.isNotEmpty
        ? ChatMessage.withContext(
            role: MessageRole.user,
            content: content,
            contexts: List.from(state.activeContexts),
          )
        : ChatMessage.user(content);
    state = state.addMessage(userMessage);

    // 开始加载
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 检查是否有全库检索上下文
      final hasAllContext = state.activeContexts.any(
        (ctx) => ctx.type == ContextType.all,
      );

      if (hasAllContext) {
        // 使用 RAG 服务进行全库问答
        await _sendWithRAG(content, config);
      } else {
        // 使用上下文注入方式
        await _sendWithContextInjection(content, config);
      }

      // 成功后清除重试内容
      _lastSentContent = null;
    } catch (e) {
      state = state.copyWith(
        error: '请求失败: $e',
        canRetry: true,
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 重试上一次失败的消息
  Future<void> retryLastMessage() async {
    if (_lastSentContent == null) return;

    // 移除最后一条用户消息（失败的那条）
    if (state.messages.isNotEmpty) {
      final newMessages = List<ChatMessage>.from(state.messages);
      // 移除最后的用户消息
      if (newMessages.isNotEmpty && newMessages.last.role == MessageRole.user) {
        newMessages.removeLast();
      }
      state = state.copyWith(messages: newMessages, clearError: true, canRetry: false);
    }

    // 重新发送
    await sendMessage(_lastSentContent!);
  }

  /// 使用 RAG 服务发送消息（全库检索模式）
  Future<void> _sendWithRAG(String content, dynamic config) async {
    final ragService = _ref.read(ragServiceProvider);
    final ragConfig = RAGConfig();

    // 创建 AI 消息占位符
    final aiMessage = ChatMessage.ai('', isStreaming: true);
    state = state.addMessage(aiMessage);

    final stream = ragService.query(content, config, ragConfig);

    await for (final chunk in stream) {
      switch (chunk.type) {
        case RAGChunkType.sources:
          // 添加来源信息到消息
          if (chunk.sources.isNotEmpty) {
            final sourcesText = _formatRAGSources(chunk.sources);
            _appendToLastMessage(sourcesText);
          }
          break;
        case RAGChunkType.answer:
          _appendToLastMessage(chunk.content);
          break;
        case RAGChunkType.error:
          state = state.copyWith(error: chunk.content);
          break;
      }
    }

    state = state.completeStreaming();
  }

  /// 使用上下文注入发送消息
  Future<void> _sendWithContextInjection(String content, dynamic config) async {
    // 准备上下文内容
    final contextService = _ref.read(contextInjectionServiceProvider);
    final contextResult = await contextService.prepareContexts(
      state.activeContexts,
    );

    // 构建消息列表（包含注入的上下文）
    final messages = _promptBuilder.buildMessagesWithContext(
      userContent: content,
      contextResult: contextResult,
      historyMessages: state.messages,
    );

    // 流式发送并接收响应
    await _streamChat(config, messages);
  }

  /// 流式发送聊天请求并更新状态
  Future<void> _streamChat(
    dynamic config,
    List<Map<String, dynamic>> messages, {
    double temperature = 0.7,
    int maxTokens = 2000,
  }) async {
    // 创建 AI 消息占位符
    final aiMessage = ChatMessage.ai('', isStreaming: true);
    state = state.addMessage(aiMessage);

    // 流式响应
    final stream = OpenAICompatibleClient.streamChatWithConfig(
      dio: _dio,
      config: config,
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    await for (final chunk in stream) {
      _appendToLastMessage(chunk);
    }

    state = state.completeStreaming();
  }

  /// 格式化 RAG 来源信息
  String _formatRAGSources(List<RAGSource> sources) {
    final buffer = StringBuffer();
    buffer.write('📚 **参考来源**:\n');
    for (var i = 0; i < sources.length && i < 3; i++) {
      final source = sources[i];
      buffer.write('- ${source.title}');
      if (source.heading.isNotEmpty) {
        buffer.write(' > ${source.heading}');
      }
      buffer.write('\n');
    }
    buffer.write('\n---\n\n');
    return buffer.toString();
  }

  /// 总结当前笔记
  Future<void> summarizeNote() => _processCurrentNote(
        action: 'summarize',
        userPrompt: (title) => '请总结这篇笔记: $title',
        buildMessages: _promptBuilder.buildSummarizeMessages,
        temperature: 0.3,
        maxTokens: 500,
      );

  /// 修正语法
  Future<void> fixGrammar() => _processCurrentNote(
        action: 'fix',
        userPrompt: (title) => '请修正这篇笔记的语法: $title',
        buildMessages: _promptBuilder.buildGrammarFixMessages,
        temperature: 0.2,
        maxTokens: 1000,
      );

  /// 通用的笔记处理方法
  Future<void> _processCurrentNote({
    required String action,
    required String Function(String title) userPrompt,
    required List<Map<String, dynamic>> Function(String content) buildMessages,
    required double temperature,
    required int maxTokens,
  }) async {
    final note = _ref.read(currentNoteProvider);
    if (note == null) {
      state = state.copyWith(error: '请先打开一篇笔记');
      return;
    }

    final config = _ref.read(llmConfigProvider);
    if (config == null || !config.isValid) {
      state = state.copyWith(error: '请先配置 LLM API');
      return;
    }

    final editorState = _ref.read(editorProvider);
    final content = editorState.rawMarkdown;
    if (content.isEmpty) {
      state = state.copyWith(error: '笔记内容为空');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final userMessage = ChatMessage.withContext(
        role: MessageRole.user,
        content: userPrompt(note.title),
        contexts: [ChatContext.note(filePath: note.filePath, title: note.title)],
      );
      state = state.addMessage(userMessage);

      final messages = buildMessages(content);
      await _streamChat(config, messages, temperature: temperature, maxTokens: maxTokens);
    } catch (e) {
      state = state.copyWith(error: '$action 失败: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 追加内容到最后一条消息
  void _appendToLastMessage(String content) {
    if (state.messages.isEmpty) return;

    final lastMessage = state.messages.last;
    if (!lastMessage.isStreaming) return;

    final updatedMessage = lastMessage.appendContent(content);
    final newMessages = [...state.messages];
    newMessages[newMessages.length - 1] = updatedMessage;
    state = state.copyWith(messages: newMessages);
  }
}

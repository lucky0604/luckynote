import 'chat_context.dart';

/// 聊天消息模型
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    this.timestamp,
    this.isStreaming = false,
    this.contexts,
  });

  /// 消息角色
  final MessageRole role;

  /// 消息内容
  final String content;

  /// 时间戳
  final DateTime? timestamp;

  /// 是否正在流式传输
  final bool isStreaming;

  /// 这条消息携带的上下文
  final List<ChatContext>? contexts;

  /// 从 JSON 反序列化
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // 处理 contexts 字段
    final contextsData = json['contexts'] as List<dynamic>?;
    final contexts = contextsData != null
        ? contextsData
              .map((e) => ChatContext.fromMap(e as Map<String, dynamic>))
              .toList()
        : null;

    return ChatMessage(
      role: MessageRole.fromString(json['role'] as String),
      content: json['content'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      isStreaming: json['isStreaming'] as bool? ?? false,
      contexts: contexts,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    final json = {
      'role': role.name,
      'content': content,
      'timestamp': timestamp?.toIso8601String(),
      'isStreaming': isStreaming,
    };

    // 添加 contexts 字段（如果存在）
    if (contexts != null) {
      json['contexts'] = contexts!.map((ctx) => ctx.toMap()).toList();
    }

    return json;
  }

  /// 创建用户消息
  factory ChatMessage.user(String content) {
    return ChatMessage(
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  /// 创建 AI 消息
  factory ChatMessage.ai(String content, {bool isStreaming = false}) {
    return ChatMessage(
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      isStreaming: isStreaming,
    );
  }

  /// 创建系统消息
  factory ChatMessage.system(String content) {
    return ChatMessage(
      role: MessageRole.system,
      content: content,
      timestamp: DateTime.now(),
      contexts: null,
    );
  }

  /// 创建带上下文的消息
  factory ChatMessage.withContext({
    required MessageRole role,
    required String content,
    List<ChatContext>? contexts,
  }) {
    return ChatMessage(
      role: role,
      content: content,
      timestamp: DateTime.now(),
      contexts: contexts,
    );
  }

  /// 追加内容（用于流式响应）
  ChatMessage appendContent(String newContent) {
    return ChatMessage(
      role: role,
      content: content + newContent,
      timestamp: timestamp,
      isStreaming: isStreaming,
    );
  }

  /// 完成流式传输
  ChatMessage completeStreaming() {
    return ChatMessage(
      role: role,
      content: content,
      timestamp: timestamp,
      isStreaming: false,
    );
  }

  /// 复制并更新部分字段
  ChatMessage copyWith({
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
    List<ChatContext>? contexts,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      contexts: contexts ?? this.contexts,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(role: ${role.name}, content: "${content.length > 50 ? '${content.substring(0, 50)}...' : content}")';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          role == other.role &&
          content == other.content &&
          timestamp == other.timestamp &&
          isStreaming == other.isStreaming &&
          _listsEqual(contexts, other.contexts);

  /// 比较两个列表是否相等
  bool _listsEqual(List<ChatContext>? a, List<ChatContext>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(role, content, timestamp, isStreaming, contexts);
}

/// 消息角色
enum MessageRole {
  system,
  user,
  assistant;

  /// 从字符串转换
  static MessageRole fromString(String value) {
    return MessageRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MessageRole.user,
    );
  }

  /// 转换为 API 格式
  String get toApiFormat {
    switch (this) {
      case MessageRole.system:
        return 'system';
      case MessageRole.user:
        return 'user';
      case MessageRole.assistant:
        return 'assistant';
    }
  }
}

/// 聊天会话配置
class ChatConfig {
  const ChatConfig({
    this.systemPrompt,
    this.maxTokens,
    this.temperature,
    this.useCurrentNoteContext = false,
  });

  /// 系统提示词
  final String? systemPrompt;

  /// 最大令牌数
  final int? maxTokens;

  /// 温度参数
  final double? temperature;

  /// 是否使用当前笔记作为上下文
  final bool useCurrentNoteContext;

  /// 默认配置
  factory ChatConfig.defaultConfig() {
    return const ChatConfig(
      systemPrompt: '你是一个友好、专业的助手。请用中文回答问题。',
      maxTokens: 2000,
      temperature: 0.7,
      useCurrentNoteContext: false,
    );
  }

  /// 总结笔记的配置
  factory ChatConfig.summarize() {
    return const ChatConfig(
      systemPrompt: '你是一个专业的总结助手。请用中文总结以下内容，保持简洁明了。',
      maxTokens: 500,
      temperature: 0.3,
      useCurrentNoteContext: true,
    );
  }

  /// 语法修正的配置
  factory ChatConfig.fixGrammar() {
    return const ChatConfig(
      systemPrompt: '你是一个语法专家。请修正以下文本的语法错误，保持原意不变。',
      maxTokens: 1000,
      temperature: 0.2,
      useCurrentNoteContext: true,
    );
  }

  /// 复制并更新部分字段
  ChatConfig copyWith({
    String? systemPrompt,
    int? maxTokens,
    double? temperature,
    bool? useCurrentNoteContext,
  }) {
    return ChatConfig(
      systemPrompt: systemPrompt ?? this.systemPrompt,
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      useCurrentNoteContext: useCurrentNoteContext ?? this.useCurrentNoteContext,
    );
  }
}

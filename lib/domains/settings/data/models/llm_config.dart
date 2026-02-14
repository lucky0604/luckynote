/// LLM 配置模型
/// 包含 API 连接所需的所有信息
class LLMConfig {
  const LLMConfig({
    required this.provider,
    required this.baseUrl,
    required this.apiKey,
    required this.modelName,
  });

  /// API 提供商类型
  final LLMProvider provider;

  /// API 基础地址
  final String baseUrl;

  /// API 密钥
  final String apiKey;

  /// 模型名称
  final String modelName;

  /// 从 JSON 反序列化
  factory LLMConfig.fromJson(Map<String, dynamic> json) {
    return LLMConfig(
      provider: LLMProvider.fromString(json['provider'] as String),
      baseUrl: json['baseUrl'] as String,
      apiKey: json['apiKey'] as String,
      modelName: json['modelName'] as String,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'modelName': modelName,
    };
  }

  /// 复制并更新部分字段
  LLMConfig copyWith({
    LLMProvider? provider,
    String? baseUrl,
    String? apiKey,
    String? modelName,
  }) {
    return LLMConfig(
      provider: provider ?? this.provider,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName ?? this.modelName,
    );
  }

  /// 验证配置是否有效
  bool get isValid {
    return baseUrl.isNotEmpty && apiKey.isNotEmpty && modelName.isNotEmpty;
  }

  @override
  String toString() {
    return 'LLMConfig(provider: ${provider.name}, baseUrl: $baseUrl, modelName: $modelName)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LLMConfig &&
          provider == other.provider &&
          baseUrl == other.baseUrl &&
          apiKey == other.apiKey &&
          modelName == other.modelName;

  @override
  int get hashCode => Object.hash(provider, baseUrl, apiKey, modelName);
}

/// LLM 提供商类型
enum LLMProvider {
  openai,
  deepseek,
  ollama,
  custom;

  /// 从字符串转换
  static LLMProvider fromString(String value) {
    return LLMProvider.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LLMProvider.custom,
    );
  }

  /// 获取默认 Base URL
  String get defaultBaseUrl {
    switch (this) {
      case LLMProvider.openai:
        return 'https://api.openai.com/v1';
      case LLMProvider.deepseek:
        return 'https://api.deepseek.com/v1';
      case LLMProvider.ollama:
        return 'http://localhost:11434/v1';
      case LLMProvider.custom:
        return '';
    }
  }

  /// 获取默认模型名称
  String get defaultModel {
    switch (this) {
      case LLMProvider.openai:
        return 'gpt-4o';
      case LLMProvider.deepseek:
        return 'deepseek-chat';
      case LLMProvider.ollama:
        return 'llama2';
      case LLMProvider.custom:
        return '';
    }
  }
}

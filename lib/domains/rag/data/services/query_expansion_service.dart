import 'package:dio/dio.dart';
import 'package:luckynote/domains/settings/data/models/llm_config.dart';
import 'package:luckynote/domains/chat/data/services/openai_compatible_client.dart';

/// 查询扩展结果
class ExpansionResult {
  const ExpansionResult({
    required this.originalQuery,
    required this.expandedQuery,
    required this.keywords,
  });

  /// 原始查询
  final String originalQuery;

  /// 扩展后的查询（用于 FTS5 搜索）
  final String expandedQuery;

  /// 提取的关键词列表
  final List<String> keywords;
}

/// 查询扩展服务
/// 使用 LLM 扩展用户查询以提升搜索召回率
class QueryExpansionService {
  QueryExpansionService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// 扩展查询以包含同义词和相关术语
  ///
  /// [query] 原始用户查询
  /// [config] LLM 配置
  /// Returns 包含扩展查询和关键词的结果
  Future<ExpansionResult> expandQuery(
    String query,
    LLMConfig config,
  ) async {
    final prompt = _buildExpansionPrompt();

    try {
      final response = await OpenAICompatibleClient.getChatCompletionWithConfig(
        dio: _dio,
        config: config,
        messages: [
          {'role': 'system', 'content': prompt},
          {'role': 'user', 'content': query},
        ],
        temperature: 0.3, // 低温度以获得一致的输出
        maxTokens: 100,
      );

      final keywords = _parseExpansionResponse(response);
      final expandedQuery = keywords.join(' OR ');

      return ExpansionResult(
        originalQuery: query,
        expandedQuery: expandedQuery,
        keywords: keywords,
      );
    } catch (e) {
      // 如果扩展失败，回退到原始查询
      return ExpansionResult(
        originalQuery: query,
        expandedQuery: query,
        keywords: [query],
      );
    }
  }

  /// 构建查询扩展的系统提示词
  String _buildExpansionPrompt() {
    return '''你是一个搜索查询优化专家。你的任务是扩展用户的查询，添加相关关键词和同义词以改进全文搜索结果。

规则：
1. 从查询中提取 3-5 个核心关键词
2. 包含常见的同义词和相关术语
3. 同时考虑英文和中文术语
4. 仅输出关键词，用空格分隔
5. 不要包含解释或其他文本

示例：
查询: "如何解决界面卡顿？"
输出: "界面卡顿 性能优化 掉帧 Jank Performance lag"

查询: "UI lag"
输出: "UI lag performance jank frame rate 卡顿 掉帧 性能优化"''';
  }

  /// 解析 LLM 扩展响应
  List<String> _parseExpansionResponse(String response) {
    // 从 LLM 响应中提取关键词
    final cleaned = response.trim();
    final keywords = cleaned.split(RegExp(r'\s+'));

    // 去重并保持顺序
    final seen = <String>{};
    final unique = <String>[];

    for (final keyword in keywords) {
      final trimmed = keyword.trim();
      if (trimmed.isNotEmpty && !seen.contains(trimmed)) {
        seen.add(trimmed);
        unique.add(trimmed);
      }
    }

    return unique;
  }
}

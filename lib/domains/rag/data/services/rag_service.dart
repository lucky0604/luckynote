import 'dart:async';
import 'package:dio/dio.dart';

import 'package:luckynote/domains/settings/data/models/llm_config.dart';
import 'package:luckynote/database/database.dart';
import 'package:luckynote/domains/rag/data/services/document_service.dart';
import 'package:luckynote/domains/chat/data/services/openai_compatible_client.dart';
import '../models/rag_result.dart';
import 'query_expansion_service.dart';

/// RAG 服务
/// 协调整个 RAG 流程：查询扩展 -> 搜索 -> 生成答案
class RAGService {
  RAGService({
    required DocumentService documentService,
    QueryExpansionService? expansionService,
    Dio? dio,
  })  : _documentService = documentService,
        _expansionService = expansionService ?? QueryExpansionService(),
        _dio = dio ?? Dio();

  final DocumentService _documentService;
  final QueryExpansionService _expansionService;
  final Dio _dio;

  /// 执行 RAG 查询
  ///
  /// [query] 用户问题
  /// [config] LLM 配置
  /// [ragConfig] RAG 配置
  /// Returns 流式响应：先发送来源，再发送答案
  Stream<RAGChunk> query(
    String query,
    LLMConfig config,
    RAGConfig ragConfig,
  ) async* {
    try {
      // Step 1: 查询扩展（可选）
      String searchQuery = query;
      if (ragConfig.enableQueryExpansion) {
        final expansion = await _expansionService.expandQuery(query, config);
        searchQuery = expansion.expandedQuery;
      }

      // Step 2: 搜索相关切片
      final results = await _documentService.searchChunks(
        searchQuery,
        limit: ragConfig.topK,
      );

      if (results.isEmpty) {
        yield RAGChunk(
          content: '抱歉，我在笔记中没有找到相关信息。请尝试换个问法或检查笔记库是否有相关内容。',
          type: RAGChunkType.answer,
        );
        return;
      }

      // 发送来源信息
      yield RAGChunk(
        content: '',
        type: RAGChunkType.sources,
        sources: results
            .map((r) => RAGSource(
                  filePath: r.sourceFilePath,
                  title: r.title,
                  heading: r.heading ?? '',
                  content: r.content,
                  score: r.score,
                ))
            .toList(),
      );

      // Step 3: 构建上下文
      final context = _buildContext(results, ragConfig.maxContextLength);

      // Step 4: 生成答案（流式）
      final messages = [
        {
          'role': 'system',
          'content': _buildSystemPrompt(),
        },
        {
          'role': 'user',
          'content': _buildUserPrompt(query, context),
        },
      ];

      final stream = OpenAICompatibleClient.streamChatWithConfig(
        dio: _dio,
        config: config,
        messages: messages,
        temperature: ragConfig.temperature,
        maxTokens: ragConfig.maxTokens,
      );

      await for (final chunk in stream) {
        yield RAGChunk(
          content: chunk,
          type: RAGChunkType.answer,
        );
      }
    } catch (e) {
      yield RAGChunk(
        content: '查询出错: $e',
        type: RAGChunkType.error,
      );
    }
  }

  /// 从搜索结果构建上下文
  String _buildContext(List<NoteChunkResult> results, int maxLength) {
    final buffer = StringBuffer();
    var currentLength = 0;

    for (final result in results) {
      final chunk = '''
---
来源: ${result.title}
章节: ${result.heading ?? '未知'}
内容: ${result.content}
''';

      if (currentLength + chunk.length > maxLength) break;
      buffer.write(chunk);
      currentLength += chunk.length;
    }

    return buffer.toString();
  }

  /// 构建系统提示词
  String _buildSystemPrompt() {
    return '你是一个基于用户笔记的智能助手。请使用以下提供的笔记内容回答用户问题，若没有相关信息，请明确说明。';
  }

  /// 构建用户提示词
  String _buildUserPrompt(String query, String context) {
    return '''以下是与问题相关的笔记内容：

$context

问题: $query

请基于以上内容回答问题。''';
  }
}

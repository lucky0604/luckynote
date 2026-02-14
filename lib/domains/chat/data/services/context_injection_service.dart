import 'dart:io';

import 'package:luckynote/domains/rag/data/services/document_service.dart';
import 'package:luckynote/domains/chat/data/models/chat_context.dart';

/// 上下文注入服务
///
/// 负责读取不同类型上下文的实际内容，用于 AI Chat 的上下文增强
class ContextInjectionService {
  ContextInjectionService({
    required DocumentService documentService,
  }) : _documentService = documentService;

  final DocumentService _documentService;

  /// 为上下文列表准备内容
  ///
  /// [contexts] 用户选择的上下文列表
  /// [maxTotalLength] 最大总字符数限制
  /// 返回格式化的上下文内容字符串
  Future<ContextInjectionResult> prepareContexts(
    List<ChatContext> contexts, {
    int maxTotalLength = 8000,
  }) async {
    if (contexts.isEmpty) {
      return const ContextInjectionResult.empty();
    }

    final buffer = StringBuffer();
    final sources = <ContextSource>[];
    var currentLength = 0;

    for (final ctx in contexts) {
      // 跳过全库上下文（由 RAG 服务处理）
      if (ctx.type == ContextType.all) {
        continue;
      }

      final content = await _getContextContent(ctx);
      if (content == null || content.isEmpty) continue;

      final formatted = _formatContext(ctx, content);
      if (currentLength + formatted.length > maxTotalLength) {
        // 超出限制，截断
        final remaining = maxTotalLength - currentLength;
        if (remaining > 100) {
          buffer.write(formatted.substring(0, remaining));
          buffer.write('\n... (内容已截断)\n');
        }
        break;
      }

      buffer.write(formatted);
      currentLength += formatted.length;
      sources.add(ContextSource(
        type: ctx.type,
        id: ctx.id,
        displayName: ctx.displayName,
        contentLength: content.length,
      ));
    }

    return ContextInjectionResult(
      content: buffer.toString(),
      sources: sources,
      hasAllContext: contexts.any((c) => c.type == ContextType.all),
    );
  }

  /// 获取单个上下文的内容
  Future<String?> _getContextContent(ChatContext context) async {
    switch (context.type) {
      case ContextType.note:
        return _readNoteContent(context.id);

      case ContextType.folder:
        // 文件夹上下文：读取文件夹内所有笔记的摘要
        return _readFolderContent(context.id);

      case ContextType.tag:
        // 标签上下文：搜索带有该标签的笔记
        return _readTagContent(context.id);

      case ContextType.all:
        // 全库由 RAG 服务处理，这里返回空
        return null;
    }
  }

  /// 读取单个笔记内容
  Future<String?> _readNoteContent(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (e) {
      return null;
    }
  }

  /// 读取文件夹内笔记内容（摘要形式）
  Future<String?> _readFolderContent(String folderPath) async {
    try {
      final directory = Directory(folderPath);
      if (!await directory.exists()) return null;

      final buffer = StringBuffer();
      var noteCount = 0;
      const maxNotes = 5; // 限制读取的笔记数量

      await for (final entity in directory.list(recursive: false)) {
        if (entity is File && entity.path.endsWith('.md')) {
          if (noteCount >= maxNotes) {
            buffer.write('\n... (更多笔记已省略)\n');
            break;
          }

          try {
            final content = await entity.readAsString();
            final title = _extractTitle(content);
            final preview = _extractPreview(content, maxLength: 500);

            buffer.write('### $title\n');
            buffer.write('$preview\n\n');
            noteCount++;
          } catch (_) {
            continue;
          }
        }
      }

      return buffer.toString();
    } catch (e) {
      return null;
    }
  }

  /// 读取标签相关笔记内容
  Future<String?> _readTagContent(String tagName) async {
    // 通过搜索带有该标签的切片
    try {
      final results = await _documentService.searchChunks(
        '#$tagName',
        limit: 5,
      );

      if (results.isEmpty) return null;

      final buffer = StringBuffer();
      for (final result in results) {
        buffer.write('### ${result.title}\n');
        if (result.heading != null) {
          buffer.write('章节: ${result.heading}\n');
        }
        buffer.write('${result.content}\n\n');
      }

      return buffer.toString();
    } catch (e) {
      return null;
    }
  }

  /// 格式化上下文内容
  String _formatContext(ChatContext context, String content) {
    final typeLabel = _getTypeLabel(context.type);

    return '''
<context type="$typeLabel" name="${context.displayName}">
$content
</context>

''';
  }

  String _getTypeLabel(ContextType type) {
    switch (type) {
      case ContextType.note:
        return 'note';
      case ContextType.folder:
        return 'folder';
      case ContextType.tag:
        return 'tag';
      case ContextType.all:
        return 'all';
    }
  }

  /// 从内容中提取标题
  String _extractTitle(String content) {
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ')) {
        return trimmed.substring(2).trim();
      }
    }
    return '未命名笔记';
  }

  /// 提取预览内容
  String _extractPreview(String content, {int maxLength = 200}) {
    final trimmed = content.trim();
    if (trimmed.length <= maxLength) return trimmed;
    return '${trimmed.substring(0, maxLength)}...';
  }
}

/// 上下文注入结果
class ContextInjectionResult {
  const ContextInjectionResult({
    required this.content,
    required this.sources,
    required this.hasAllContext,
  });

  final String content;
  final List<ContextSource> sources;
  final bool hasAllContext;

  bool get isNotEmpty => content.isNotEmpty;

  const ContextInjectionResult.empty()
      : content = '',
        sources = const [],
        hasAllContext = false;
}

/// 上下文来源信息
class ContextSource {
  const ContextSource({
    required this.type,
    required this.id,
    required this.displayName,
    required this.contentLength,
  });

  final ContextType type;
  final String id;
  final String displayName;
  final int contentLength;
}

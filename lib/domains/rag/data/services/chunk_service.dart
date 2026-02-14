import 'package:drift/drift.dart';
import '../../../../database/database.dart';

/// 表示单个切片及其上下文信息
class Chunk {
  const Chunk({
    required this.headingPath,
    required this.content,
    required this.level,
  });

  /// 标题路径（如："2.1 Install > Windows"）
  final String headingPath;

  /// 切片内容
  final String content;

  /// 标题层级（1-6）
  final int level;

  /// 转换为 NoteChunksCompanion 对象（用于数据库插入）
  NoteChunksCompanion toNoteChunksCompanion(int documentId) {
    return NoteChunksCompanion.insert(
      documentId: documentId,
      heading: Value(headingPath),
      content: content,
      priority: Value(level),
    );
  }
}

/// 切片操作结果元数据
class ChunkMetadata {
  const ChunkMetadata({
    required this.totalChunks,
    required this.totalCharacters,
    required this.maxDepth,
  });

  /// 总切片数
  final int totalChunks;

  /// 总字符数
  final int totalCharacters;

  /// 最大标题层级深度
  final int maxDepth;
}

/// 切片操作结果
class ChunkResult {
  const ChunkResult({
    required this.chunks,
    required this.metadata,
  });

  /// 切片列表
  final List<Chunk> chunks;

  /// 元数据
  final ChunkMetadata metadata;
}

/// Markdown 文档切片服务
/// 基于标题层级进行语义切片，保持上下文信息
class ChunkService {
  /// 解析 Markdown 并按标题切片
  ///
  /// [markdown] Markdown 内容
  /// [maxChunkSize] 单个切片最大字符数（默认 1000）
  /// Returns 包含切片和元数据的结果
  ChunkResult chunkMarkdown(String markdown, {int maxChunkSize = 1000}) {
    final chunks = <Chunk>[];
    final headingStack = <String>[]; // 跟踪标题层级
    final currentContent = StringBuffer();
    var currentLevel = 0;
    var totalChars = 0;
    var maxDepth = 0;

    final lines = markdown.split('\n');

    for (final line in lines) {
      // 检测标题行
      final headingMatch = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);

      if (headingMatch != null) {
        // 保存前一个切片（如果有内容）
        if (currentContent.isNotEmpty) {
          chunks.add(_createChunk(
            headingStack,
            currentContent.toString().trim(),
            currentLevel,
          ));
          currentContent.clear();
        }

        // 更新标题栈
        final level = headingMatch.group(1)!.length;
        final headingText = headingMatch.group(2)!.trim();

        // 弹出栈到正确层级
        while (headingStack.length >= level) {
          headingStack.removeLast();
        }
        headingStack.add(headingText);

        currentLevel = level;
        maxDepth = maxDepth > level ? maxDepth : level;
      } else {
        // 添加到当前内容
        currentContent.writeln(line);
        totalChars += line.length + 1;

        // 如果内容过长，按段落分割
        if (currentContent.length > maxChunkSize) {
          final paragraphs = currentContent.toString().split('\n\n');
          if (paragraphs.length > 1) {
            // 保存完整段落
            for (var i = 0; i < paragraphs.length - 1; i++) {
              final trimmed = paragraphs[i].trim();
              if (trimmed.isNotEmpty) {
                chunks.add(_createChunk(
                  headingStack,
                  trimmed,
                  currentLevel,
                ));
              }
            }
            // 保留最后一个段落作为当前内容
            currentContent.clear();
            currentContent.write(paragraphs.last);
          }
        }
      }
    }

    // 添加最后一个切片
    if (currentContent.isNotEmpty) {
      chunks.add(_createChunk(
        headingStack,
        currentContent.toString().trim(),
        currentLevel,
      ));
    }

    return ChunkResult(
      chunks: chunks,
      metadata: ChunkMetadata(
        totalChunks: chunks.length,
        totalCharacters: totalChars,
        maxDepth: maxDepth,
      ),
    );
  }

  /// 创建切片对象
  Chunk _createChunk(List<String> headingStack, String content, int level) {
    final headingPath = headingStack.isNotEmpty
        ? headingStack.join(' > ')
        : '简介';

    return Chunk(
      headingPath: headingPath,
      content: content,
      level: level,
    );
  }
}

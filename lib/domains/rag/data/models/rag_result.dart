/// RAG 响应数据块类型
enum RAGChunkType {
  /// AI 回答内容
  answer,

  /// 来源引用
  sources,

  /// 错误信息
  error,
}

/// RAG 响应数据块
/// 用于流式传输 RAG 查询结果
class RAGChunk {
  const RAGChunk({
    required this.content,
    required this.type,
    this.sources = const [],
  });

  /// 内容文本
  final String content;

  /// 数据块类型
  final RAGChunkType type;

  /// 来源引用列表（仅当 type 为 sources 时有值）
  final List<RAGSource> sources;
}

/// RAG 来源引用
/// 表示搜索结果中的一个文档切片
class RAGSource {
  const RAGSource({
    required this.filePath,
    required this.title,
    required this.heading,
    required this.content,
    required this.score,
  });

  /// 来源文件路径
  final String filePath;

  /// 文档标题
  final String title;

  /// 所属章节标题
  final String heading;

  /// 切片内容
  final String content;

  /// BM25 相关性评分（越低越相关）
  final double score;
}

/// RAG 查询配置
class RAGConfig {
  const RAGConfig({
    this.enableQueryExpansion = false, // 默认禁用，避免额外 API 调用
    this.topK = 10,
    this.maxContextLength = 4000,
    this.temperature = 0.7,
    this.maxTokens = 2000,
  });

  /// 是否启用查询扩展
  final bool enableQueryExpansion;

  /// 返回的最大结果数量
  final int topK;

  /// 最大上下文长度（字符数）
  final int maxContextLength;

  /// LLM 温度参数
  final double temperature;

  /// LLM 最大 token 数
  final int maxTokens;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/rag_result.dart';
import '../../data/services/rag_service.dart';
import '../../data/repositories/rag_repository.dart';
import '../../../shared_infra/providers/database_provider.dart';
import '../../../settings/presentation/providers/llm_config_provider.dart';

/// RAG 查询状态
class RAGState {
  const RAGState({
    this.query = '',
    this.isSearching = false,
    this.isStreaming = false,
    this.answer = '',
    this.sources = const [],
    this.error,
  });

  final String query;
  final bool isSearching;
  final bool isStreaming;
  final String answer;
  final List<RAGSource> sources;
  final String? error;

  RAGState copyWith({
    String? query,
    bool? isSearching,
    bool? isStreaming,
    String? answer,
    List<RAGSource>? sources,
    String? error,
    bool clearError = false,
  }) {
    return RAGState(
      query: query ?? this.query,
      isSearching: isSearching ?? this.isSearching,
      isStreaming: isStreaming ?? this.isStreaming,
      answer: answer ?? this.answer,
      sources: sources ?? this.sources,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// RAG 状态管理器
class RAGNotifier extends StateNotifier<RAGState> {
  RAGNotifier(this._ref) : super(const RAGState());

  final Ref _ref;
  late final RAGService _ragService;

  void init() {
    final documentService = _ref.read(documentServiceProvider);
    _ragService = RAGService(documentService: documentService);
  }

  /// 提交 RAG 查询
  Future<void> submitQuery(
    String query, {
    bool enableExpansion = true,
  }) async {
    final config = _ref.read(llmConfigProvider);
    if (config == null || !config.isValid) {
      state = state.copyWith(
        error: '请先配置 LLM API',
      );
      return;
    }

    state = state.copyWith(
      query: query,
      isSearching: true,
      isStreaming: true,
      answer: '',
      sources: [],
      error: null,
    );

    try {
      final ragConfig = RAGConfig(
        enableQueryExpansion: enableExpansion,
        topK: 10,
        maxContextLength: 4000,
      );

      final answerBuffer = StringBuffer();
      var sourcesReceived = false;

      await for (final chunk in _ragService.query(query, config, ragConfig)) {
        if (chunk.type == RAGChunkType.sources && !sourcesReceived) {
          state = state.copyWith(sources: chunk.sources);
          sourcesReceived = true;
        } else if (chunk.type == RAGChunkType.answer) {
          answerBuffer.write(chunk.content);
          state = state.copyWith(answer: answerBuffer.toString());
        } else if (chunk.type == RAGChunkType.error) {
          state = state.copyWith(
            error: chunk.content,
            isStreaming: false,
          );
        }
      }

      state = state.copyWith(
        isSearching: false,
        isStreaming: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: '查询失败: $e',
        isSearching: false,
        isStreaming: false,
      );
    }
  }

  /// 清空当前查询
  void clearQuery() {
    state = const RAGState();
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// RAG Provider
final ragNotifierProvider = StateNotifierProvider<RAGNotifier, RAGState>((ref) {
  final notifier = RAGNotifier(ref);
  notifier.init();
  return notifier;
});

/// RAG 统计信息 Provider
final ragStatsProvider = FutureProvider<RAGStats>((ref) async {
  final database = ref.watch(databaseProvider);
  final repository = RAGRepository(database);
  return await repository.getStats();
});

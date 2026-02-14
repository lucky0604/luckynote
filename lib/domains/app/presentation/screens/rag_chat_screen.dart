import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luckynote/domains/rag/data/models/rag_result.dart';
import 'package:luckynote/domains/rag/presentation/providers/rag_provider.dart';
import '../widgets/rag/source_card.dart';

/// RAG 聊天搜索屏幕
class RAGChatScreen extends ConsumerStatefulWidget {
  const RAGChatScreen({super.key});

  @override
  ConsumerState<RAGChatScreen> createState() => _RAGChatScreenState();
}

class _RAGChatScreenState extends ConsumerState<RAGChatScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  bool _enableExpansion = true;

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final query = _textController.text.trim();
    if (query.isEmpty) return;

    ref.read(ragNotifierProvider.notifier).submitQuery(
      query,
      enableExpansion: _enableExpansion,
    );
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ragNotifierProvider);
    final stats = ref.watch(ragStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(LucideIcons.search, size: 18),
            SizedBox(width: 8),
            Text('知识库搜索', style: TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          // 查询扩展开关
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Text('智能扩展', style: TextStyle(fontSize: 12)),
                Switch(
                  value: _enableExpansion,
                  onChanged: (value) {
                    setState(() => _enableExpansion = value);
                  },
                ),
              ],
            ),
          ),
          // 统计信息显示
          if (stats.valueOrNull != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  '已索引 ${stats.valueOrNull!.documentCount} 篇',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 消息区域
          Expanded(
            child: state.answer.isEmpty && state.sources.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 用户查询气泡
                        if (state.query.isNotEmpty) _buildQueryBubble(state.query),
                        if (state.query.isNotEmpty) const SizedBox(height: 16),

                        // AI 回答
                        if (state.answer.isNotEmpty) _buildAnswerBubble(state.answer, state.isStreaming),

                        // 来源引用
                        if (state.sources.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            '参考来源',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...state.sources.map((source) => SourceCard(
                            source: source,
                            onTap: () => _openSource(source),
                          )),
                        ],
                      ],
                    ),
                  ),
          ),

          // 错误横幅
          if (state.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(LucideIcons.xCircle, size: 16, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 14, color: Colors.red[700]),
                    onPressed: () {
                      ref.read(ragNotifierProvider.notifier).clearError();
                    },
                  ),
                ],
              ),
            ),

          // 输入区域
          _buildInputArea(state.isSearching || state.isStreaming),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.search, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '搜索你的笔记',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '输入问题，AI 会基于你的笔记回答',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildQueryBubble(String query) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(
          query,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAnswerBubble(String answer, bool isStreaming) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'AI 回答',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(answer),
          if (isStreaming) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  '正在生成...',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: '输入问题...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _handleSubmit(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: isLoading ? null : _handleSubmit,
            icon: Icon(
              isLoading ? Icons.hourglass_empty : Icons.send,
              color: isLoading ? Colors.grey : Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _openSource(RAGSource source) {
    // 导航到笔记并高亮显示
    Navigator.of(context).pop(source.filePath);
  }
}

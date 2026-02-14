import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/association/data/models/graph_node.dart';
import 'package:luckynote/domains/association/presentation/providers/local_graph_provider.dart';
import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';
import 'graph_canvas.dart';
import 'graph_legend.dart';

/// Local Graph View - visualizes note relationships.
class LocalGraphView extends ConsumerStatefulWidget {
  const LocalGraphView({super.key});

  @override
  ConsumerState<LocalGraphView> createState() => _LocalGraphViewState();
}

class _LocalGraphViewState extends ConsumerState<LocalGraphView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  GraphNode? _selectedNode;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localGraphProvider);
    final currentNote = ref.watch(currentNoteProvider);

    if (currentNote == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(state, ref),
          const SizedBox(height: 12),
          Expanded(
            child: _buildGraphContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(LocalGraphState state, WidgetRef ref) {
    return Row(
      children: [
        Icon(LucideIcons.network, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '关联图谱',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        if (state.graphData != null && state.graphData!.nodes.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accentSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${state.graphData!.nodes.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.accentSecondary,
              ),
            ),
          ),
        ],
        const Spacer(),
        // Legend
        const GraphLegend(),
        const SizedBox(width: 8),
        // Refresh button
        IconButton(
          icon: Icon(
            state.isLoading ? LucideIcons.loader2 : LucideIcons.refreshCw,
            size: 14,
            color: AppColors.textSecondary,
          ),
          onPressed: state.isLoading
              ? null
              : () => ref.read(localGraphProvider.notifier).refresh(),
          tooltip: '刷新',
          style: IconButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.all(6),
            minimumSize: const Size(28, 28),
          ),
        ),
      ],
    );
  }

  Widget _buildGraphContent(LocalGraphState state) {
    if (state.isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 24, color: AppColors.error),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final graphData = state.graphData;
    if (graphData == null || graphData.nodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.network,
              size: 32,
              color: AppColors.textPlaceholder,
            ),
            const SizedBox(height: 8),
            Text(
              '暂无关联图谱',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPlaceholder,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _animationController,
      child: _GraphPainterWidget(
        graphData: graphData,
        onNodeTap: _handleNodeTap,
        selectedNode: _selectedNode,
      ),
    );
  }

  void _handleNodeTap(GraphNode node) {
    setState(() {
      _selectedNode = _selectedNode == node ? null : node;
    });

    // Navigate to the note if it has a file path
    if (node.filePath != null) {
      ref.read(editorProvider.notifier).openNoteByPath(node.filePath!);
    }
  }
}

/// Wrapper widget for graph canvas.
class _GraphPainterWidget extends StatelessWidget {
  const _GraphPainterWidget({
    required this.graphData,
    required this.onNodeTap,
    this.selectedNode,
  });

  final GraphData graphData;
  final void Function(GraphNode) onNodeTap;
  final GraphNode? selectedNode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GraphCanvas(
          graphData: graphData,
          size: Size(constraints.maxWidth, constraints.maxHeight),
          onNodeTap: onNodeTap,
          selectedNode: selectedNode,
        );
      },
    );
  }
}

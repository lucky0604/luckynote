import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';
import 'unlinked_mentions_panel.dart';
import 'graph/local_graph_view.dart';

/// Association Panel - tab container for mentions and graph views
class AssociationPanel extends ConsumerStatefulWidget {
  const AssociationPanel({super.key});

  @override
  ConsumerState<AssociationPanel> createState() => _AssociationPanelState();
}

enum _AssociationTab { mentions, graph }

class _AssociationPanelState extends ConsumerState<AssociationPanel>
    with SingleTickerProviderStateMixin {
  _AssociationTab _currentTab = _AssociationTab.mentions;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
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
    final currentNote = ref.watch(currentNoteProvider);

    if (currentNote == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabBar(),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: SizedBox(
              height: _currentTab == _AssociationTab.graph ? 280 : null,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildCurrentTab(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildTabButton(
            label: '未关联的提及',
            icon: LucideIcons.search,
            tab: _AssociationTab.mentions,
          ),
          const SizedBox(width: 8),
          _buildTabButton(
            label: '关联图谱',
            icon: LucideIcons.network,
            tab: _AssociationTab.graph,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required _AssociationTab tab,
  }) {
    final isSelected = _currentTab == tab;

    return GestureDetector(
      onTap: () => _switchTab(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case _AssociationTab.mentions:
        return const UnlinkedMentionsPanel();
      case _AssociationTab.graph:
        return const LocalGraphView();
    }
  }

  void _switchTab(_AssociationTab newTab) {
    if (_currentTab == newTab) return;

    setState(() {
      _currentTab = newTab;
    });

    // Restart animation for smooth transition
    _animationController.reset();
    _animationController.forward();
  }
}

/// Standalone unlinked mentions panel for use in other contexts
class UnlinkedMentionsPanelStandalone extends ConsumerWidget {
  const UnlinkedMentionsPanelStandalone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentNote = ref.watch(currentNoteProvider);

    if (currentNote == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: const UnlinkedMentionsPanel(),
    );
  }
}

/// Standalone graph view for use in other contexts
class LocalGraphViewStandalone extends ConsumerWidget {
  const LocalGraphViewStandalone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentNote = ref.watch(currentNoteProvider);

    if (currentNote == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      height: 280,
      child: const LocalGraphView(),
    );
  }
}

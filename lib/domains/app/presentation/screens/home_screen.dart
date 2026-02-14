import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:luckynote/domains/editor/presentation/providers/editor_provider.dart';
import 'package:luckynote/domains/notes/presentation/providers/notes_provider.dart';
import 'package:luckynote/domains/chat/presentation/providers/chat_provider.dart';
import '../widgets/common/indexing_progress_overlay.dart';
import '../widgets/editor/editor_panel.dart';
import '../widgets/navigation_panel.dart';
import '../widgets/layout/resizable_layout.dart';
import '../widgets/sidebar/sidebar.dart';
import '../widgets/chat/chat_sidebar.dart';
import '../widgets/global_search/global_search_dialog.dart';

/// 侧边栏显示状态 Provider
final sidebarVisibleProvider = StateProvider<bool>((ref) => true);

/// 主界面
/// 采用两栏布局：Sidebar + Editor
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _createNewNote() async {
    final note = await ref.read(notesProvider.notifier).createNote();
    if (note != null) {
      ref.read(editorProvider.notifier).openNote(note);
    }
  }

  Future<void> _saveCurrentNote() async {
    await ref.read(editorProvider.notifier).saveCurrentNote();
  }

  void _openChatSidebar() {
    // 更新当前笔记上下文
    final currentNote = ref.read(currentNoteProvider);
    ref.read(chatNotifierProvider.notifier).setCurrentNote(currentNote);

    // 打开 AI 侧边栏（从右侧滑入）
    showChatSidebar(context);
  }

  void _showGlobalSearch() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const GlobalSearchDialog(),
    );
  }

  Future<void> _closeCurrentNote() async {
    final editorState = ref.read(editorProvider);
    if (editorState.currentNote != null) {
      await ref.read(editorProvider.notifier).closeNote();
    }
  }

  void _toggleSidebar() {
    // 切换侧边栏显示状态
    ref.read(sidebarVisibleProvider.notifier).state = 
        !ref.read(sidebarVisibleProvider);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        // Cmd/Ctrl + N: 新建笔记
        SingleActivator(
          LogicalKeyboardKey.keyN,
          meta: Theme.of(context).platform == TargetPlatform.macOS,
          control: Theme.of(context).platform != TargetPlatform.macOS,
        ): _createNewNote,
        // Cmd/Ctrl + W: 关闭当前笔记
        SingleActivator(
          LogicalKeyboardKey.keyW,
          meta: Theme.of(context).platform == TargetPlatform.macOS,
          control: Theme.of(context).platform != TargetPlatform.macOS,
        ): _closeCurrentNote,
        // Cmd/Ctrl + \: 切换侧边栏
        SingleActivator(
          LogicalKeyboardKey.backslash,
          meta: Theme.of(context).platform == TargetPlatform.macOS,
          control: Theme.of(context).platform != TargetPlatform.macOS,
        ): _toggleSidebar,
        // Cmd/Ctrl + S: 保存
        SingleActivator(
          LogicalKeyboardKey.keyS,
          meta: Theme.of(context).platform == TargetPlatform.macOS,
          control: Theme.of(context).platform != TargetPlatform.macOS,
        ): _saveCurrentNote,
        // Cmd/Ctrl + J: 打开 AI 侧边栏
        SingleActivator(
          LogicalKeyboardKey.keyJ,
          meta: Theme.of(context).platform == TargetPlatform.macOS,
          control: Theme.of(context).platform != TargetPlatform.macOS,
        ): _openChatSidebar,
        // Cmd/Ctrl + P: 全局搜索
        SingleActivator(
          LogicalKeyboardKey.keyP,
          meta: Theme.of(context).platform == TargetPlatform.macOS,
          control: Theme.of(context).platform != TargetPlatform.macOS,
        ): _showGlobalSearch,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Stack(
            children: [
              ResizableLayout(
                sidebar: ref.watch(sidebarVisibleProvider) 
                    ? const Sidebar() 
                    : const SizedBox.shrink(),
                noteList: const NavigationPanel(),
                editor: const EditorPanel(),
              ),
              // 索引进度遮罩
              const IndexingProgressOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

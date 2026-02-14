import 'dart:ui';

import 'package:flutter/material.dart';
import './components/glassmorphism_container.dart';
import 'chat_sidebar_content.dart';

/// 聊天侧边栏默认宽度
const double kChatSidebarWidth = 360.0;
const double kChatSidebarMinWidth = 300.0;
const double kChatSidebarMaxWidthRatio = 0.5;

/// AI 聊天侧边栏（Glassmorphism 版本）
///
/// 根据 ai_chat.md 规格设计：
/// - 位置：屏幕最右侧
/// - 宽度：默认 360px
/// - 背景：毛玻璃效果
/// - 层级：Overlay 覆盖在编辑器之上
class ChatSidebar extends StatelessWidget {
  const ChatSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * kChatSidebarMaxWidthRatio;
    final sidebarWidth = kChatSidebarWidth.clamp(kChatSidebarMinWidth, maxWidth);

    return Material(
      type: MaterialType.transparency,
      child: GlassmorphismContainer(
        borderRadius: 0,
        blur: 20,
        opacity: 0.92,
        child: SizedBox(
          width: sidebarWidth,
          child: const ChatSidebarContent(),
        ),
      ),
    );
  }
}

/// 显示聊天侧边栏
///
/// 使用 showGeneralDialog 实现右侧滑入效果
/// 根据 ai_chat.md 规格：
/// - 点击顶部 ✨ 图标，右侧平滑滑出毛玻璃侧边栏
/// - 点击外部关闭
Future<void> showChatSidebar(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Chat Sidebar',
    barrierColor: Colors.black.withValues(alpha: 0.3),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: const ChatSidebar(),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // 从右侧滑入的动画
      final slideAnimation = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ));

      return SlideTransition(
        position: slideAnimation,
        child: child,
      );
    },
  );
}

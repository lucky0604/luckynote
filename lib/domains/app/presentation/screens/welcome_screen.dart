import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../../../../app/router.dart';
import 'package:luckynote/app/theme/app_colors.dart';
import '../../../notes/presentation/providers/vault_provider.dart';

/// 欢迎页面
/// 首次启动时让用户选择笔记仓库目录，包含功能介绍轮播
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isSelecting = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  /// 功能特性列表
  static const List<_FeatureItem> _features = [
    _FeatureItem(
      icon: LucideIcons.hardDrive,
      title: '本地优先',
      description: '您的笔记以 Markdown 文件存储在本地\n完全掌控自己的数据，无需担心隐私',
    ),
    _FeatureItem(
      icon: LucideIcons.link,
      title: '双向链接',
      description: '使用 [[WikiLink]] 语法连接笔记\n构建个人知识网络，发现隐藏关联',
    ),
    _FeatureItem(
      icon: LucideIcons.sparkles,
      title: 'AI 助手',
      description: '内置智能助手帮助整理和扩展思路\n支持多种 LLM 模型，本地运行更安全',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 打开现有仓库
  Future<void> _openExistingVault() async {
    if (_isSelecting) return;

    setState(() => _isSelecting = true);

    try {
      final String? directoryPath = await getDirectoryPath(
        confirmButtonText: '打开此文件夹',
      );

      if (directoryPath != null && mounted) {
        await ref.read(vaultProvider.notifier).setVaultPath(directoryPath);

        if (mounted) {
          context.go(AppRoutes.home);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开文件夹失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSelecting = false);
      }
    }
  }

  /// 创建新仓库
  Future<void> _createNewVault() async {
    if (_isSelecting) return;

    setState(() => _isSelecting = true);

    try {
      final String? directoryPath = await getDirectoryPath(
        confirmButtonText: '在此创建仓库',
      );

      if (directoryPath != null && mounted) {
        // 创建欢迎笔记
        await _createWelcomeNote(directoryPath);

        await ref.read(vaultProvider.notifier).setVaultPath(directoryPath);

        if (mounted) {
          context.go(AppRoutes.home);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建仓库失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSelecting = false);
      }
    }
  }

  /// 在新仓库中创建欢迎笔记
  Future<void> _createWelcomeNote(String vaultPath) async {
    final welcomeContent = '''# 欢迎使用 LuckyNote

恭喜你开启了个人知识管理的新旅程！

## 快速入门

### 创建笔记
- 按 **Cmd/Ctrl + N** 快速创建新笔记
- 点击侧边栏的 **+** 按钮创建笔记

### 双向链接
使用 `[[笔记标题]]` 语法创建链接到其他笔记：
- 输入 `[[` 会弹出笔记选择器
- 点击链接可以快速跳转

### 标签系统
使用 `#标签名` 来组织笔记，例如：#入门 #教程

### AI 助手
- 按 **Cmd/Ctrl + J** 打开 AI 助手
- 在设置中配置您的 API Key

### 全局搜索
- 按 **Cmd/Ctrl + P** 打开全局搜索
- 快速找到任何笔记

## 下一步
- [ ] 创建你的第一篇笔记
- [ ] 尝试使用双向链接
- [ ] 探索 AI 助手功能

祝你笔记愉快！
''';

    final welcomeFile = File(p.join(vaultPath, '欢迎使用 LuckyNote.md'));
    await welcomeFile.writeAsString(welcomeContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.background, const Color(0xFFFFF5EE)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo 区域
                        _buildLogo(),
                        const SizedBox(height: 24),

                        // 标题
                        Text(
                          '欢迎使用 LuckyNote',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // 副标题
                        Text(
                          '本地优先的个人知识库与 AI 助手',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // 功能特性轮播
                        _buildFeatureCarousel(),
                        const SizedBox(height: 32),

                        // 操作按钮区域
                        _buildActionButtons(),
                        const SizedBox(height: 16),

                        // 提示文字
                        Text(
                          '您的数据完全存储在本地，我们不会收集任何信息',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textPlaceholder,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Icon(LucideIcons.bookOpen, size: 48, color: AppColors.accent),
    );
  }

  Widget _buildFeatureCarousel() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _features.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final feature = _features[index];
                return _buildFeatureCard(feature);
              },
            ),
          ),
          const SizedBox(height: 16),
          // 页面指示器
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _features.length,
              (index) => GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.accent
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureItem feature) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(feature.icon, size: 32, color: AppColors.accent),
          const SizedBox(height: 12),
          Text(
            feature.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              feature.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        children: [
          // 创建新仓库按钮（主要操作）
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSelecting ? null : _createNewVault,
              icon: _isSelecting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.folderPlus, size: 18),
              label: const Text('创建新仓库'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 打开现有仓库按钮（次要操作）
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSelecting ? null : _openExistingVault,
              icon: const Icon(LucideIcons.folderOpen, size: 18),
              label: const Text('打开现有仓库'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.border, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 功能特性数据模型
class _FeatureItem {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

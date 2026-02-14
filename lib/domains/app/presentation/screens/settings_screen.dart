import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../widgets/settings/theme_selector.dart';
import '../widgets/settings/font_settings_section.dart';
import '../widgets/settings/layout_settings_section.dart';
import '../widgets/settings/llm/llm_settings_section.dart';

/// 设置页面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ThemeSelector(),
          SizedBox(height: 16),
          FontSettingsSection(),
          SizedBox(height: 16),
          LayoutSettingsSection(),
          SizedBox(height: 16),
          LLMSettingsSection(),
        ],
      ),
    );
  }
}

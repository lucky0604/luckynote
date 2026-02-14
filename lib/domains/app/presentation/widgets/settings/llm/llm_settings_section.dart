import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:luckynote/domains/settings/data/models/llm_config.dart';
import 'package:luckynote/domains/chat/data/services/openai_compatible_client.dart';
import 'package:luckynote/domains/settings/presentation/providers/llm_config_provider.dart';
import 'llm_config_form.dart';

/// AI 设置组件
class LLMSettingsSection extends ConsumerStatefulWidget {
  const LLMSettingsSection({super.key});

  @override
  ConsumerState<LLMSettingsSection> createState() => _LLMSettingsSectionState();
}

class _LLMSettingsSectionState extends ConsumerState<LLMSettingsSection> {
  final _configFormKey = GlobalKey<LLMConfigFormState>();
  LLMProvider _selectedProvider = LLMProvider.deepseek;
  bool _isTesting = false;
  bool? _testResult;
  LLMConfig? _currentConfig;

  @override
  void initState() {
    super.initState();
    _loadInitialConfig();
  }

  Future<void> _loadInitialConfig() async {
    final config = ref.read(llmConfigProvider);
    if (config != null) {
      setState(() {
        _selectedProvider = config.provider;
        _currentConfig = config;
      });
    }
  }

  void _handleProviderChanged(LLMProvider provider) {
    setState(() {
      _selectedProvider = provider;
      _testResult = null;
      // Update defaults
      if (_currentConfig == null || _currentConfig!.provider != provider) {
        _currentConfig = LLMConfig(
          provider: provider,
          baseUrl: provider.defaultBaseUrl,
          apiKey: '',
          modelName: provider.defaultModel,
        );
      }
    });
  }

  Future<void> _saveConfig() async {
    final formState = _configFormKey.currentState;
    if (formState == null) {
      _showSnackBar('表单状态异常', Colors.red);
      return;
    }
    
    if (!formState.validateForm()) {
      _showSnackBar('请填写所有必填字段', Colors.orange);
      return;
    }

    final config = formState.currentConfig;

    try {
      final success = await ref
          .read(llmConfigNotifierProvider.notifier)
          .saveConfig(config);

      if (success && mounted) {
        _showSnackBar('配置已保存', Colors.green);
      } else if (mounted) {
        _showSnackBar('保存失败', Colors.red);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('保存异常: $e', Colors.red);
      }
    }
  }

  Future<void> _testConnection() async {
    final formState = _configFormKey.currentState;
    if (formState == null) {
      _showSnackBar('表单状态异常', Colors.red);
      return;
    }

    if (!formState.validateForm()) {
      _showSnackBar('请填写所有必填字段', Colors.orange);
      return;
    }

    final config = formState.currentConfig;

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final dio = Dio();
      final success = await OpenAICompatibleClient.testConnectionWithConfig(
        dio: dio,
        config: config,
      );

      if (!mounted) return;

      setState(() {
        _isTesting = false;
        _testResult = success;
      });

      if (success) {
        await ref
            .read(llmConfigNotifierProvider.notifier)
            .saveConfig(config);

        if (!mounted) return;
        _showSnackBar('✅ 连接成功！配置已自动保存', Colors.green);
      } else {
        if (!mounted) return;
        _showSnackBar(
          '❌ 连接失败\nURL: ${config.baseUrl}/chat/completions\nModel: ${config.modelName}',
          Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTesting = false;
        _testResult = false;
      });
      _showSnackBar('测试异常: $e', Colors.red);
    }
  }

  Future<void> _clearConfig() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除配置'),
        content: const Text('确定要清除所有 AI 配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(llmConfigNotifierProvider.notifier).clearConfig();
      if (mounted) {
        setState(() {
          _currentConfig = LLMConfig(
            provider: _selectedProvider,
            baseUrl: _selectedProvider.defaultBaseUrl,
            apiKey: '',
            modelName: _selectedProvider.defaultModel,
          );
          _testResult = null;
        });
        _showSnackBar('配置已清除', Colors.grey);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: color == Colors.red ? const Duration(seconds: 5) : const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, size: 20),
                const SizedBox(width: 12),
                Text(
                  'AI 模型配置',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LLMConfigForm(
              key: _configFormKey,
              selectedProvider: _selectedProvider,
              onProviderChanged: _handleProviderChanged,
              onTest: _testConnection,
              onSave: _saveConfig,
              isTesting: _isTesting,
              testResult: _testResult,
              initialConfig: _currentConfig,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearConfig,
                icon: const Icon(Icons.delete_outline, size: 14),
                label: const Text('清除配置'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

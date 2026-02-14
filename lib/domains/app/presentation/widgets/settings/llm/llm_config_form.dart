import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/domains/settings/data/models/llm_config.dart';
import 'llm_connection_tester.dart';
import 'llm_provider_selector.dart';

/// LLM configuration form.
///
/// Contains the form fields for configuring the LLM connection.
class LLMConfigForm extends ConsumerStatefulWidget {
  const LLMConfigForm({
    super.key,
    required this.selectedProvider,
    required this.onProviderChanged,
    required this.onTest,
    required this.onSave,
    this.isTesting = false,
    this.testResult,
    this.initialConfig,
  });

  final LLMProvider selectedProvider;
  final ValueChanged<LLMProvider> onProviderChanged;
  final VoidCallback onTest;
  final VoidCallback onSave;
  final bool isTesting;
  final bool? testResult;
  final LLMConfig? initialConfig;

  @override
  ConsumerState<LLMConfigForm> createState() => LLMConfigFormState();
}

class LLMConfigFormState extends ConsumerState<LLMConfigForm> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelNameController;
  bool _obscureApiKey = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(text: widget.initialConfig?.baseUrl);
    _apiKeyController = TextEditingController(text: widget.initialConfig?.apiKey);
    _modelNameController = TextEditingController(text: widget.initialConfig?.modelName);
  }

  @override
  void didUpdateWidget(LLMConfigForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialConfig != oldWidget.initialConfig && widget.initialConfig != null) {
      _baseUrlController.text = widget.initialConfig!.baseUrl;
      _modelNameController.text = widget.initialConfig!.modelName;
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }

  LLMConfig get currentConfig => LLMConfig(
    provider: widget.selectedProvider,
    baseUrl: _baseUrlController.text.trim(),
    apiKey: _apiKeyController.text.trim(),
    modelName: _modelNameController.text.trim(),
  );

  bool validateForm() {
    return _formKey.currentState?.validate() ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LLMProviderSelector(
            selectedProvider: widget.selectedProvider,
            onChanged: widget.onProviderChanged,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _baseUrlController,
            label: 'Base URL',
            hint: 'https://api.deepseek.com',
            icon: LucideIcons.link,
            validator: (value) {
              if (value == null || value.isEmpty) return '请输入 Base URL';
              if (!value.startsWith('http')) return '必须以 http:// 或 https:// 开头';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _apiKeyController,
            label: 'API Key',
            hint: 'sk-...',
            icon: LucideIcons.key,
            obscureText: _obscureApiKey,
            suffixIcon: IconButton(
              icon: Icon(_obscureApiKey ? LucideIcons.eye : LucideIcons.eyeOff, size: 18),
              onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return '请输入 API Key';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _modelNameController,
            label: 'Model Name',
            hint: 'deepseek-chat',
            icon: LucideIcons.cpu,
            validator: (value) {
              if (value == null || value.isEmpty) return '请输入模型名称';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ConnectionTestButton(
                isTesting: widget.isTesting,
                onPressed: () {
                  if (validateForm()) widget.onTest();
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    if (validateForm()) widget.onSave();
                  },
                  icon: const Icon(LucideIcons.save, size: 16),
                  label: const Text('保存配置'),
                ),
              ),
            ],
          ),
          if (widget.testResult != null) ...[
            const SizedBox(height: 8),
            ConnectionTestResult(result: widget.testResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      obscureText: obscureText,
      validator: validator,
    );
  }
}

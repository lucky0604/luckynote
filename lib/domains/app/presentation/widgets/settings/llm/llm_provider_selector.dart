import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/domains/settings/data/models/llm_config.dart';

/// Provider selector dropdown for LLM settings.
///
/// Allows users to select which LLM provider to use.
class LLMProviderSelector extends StatelessWidget {
  const LLMProviderSelector({
    super.key,
    required this.selectedProvider,
    required this.onChanged,
  });

  final LLMProvider selectedProvider;
  final ValueChanged<LLMProvider> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<LLMProvider>(
      initialValue: selectedProvider,
      decoration: InputDecoration(
        labelText: 'Provider',
        prefixIcon: const Icon(LucideIcons.cloud, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: LLMProvider.values.map((provider) {
        return DropdownMenuItem(
          value: provider,
          child: Text(provider.name.toUpperCase()),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

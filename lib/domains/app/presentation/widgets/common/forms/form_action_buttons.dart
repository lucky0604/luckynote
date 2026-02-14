import 'package:flutter/material.dart';

/// Standard form action buttons for save/cancel/test patterns.
///
/// Based on the pattern from llm_settings_section.dart.
class FormActionButtons extends StatelessWidget {
  const FormActionButtons({
    super.key,
    this.primaryLabel = '保存',
    this.secondaryLabel,
    this.tertiaryLabel,
    this.onPrimary,
    this.onSecondary,
    this.onTertiary,
    this.primaryIcon,
    this.secondaryIcon,
    this.tertiaryIcon,
    this.isPrimaryLoading = false,
    this.isPrimaryEnabled = true,
    this.isSecondaryEnabled = true,
  });

  final String primaryLabel;
  final String? secondaryLabel;
  final String? tertiaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;
  final VoidCallback? onTertiary;
  final IconData? primaryIcon;
  final IconData? secondaryIcon;
  final IconData? tertiaryIcon;
  final bool isPrimaryLoading;
  final bool isPrimaryEnabled;
  final bool isSecondaryEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (secondaryLabel != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isSecondaryEnabled ? onSecondary : null,
              icon: secondaryIcon != null
                  ? Icon(secondaryIcon, size: 16)
                  : (isPrimaryLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : null),
              label: Text(isPrimaryLoading && secondaryIcon == null ? '处理中...' : secondaryLabel!),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: FilledButton.icon(
            onPressed: isPrimaryEnabled && !isPrimaryLoading ? onPrimary : null,
            icon: primaryIcon != null
                ? Icon(primaryIcon, size: 16)
                : (isPrimaryLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : null),
            label: Text(isPrimaryLoading && primaryIcon == null ? '处理中...' : primaryLabel),
          ),
        ),
      ],
    );
  }
}

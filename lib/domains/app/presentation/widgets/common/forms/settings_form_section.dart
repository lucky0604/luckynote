import 'package:flutter/material.dart';

/// A reusable form section wrapper for settings pages.
///
/// Provides consistent layout and styling for settings forms.
/// Based on the pattern from llm_settings_section.dart.
class SettingsFormSection extends StatelessWidget {
  const SettingsFormSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.padding = const EdgeInsets.all(16),
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Row(
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              )
            else
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

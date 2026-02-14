import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/domains/settings/data/models/font_settings.dart';
import 'package:luckynote/domains/settings/presentation/providers/font_settings_provider.dart';

class FontSettingsSection extends ConsumerWidget {
  const FontSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSettings = ref.watch(fontSettingsNotifierProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.type, size: 20),
                const SizedBox(width: 12),
                Text('编辑器字体', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _buildFontFamilySelector(context, ref, fontSettings),
            const SizedBox(height: 16),
            _buildFontSizeSlider(context, ref, fontSettings),
          ],
        ),
      ),
    );
  }

  Widget _buildFontFamilySelector(
    BuildContext context,
    WidgetRef ref,
    FontSettings fontSettings,
  ) {
    final availableFonts = [
      'SF Pro Text',
      'Segoe UI',
      'Roboto',
      'LXGW WenKai',
      'JetBrains Mono',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '字体',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: fontSettings.fontFamily,
          items: availableFonts.map((font) {
            return DropdownMenuItem<String>(
              value: font,
              child: Text(font, style: TextStyle(fontFamily: font)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              ref
                  .read(fontSettingsNotifierProvider.notifier)
                  .setFontFamily(value);
            }
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.backgroundPure,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.accent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeSlider(
    BuildContext context,
    WidgetRef ref,
    FontSettings fontSettings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '字体大小',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              '${fontSettings.fontSize.toInt()}px',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: fontSettings.fontSize,
          min: 12,
          max: 24,
          divisions: 12,
          label: '${fontSettings.fontSize.toInt()}px',
          onChanged: (value) {
            ref.read(fontSettingsNotifierProvider.notifier).setFontSize(value);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFontSizeButton(context, ref, 12),
              _buildFontSizeButton(context, ref, 14),
              _buildFontSizeButton(context, ref, 16),
              _buildFontSizeButton(context, ref, 18),
              _buildFontSizeButton(context, ref, 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeButton(
    BuildContext context,
    WidgetRef ref,
    double fontSize,
  ) {
    final fontSettings = ref.watch(fontSettingsNotifierProvider);
    final isSelected = fontSettings.fontSize == fontSize;

    return InkWell(
      onTap: () =>
          ref.read(fontSettingsNotifierProvider.notifier).setFontSize(fontSize),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(4),
          color: isSelected ? AppColors.selectedBackground : Colors.transparent,
        ),
        child: Text(
          '${fontSize.toInt()}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

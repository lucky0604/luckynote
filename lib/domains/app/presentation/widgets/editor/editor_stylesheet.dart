import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import 'package:luckynote/app/theme/app_colors.dart';
import 'package:luckynote/core/constants/app_constants.dart';
import 'package:luckynote/domains/editor/data/models/latex_attribution.dart';
import 'package:luckynote/domains/association/data/models/wikilink_attribution.dart';

/// 编辑器样式表构建器
/// 提供统一的编辑器样式配置，包括 WikiLink 高亮
class EditorStylesheet {
  EditorStylesheet._();

  /// 构建编辑器样式表
  /// 继承 defaultStylesheet 但覆盖 maxWidth 为无限制
  static Stylesheet build() {
    return defaultStylesheet.copyWith(
      addRulesBefore: [
        // 在所有默认规则之前，先设置全局 maxWidth 为无限制
        StyleRule(BlockSelector.all, (doc, docNode) {
          return {
            Styles.maxWidth: double.infinity,
          };
        }),
      ],
      addRulesAfter: [
        // 全局边距设置
        StyleRule(BlockSelector.all, (doc, docNode) {
          return {
            Styles.maxWidth: double.infinity,
            Styles.padding: CascadingPadding.symmetric(
              horizontal: AppConstants.editorHorizontalPadding,
              vertical: 8,
            ),
          };
        }),

        // 标题1样式
        StyleRule(const BlockSelector('header1'), (doc, docNode) {
          return {
            Styles.maxWidth: double.infinity,
            Styles.textStyle: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              fontFamily: AppConstants.previewModeFontFamily,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
            Styles.padding: CascadingPadding.only(
              left: AppConstants.editorHorizontalPadding,
              right: AppConstants.editorHorizontalPadding,
              top: 24,
              bottom: 8,
            ),
          };
        }),

        // 标题2样式
        StyleRule(const BlockSelector('header2'), (doc, docNode) {
          return {
            Styles.maxWidth: double.infinity,
            Styles.textStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              fontFamily: AppConstants.previewModeFontFamily,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
            Styles.padding: CascadingPadding.only(
              left: AppConstants.editorHorizontalPadding,
              right: AppConstants.editorHorizontalPadding,
              top: 20,
              bottom: 8,
            ),
          };
        }),

        // 标题3样式
        StyleRule(const BlockSelector('header3'), (doc, docNode) {
          return {
            Styles.maxWidth: double.infinity,
            Styles.textStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: AppConstants.previewModeFontFamily,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
            Styles.padding: CascadingPadding.only(
              left: AppConstants.editorHorizontalPadding,
              right: AppConstants.editorHorizontalPadding,
              top: 16,
              bottom: 8,
            ),
          };
        }),

        // 段落样式
        StyleRule(const BlockSelector('paragraph'), (doc, docNode) {
          return {
            Styles.maxWidth: double.infinity,
            Styles.textStyle: TextStyle(
              fontSize: AppConstants.editorFontSize,
              fontFamily: AppConstants.previewModeFontFamily,
              color: AppColors.textPrimary,
              height: AppConstants.editorLineHeight,
            ),
          };
        }),

        // 引用块样式
        StyleRule(const BlockSelector('blockquote'), (doc, docNode) {
          return {
            Styles.maxWidth: double.infinity,
            Styles.textStyle: TextStyle(
              fontSize: AppConstants.editorFontSize,
              fontFamily: AppConstants.previewModeFontFamily,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
              height: AppConstants.editorLineHeight,
            ),
            Styles.padding: CascadingPadding.only(
              left: AppConstants.editorHorizontalPadding + 16,
              right: AppConstants.editorHorizontalPadding,
              top: 8,
              bottom: 8,
            ),
          };
        }),

        // 代码块样式
        StyleRule(const BlockSelector('code'), (doc, docNode) {
          return {
            Styles.maxWidth: double.infinity,
            Styles.textStyle: TextStyle(
              fontSize: 14,
              fontFamily: AppConstants.sourceModeFontFamily,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
            Styles.backgroundColor: AppColors.noteListBackground,
            Styles.padding: CascadingPadding.symmetric(
              horizontal: AppConstants.editorHorizontalPadding,
              vertical: 12,
            ),
          };
        }),

        // 无序列表样式
        StyleRule(const BlockSelector('unorderedListItem'), (doc, docNode) {
          return {
            Styles.maxWidth: double.infinity,
            Styles.textStyle: TextStyle(
              fontSize: AppConstants.editorFontSize,
              fontFamily: AppConstants.previewModeFontFamily,
              color: AppColors.textPrimary,
              height: AppConstants.editorLineHeight,
            ),
            Styles.padding: CascadingPadding.only(
              left: AppConstants.editorHorizontalPadding + 16,
              right: AppConstants.editorHorizontalPadding,
              top: 4,
              bottom: 4,
            ),
          };
        }),

        // 有序列表样式
        StyleRule(const BlockSelector('orderedListItem'), (doc, docNode) {
          return {
            Styles.maxWidth: double.infinity,
            Styles.textStyle: TextStyle(
              fontSize: AppConstants.editorFontSize,
              fontFamily: AppConstants.previewModeFontFamily,
              color: AppColors.textPrimary,
              height: AppConstants.editorLineHeight,
            ),
            Styles.padding: CascadingPadding.only(
              left: AppConstants.editorHorizontalPadding + 16,
              right: AppConstants.editorHorizontalPadding,
              top: 4,
              bottom: 4,
            ),
          };
        }),

        // 任务列表样式
        StyleRule(const BlockSelector('task'), (doc, docNode) {
          return {
            Styles.maxWidth: double.infinity,
            Styles.textStyle: TextStyle(
              fontSize: AppConstants.editorFontSize,
              fontFamily: AppConstants.previewModeFontFamily,
              color: AppColors.textPrimary,
              height: AppConstants.editorLineHeight,
            ),
            Styles.padding: CascadingPadding.only(
              left: AppConstants.editorHorizontalPadding + 16,
              right: AppConstants.editorHorizontalPadding,
              top: 4,
              bottom: 4,
            ),
          };
        }),
      ],
      inlineTextStyler: _inlineStyler,
    );
  }

  /// 行内文本样式器
  /// 处理 WikiLink 和 LaTeX 的样式
  static TextStyle _inlineStyler(
    Set<Attribution> attributions,
    TextStyle existingStyle,
  ) {
    // 先应用默认样式
    var newStyle = defaultInlineTextStyler(attributions, existingStyle);

    // 检查是否有 LaTeX Attribution
    for (final attribution in attributions) {
      if (attribution is LatexAttribution) {
        // LaTeX 行内公式的样式：使用 serif 字体和背景色区分
        newStyle = newStyle.copyWith(
          fontFamily: 'serif',
          fontStyle: FontStyle.italic,
          fontSize: attribution.isBlockLevel ? 18 : 16,
          color: AppColors.textPrimary,
          backgroundColor: AppColors.noteListBackground.withValues(alpha: 0.5),
          letterSpacing: 0.5,
        );
        return newStyle;
      }
    }

    // 检查是否有 WikiLink Attribution
    for (final attribution in attributions) {
      if (attribution is WikiLinkAttribution) {
        newStyle = newStyle.copyWith(
          color: AppColors.linkColor,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.linkColor.withValues(alpha: 0.5),
        );
        break;
      }
    }

    return newStyle;
  }
}

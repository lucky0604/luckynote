import 'package:flutter/material.dart';

/// Super Editor 配置实体
/// 集中管理编辑器的各种配置选项
class EditorConfig {
  const EditorConfig({
    this.maxWidth = 700.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    this.fontSize = 16.0,
    this.lineHeight = 1.6,
    this.fontFamily = 'Georgia',
    this.autoSaveDelayMs = 2500,
    this.maxUndoStackSize = 50,
    this.showLineNumbers = false,
    this.enableSyntaxHighlighting = true,
    this.enableSpellCheck = false,
  });

  /// 编辑器最大宽度 (Typora 风格)
  final double maxWidth;

  /// 内边距
  final EdgeInsets padding;

  /// 字体大小
  final double fontSize;

  /// 行高
  final double lineHeight;

  /// 字体家族
  final String fontFamily;

  /// 自动保存延迟 (毫秒)
  final int autoSaveDelayMs;

  /// 撤销栈最大容量
  final int maxUndoStackSize;

  /// 是否显示行号
  final bool showLineNumbers;

  /// 是否启用语法高亮
  final bool enableSyntaxHighlighting;

  /// 是否启用拼写检查
  final bool enableSpellCheck;

  /// 复制并修改配置
  EditorConfig copyWith({
    double? maxWidth,
    EdgeInsets? padding,
    double? fontSize,
    double? lineHeight,
    String? fontFamily,
    int? autoSaveDelayMs,
    int? maxUndoStackSize,
    bool? showLineNumbers,
    bool? enableSyntaxHighlighting,
    bool? enableSpellCheck,
  }) {
    return EditorConfig(
      maxWidth: maxWidth ?? this.maxWidth,
      padding: padding ?? this.padding,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      autoSaveDelayMs: autoSaveDelayMs ?? this.autoSaveDelayMs,
      maxUndoStackSize: maxUndoStackSize ?? this.maxUndoStackSize,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      enableSyntaxHighlighting: enableSyntaxHighlighting ?? this.enableSyntaxHighlighting,
      enableSpellCheck: enableSpellCheck ?? this.enableSpellCheck,
    );
  }
}

/// 预设配置
class EditorConfigPresets {
  static const EditorConfig typora = EditorConfig(
    maxWidth: 700.0,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    fontSize: 16.0,
    lineHeight: 1.6,
    fontFamily: 'Georgia',
    autoSaveDelayMs: 2500,
    maxUndoStackSize: 50,
  );

  static const EditorConfig compact = EditorConfig(
    maxWidth: double.infinity,
    padding: EdgeInsets.all(16),
    fontSize: 14.0,
    lineHeight: 1.5,
    fontFamily: 'monospace',
    autoSaveDelayMs: 1500,
    maxUndoStackSize: 30,
  );

  static const EditorConfig reading = EditorConfig(
    maxWidth: 650.0,
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    fontSize: 18.0,
    lineHeight: 1.8,
    fontFamily: 'Georgia',
    autoSaveDelayMs: 3000,
    maxUndoStackSize: 20,
  );
}
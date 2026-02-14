import 'package:super_editor/super_editor.dart';

/// LaTeX 数学公式属性
/// 用于标识 LaTeX 数学公式（行内或块级）
class LatexAttribution implements Attribution {
  const LatexAttribution({
    required this.expression,
    this.isBlockLevel = false,
  });

  final String expression;
  final bool isBlockLevel;

  @override
  String get id => 'latex';

  @override
  bool canMergeWith(Attribution other) {
    return other is LatexAttribution &&
        other.expression == expression &&
        other.isBlockLevel == isBlockLevel;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatexAttribution &&
        other.expression == expression &&
        other.isBlockLevel == isBlockLevel;
  }

  @override
  int get hashCode => Object.hash(expression, isBlockLevel);

  @override
  String toString() =>
      'LatexAttribution(expression: $expression, isBlockLevel: $isBlockLevel)';
}

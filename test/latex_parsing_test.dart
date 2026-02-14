import 'package:flutter_test/flutter_test.dart';
import 'package:luckynote/domains/editor/data/models/latex_attribution.dart';
import 'package:luckynote/domains/editor/data/markdown/markdown_latex_parser.dart';
import 'package:luckynote/domains/editor/data/markdown/markdown_serializer.dart';
import 'package:super_editor/super_editor.dart';

void main() {
  group('LaTeX Parsing Tests', () {
    late MarkdownSerializer serializer;

    setUp(() {
      serializer = MarkdownSerializer();
    });

    group(r'Block Level LaTeX ($$...$$)', () {
      test('should detect block math line', () {
        expect(MarkdownLatexParser.isBlockMathLine(r'$$E=mc^2$$'), isTrue);
        expect(MarkdownLatexParser.isBlockMathLine(r'$$\int_0^\infty x^2 dx$$'), isTrue);
        expect(MarkdownLatexParser.isBlockMathLine(r'$E=mc^2$'), isFalse);
        expect(MarkdownLatexParser.isBlockMathLine('普通文本'), isFalse);
      });

      test('should extract block math expression', () {
        expect(
          MarkdownLatexParser.extractBlockMathExpression(r'$$E=mc^2$$'),
          equals('E=mc^2'),
        );
        expect(
          MarkdownLatexParser.extractBlockMathExpression(r'$$\frac{a}{b}$$'),
          equals(r'\frac{a}{b}'),
        );
      });

      test('should parse block math in document', () {
        final markdown = r'$$\sum_{i=1}^{n} x_i$$';
        final document = serializer.deserialize(markdown);

        expect(document.nodeCount, equals(1));
        final node = document.getNodeAt(0);
        expect(node, isA<TextNode>());
        expect((node as TextNode).metadata['isLatex'], isTrue);
        expect(node.metadata['isBlockLevel'], isTrue);
        expect(node.metadata['latexExpression'], equals(r'\sum_{i=1}^{n} x_i'));
      });
    });

    group(r'Inline LaTeX ($...$)', () {
      test('should parse inline math with LatexAttribution', () {
        final text = r'The formula $E=mc^2$ is famous.';
        final attributedText = MarkdownLatexParser.parseInlineMath(text);

        expect(attributedText.toPlainText(), equals('The formula E=mc^2 is famous.'));

        // 检查 LaTeX 部分是否有正确的 Attribution
        final latexStartOffset = 12; // "The formula " 的长度
        final attributions = attributedText.getAllAttributionsAt(latexStartOffset);

        expect(attributions.whereType<LatexAttribution>().isNotEmpty, isTrue);
        final latexAttr = attributions.whereType<LatexAttribution>().first;
        expect(latexAttr.expression, equals('E=mc^2'));
        expect(latexAttr.isBlockLevel, isFalse);
      });

      test('should parse multiple inline math expressions', () {
        final text = r'Both $a^2$ and $b^2$ are squares.';
        final attributedText = MarkdownLatexParser.parseInlineMath(text);

        expect(attributedText.toPlainText(), equals('Both a^2 and b^2 are squares.'));
      });

      test(r'should not match $$ as inline math', () {
        final text = r'Block: $$x^2$$ not inline';
        final attributedText = MarkdownLatexParser.parseInlineMath(text);

        // $$ 不应该被当作行内公式处理
        // 这个测试验证正则不会错误匹配
        expect(attributedText.toPlainText().contains(r'$$'), isTrue);
      });
    });

    group('Combined LaTeX and WikiLink parsing', () {
      test('should parse inline LaTeX in paragraph', () {
        final markdown = r'The energy equation $E=mc^2$ is revolutionary.';
        final document = serializer.deserialize(markdown);

        expect(document.nodeCount, equals(1));
        final node = document.getNodeAt(0) as ParagraphNode;
        final text = node.text;

        // 文本应该移除了 $ 符号
        // "The energy equation " = 20 chars, "E=mc^2" = 6 chars
        // 所以处理后的文本是 "The energy equation E=mc^2 is revolutionary."
        expect(text.toPlainText(), equals('The energy equation E=mc^2 is revolutionary.'));

        // 检查 LaTeX Attribution - 应该在 offset 20 处开始 (E 的位置)
        final latexOffset = 20;
        final attributions = text.getAllAttributionsAt(latexOffset);
        expect(attributions.whereType<LatexAttribution>().isNotEmpty, isTrue);
      });

      test('should parse WikiLink alongside LaTeX', () {
        final markdown = r'See [[Note]] and $x^2$ formula.';
        final document = serializer.deserialize(markdown);

        expect(document.nodeCount, equals(1));
        final node = document.getNodeAt(0) as ParagraphNode;
        final text = node.text;

        // 文本应该正确处理
        expect(text.toPlainText(), equals('See Note and x^2 formula.'));
      });
    });

    group('Serialization', () {
      test('should serialize block LaTeX back to markdown', () {
        final markdown = r'$$E=mc^2$$';
        final document = serializer.deserialize(markdown);
        final result = serializer.serialize(document);

        expect(result.trim(), contains(r'$$E=mc^2$$'));
      });

      test('should restore inline LaTeX syntax', () {
        final text = 'The formula E=mc^2 is famous.';
        final attribution = LatexAttribution(expression: 'E=mc^2', isBlockLevel: false);

        // "The formula " = 12 chars (index 0-11)
        // "E=mc^2" = 6 chars (index 12-17)
        final attributedText = AttributedText(
          text,
          AttributedSpans(attributions: [
            SpanMarker(
              attribution: attribution,
              offset: 12,
              markerType: SpanMarkerType.start,
            ),
            SpanMarker(
              attribution: attribution,
              offset: 17, // 12 + 6 - 1 = 17
              markerType: SpanMarkerType.end,
            ),
          ]),
        );

        final restored = MarkdownLatexParser.restoreInlineMathSyntax(attributedText);
        expect(restored, equals(r'The formula $E=mc^2$ is famous.'));
      });
    });
  });
}

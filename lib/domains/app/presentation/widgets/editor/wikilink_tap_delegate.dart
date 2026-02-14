import 'package:super_editor/super_editor.dart';

/// WikiLink 点击代理
/// 用于处理文档内容的点击事件，检测 WikiLink 并触发导航
class WikiLinkTapDelegate extends ContentTapDelegate {
  WikiLinkTapDelegate({required this.tapHandler});

  final void Function(DocumentTapDetails) tapHandler;

  @override
  TapHandlingInstruction onTap(DocumentTapDetails details) {
    tapHandler(details);
    return TapHandlingInstruction.continueHandling;
  }
}

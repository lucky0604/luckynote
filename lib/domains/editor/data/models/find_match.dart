/// 查找匹配结果数据模型
class FindMatch {
  const FindMatch({
    required this.nodeId,
    required this.startOffset,
    required this.endOffset,
    required this.text,
  });

  /// 匹配所在的文档节点 ID
  final String nodeId;

  /// 匹配文本的起始偏移量
  final int startOffset;

  /// 匹配文本的结束偏移量
  final int endOffset;

  /// 匹配的文本内容
  final String text;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FindMatch &&
        other.nodeId == nodeId &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset;
  }

  @override
  int get hashCode => Object.hash(nodeId, startOffset, endOffset);

  @override
  String toString() =>
      'FindMatch(nodeId: $nodeId, range: $startOffset-$endOffset, text: "$text")';
}

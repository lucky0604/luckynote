/// 索引进度数据模型
class IndexProgress {
  const IndexProgress({
    this.current = 0,
    this.total = 0,
    this.isIndexing = false,
  });

  /// 当前已索引的文件数
  final int current;

  /// 总文件数
  final int total;

  /// 是否正在索引
  final bool isIndexing;

  /// 进度百分比 (0.0 ~ 1.0)
  double get percentage => total > 0 ? current / total : 0.0;

  /// 是否完成
  bool get isComplete => !isIndexing && current >= total && total > 0;

  /// 进度文本
  String get progressText {
    if (!isIndexing) return '';
    if (total == 0) return '正在扫描文件...';
    return '正在索引 $current / $total 文件';
  }

  IndexProgress copyWith({
    int? current,
    int? total,
    bool? isIndexing,
  }) {
    return IndexProgress(
      current: current ?? this.current,
      total: total ?? this.total,
      isIndexing: isIndexing ?? this.isIndexing,
    );
  }
}

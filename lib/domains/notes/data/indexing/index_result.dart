/// 索引结果统计
class IndexResult {
  IndexResult({this.added = 0, this.updated = 0, this.deleted = 0});

  factory IndexResult.empty() => IndexResult();

  int added;
  int updated;
  int deleted;

  int get total => added + updated + deleted;

  bool get hasChanges => total > 0;

  @override
  String toString() {
    return 'IndexResult(added: $added, updated: $updated, deleted: $deleted)';
  }
}

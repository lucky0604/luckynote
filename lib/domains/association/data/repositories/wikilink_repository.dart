import 'package:luckynote/database/database.dart';

/// WikiLink 仓库
/// 管理笔记之间的双向链接关系
class WikiLinkRepository {
  WikiLinkRepository(this._database);

  final AppDatabase _database;

  /// 更新文档的 WikiLink 引用关系
  /// 从内容中提取 [[Title]] 或 [[Title|Alias]] 格式的链接并存储
  Future<void> updateReferences(int documentId, String content) async {
    await _database.updateNoteReferences(documentId, content);
  }

  /// 获取指向某个笔记的反向链接 (Backlinks)
  /// 返回所有引用了当前标题的笔记列表
  Future<List<BacklinkResult>> getBacklinks(String title) async {
    return await _database.getBacklinks(title);
  }

  /// 按标题搜索文档 (用于自动补全)
  Future<List<String>> searchTitles(String query) async {
    final results = await _database.searchByTitle(query, limit: 10);
    return results.map((r) => r.title).toList();
  }

  /// 获取所有笔记标题 (用于 WikiLink 自动补全)
  Future<List<String>> getAllTitles() async {
    return await _database.getAllNoteTitles();
  }
}

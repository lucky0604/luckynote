part of 'database.dart';

class NoteChunkResult {
  final int id;
  final int documentId;
  final String? heading;
  final String content;
  final int priority;
  final String sourceFilePath;
  final String title;
  final double score;

  NoteChunkResult({
    required this.id,
    required this.documentId,
    required this.heading,
    required this.content,
    required this.priority,
    required this.sourceFilePath,
    required this.title,
    required this.score,
  });

  @override
  String toString() {
    return 'NoteChunkResult(id: $id, documentId: $documentId, heading: $heading, content: $content, priority: $priority, sourceFilePath: $sourceFilePath, title: $title, score: $score)';
  }
}

/// 反向链接搜索结果
class BacklinkResult {
  final int id;
  final int sourceDocId;
  final String sourceTitle;
  final String sourceFilePath;

  BacklinkResult({
    required this.id,
    required this.sourceDocId,
    required this.sourceTitle,
    required this.sourceFilePath,
  });

  @override
  String toString() {
    return 'BacklinkResult(id: $id, sourceDocId: $sourceDocId, sourceTitle: $sourceTitle, sourceFilePath: $sourceFilePath)';
  }
}

/// 标题搜索结果 (用于全局搜索)
class TitleSearchResult {
  final int documentId;
  final String title;
  final String filePath;

  TitleSearchResult({
    required this.documentId,
    required this.title,
    required this.filePath,
  });

  @override
  String toString() {
    return 'TitleSearchResult(documentId: $documentId, title: $title, filePath: $filePath)';
  }
}

class TaskWithDocument {
  final int id;
  final int documentId;
  final String content;
  final bool isCompleted;
  final String rawLine;
  final int lineNumber;
  final DateTime createdAt;
  final String documentTitle;
  final String filePath;

  TaskWithDocument({
    required this.id,
    required this.documentId,
    required this.content,
    required this.isCompleted,
    required this.rawLine,
    required this.lineNumber,
    required this.createdAt,
    required this.documentTitle,
    required this.filePath,
  });

  @override
  String toString() {
    return 'TaskWithDocument(id: $id, documentId: $documentId, content: $content, isCompleted: $isCompleted, rawLine: $rawLine, lineNumber: $lineNumber, createdAt: $createdAt, documentTitle: $documentTitle, filePath: $filePath)';
  }
}

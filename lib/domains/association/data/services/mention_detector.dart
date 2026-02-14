import 'package:luckynote/database/database.dart';
import 'package:luckynote/domains/rag/data/services/document_service.dart';
import '../models/mention_candidate.dart';
import 'title_cache.dart';

/// Mention detection service.
///
/// Detects unlinked mentions of note titles in content.
class MentionDetector {
  MentionDetector({
    required this.database,
    required this.titleCache,
    DocumentService? documentService,
  }) : _documentService = documentService;

  final AppDatabase database;
  final TitleCache titleCache;
  final DocumentService? _documentService;

  /// Find all note titles mentioned in content that aren't linked
  ///
  /// [content] The markdown content to scan
  /// [currentNotePath] Path of current note (to exclude self-mentions)
  /// [currentNoteTitle] Title of current note (preferred for self-mention exclusion)
  /// Returns list of mention candidates
  Future<List<MentionCandidate>> findUnlinkedMentions({
    required String content,
    required String currentNotePath,
    String? currentNoteTitle,
  }) async {
    if (content.isEmpty) return [];

    final allTitles = await titleCache.getAllTitles();
    if (allTitles.isEmpty) return [];

    // Use provided title first, fallback to database query
    String? currentTitle = currentNoteTitle;
    if (currentTitle == null && _documentService != null) {
      final currentDoc =
          await _documentService.getDocumentByFilePath(currentNotePath);
      currentTitle = currentDoc?.title;
    }
    
    print('[MentionDetector] All titles in cache: $allTitles');
    print('[MentionDetector] Current title to exclude: "$currentTitle"');

    // Build exclusion ranges for existing WikiLinks and code blocks
    final exclusions = _buildExclusionRanges(content);

    // Get all URL ranges to exclude
    final urlRanges = _findUrlRanges(content);

    final candidates = <MentionCandidate>[];

    // Sort titles by length (longest first) to match multi-word titles first
    final sortedTitles = allTitles.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final title in sortedTitles) {
      // Skip self-mentions
      if (currentTitle != null && title == currentTitle) {
        print('[MentionDetector] Skipping self-mention: "$title"');
        continue;
      }

      // Find all occurrences of this title
      final pattern = RegExp(
        RegExp.escape(title),
        caseSensitive: true,
      );

      for (final match in pattern.allMatches(content)) {
        final start = match.start;
        final end = match.end;

        // Check if this match is within an excluded range
        if (_isExcluded(start, end, exclusions) ||
            _isExcluded(start, end, urlRanges)) {
          continue;
        }

        // Check word boundary - ensure it's a standalone mention
        if (!_isValidWordBoundary(content, start, end)) {
          continue;
        }

        // Extract context (up to 50 chars before and after)
        final contextStart = (start - 50).clamp(0, content.length);
        final contextEnd = (end + 50).clamp(0, content.length);
        final context = content.substring(contextStart, contextEnd);

        // Get the file path for this title
        final docs = await (database.select(database.noteDocuments)
              ..where((tbl) => tbl.title.equals(title))
              ..limit(1))
            .get();

        if (docs.isEmpty) continue;

        candidates.add(MentionCandidate(
          matchedText: match.group(0)!,
          targetNoteTitle: title,
          targetNotePath: docs.first.filePath,
          startIndex: start,
          endIndex: end,
          context: context,
        ));
      }
    }

    // Sort by position and remove duplicates
    candidates.sort((a, b) => a.startIndex.compareTo(b.startIndex));
    return _removeOverlappingCandidates(candidates);
  }

  /// Build exclusion ranges for WikiLinks, code blocks, etc.
  List<_ExclusionRange> _buildExclusionRanges(String content) {
    final exclusions = <_ExclusionRange>[];

    // WikiLink patterns: [[Title]] or [[Title|Alias]]
    final wikilinkPattern = RegExp(r'\[\[(.*?)(?:\|(.*?))?\]\]');
    for (final match in wikilinkPattern.allMatches(content)) {
      exclusions.add(_ExclusionRange(match.start, match.end));
    }

    // Code blocks: ```code```
    final codeBlockPattern = RegExp(r'```[\s\S]*?```');
    for (final match in codeBlockPattern.allMatches(content)) {
      exclusions.add(_ExclusionRange(match.start, match.end));
    }

    // Inline code: `code`
    final inlineCodePattern = RegExp(r'`[^`]+`');
    for (final match in inlineCodePattern.allMatches(content)) {
      exclusions.add(_ExclusionRange(match.start, match.end));
    }

    // Headers: # Title (where Title might match a note name)
    final headerPattern = RegExp(r'^#+\s.+$', multiLine: true);
    for (final match in headerPattern.allMatches(content)) {
      exclusions.add(_ExclusionRange(match.start, match.end));
    }

    return exclusions;
  }

  /// Find URL ranges to exclude from mention detection
  List<_ExclusionRange> _findUrlRanges(String content) {
    final ranges = <_ExclusionRange>[];

    // URL pattern
    final urlPattern = RegExp(
      r'https?:\/\/[^\s<>"{}|\\^`\[\]]+|www\.[^\s<>"{}|\\^`\[\]]+',
    );

    for (final match in urlPattern.allMatches(content)) {
      ranges.add(_ExclusionRange(match.start, match.end));
    }

    return ranges;
  }

  /// Check if a range overlaps with any exclusion range
  bool _isExcluded(int start, int end, List<_ExclusionRange> exclusions) {
    for (final exclusion in exclusions) {
      // Check for overlap or containment
      if (start < exclusion.end && end > exclusion.start) {
        return true;
      }
    }
    return false;
  }

  /// Check if match has valid word boundaries
  bool _isValidWordBoundary(String content, int start, int end) {
    final before = start > 0 ? content[start - 1] : ' ';
    final after = end < content.length ? content[end] : ' ';

    // Allow whitespace, punctuation, or string boundaries
    final validBefore = _isWordBoundaryChar(before);
    final validAfter = _isWordBoundaryChar(after);

    return validBefore && validAfter;
  }

  /// Check if character is a word boundary
  bool _isWordBoundaryChar(String char) {
    return char.contains(RegExp(r'[\s\p{P}]', unicode: true));
  }

  /// Remove overlapping candidates, keeping the first one
  List<MentionCandidate> _removeOverlappingCandidates(
    List<MentionCandidate> candidates,
  ) {
    if (candidates.isEmpty) return [];

    final result = <MentionCandidate>[candidates.first];
    var lastEnd = candidates.first.endIndex;

    for (final candidate in candidates.skip(1)) {
      if (candidate.startIndex >= lastEnd) {
        result.add(candidate);
        lastEnd = candidate.endIndex;
      }
    }

    return result;
  }
}

class _ExclusionRange {
  const _ExclusionRange(this.start, this.end);
  final int start;
  final int end;
}

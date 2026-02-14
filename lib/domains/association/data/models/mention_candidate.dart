/// Mention Candidate - represents a potential unlinked mention of a note title
class MentionCandidate {
  const MentionCandidate({
    required this.matchedText,
    required this.targetNoteTitle,
    required this.targetNotePath,
    required this.startIndex,
    required this.endIndex,
    required this.context,
  });

  /// The actual text that matched (e.g., "My Note Title")
  final String matchedText;

  /// The title of the target note that this mentions
  final String targetNoteTitle;

  /// File path to the target note
  final String targetNotePath;

  /// Start index in the content where the mention appears
  final int startIndex;

  /// End index in the content where the mention appears
  final int endIndex;

  /// Context around the mention for display
  final String context;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MentionCandidate &&
        other.matchedText == matchedText &&
        other.targetNoteTitle == targetNoteTitle &&
        other.targetNotePath == targetNotePath &&
        other.startIndex == startIndex &&
        other.endIndex == endIndex &&
        other.context == context;
  }

  @override
  int get hashCode {
    return Object.hash(
      matchedText,
      targetNoteTitle,
      targetNotePath,
      startIndex,
      endIndex,
      context,
    );
  }

  @override
  String toString() {
    return 'MentionCandidate(matchedText: $matchedText, targetNoteTitle: $targetNoteTitle, '
        'targetNotePath: $targetNotePath, startIndex: $startIndex, endIndex: $endIndex, '
        'context: $context)';
  }
}

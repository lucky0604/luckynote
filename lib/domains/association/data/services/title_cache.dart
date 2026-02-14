import 'package:luckynote/database/database.dart';

/// Title cache service.
///
/// Caches note titles with timestamps for efficient repeated access.
class TitleCache {
  TitleCache(this._database);

  final AppDatabase _database;

  /// Cache for note titles with timestamp
  List<String>? _titleCache;
  DateTime? _cacheTimestamp;
  static const _cacheValidity = Duration(minutes: 5);

  /// Get all note titles with caching
  Future<List<String>> getAllTitles() async {
    // Check cache validity
    if (_titleCache != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheValidity) {
      return _titleCache!;
    }

    // Refresh cache
    _titleCache = await _database.getAllNoteTitles();
    _cacheTimestamp = DateTime.now();
    return _titleCache!;
  }

  /// Invalidate title cache (call when notes are created/deleted/renamed)
  void invalidateCache() {
    _titleCache = null;
    _cacheTimestamp = null;
  }
}

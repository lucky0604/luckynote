import 'package:shared_preferences/shared_preferences.dart';

/// Folder storage service
/// 持久化文件夹折叠状态
class FolderStorageService {
  FolderStorageService._internal();

  static final FolderStorageService _instance =
      FolderStorageService._internal();
  factory FolderStorageService() => _instance;

  SharedPreferences? _prefs;
  static const String _keyExpandedFolders = 'expanded_folders';

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<Set<String>> getExpandedFolders() async {
    if (_prefs == null) await init();
    final list = _prefs!.getStringList(_keyExpandedFolders) ?? [];
    return list.toSet();
  }

  Future<void> saveExpandedFolders(Set<String> paths) async {
    if (_prefs == null) await init();
    await _prefs!.setStringList(_keyExpandedFolders, paths.toList());
  }

  Future<void> toggleFolder(String path) async {
    final expanded = await getExpandedFolders();
    if (expanded.contains(path)) {
      expanded.remove(path);
    } else {
      expanded.add(path);
    }
    await saveExpandedFolders(expanded);
  }

  Future<void> clear() async {
    if (_prefs == null) await init();
    await _prefs!.remove(_keyExpandedFolders);
  }

  @override
  String toString() => 'FolderStorageService()';
}

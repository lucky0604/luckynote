import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';

part 'layout_settings_provider.g.dart';

/// 布局设置状态
@riverpod
class LayoutSettingsNotifier extends _$LayoutSettingsNotifier {
  @override
  LayoutSettings build() {
    _loadLayoutSettings();
    return const LayoutSettings();
  }

  Future<void> _loadLayoutSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final sidebarWidth = prefs.getDouble(AppConstants.keySidebarWidth);
    final noteListWidth = prefs.getDouble(AppConstants.keyNoteListWidth);

    if (sidebarWidth != null || noteListWidth != null) {
      state = LayoutSettings(
        sidebarWidth: sidebarWidth ?? state.sidebarWidth,
        noteListWidth: noteListWidth ?? state.noteListWidth,
      );
    }
  }

  Future<void> setSidebarWidth(double width) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keySidebarWidth, width);
    state = state.copyWith(sidebarWidth: width);
  }

  Future<void> setNoteListWidth(double width) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyNoteListWidth, width);
    state = state.copyWith(noteListWidth: width);
  }

  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keySidebarWidth);
    await prefs.remove(AppConstants.keyNoteListWidth);
    state = const LayoutSettings();
  }
}

/// 布局设置数据类
class LayoutSettings {
  final double sidebarWidth;
  final double noteListWidth;

  const LayoutSettings({
    this.sidebarWidth = AppConstants.sidebarWidth,
    this.noteListWidth = AppConstants.noteListPanelWidth,
  });

  LayoutSettings copyWith({double? sidebarWidth, double? noteListWidth}) {
    return LayoutSettings(
      sidebarWidth: sidebarWidth ?? this.sidebarWidth,
      noteListWidth: noteListWidth ?? this.noteListWidth,
    );
  }
}

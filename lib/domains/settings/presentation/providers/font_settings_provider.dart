import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/font_settings.dart';

part 'font_settings_provider.g.dart';

/// 字体设置状态
@riverpod
class FontSettingsNotifier extends _$FontSettingsNotifier {
  @override
  FontSettings build() {
    _loadFontSettings();
    return const FontSettings();
  }

  Future<void> _loadFontSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final fontFamily = prefs.getString(AppConstants.keyEditorFontFamily);
    final fontSize = prefs.getDouble(AppConstants.keyEditorFontSize);

    if (fontFamily != null || fontSize != null) {
      state = FontSettings(
        fontFamily: fontFamily ?? state.fontFamily,
        fontSize: fontSize ?? state.fontSize,
      );
    }
  }

  Future<void> setFontFamily(String fontFamily) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyEditorFontFamily, fontFamily);
    state = state.copyWith(fontFamily: fontFamily);
  }

  Future<void> setFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyEditorFontSize, fontSize);
    state = state.copyWith(fontSize: fontSize);
  }

  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyEditorFontFamily);
    await prefs.remove(AppConstants.keyEditorFontSize);
    state = const FontSettings();
  }
}

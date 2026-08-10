import 'package:shared_preferences/shared_preferences.dart';

/// Replaces translator_config.json. No tesseract_path setting is needed
/// anymore since OCR runs on-device via ML Kit.
class SettingsService {
  static const _darkModeKey = 'dark_mode';
  static const _chunkSizeKey = 'chunk_size';
  static const _sttLocaleKey = 'stt_locale';

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? true;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<int> getChunkSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_chunkSizeKey) ?? 4000;
  }

  Future<void> setChunkSize(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chunkSizeKey, value);
  }

  Future<String> getSttLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sttLocaleKey) ?? 'en_US';
  }

  Future<void> setSttLocale(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sttLocaleKey, value);
  }
}

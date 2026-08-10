import 'package:flutter_tts/flutter_tts.dart';

/// Replaces pyttsx3 / gTTS - uses the device's built-in TTS voices, so it
/// works offline once the target language's voice pack is installed, and
/// always matches the translated language (mirrors the Python app's
/// "always speak the Output box, in the target language" behaviour).
class TtsService {
  final FlutterTts _tts = FlutterTts();

  static const Map<String, String> ttsLocales = {
    'auto': 'en-US',
    'english': 'en-US',
    'hindi': 'hi-IN',
    'french': 'fr-FR',
    'german': 'de-DE',
    'spanish': 'es-ES',
    'arabic': 'ar-SA',
    'russian': 'ru-RU',
    'japanese': 'ja-JP',
    'korean': 'ko-KR',
    'chinese': 'zh-CN',
  };

  Future<void> speak(String text, String targetLangName) async {
    final locale = ttsLocales[targetLangName.toLowerCase()] ?? 'en-US';
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}

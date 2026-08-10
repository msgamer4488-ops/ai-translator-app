import 'dart:convert';
import 'package:http/http.dart' as http;

/// Same language list as the desktop app, mapped to ISO codes.
/// NOTE: this hits Google Translate's unofficial "gtx" endpoint - the same
/// underlying mechanism deep_translator's GoogleTranslator used. It has no
/// official uptime/rate-limit guarantee. For a production Play Store app,
/// swap the body of `_translateChunk` to call the paid Cloud Translation
/// API with an API key instead.
class TranslationService {
  static const Map<String, String> languageCodes = {
    'auto': 'auto',
    'english': 'en',
    'hindi': 'hi',
    'french': 'fr',
    'german': 'de',
    'spanish': 'es',
    'arabic': 'ar',
    'russian': 'ru',
    'japanese': 'ja',
    'korean': 'ko',
    'chinese': 'zh-CN',
  };

  static List<String> get languages => languageCodes.keys.toList();

  /// Translates [text] in chunks (mirrors the Python chunk_size behaviour)
  /// and reports progress 0-100 via [onProgress].
  Future<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
    int chunkSize = 4000,
    void Function(double percent)? onProgress,
  }) async {
    if (text.trim().isEmpty) return '';

    final srcCode = languageCodes[sourceLang.toLowerCase()] ?? 'auto';
    final tgtCode = languageCodes[targetLang.toLowerCase()] ?? 'en';

    final buffer = StringBuffer();
    final total = text.length;

    for (int i = 0; i < total; i += chunkSize) {
      final end = (i + chunkSize < total) ? i + chunkSize : total;
      final chunk = text.substring(i, end);
      buffer.write(await _translateChunk(chunk, srcCode, tgtCode));
      onProgress?.call(((i + chunkSize) / total * 100).clamp(0, 100));
    }

    return buffer.toString();
  }

  Future<String> _translateChunk(String chunk, String src, String tgt) async {
    final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
      'client': 'gtx',
      'sl': src,
      'tl': tgt,
      'dt': 't',
      'q': chunk,
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Translation request failed (${response.statusCode})');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    final segments = decoded[0] as List;
    return segments.map((s) => (s as List)[0] as String).join();
  }
}

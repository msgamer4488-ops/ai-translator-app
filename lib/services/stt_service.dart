import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// Replaces SpeechRecognition + pyaudio - uses the device's native speech
/// recognizer, so there's no microphone-driver setup needed.
class SttService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  Future<bool> _ensureReady() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) return false;

    if (!_initialized) {
      _initialized = await _speech.initialize();
    }
    return _initialized;
  }

  /// Listens once and returns the recognized text, or null on failure /
  /// timeout / no permission.
  Future<String?> listenOnce({String localeId = 'en_US'}) async {
    final ready = await _ensureReady();
    if (!ready) return null;

    String result = '';
    final completer = Completer<String?>();

    await _speech.listen(
      localeId: localeId,
      onResult: (r) {
        result = r.recognizedWords;
        if (r.finalResult) {
          _speech.stop();
          if (!completer.isCompleted) completer.complete(result);
        }
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
    );

    // Safety timeout in case onResult never fires a final result.
    Future.delayed(const Duration(seconds: 16), () {
      if (!completer.isCompleted) completer.complete(result.isEmpty ? null : result);
    });

    return completer.future;
  }

  bool get isListening => _speech.isListening;
}


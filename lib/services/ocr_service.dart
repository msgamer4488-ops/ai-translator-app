import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Replaces pytesseract - runs fully on-device via ML Kit, no external
/// binary to install or path to configure in Settings.
class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _picker = ImagePicker();

  Future<String?> pickImageAndExtractText({required bool fromCamera}) async {
    final XFile? file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (file == null) return null;

    final inputImage = InputImage.fromFile(File(file.path));
    final RecognizedText result = await _recognizer.processImage(inputImage);
    return result.text;
  }

  void dispose() => _recognizer.close();
}

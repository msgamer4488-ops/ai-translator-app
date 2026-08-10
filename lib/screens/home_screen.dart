import 'package:flutter/material.dart';
import '../models/history_entry.dart';
import '../services/translation_service.dart';
import '../services/ocr_service.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import '../services/history_service.dart';
import '../services/file_service.dart';
import '../services/settings_service.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<bool> onDarkModeChanged;

  const HomeScreen({super.key, required this.onDarkModeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _translation = TranslationService();
  final _ocr = OcrService();
  final _tts = TtsService();
  final _stt = SttService();
  final _history = HistoryService();
  final _files = FileService();
  final _settings = SettingsService();

  final _inputController = TextEditingController();
  final _outputController = TextEditingController();

  String _sourceLang = 'auto';
  String _targetLang = 'hindi';

  bool _busy = false;
  double _progress = 0;
  String _status = 'Ready';

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  void _setStatus(String s) => setState(() => _status = s);

  Future<void> _translate() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      _snack('Please enter text.');
      return;
    }

    setState(() {
      _busy = true;
      _progress = 0;
      _status = 'Translating...';
    });

    try {
      final chunkSize = await _settings.getChunkSize();
      final result = await _translation.translate(
        text: text,
        sourceLang: _sourceLang,
        targetLang: _targetLang,
        chunkSize: chunkSize,
        onProgress: (p) => setState(() => _progress = p),
      );

      setState(() {
        _outputController.text = result;
        _status = 'Translation Complete';
      });

      await _history.add(HistoryEntry(
        time: DateTime.now().toString().split('.').first,
        sourceLang: _sourceLang,
        targetLang: _targetLang,
        sourceText: text,
        translatedText: result,
      ));
    } catch (e) {
      _snack('Error: $e');
      _setStatus('Error');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _openTextFile() async {
    try {
      final text = await _files.openTextFile();
      if (text != null) {
        setState(() {
          _inputController.text = text;
          _status = 'File Loaded';
        });
      }
    } catch (e) {
      _snack('Error: $e');
    }
  }

  Future<void> _ocrFromImage(bool fromCamera) async {
    _setStatus('Running OCR...');
    try {
      final text = await _ocr.pickImageAndExtractText(fromCamera: fromCamera);
      if (text != null) {
        setState(() {
          _inputController.text = text;
          _status = 'OCR Completed';
        });
      } else {
        _setStatus('Ready');
      }
    } catch (e) {
      _snack('OCR Error: $e');
      _setStatus('Error');
    }
  }

  Future<void> _speechToText() async {
    _setStatus('Listening... (speak now)');
    final locale = await _settings.getSttLocale();
    final text = await _stt.listenOnce(localeId: locale);
    if (text != null && text.isNotEmpty) {
      setState(() {
        _inputController.text = '${_inputController.text} $text'.trim();
        _status = 'Speech recognized';
      });
    } else {
      _snack('No speech detected or permission denied.');
      _setStatus('Ready');
    }
  }

  Future<void> _speakTranslation() async {
    final text = _outputController.text.trim();
    if (text.isEmpty) {
      _snack('No translated text to speak yet. Translate something first.');
      return;
    }
    await _tts.speak(text, _targetLang);
  }

  Future<void> _saveAs(String format) async {
    final text = _outputController.text.trim();
    if (text.isEmpty) {
      _snack('Nothing to save.');
      return;
    }
    if (format == 'txt') {
      await _files.saveAsTxt(text);
    } else {
      await _files.saveAsPdf(text);
    }
  }

  Future<void> _openHistory() async {
    final selected = await Navigator.push<HistoryEntry>(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
    if (selected != null) {
      setState(() {
        _inputController.text = selected.sourceText;
        _outputController.text = selected.translatedText;
        _sourceLang = selected.sourceLang;
        _targetLang = selected.targetLang;
      });
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(onDarkModeChanged: widget.onDarkModeChanged),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final languages = TranslationService.languages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Language Translator Pro'),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: _openHistory),
          IconButton(icon: const Icon(Icons.settings), onPressed: _openSettings),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sourceLang,
                    decoration: const InputDecoration(labelText: 'Source', border: OutlineInputBorder()),
                    items: languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                    onChanged: (v) => setState(() => _sourceLang = v ?? _sourceLang),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _targetLang,
                    decoration: const InputDecoration(labelText: 'Target', border: OutlineInputBorder()),
                    items: languages
                        .where((l) => l != 'auto')
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) => setState(() => _targetLang = v ?? _targetLang),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _textPanel('Input', _inputController)),
                  const SizedBox(width: 8),
                  Expanded(child: _textPanel('Translated', _outputController, readOnly: true)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_busy) LinearProgressIndicator(value: _progress / 100),
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerLeft, child: Text(_status)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _translate,
                  icon: const Icon(Icons.translate),
                  label: const Text('Translate'),
                ),
                OutlinedButton.icon(
                  onPressed: _openTextFile,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Open .txt'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _ocrFromImage(false),
                  icon: const Icon(Icons.image),
                  label: const Text('OCR Gallery'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _ocrFromImage(true),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('OCR Camera'),
                ),
                OutlinedButton.icon(
                  onPressed: _speechToText,
                  icon: const Icon(Icons.mic),
                  label: const Text('Speak → Text'),
                ),
                OutlinedButton.icon(
                  onPressed: _speakTranslation,
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Speak Translation'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _saveAs('txt'),
                  icon: const Icon(Icons.save),
                  label: const Text('Save TXT'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _saveAs('pdf'),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Save PDF'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _textPanel(String label, TextEditingController controller, {bool readOnly = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }
}

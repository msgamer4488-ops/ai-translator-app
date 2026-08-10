import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Replaces open_file/save_file/save_docx/save_pdf from the desktop app.
///
/// Supported on load: .txt directly. For .pdf / .docx text extraction on
/// Android, add a package such as syncfusion_flutter_pdf (pdf) or a docx
/// text-extraction package of your choice - left out here to keep this
/// scaffold dependency-light; the OCR flow covers the image case already.
class FileService {
  /// Lets the user pick a .txt file and returns its contents.
  Future<String?> openTextFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (result == null || result.files.single.path == null) return null;
    return File(result.files.single.path!).readAsString();
  }

  /// Saves [text] as a .txt file and opens the share sheet so the user can
  /// save it wherever they like (Drive, Files app, etc).
  Future<void> saveAsTxt(String text, {String filename = 'translation.txt'}) async {
    final path = await _writeTemp(filename, text);
    await Share.shareXFiles([XFile(path)]);
  }

  /// Saves [text] as a simple single-column PDF and shares it.
  Future<void> saveAsPdf(String text, {String filename = 'translation.pdf'}) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Paragraph(text: text, style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
    final bytes = await doc.save();
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<String> _writeTemp(String filename, String content) async {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    return file.path;
  }
}

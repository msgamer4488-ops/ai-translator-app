class HistoryEntry {
  final String time;
  final String sourceLang;
  final String targetLang;
  final String sourceText;
  final String translatedText;

  HistoryEntry({
    required this.time,
    required this.sourceLang,
    required this.targetLang,
    required this.sourceText,
    required this.translatedText,
  });

  Map<String, dynamic> toJson() => {
        'time': time,
        'source_lang': sourceLang,
        'target_lang': targetLang,
        'source_text': sourceText,
        'translated_text': translatedText,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        time: json['time'] ?? '',
        sourceLang: json['source_lang'] ?? '',
        targetLang: json['target_lang'] ?? '',
        sourceText: json['source_text'] ?? '',
        translatedText: json['translated_text'] ?? '',
      );
}

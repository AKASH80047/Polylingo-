class HistoryItem {
  final String id;
  final String type; // pdf, image, docx, xlsx, text
  final String fileName;
  final String sourceLanguage;
  final String sourceCode;
  final String targetLanguage;
  final String targetCode;
  final int pageCount;
  final double originalSizeMb;
  final double translatedSizeMb;
  final String status;
  final String timestamp;
  final String fileType;

  HistoryItem({
    required this.id,
    required this.type,
    required this.fileName,
    required this.sourceLanguage,
    required this.sourceCode,
    required this.targetLanguage,
    required this.targetCode,
    required this.pageCount,
    required this.originalSizeMb,
    required this.translatedSizeMb,
    required this.status,
    required this.timestamp,
    required this.fileType,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] ?? '',
      type: json['type'] ?? 'text',
      fileName: json['fileName'] ?? 'Document',
      sourceLanguage: json['sourceLanguage'] ?? 'English',
      sourceCode: json['sourceCode'] ?? 'en',
      targetLanguage: json['targetLanguage'] ?? 'Spanish',
      targetCode: json['targetCode'] ?? 'es',
      pageCount: json['pageCount'] ?? 1,
      originalSizeMb: (json['originalSizeMb'] ?? 1.0).toDouble(),
      translatedSizeMb: (json['translatedSizeMb'] ?? 0.5).toDouble(),
      status: json['status'] ?? 'Completed',
      timestamp: json['timestamp'] ?? 'Just now',
      fileType: json['fileType'] ?? 'PDF',
    );
  }
}

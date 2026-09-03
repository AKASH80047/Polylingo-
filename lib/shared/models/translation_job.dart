class JobStep {
  final String label;
  final String status; // 'pending', 'processing', 'completed'

  JobStep({required this.label, required this.status});

  factory JobStep.fromJson(Map<String, dynamic> json) {
    return JobStep(
      label: json['label'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}

class TranslationJob {
  final String id;
  final String type;
  final String fileName;
  final double fileSize;
  final String sourceLanguage;
  final String targetLanguage;
  final String status;
  final double progress;
  final String currentStep;
  final int pageCount;
  final int currentPage;
  final List<JobStep> steps;
  final Map<String, dynamic>? result;
  final String? error;

  TranslationJob({
    required this.id,
    required this.type,
    required this.fileName,
    required this.fileSize,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.status,
    required this.progress,
    required this.currentStep,
    required this.pageCount,
    required this.currentPage,
    required this.steps,
    this.result,
    this.error,
  });

  factory TranslationJob.fromJson(Map<String, dynamic> json) {
    var rawSteps = json['steps'] as List? ?? [];
    List<JobStep> stepList = rawSteps.map((s) => JobStep.fromJson(s)).toList();

    return TranslationJob(
      id: json['id'] ?? '',
      type: json['type'] ?? 'pdf',
      fileName: json['fileName'] ?? 'Document.pdf',
      fileSize: (json['fileSize'] ?? 1.0).toDouble(),
      sourceLanguage: json['sourceLanguage'] ?? 'en',
      targetLanguage: json['targetLanguage'] ?? 'es',
      status: json['status'] ?? 'Uploading',
      progress: (json['progress'] ?? 0).toDouble(),
      currentStep: json['currentStep'] ?? 'Initializing...',
      pageCount: json['pageCount'] ?? 1,
      currentPage: json['currentPage'] ?? 1,
      steps: stepList,
      result: json['result'],
      error: json['error'],
    );
  }
}

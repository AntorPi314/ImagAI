class HistoryModel {
  final String id;
  final String title;
  final String prompt;
  final String resultText;
  final String imagePath;
  final String fileName;
  final String sizeLabel;

  const HistoryModel({
    required this.id,
    required this.title,
    required this.prompt,
    required this.resultText,
    required this.imagePath,
    required this.fileName,
    required this.sizeLabel,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'prompt': prompt,
      'resultText': resultText,
      'imagePath': imagePath,
      'fileName': fileName,
      'sizeLabel': sizeLabel,
    };
  }

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      resultText: json['resultText'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      sizeLabel: json['sizeLabel'] as String? ?? '',
    );
  }
}

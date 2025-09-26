class ProcessingResult {
  final int? id;
  final String imagePath;
  final String prediction;
  final double confidence;
  final String processedAt;

  ProcessingResult({
    this.id,
    required this.imagePath,
    required this.prediction,
    required this.confidence,
    required this.processedAt,
  });

  factory ProcessingResult.fromMap(Map<String, dynamic> map) {
    return ProcessingResult(
      id: map['id'],
      imagePath: map['image_path'],
      prediction: map['prediction'],
      confidence: map['confidence'],
      processedAt: map['processed_at'],
    );
  }
}
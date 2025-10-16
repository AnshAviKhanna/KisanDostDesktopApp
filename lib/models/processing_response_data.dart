class ProcessingResponseData {
  final String processedImagePath;
  final int ripeCount;
  final int unripeCount;

  ProcessingResponseData({
    required this.processedImagePath,
    required this.ripeCount,
    required this.unripeCount,
  });

  factory ProcessingResponseData.fromMap(Map<String, dynamic> map) {
    return ProcessingResponseData(
      processedImagePath: map['processed_image_path'],
      ripeCount: map['ripe_count'],
      unripeCount: map['unripe_count'],
    );
  }
}
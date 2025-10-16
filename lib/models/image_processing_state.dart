enum ProcessingStatus { idle, processing, complete, error }

class ImageProcessingState {
  final String originalPath;
  String? processedPath;
  ProcessingStatus status;
  String? errorMessage;
  int? ripeCount;
  int? unripeCount;

  ImageProcessingState({required this.originalPath})
      : status = ProcessingStatus.idle,
        processedPath = null,
        errorMessage = null,
        ripeCount = null,
        unripeCount = null;
}
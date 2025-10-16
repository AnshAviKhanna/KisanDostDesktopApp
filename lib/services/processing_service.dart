import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kisandost_app/models/processing_response_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class ProcessingService {
  final String _baseUrl = 'http://localhost:8081';

  Future<ProcessingResponseData> processImage(String imagePath) async {
    final supportDir = await getApplicationSupportDirectory();
    final outputDir = Directory(path.join(supportDir.path, 'processed_images'));

    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    final originalFileName = path.basenameWithoutExtension(imagePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final processedFileName = '${originalFileName}_${timestamp}_processed.jpg';
    final outputPath = path.join(outputDir.path, processedFileName);

    final response = await http.post(
      Uri.parse('$_baseUrl/process-image'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'image_path': imagePath,
        'output_path': outputPath, 
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ProcessingResponseData.fromMap(data);
    } else {
      String errorMessage = response.body;
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['error'] != null) {
          errorMessage = errorData['error'];
        }
      } catch (_) {
      }
      throw Exception('Failed to process image: $errorMessage');
    }
  }
}
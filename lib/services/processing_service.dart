import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ProcessingService {
  final String _apiUrl = 'http://localhost:8081';

  /// Starts a new processing session by calling the local Go API server.
  ///
  /// Returns the path to the newly created database file for this session.
  Future<String> startNewSession(List<String> imagePaths) async {
    final url = Uri.parse('$_apiUrl/start-processing');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'image_paths': imagePaths}),
      );

      if (response.statusCode == 202) { // 202 Accepted
        final responseBody = json.decode(response.body);
        debugPrint('Processing session started. DB path: ${responseBody['database_path']}');
        return responseBody['database_path'];
      } else {
        debugPrint('API server returned an error: ${response.statusCode} ${response.body}');
        throw Exception('Failed to start processing session.');
      }
    } catch (e) {
      debugPrint('Error connecting to local API server: $e');
      throw Exception(
        'Could not connect to the local processing server. Please ensure it is running.'
      );
    }
  }
}
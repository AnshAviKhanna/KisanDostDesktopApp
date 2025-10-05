import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ProcessingService {
  final String _baseUrl = 'http://localhost:8081';

  Future<String> startNewSession(List<String> filePaths) async {
    // 1. Get the app's private, sandboxed-safe directory
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final String dbDir = path.join(appSupportDir.path, 'sessions');

    // 2. Create the directory if it doesn't exist
    await Directory(dbDir).create(recursive: true);

    final response = await http.post(
      Uri.parse('$_baseUrl/start-processing'),
      headers: {'Content-Type': 'application/json'},
      // 3. Send the safe directory path in the request body
      body: jsonEncode({
        'image_paths': filePaths,
        'database_dir': dbDir,
      }),
    );

    if (response.statusCode == 202) { // StatusAccepted
      final data = jsonDecode(response.body);
      return data['database_path'];
    } else {
      throw Exception('Failed to start processing: ${response.body}');
    }
  }
}
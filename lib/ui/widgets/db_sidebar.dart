import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kisandost_app/services/processing_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class _DbSidebarState extends State<DbSidebar> {
  final ProcessingService _processingService = ProcessingService();
  // ... (rest of the state variables are the same)

  Future<void> _startNewSession() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (result != null) {
      setState(() => _isLoading = true);

      final filePaths = result.paths.where((p) => p != null).map((p) => p!).toList();
      
      try {
        // Call the Go API server via the service
        final newDbPath = await _processingService.startNewSession(filePaths);
        
        // Refresh the list of DBs and select the new one
        await _loadDbFiles();
        widget.onDbSelected(newDbPath);

      } catch (e) {
        // Show an error to the user if the server connection fails
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Processing Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // The rest of the file (_loadDbFiles, build method) remains the same.
  // Full code for brevity:
  List<File> _dbFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDbFiles();
  }

  Future<void> _loadDbFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir
        .listSync()
        .where((item) => item.path.endsWith('.db'))
        .whereType<File>()
        .toList();

    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    setState(() {
      _dbFiles = files;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Material(
        color: Theme.of(context).colorScheme.surface.withAlpha(50),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _startNewSession,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add),
                label: const Text('New Processing Session'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _dbFiles.isEmpty
                  ? const Center(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No sessions yet. Click "New" to start.', textAlign: TextAlign.center,),
                  ))
                  : ListView.builder(
                      itemCount: _dbFiles.length,
                      itemBuilder: (context, index) {
                        final file = _dbFiles[index];
                        final fileName = path.basename(file.path);
                        final isSelected = file.path == widget.selectedDbPath;
                        return ListTile(
                          title:
                              Text(fileName, overflow: TextOverflow.ellipsis),
                          leading: const Icon(Icons.analytics_outlined),
                          selected: isSelected,
                          selectedTileColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.4),
                          onTap: () => widget.onDbSelected(file.path),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ensure the class definition is present
class DbSidebar extends StatefulWidget {
  final Function(String) onDbSelected;
  final String? selectedDbPath;

  const DbSidebar({
    super.key,
    required this.onDbSelected,
    this.selectedDbPath,
  });

  @override
  State<DbSidebar> createState() => _DbSidebarState();
}
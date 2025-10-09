import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kisandost_app/services/processing_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class _DbSidebarState extends State<DbSidebar> {
  final ProcessingService _processingService = ProcessingService();
  List<File> _dbFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDbFiles();
  }

  // This is the method that needed to be fixed
  Future<void> _loadDbFiles() async {
    // --- CHANGE 1: Get the Application Support directory, not Documents ---
    final supportDir = await getApplicationSupportDirectory();
    final sessionsDir = Directory(path.join(supportDir.path, 'sessions'));

    // If the folder doesn't exist yet (e.g., on first run), create it to avoid errors.
    if (!await sessionsDir.exists()) {
      await sessionsDir.create(recursive: true);
    }
    
    // --- CHANGE 2: List files from the correct 'sessions' directory ---
    final files = sessionsDir
        .listSync()
        .where((item) => item.path.endsWith('.db'))
        .whereType<File>()
        .toList();

    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    if (mounted) {
      setState(() {
        _dbFiles = files;
      });
    }
  }

  Future<void> _startNewSession() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (result != null) {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final filePaths =
          result.paths.where((p) => p != null).map((p) => p!).toList();

      try {
        final newDbPath = await _processingService.startNewSession(filePaths);
        await _loadDbFiles(); // Refresh the list of DBs
        if (mounted) {
          widget.onDbSelected(newDbPath); // Select the new one
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Processing Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // The build method remains exactly the same
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
                  ? const Center(
                      child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'No sessions yet. Click "New" to start.',
                        textAlign: TextAlign.center,
                      ),
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
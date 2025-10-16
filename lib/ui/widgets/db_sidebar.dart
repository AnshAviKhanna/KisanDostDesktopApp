import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class _DbSidebarState extends State<DbSidebar> {
  List<File> _dbFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDbFiles();
  }

  Future<void> _loadDbFiles() async {
    final supportDir = await getApplicationSupportDirectory();
    final sessionsDir = Directory(path.join(supportDir.path, 'sessions'));
    if (!await sessionsDir.exists()) {
      await sessionsDir.create(recursive: true);
    }
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
    setState(() => _isLoading = true);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false, 
      type: FileType.image,
    );
    setState(() => _isLoading = false);

    if (result != null && result.files.single.path != null) {
      widget.onImageSelected(result.files.single.path!);
    }
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
                  ? const Center(
                      child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'No past sessions found.',
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
                          subtitle: const Text("Past Session"),
                          leading: const Icon(Icons.history),
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


class DbSidebar extends StatefulWidget {
  final Function(String) onDbSelected;
  final Function(String) onImageSelected;
  final String? selectedDbPath;

  const DbSidebar({
    super.key,
    required this.onDbSelected,
    required this.onImageSelected, 
    this.selectedDbPath,
  });

  @override
  State<DbSidebar> createState() => _DbSidebarState();
}
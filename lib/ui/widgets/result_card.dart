import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kisandost_app/models/image_processing_state.dart';
import 'package:path/path.dart' as path;

class ResultCard extends StatelessWidget {
  final ImageProcessingState imageState;
  final VoidCallback onProcess;

  const ResultCard({
    super.key,
    required this.imageState,
    required this.onProcess,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = path.basename(imageState.originalPath);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fileName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            _buildCardBody(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBody(BuildContext context) {
    switch (imageState.status) {
      case ProcessingStatus.complete:
        return Row(
          children: [
            Expanded(
              child: _buildImageColumn('Original', imageState.originalPath),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildImageColumn(
                  'Processed', imageState.processedPath!),
            ),
          ],
        );
      
      case ProcessingStatus.processing:
        return Row(
          children: [
            _buildImageDisplay(imageState.originalPath),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Processing...'),
                ],
              ),
            ),
          ],
        );

      case ProcessingStatus.error:
         return Row(
          children: [
            _buildImageDisplay(imageState.originalPath),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 const Icon(Icons.error_outline, color: Colors.red, size: 28),
                 const SizedBox(height: 8),
                 Text('Error:', style: Theme.of(context).textTheme.titleSmall),
                 Text(imageState.errorMessage ?? 'An unknown error occurred.',
                  style: const TextStyle(color: Colors.red)),
                ],
              )
            )
          ],
        );

      case ProcessingStatus.idle:
      default:
        return Row(
          children: [
            _buildImageDisplay(imageState.originalPath),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onProcess,
                icon: const Icon(Icons.hub_outlined),
                label: const Text('Process'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildImageColumn(String label, String imagePath) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildImageDisplay(imagePath),
      ],
    );
  }

  Widget _buildImageDisplay(String imagePath) {
    return SizedBox(
      width: 150,
      height: 150,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }
}
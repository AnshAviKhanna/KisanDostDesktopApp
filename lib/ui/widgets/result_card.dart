import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kisandost_app/models/processing_result.dart';
import 'package:path/path.dart' as path;

class ResultCard extends StatelessWidget {
  final ProcessingResult result;

  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final fileName = path.basename(result.imagePath);
    final confidencePercentage = (result.confidence * 100).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  File(result.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image,
                        size: 40, color: Colors.grey);
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prediction: ${result.prediction}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Confidence: $confidencePercentage%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
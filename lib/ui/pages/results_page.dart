import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kisandost_app/models/image_processing_state.dart';
import 'package:kisandost_app/services/processing_service.dart';
import 'package:path/path.dart' as path;

class ResultsPage extends StatefulWidget {
  final String imagePath;

  const ResultsPage({super.key, required this.imagePath});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  late ImageProcessingState _imageState;
  final ProcessingService _processingService = ProcessingService();

  @override
  void initState() {
    super.initState();
    _imageState = ImageProcessingState(originalPath: widget.imagePath);
  }

  Future<void> _processImage() async {
    setState(() {
      _imageState.status = ProcessingStatus.processing;
    });

    try {
      final responseData =
          await _processingService.processImage(_imageState.originalPath);
      
      setState(() {
        _imageState.status = ProcessingStatus.complete;
        _imageState.processedPath = responseData.processedImagePath;
        _imageState.ripeCount = responseData.ripeCount;
        _imageState.unripeCount = responseData.unripeCount;
      });
    } catch (e) {
      setState(() {
        _imageState.status = ProcessingStatus.error;
        _imageState.errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = path.basename(_imageState.originalPath);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Process: $fileName'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: _buildImageView(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 60,
              child: _buildActionWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageView() {
    if (_imageState.status == ProcessingStatus.complete) {
      return Row(
        children: [
          _buildImageDisplay('Original', _imageState.originalPath),
          const SizedBox(width: 16),
          _buildImageDisplay('Processed', _imageState.processedPath!, state: _imageState),
        ],
      );
    } else {
      return _buildImageDisplay('Input Image', _imageState.originalPath,
          isCentered: true);
    }
  }

  Widget _buildActionWidget() {
    switch (_imageState.status) {
      case ProcessingStatus.processing:
        return const Center(child: CircularProgressIndicator());
      case ProcessingStatus.error:
        return Center(
          child: Text(
            'Error: ${_imageState.errorMessage}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        );
      case ProcessingStatus.complete:
        return const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Processing Complete', style: TextStyle(fontSize: 18)),
            ],
          ),
        );
      case ProcessingStatus.idle:
      default:
        return SizedBox(
          width: 200,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _processImage,
            icon: const Icon(Icons.hub_outlined),
            label: const Text('Process Image'),
          ),
        );
    }
  }

  Widget _buildImageDisplay(String label, String imagePath,
      {bool isCentered = false, ImageProcessingState? state}) {
    Widget imageContent = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print("--- FLUTTER IMAGE LOAD ERROR ---");
                  print("Failed to load image at path: $imagePath");
                  print("Error: $error");
                  print("---------------------------------");
                  return const Center(
                      child: Icon(Icons.broken_image,
                          size: 60, color: Colors.grey));
                },
              ),
            ),
          ),
        ),
        if (state?.status == ProcessingStatus.complete)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCountChip('Ripe', state!.ripeCount ?? 0, Colors.green),
                _buildCountChip('Unripe', state.unripeCount ?? 0, Colors.orange),
              ],
            ),
          )
      ],
    );

    return isCentered
        ? Center(child: AspectRatio(aspectRatio: 1.0, child: imageContent))
        : Expanded(child: imageContent);
  }

  Widget _buildCountChip(String label, int count, Color color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.withOpacity(0.8),
        child: Text(
          count.toString(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}
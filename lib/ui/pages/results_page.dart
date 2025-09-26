import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kisandost_app/models/processing_result.dart';
import 'package:kisandost_app/services/database_service.dart';
import 'package:kisandost_app/ui/widgets/result_card.dart';
import 'package:path/path.dart' as path;

class ResultsPage extends StatefulWidget {
  final String dbPath;

  const ResultsPage({super.key, required this.dbPath});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  late Future<List<ProcessingResult>> _resultsFuture;
  late final DatabaseService _dbService;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(dbPath: widget.dbPath);
    _fetchResults();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchResults();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _fetchResults() {
    setState(() {
      _resultsFuture = _dbService.getAllResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Results: ${path.basename(widget.dbPath)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchResults,
            tooltip: 'Refresh Results',
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<ProcessingResult>>(
        future: _resultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              (!snapshot.hasData || snapshot.data!.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Processing images...\nResults will appear here automatically.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final results = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: results.length,
            itemBuilder: (context, index) {
              return ResultCard(result: results[index]);
            },
          );
        },
      ),
    );
  }
}
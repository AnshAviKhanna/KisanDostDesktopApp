import 'package:kisandost_app/models/processing_result.dart'; // Make sure this path is correct
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  Database? _database;
  final String dbPath;

  DatabaseService({required this.dbPath});

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbFactory = databaseFactoryFfi;
    return await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDB,
      ),
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS results (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          image_path TEXT NOT NULL UNIQUE,
          prediction TEXT NOT NULL,
          confidence REAL NOT NULL,
          processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<List<ProcessingResult>> getAllResults() async {
    final db = await database;
    final result = await db.query('results', orderBy: 'id DESC');
    return result.map((json) => ProcessingResult.fromMap(json)).toList();
  }
}
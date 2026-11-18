import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../core/exceptions.dart';

/// Apertura y esquema de la base SQLite. Una sola responsabilidad:
/// entregar una conexión lista para usarse.
class WalkDatabase {
  static const _name = 'paseo_perruno.db';
  static const _version = 1;
  static const table = 'walks';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    try {
      final dir = await getDatabasesPath();
      _db = await openDatabase(
        p.join(dir, _name),
        version: _version,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE $table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            dog_name TEXT NOT NULL,
            notes TEXT NOT NULL,
            duration_minutes INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            image_path TEXT,
            latitude REAL,
            longitude REAL
          )
        '''),
      );
      return _db!;
    } catch (e) {
      throw StorageException('No se pudo abrir la base de datos.', e);
    }
  }
}

import '../core/exceptions.dart';
import '../domain/models/walk_entry.dart';
import '../domain/repositories/walk_repository.dart';
import 'walk_database.dart';

/// Implementación SQLite de [WalkRepository].
///
/// Cada operación captura errores de sqflite y los convierte en
/// [StorageException] para que la UI muestre un mensaje claro.
class SqliteWalkRepository implements WalkRepository {
  final WalkDatabase _database;

  SqliteWalkRepository(this._database);

  @override
  Future<List<WalkEntry>> getAll() async {
    try {
      final db = await _database.database;
      final rows = await db.query(WalkDatabase.table, orderBy: 'created_at DESC');
      return rows.map(WalkEntry.fromMap).toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw StorageException('No se pudieron cargar los paseos.', e);
    }
  }

  @override
  Future<WalkEntry?> getById(int id) async {
    try {
      final db = await _database.database;
      final rows =
          await db.query(WalkDatabase.table, where: 'id = ?', whereArgs: [id], limit: 1);
      return rows.isEmpty ? null : WalkEntry.fromMap(rows.first);
    } on AppException {
      rethrow;
    } catch (e) {
      throw StorageException('No se pudo cargar el paseo.', e);
    }
  }

  @override
  Future<WalkEntry> insert(WalkEntry entry) async {
    try {
      final db = await _database.database;
      final id = await db.insert(WalkDatabase.table, entry.toMap()..remove('id'));
      return entry.copyWith(id: id);
    } on AppException {
      rethrow;
    } catch (e) {
      throw StorageException('No se pudo guardar el paseo.', e);
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      final db = await _database.database;
      await db.delete(WalkDatabase.table, where: 'id = ?', whereArgs: [id]);
    } on AppException {
      rethrow;
    } catch (e) {
      throw StorageException('No se pudo eliminar el paseo.', e);
    }
  }
}

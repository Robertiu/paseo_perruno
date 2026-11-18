import '../models/walk_entry.dart';

/// Contrato de acceso a los paseos (DIP): la UI depende de esta
/// abstracción, no de SQLite. Cambiar de motor de almacenamiento solo
/// requiere otra implementación.
abstract class WalkRepository {
  Future<List<WalkEntry>> getAll();
  Future<WalkEntry?> getById(int id);
  Future<WalkEntry> insert(WalkEntry entry);
  Future<void> delete(int id);
}

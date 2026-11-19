import '../models/game.dart';
import '../models/walk_entry.dart';

/// Resultado de guardar un paseo: el registro creado y lo que ganó el usuario.
class SavedWalk {
  final WalkEntry entry;
  final Reward reward;
  const SavedWalk(this.entry, this.reward);
}

/// Contrato de acceso a paseos (CRUD). La UI depende de esta abstracción.
abstract interface class WalkRepository {
  Future<List<WalkEntry>> getAll();
  Future<SavedWalk> insert(WalkEntry entry);
  Future<WalkEntry> update(WalkEntry entry);
  Future<void> delete(String id);
}

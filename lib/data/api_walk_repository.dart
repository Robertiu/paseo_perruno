import '../domain/models/game.dart';
import '../domain/models/walk_entry.dart';
import '../domain/repositories/walk_repository.dart';
import 'api_client.dart';

/// Implementación de [WalkRepository] sobre la API (Redis en la nube).
class ApiWalkRepository implements WalkRepository {
  final ApiClient _api;
  ApiWalkRepository(this._api);

  @override
  Future<List<WalkEntry>> getAll() async {
    final list = await _api.get('/walks') as List;
    return list.map((j) => WalkEntry.fromJson(j as Map<String, dynamic>)).toList();
  }

  @override
  Future<SavedWalk> insert(WalkEntry entry) async {
    final json = await _api.post('/walks', entry.toJson()) as Map<String, dynamic>;
    return SavedWalk(
      WalkEntry.fromJson(json['walk'] as Map<String, dynamic>),
      Reward.fromJson(json['reward'] as Map<String, dynamic>),
    );
  }

  @override
  Future<WalkEntry> update(WalkEntry entry) async {
    final json = await _api.put('/walks/${entry.id}', {
      'dogName': entry.dogName,
      'notes': entry.notes,
      'durationMinutes': entry.durationMinutes,
    }) as Map<String, dynamic>;
    return WalkEntry.fromJson(json);
  }

  @override
  Future<void> delete(String id) => _api.delete('/walks/$id');
}

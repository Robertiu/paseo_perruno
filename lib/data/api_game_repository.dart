import '../domain/models/game.dart';
import '../domain/repositories/game_repository.dart';
import 'api_client.dart';

class ApiGameRepository implements GameRepository {
  final ApiClient _api;
  ApiGameRepository(this._api);

  @override
  Future<bool> hasSession() => _api.loadSession();

  @override
  Future<void> signUp(String name) => _open('/walkers', name);

  @override
  Future<void> logIn(String name) => _open('/login', name);

  Future<void> _open(String path, String name) async {
    final json = await _api.post(path, {'name': name}) as Map<String, dynamic>;
    await _api.saveSession(json['token'] as String);
  }

  @override
  Future<void> logOut() async {
    try {
      await _api.post('/logout');
    } finally {
      await _api.clearSession();
    }
  }

  @override
  Future<Profile> profile() async => Profile.fromJson(await _api.get('/me') as Map<String, dynamic>);

  @override
  Future<Leaderboard> leaderboard({required bool weekly}) async => Leaderboard.fromJson(
      await _api.get('/leaderboard', query: {'scope': weekly ? 'week' : 'global'}) as Map<String, dynamic>);
}

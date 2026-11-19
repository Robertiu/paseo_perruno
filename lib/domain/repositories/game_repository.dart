import '../models/game.dart';

/// Sesión, perfil y ranking.
abstract interface class GameRepository {
  Future<bool> hasSession();
  Future<void> signUp(String name);
  Future<void> logIn(String name);
  Future<void> logOut();
  Future<Profile> profile();
  Future<Leaderboard> leaderboard({required bool weekly});
}

import 'package:flutter/widgets.dart';

import 'data/api_client.dart';
import 'data/api_game_repository.dart';
import 'data/api_walk_repository.dart';
import 'domain/models/game.dart';
import 'domain/repositories/game_repository.dart';
import 'domain/repositories/walk_repository.dart';
import 'services/location_service.dart';
import 'services/media_service.dart';
import 'services/speech_service.dart';

/// Contenedor de dependencias. Se arma una vez en `main` y se expone con
/// un [InheritedWidget]; las pantallas piden abstracciones, no clases concretas.
class AppServices extends InheritedWidget {
  final WalkRepository walks;
  final GameRepository game;
  final MediaService media;
  final LocationService location;
  final SpeechService speech;

  /// Perfil en caché: el header de todas las pantallas lo escucha.
  final ValueNotifier<Profile?> profile;

  const AppServices({
    super.key,
    required this.walks,
    required this.game,
    required this.media,
    required this.location,
    required this.speech,
    required this.profile,
    required super.child,
  });

  factory AppServices.production({Key? key, required Widget child}) {
    final api = ApiClient();
    return AppServices(
      key: key,
      walks: ApiWalkRepository(api),
      game: ApiGameRepository(api),
      media: MediaService(),
      location: LocationService(),
      speech: SpeechService(),
      profile: ValueNotifier<Profile?>(null),
      child: child,
    );
  }

  /// Vuelve a pedir el perfil a la API y avisa a quien lo escucha.
  Future<void> refreshProfile() async {
    try {
      profile.value = await game.profile();
    } catch (_) {
      // El header simplemente conserva el último perfil conocido.
    }
  }

  static AppServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppServices>()!;

  @override
  bool updateShouldNotify(AppServices oldWidget) => false;
}

import 'package:flutter/widgets.dart';

import 'data/sqlite_walk_repository.dart';
import 'data/walk_database.dart';
import 'domain/repositories/walk_repository.dart';
import 'services/location_service.dart';
import 'services/media_service.dart';
import 'services/speech_service.dart';

/// Contenedor de dependencias. Se arma una vez en `main` y se expone con
/// un [InheritedWidget]; las pantallas piden abstracciones, no clases concretas.
class AppServices extends InheritedWidget {
  final WalkRepository walks;
  final MediaService media;
  final LocationService location;
  final SpeechService speech;

  const AppServices({
    super.key,
    required this.walks,
    required this.media,
    required this.location,
    required this.speech,
    required super.child,
  });

  factory AppServices.production({Key? key, required Widget child}) => AppServices(
        key: key,
        walks: SqliteWalkRepository(WalkDatabase()),
        media: MediaService(),
        location: LocationService(),
        speech: SpeechService(),
        child: child,
      );

  static AppServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppServices>()!;

  @override
  bool updateShouldNotify(AppServices oldWidget) => false;
}

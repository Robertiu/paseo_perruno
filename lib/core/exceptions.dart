/// Excepción de la app con un mensaje apto para mostrar al usuario.
///
/// Las capas de datos y servicios traducen los errores de plataforma a
/// este tipo para que la UI no dependa de excepciones de cada paquete.
class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, [this.cause]);

  @override
  String toString() => 'AppException: $message${cause != null ? ' ($cause)' : ''}';
}

class StorageException extends AppException {
  const StorageException(super.message, [super.cause]);
}

class LocationException extends AppException {
  const LocationException(super.message, [super.cause]);
}

class MediaException extends AppException {
  const MediaException(super.message, [super.cause]);
}

class SpeechException extends AppException {
  const SpeechException(super.message, [super.cause]);
}

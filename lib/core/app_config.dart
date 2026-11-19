/// URL del backend. En el emulador Android `10.0.2.2` apunta al equipo anfitrión;
/// para otro destino: `flutter run --dart-define=API_URL=https://mi-api.onrender.com`.
abstract final class AppConfig {
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:3000');
}

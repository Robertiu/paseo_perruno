import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/exceptions.dart';

/// Gadget 3: GPS y apertura de Google Maps.
class LocationService {
  /// Obtiene la posición actual, pidiendo permiso si hace falta.
  Future<Position> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationException('El GPS está desactivado.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const LocationException('Permiso de ubicación denegado.');
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on LocationException {
      rethrow;
    } catch (e) {
      throw LocationException('No se pudo obtener la ubicación.', e);
    }
  }

  /// Abre Google Maps (app o navegador) en las coordenadas dadas.
  Future<void> openInMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw const LocationException('No se pudo abrir Google Maps.');
    } on LocationException {
      rethrow;
    } catch (e) {
      throw LocationException('No se pudo abrir Google Maps.', e);
    }
  }
}

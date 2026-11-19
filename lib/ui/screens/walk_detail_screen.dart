import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../app_services.dart';
import '../../core/exceptions.dart';
import '../../domain/models/walk_entry.dart';
import '../widgets/walk_image.dart';

/// Detalle del paseo: foto (Hero), notas y mapa interactivo con botón
/// para abrir Google Maps.
class WalkDetailScreen extends StatelessWidget {
  final WalkEntry entry;

  const WalkDetailScreen({super.key, required this.entry});

  Future<void> _delete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final repo = AppServices.of(context).walks;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar paseo'),
        content: Text('¿Eliminar el paseo de ${entry.dogName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await repo.delete(entry.id!);
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e is AppException ? e.message : 'No se pudo eliminar.'),
      ));
    }
  }

  Future<void> _openMaps(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AppServices.of(context)
          .location
          .openInMaps(entry.latitude!, entry.longitude!);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(
            e is AppException ? e.message : 'No se pudo abrir Google Maps.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final date =
        DateFormat("EEEE d 'de' MMMM y, HH:mm", 'es').format(entry.createdAt);
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.dogName),
        actions: [
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context),
          ),
        ],
      ),
      body: ListView(
        children: [
          WalkImage(entry: entry, height: 260, width: double.infinity),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text('${entry.durationMinutes} minutos de paseo'),
                const SizedBox(height: 16),
                Text(entry.notes.isEmpty ? 'Sin notas.' : entry.notes),
                const SizedBox(height: 24),
                if (entry.hasLocation) ...[
                  _WalkMap(entry: entry),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _openMaps(context),
                    icon: const Icon(Icons.map),
                    label: const Text('Abrir en Google Maps'),
                  ),
                ] else
                  const Text('Este paseo no tiene ubicación guardada.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkMap extends StatelessWidget {
  final WalkEntry entry;

  const _WalkMap({required this.entry});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(entry.latitude!, entry.longitude!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(initialCenter: point, initialZoom: 16),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.paseo_perruno',
            ),
            MarkerLayer(markers: [
              Marker(
                point: point,
                width: 40,
                height: 40,
                child:
                    const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

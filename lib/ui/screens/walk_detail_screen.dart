import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/exceptions.dart';
import '../../core/routes.dart';
import '../../domain/models/walk_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/walk_image.dart';

/// Detalle del paseo: foto (Hero), notas, mapa y acciones de editar / eliminar.
class WalkDetailScreen extends StatelessWidget {
  final WalkEntry entry;

  const WalkDetailScreen({super.key, required this.entry});

  Future<void> _delete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final services = AppServices.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar paseo', style: Tk.display(20)),
        content: Text('¿Eliminar el paseo de ${entry.dogName}? También se restará su XP.', style: Tk.body(14, height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await services.walks.delete(entry.id!);
      services.refreshProfile();
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo eliminar.')));
    }
  }

  Future<void> _edit(BuildContext context) async {
    final navigator = Navigator.of(context);
    final saved = await navigator.pushNamed(AppRoutes.form, arguments: entry);
    if (saved == true) navigator.pop(true);
  }

  Future<void> _openMaps(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AppServices.of(context).location.openInMaps(entry.latitude!, entry.longitude!);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo abrir Google Maps.')));
    }
  }

  Widget _chip(IconData icon, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Tk.card, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(text, style: Tk.body(12, w: FontWeight.w600, color: Tk.ink)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final date = DateFormat("EEEE d 'de' MMMM y, HH:mm", 'es').format(entry.createdAt);
    return AppShell(
      title: entry.dogName,
      back: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Tk.pad, 20, Tk.pad, 32),
        children: [
          PageTitle(entry.dogName),
          if (entry.hasImage) ...[
            WalkImage(entry: entry, height: 240, width: double.infinity),
            const SizedBox(height: 16),
          ],
          Text(date, style: Tk.body(12, w: FontWeight.w600, color: Tk.rust)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _chip(Icons.schedule, '${entry.durationMinutes} min', Tk.blue),
            _chip(Icons.bolt, '+${entry.xp} XP', Tk.rust),
            if (entry.hasLocation) _chip(Icons.near_me_outlined, 'GPS', Tk.green),
          ]),
          const Rule(gap: 20),
          Text('Notas del sendero', style: Tk.body(14, w: FontWeight.w700, color: Tk.ink)),
          const SizedBox(height: 8),
          Text(entry.notes.isEmpty ? 'Sin notas.' : '“${entry.notes}”', style: Tk.body(14, height: 1.5)),
          const Rule(gap: 20),
          if (entry.hasLocation) ...[
            _WalkMap(entry: entry),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openMaps(context),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Abrir en Google Maps'),
            ),
          ] else
            Row(children: [
              const Icon(Icons.location_off_outlined, size: 18, color: Tk.inkSoft),
              const SizedBox(width: 8),
              Expanded(child: Text('Este paseo no tiene ubicación guardada.', style: Tk.body(13))),
            ]),
          const Rule(gap: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _edit(context),
                style: OutlinedButton.styleFrom(foregroundColor: Tk.green),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _delete(context),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Eliminar'),
              ),
            ),
          ]),
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
      borderRadius: BorderRadius.circular(Tk.radius),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(initialCenter: point, initialZoom: 16),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.paseo_perruno'),
            MarkerLayer(markers: [
              Marker(point: point, width: 40, height: 40, child: const Icon(Icons.location_on, color: Tk.rust, size: 40)),
            ]),
          ],
        ),
      ),
    );
  }
}

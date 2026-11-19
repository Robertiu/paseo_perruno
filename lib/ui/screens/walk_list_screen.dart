import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/exceptions.dart';
import '../../core/routes.dart';
import '../../domain/models/game.dart';
import '../../domain/models/walk_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/walk_image.dart';

enum _Filter { all, week, photos }

/// Mis paseos: reto del día, filtros y bitácora de paseos.
class WalkListScreen extends StatefulWidget {
  const WalkListScreen({super.key});

  @override
  State<WalkListScreen> createState() => _WalkListScreenState();
}

class _WalkListScreenState extends State<WalkListScreen> {
  Future<List<WalkEntry>>? _future;
  _Filter _filter = _Filter.all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppServices.of(context).walks.getAll();
  }

  Future<void> _reload() {
    final services = AppServices.of(context);
    final future = services.walks.getAll();
    setState(() => _future = future);
    services.refreshProfile();
    return future.then((_) {}, onError: (_) {});
  }

  Future<void> _openDetail(WalkEntry entry) async {
    final changed = await Navigator.pushNamed(context, AppRoutes.detail, arguments: entry);
    if (changed == true) _reload();
  }

  List<WalkEntry> _apply(List<WalkEntry> all) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    return switch (_filter) {
      _Filter.all => all,
      _Filter.week => all.where((w) => !w.createdAt.isBefore(monday)).toList(),
      _Filter.photos => all.where((w) => w.hasImage).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Mis paseos',
      tab: AppTab.walks,
      body: FutureBuilder<List<WalkEntry>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            if (snap.error is AuthException) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
              });
            }
            return ErrorRetry(error: snap.error!, onRetry: _reload);
          }
          final all = snap.data ?? [];
          final shown = _apply(all);
          return RefreshIndicator(
            color: Tk.rust,
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(Tk.pad, 20, Tk.pad, 24),
              children: [
                const PageTitle('Mis paseos'),
                _ChallengeBlock(walks: all),
                const Rule(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${shown.length} ${shown.length == 1 ? 'paseo' : 'paseos'}', style: Tk.label()),
                  Text(switch (_filter) { _Filter.all => 'Historial', _Filter.week => 'Esta semana', _Filter.photos => 'Con fotos' },
                      style: Tk.body(11)),
                ]),
                const SizedBox(height: 12),
                _FilterTabs(value: _filter, onChanged: (f) => setState(() => _filter = f)),
                const SizedBox(height: 8),
                if (shown.isEmpty)
                  const _EmptyWalks()
                else
                  for (final w in shown) _WalkCard(entry: w, onTap: () => _openDetail(w)),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.form),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Registrar nuevo hito de paseo'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Avance del reto del día calculado con los paseos de hoy.
({int current, int target, String unit}) challengeProgress(DailyChallenge c, List<WalkEntry> walks) {
  final today = dayKey(DateTime.now());
  final todays = walks.where((w) => w.localDay == today).toList();
  switch (c.type) {
    case 'minutes':
      final best = todays.fold<int>(0, (m, w) => w.durationMinutes > m ? w.durationMinutes : m);
      return (current: best.clamp(0, c.target), target: c.target, unit: 'min');
    case 'photo':
      return (current: todays.any((w) => w.hasImage) ? 1 : 0, target: 1, unit: 'foto');
    case 'location':
      return (current: todays.any((w) => w.hasLocation) ? 1 : 0, target: 1, unit: 'ubicación');
    default:
      return (current: todays.any((w) => w.notes.isNotEmpty) ? 1 : 0, target: 1, unit: 'nota');
  }
}

class _ChallengeBlock extends StatelessWidget {
  final List<WalkEntry> walks;
  const _ChallengeBlock({required this.walks});

  @override
  Widget build(BuildContext context) {
    final profile = AppServices.of(context).profile;
    return ValueListenableBuilder<Profile?>(
      valueListenable: profile,
      builder: (_, p, __) {
        if (p == null) return const SizedBox(height: 90);
        final c = p.challenge;
        final prog = challengeProgress(c, walks);
        final done = c.completed || prog.current >= prog.target;
        final left = prog.target - prog.current;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Reto del día', style: Tk.display(20)),
            Text('+${c.bonusXp} XP', style: Tk.body(15, w: FontWeight.w700, color: Tk.green)),
          ]),
          const SizedBox(height: 8),
          Text(c.title, style: Tk.display(16, color: Tk.inkSoft)),
          const SizedBox(height: 14),
          ProgressLine(value: prog.current / prog.target),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${prog.current} de ${prog.target} ${prog.unit}', style: Tk.body(12, color: Tk.ink)),
            Text(done ? 'Cumplido' : (prog.unit == 'min' ? 'Faltan $left min' : 'Pendiente'), style: Tk.body(12)),
          ]),
        ]);
      },
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final _Filter value;
  final ValueChanged<_Filter> onChanged;
  const _FilterTabs({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = {_Filter.all: 'Todos', _Filter.week: 'Esta semana', _Filter.photos: 'Con fotos'};
    return Row(children: [
      for (final f in _Filter.values)
        Expanded(
          child: InkWell(
            onTap: () => onChanged(f),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: f == value ? Tk.rust : Tk.line, width: f == value ? 2.5 : 1)),
              ),
              child: Text(labels[f]!,
                  style: Tk.body(12, w: f == value ? FontWeight.w700 : FontWeight.w500, color: f == value ? Tk.rust : Tk.inkSoft)),
            ),
          ),
        ),
    ]);
  }
}

class _EmptyWalks extends StatelessWidget {
  const _EmptyWalks();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Icon(Icons.pets, size: 44, color: Tk.rust),
          SizedBox(height: 12),
          Text('Aún no hay paseos aquí.\n¡Registra el primero!', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, color: Tk.inkSoft)),
        ]),
      );
}

String _kind(int minutes) => minutes >= 45 ? 'Paseo largo' : (minutes >= 20 ? 'Paseo medio' : 'Paseo corto');

String _when(DateTime d) {
  final now = DateTime.now();
  final time = DateFormat('h:mm a', 'es').format(d);
  final dd = DateTime(d.year, d.month, d.day);
  final today = DateTime(now.year, now.month, now.day);
  if (dd == today) return 'Hoy, $time';
  if (dd == today.subtract(const Duration(days: 1))) return 'Ayer, $time';
  return DateFormat("d 'de' MMMM", 'es').format(d);
}

class _WalkCard extends StatelessWidget {
  final WalkEntry entry;
  final VoidCallback onTap;
  const _WalkCard({required this.entry, required this.onTap});

  Widget _meta(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Tk.blue),
        const SizedBox(width: 5),
        Text(text, style: Tk.body(12, color: Tk.ink)),
      ]);

  @override
  Widget build(BuildContext context) {
    final metas = <Widget>[
      _meta(Icons.schedule, '${entry.durationMinutes} min'),
      if (entry.hasLocation) _meta(Icons.near_me_outlined, 'GPS'),
      if (entry.hasImage) _meta(Icons.photo_camera_outlined, 'Foto'),
    ];
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Tk.line))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_when(entry.createdAt), style: Tk.body(10)),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(entry.dogName, style: Tk.display(22))),
            Column(children: [
              Text('+${entry.xp}', style: Tk.body(12, w: FontWeight.w700, color: Tk.rust)),
              Text('XP', style: Tk.body(8, w: FontWeight.w600, color: Tk.rust)),
            ]),
          ]),
          Text(_kind(entry.durationMinutes), style: Tk.body(12, w: FontWeight.w600, color: Tk.green)),
          const SizedBox(height: 12),
          Wrap(spacing: 14, runSpacing: 6, children: metas),
          if (entry.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('“${entry.notes}”', maxLines: 3, overflow: TextOverflow.ellipsis, style: Tk.body(14, height: 1.5)),
          ],
          if (entry.hasImage) ...[
            const SizedBox(height: 14),
            WalkImage(entry: entry, width: double.infinity, height: 145),
          ],
          if (entry.durationMinutes >= 60) ...[
            const SizedBox(height: 14),
            const _Milestone(),
          ],
        ]),
      ),
    );
  }
}

class _Milestone extends StatelessWidget {
  const _Milestone();

  @override
  Widget build(BuildContext context) => SoftCard(
        child: Row(children: [
          const Icon(Icons.verified_outlined, color: Tk.rust, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Paseo maratonista', style: Tk.body(12, w: FontWeight.w700, color: Tk.ink)),
              Text('Hito superado: 60 min o más de ruta', style: Tk.body(10)),
            ]),
          ),
          const Icon(Icons.pets, color: Tk.rust, size: 20),
        ]),
      );
}

import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/routes.dart';
import '../../core/exceptions.dart';
import '../../domain/models/game.dart';
import '../widgets/trail_app_bar.dart';
import '../widgets/trail_navigation.dart';
import '../widgets/trail_progress.dart';
import '../trail_theme.dart';
import '../widgets/badge_icon.dart';

/// Perfil gamificado: nivel, racha, reto diario e insignias.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Profile>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppServices.of(context).game.profile();
  }

  Future<void> _reload() async {
    final future = AppServices.of(context).game.profile();
    setState(() {
      _future = future;
    });
    await future.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TrailAppBar(title: 'Mi perfil', profile: _future),
      bottomNavigationBar: const TrailNavigation(route: AppRoutes.profile),
      body: FutureBuilder<Profile>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            if (snap.error is AuthException) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppRoutes.login, (_) => false);
                }
              });
            }
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${snap.error}', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: _reload, child: const Text('Reintentar')),
              ]),
            );
          }
          return RefreshIndicator(
              onRefresh: _reload, child: _ProfileBody(profile: snap.data!));
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final Profile profile;
  const _ProfileBody({required this.profile});

  Future<void> _logOut(BuildContext context) async {
    final navigator = Navigator.of(context);
    try {
      await AppServices.of(context).game.logOut();
    } catch (_) {
      // El repositorio ya limpió la sesión local.
    }
    if (context.mounted) {
      navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border: Border.all(color: scheme.primary, width: 2),
                borderRadius: trailCut),
            child: Icon(Icons.pets, size: 34, color: scheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(profile.name, style: text.headlineSmall),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        TrailProgress(profile: profile),
        const SizedBox(height: 4),
        Text(
            '${profile.xpIntoLevel} / ${profile.xpForNextLevel} XP para el nivel ${profile.level + 1}',
            style: text.bodySmall),
        const SizedBox(height: 16),
        Row(children: [
          _Stat(
              icon: Icons.local_fire_department_outlined,
              value: '${profile.streak}',
              label: 'Racha'),
          _Stat(icon: Icons.pets, value: '${profile.walks}', label: 'Paseos'),
          _Stat(
              icon: Icons.timer_outlined,
              value: '${profile.minutes}',
              label: 'Minutos'),
          _Stat(
              icon: Icons.emoji_events_outlined,
              value: profile.rank == null ? '-' : '#${profile.rank}',
              label: 'Ranking'),
        ]),
        const SizedBox(height: 16),
        DailyTrail(challenge: profile.challenge),
        const SizedBox(height: 16),
        Text('Insignias', style: text.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final b in profile.badges) _BadgeChip(badge: b)],
        ),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Acerca de'),
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.about),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Cerrar sesión'),
          onTap: () => _logOut(context),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Icon(icon, color: Theme.of(context).colorScheme.tertiary),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]),
      );
}

class _BadgeChip extends StatelessWidget {
  final GameBadge badge;
  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        badge.earned ? theme.colorScheme.tertiary : theme.colorScheme.outline;
    return Tooltip(
      message: badge.description,
      triggerMode: TooltipTriggerMode.tap,
      child: SizedBox(
        width: 91,
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2)),
              child: SizedBox.square(
                dimension: 58,
                child: Center(
                  child: badge.earned
                      ? Icon(badgeIcon(badge.id), size: 27, color: color)
                      : Icon(Icons.lock_outline, color: color),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(badge.name,
                textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

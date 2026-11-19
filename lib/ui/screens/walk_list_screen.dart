import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../app_services.dart';
import '../../core/exceptions.dart';
import '../../core/routes.dart';
import '../../domain/models/walk_entry.dart';
import '../../domain/models/game.dart';
import '../trail_theme.dart';
import '../widgets/trail_progress.dart';
import '../widgets/trail_app_bar.dart';
import '../widgets/trail_navigation.dart';
import '../widgets/walk_image.dart';

/// Vista de lista: carga los paseos con [FutureBuilder].
class WalkListScreen extends StatefulWidget {
  const WalkListScreen({super.key});

  @override
  State<WalkListScreen> createState() => _WalkListScreenState();
}

class _WalkListScreenState extends State<WalkListScreen> {
  Future<List<WalkEntry>>? _future;
  Future<Profile?>? _profile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppServices.of(context);
    _future ??= services.walks.getAll();
    _profile ??= _loadProfile(services);
  }

  Future<Profile?> _loadProfile(AppServices services) async {
    try {
      return await services.game.profile();
    } catch (_) {
      return null;
    }
  }

  Future<void> _reload() async {
    final services = AppServices.of(context);
    final future = services.walks.getAll();
    setState(() {
      _future = future;
      _profile = _loadProfile(services);
    });
    await future.then((_) {}, onError: (_) {});
  }

  Future<void> _openForm() async {
    final saved = await Navigator.pushNamed(context, AppRoutes.form);
    if (mounted && saved == true) _reload();
  }

  Future<void> _openDetail(WalkEntry entry) async {
    final changed =
        await Navigator.pushNamed(context, AppRoutes.detail, arguments: entry);
    if (mounted && changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TrailAppBar(title: 'Paseo Perruno', profile: _profile),
      bottomNavigationBar:
          TrailNavigation(route: AppRoutes.list, onNewWalk: _openForm),
      body: FutureBuilder<List<WalkEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            if (snapshot.error is AuthException) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppRoutes.login, (_) => false);
                }
              });
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                        onPressed: _reload, child: const Text('Reintentar')),
                  ],
                ),
              ),
            );
          }
          final walks = snapshot.data ?? [];
          final theme = Theme.of(context);
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              itemCount: walks.isEmpty ? 2 : walks.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mis paseos', style: theme.textTheme.displaySmall),
                      const SizedBox(height: 16),
                      FutureBuilder<Profile?>(
                        future: _profile,
                        builder: (_, snapshot) {
                          final profile = snapshot.data;
                          if (profile == null) return const SizedBox.shrink();
                          return Column(children: [
                            DailyTrail(challenge: profile.challenge),
                            const SizedBox(height: 20),
                          ]);
                        },
                      ),
                    ],
                  );
                }
                if (walks.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.pets,
                            size: 54, color: theme.colorScheme.tertiary),
                        const SizedBox(height: 12),
                        Text('Aún no hay paseos. ¡Registra el primero!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  );
                }
                final walk = walks[i - 1];
                return _WalkTile(entry: walk, onTap: () => _openDetail(walk));
              },
            ),
          );
        },
      ),
    );
  }
}

class _WalkTile extends StatelessWidget {
  final WalkEntry entry;
  final VoidCallback onTap;

  const _WalkTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM y, HH:mm', 'es').format(entry.createdAt);
    final text = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: trailCut,
              child:
                  WalkImage(entry: entry, width: double.infinity, height: 184),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text(entry.dogName, style: text.headlineSmall)),
              Text('+${entry.xp} XP',
                  style: text.labelLarge?.copyWith(color: color.primary)),
              const Icon(Icons.chevron_right),
            ]),
            Text('$date · ${entry.durationMinutes} min',
                style: text.bodyMedium),
            const Divider(height: 24),
          ],
        ),
      ),
    );
  }
}

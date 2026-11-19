import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/routes.dart';
import '../../core/exceptions.dart';
import '../../domain/models/game.dart';
import '../widgets/trail_app_bar.dart';
import '../widgets/trail_navigation.dart';

/// Ranking de paseadores: global y de la semana (dos sorted sets en Redis).
class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const TrailAppBar(
          title: 'Ranking',
          bottom: TabBar(tabs: [Tab(text: 'Global'), Tab(text: 'Esta semana')]),
        ),
        bottomNavigationBar: const TrailNavigation(route: AppRoutes.ranking),
        body: const TabBarView(
            children: [_Board(weekly: false), _Board(weekly: true)]),
      ),
    );
  }
}

class _Board extends StatefulWidget {
  final bool weekly;
  const _Board({required this.weekly});

  @override
  State<_Board> createState() => _BoardState();
}

class _BoardState extends State<_Board> with AutomaticKeepAliveClientMixin {
  Future<Leaderboard>? _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppServices.of(context).game.leaderboard(weekly: widget.weekly);
  }

  Future<void> _reload() {
    final future =
        AppServices.of(context).game.leaderboard(weekly: widget.weekly);
    setState(() {
      _future = future;
    });
    return future.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Leaderboard>(
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
              FilledButton(onPressed: _reload, child: const Text('Reintentar')),
            ]),
          );
        }
        final board = snap.data!;
        if (board.entries.isEmpty) {
          return const Center(
              child: Text('Nadie ha sumado XP todavía. ¡Sal a pasear!'));
        }
        final entries = board.entries.where((entry) => entry.rank > 3);
        final myRank = board.myRank;
        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  children: [
                    _Podium(
                        entries: board.entries
                            .where((entry) => entry.rank <= 3)
                            .toList()),
                    for (final entry in entries) _Row(entry: entry),
                  ],
                ),
              ),
            ),
            if (myRank != null && !board.entries.any((entry) => entry.isMe))
              ListTile(
                tileColor: Theme.of(context).colorScheme.primaryContainer,
                leading: Text('#$myRank'),
                title: const Text('Tu posición'),
                trailing: Text('${board.myXp} XP'),
              ),
          ],
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  final LeaderboardEntry entry;
  const _Row({required this.entry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: entry.isMe ? scheme.primaryContainer : null,
      child: ListTile(
        leading: SizedBox(
          width: 40,
          child: Center(
            child: Text('#${entry.rank}', style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(entry.isMe ? '${entry.name} (tú)' : entry.name),
        subtitle: Text('Nivel ${entry.level}'),
        trailing: Text('${entry.xp} XP',
            style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const _Podium({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byRank = {for (final entry in entries) entry.rank: entry};
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final rank in [2, 1, 3])
          Expanded(
            child: byRank[rank] == null
                ? const SizedBox.shrink()
                : _step(byRank[rank]!, theme),
          ),
      ],
    );
  }

  Widget _step(LeaderboardEntry entry, ThemeData theme) {
    final colors = theme.colorScheme;
    final color = switch (entry.rank) {
      1 => colors.primaryContainer,
      2 => colors.secondaryContainer,
      _ => colors.tertiaryContainer,
    };
    final ink = switch (entry.rank) {
      1 => colors.onPrimaryContainer,
      2 => colors.onSecondaryContainer,
      _ => colors.onTertiaryContainer,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          Text(
            entry.isMe ? '${entry.name} (tú)' : entry.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text('Nivel ${entry.level} · ${entry.xp} XP',
              textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: 108.0 - 19 * entry.rank),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              border: entry.isMe
                  ? Border.all(color: colors.primary, width: 2)
                  : null,
              borderRadius:
                  const BorderRadius.only(topRight: Radius.circular(15)),
            ),
            padding: const EdgeInsets.all(8),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 5,
              children: [
                Icon(Icons.emoji_events_outlined, color: ink, size: 26),
                Text('#${entry.rank}',
                    style: TextStyle(fontSize: 18, color: ink)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

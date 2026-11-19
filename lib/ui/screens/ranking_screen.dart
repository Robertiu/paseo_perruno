import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/routes.dart';
import '../../domain/models/game.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/avatar.dart';
import '../widgets/common.dart';

/// Ranking global y semanal (dos sorted sets de Redis) con podio y tu posición.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  bool _weekly = false;
  Future<Leaderboard>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppServices.of(context).game.leaderboard(weekly: _weekly);
  }

  Future<void> _load() {
    final future = AppServices.of(context).game.leaderboard(weekly: _weekly);
    setState(() => _future = future);
    return future.then((_) {}, onError: (_) {});
  }

  void _setScope(bool weekly) {
    if (weekly == _weekly) return;
    _weekly = weekly;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Ranking',
      tab: AppTab.ranking,
      body: FutureBuilder<Leaderboard>(
        future: _future,
        builder: (context, snap) {
          return RefreshIndicator(
            color: Tk.rust,
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(Tk.pad, 20, Tk.pad, 24),
              children: [
                const PageTitle('Ranking'),
                _ScopeTabs(weekly: _weekly, onChanged: _setScope),
                const SizedBox(height: 20),
                if (snap.connectionState != ConnectionState.done)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 80), child: Center(child: CircularProgressIndicator()))
                else if (snap.hasError)
                  SizedBox(height: 360, child: ErrorRetry(error: snap.error!, onRetry: _load))
                else
                  _Board(board: snap.data!, weekly: _weekly),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScopeTabs extends StatelessWidget {
  final bool weekly;
  final ValueChanged<bool> onChanged;
  const _ScopeTabs({required this.weekly, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget tab(String text, IconData icon, bool value) {
      final active = weekly == value;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(value),
          child: Container(
            height: 44,
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? Tk.rust : Tk.line, width: active ? 3 : 1))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 16, color: active ? Tk.rust : Tk.inkSoft),
              const SizedBox(width: 6),
              Text(text, style: Tk.body(13, w: FontWeight.w600, color: active ? Tk.rust : Tk.inkSoft)),
            ]),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Tk.card, borderRadius: BorderRadius.circular(Tk.radius)),
      clipBehavior: Clip.antiAlias,
      child: Row(children: [
        tab('Global', Icons.emoji_events_outlined, false),
        tab('Esta semana', Icons.calendar_today_outlined, true),
      ]),
    );
  }
}

class _Board extends StatelessWidget {
  final Leaderboard board;
  final bool weekly;
  const _Board({required this.board, required this.weekly});

  @override
  Widget build(BuildContext context) {
    final entries = board.entries;
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(children: [
          Icon(Icons.emoji_events_outlined, size: 44, color: Tk.rust),
          SizedBox(height: 12),
          Text('Nadie ha sumado XP todavía.\n¡Sal a pasear!', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, color: Tk.inkSoft)),
        ]),
      );
    }
    final rest = entries.length > 3 ? entries.sublist(3) : <LeaderboardEntry>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Podium(entries: entries),
      const Rule(gap: 20),
      _MyPosition(board: board),
      if (rest.isNotEmpty) ...[
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.format_list_numbered, color: Tk.rust, size: 20),
            const SizedBox(width: 8),
            Text('Paseadores', style: Tk.display(20)),
          ]),
          Text('Top ${entries.length}', style: Tk.body(11)),
        ]),
        const SizedBox(height: 8),
        for (final e in rest) _Row(entry: e),
      ],
      const SizedBox(height: 20),
      const _NextBadge(),
    ]);
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const _Podium({required this.entries});

  @override
  Widget build(BuildContext context) {
    LeaderboardEntry? at(int i) => i < entries.length ? entries[i] : null;
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(flex: 3, child: _PodiumSlot(entry: at(1), place: 2, pedestal: 66, label: 'Plata')),
      const SizedBox(width: 6),
      Expanded(flex: 4, child: _PodiumSlot(entry: at(0), place: 1, pedestal: 96, label: 'Líder')),
      const SizedBox(width: 6),
      Expanded(flex: 3, child: _PodiumSlot(entry: at(2), place: 3, pedestal: 56, label: 'Bronce')),
    ]);
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry? entry;
  final int place;
  final double pedestal;
  final String label;
  const _PodiumSlot({required this.entry, required this.place, required this.pedestal, required this.label});

  @override
  Widget build(BuildContext context) {
    final first = place == 1;
    final e = entry;
    final size = first ? 84.0 : 58.0;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (e != null) ...[
        Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: EdgeInsets.all(first ? 5 : 4),
              decoration: BoxDecoration(color: first ? Tk.rust : Tk.card, borderRadius: BorderRadius.circular(first ? 18 : 14)),
              child: Avatar(name: e.name, size: size, radius: first ? 14 : 11),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: first ? 10 : 8, vertical: 2),
            decoration: BoxDecoration(color: first ? Tk.rustDeep : Tk.card, borderRadius: BorderRadius.circular(10)),
            child: Text(first ? '#1' : '$place', style: Tk.body(first ? 12 : 10, w: FontWeight.w700, color: first ? Colors.white : Tk.ink)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(e.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: first ? Tk.display(15, color: Tk.rust) : Tk.display(13)),
        Text('${NumberFormat.decimalPattern('es').format(e.xp)} XP', style: Tk.body(first ? 13 : 11, w: FontWeight.w700, color: first ? Tk.ink : Tk.green)),
        Text('Nivel ${e.level}', style: Tk.body(10, w: FontWeight.w600, color: Tk.flame)),
        const SizedBox(height: 8),
      ] else
        const SizedBox(height: 60),
      Container(
        height: pedestal,
        width: double.infinity,
        decoration: BoxDecoration(
          color: first ? Tk.rust : Tk.card,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(first ? 12 : 4), topRight: const Radius.circular(12)),
          border: first ? null : const Border(top: BorderSide(color: Tk.blue, width: 2)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(first ? Icons.military_tech : Icons.workspace_premium_outlined, size: 22, color: first ? Tk.blush : Tk.inkSoft),
          Text('$place', style: Tk.body(12, w: FontWeight.w700, color: first ? Colors.white : Tk.ink)),
          Text(label, style: Tk.body(10, color: first ? Tk.blush : Tk.inkSoft)),
        ]),
      ),
    ]);
  }
}

class _MyPosition extends StatelessWidget {
  final Leaderboard board;
  const _MyPosition({required this.board});

  @override
  Widget build(BuildContext context) {
    final profile = AppServices.of(context).profile.value;
    final rank = board.myRank;
    if (rank == null) return const SizedBox.shrink();
    final above = rank > 1 ? board.entries.where((e) => e.rank == rank - 1).firstOrNull : null;
    final gap = above == null ? null : above.xp - board.myXp;
    return Container(
      decoration: BoxDecoration(
        color: Tk.card,
        borderRadius: BorderRadius.circular(Tk.radius),
        border: const Border(left: BorderSide(color: Tk.blue, width: 4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        Row(children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: Tk.rustDeep, borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text('Puesto', style: Tk.body(8, color: Colors.white)),
              Text('$rank', style: Tk.display(20, color: Colors.white)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tú${profile == null ? '' : ' (${profile.name})'}', style: Tk.display(17)),
              if (profile != null) Text('Nivel ${profile.level} · ${profile.walks} paseos', style: Tk.body(12)),
            ]),
          ),
          Text('${NumberFormat.decimalPattern('es').format(board.myXp)} XP', style: Tk.display(20, color: Tk.rust)),
        ]),
        const Divider(height: 24),
        Row(children: [
          const Icon(Icons.bolt, size: 16, color: Tk.rust),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              rank == 1
                  ? '¡Eres el líder! Mantén tu racha.'
                  : (gap == null ? 'Sigue sumando XP para subir posiciones.' : '¡A solo ${gap == 0 ? 1 : gap} XP del puesto ${rank - 1}!'),
              style: Tk.body(11, w: FontWeight.w600, color: Tk.rust),
            ),
          ),
          SizedBox(
            height: 34,
            child: FilledButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.form),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              icon: const Icon(Icons.arrow_forward, size: 14),
              iconAlignment: IconAlignment.end,
              label: Text('Caminar', style: Tk.body(12, w: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final LeaderboardEntry entry;
  const _Row({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: entry.isMe ? Tk.card : null,
        borderRadius: entry.isMe ? BorderRadius.circular(Tk.radius) : null,
        border: entry.isMe ? null : const Border(bottom: BorderSide(color: Tk.line)),
      ),
      child: Row(children: [
        SizedBox(width: 34, child: Text(entry.rank.toString().padLeft(2, '0'), style: Tk.display(16, color: Tk.inkSoft))),
        Avatar(name: entry.name, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry.isMe ? '${entry.name} (tú)' : entry.name, style: Tk.display(15)),
            Text('Nivel ${entry.level}', style: Tk.body(12)),
          ]),
        ),
        Text('${NumberFormat.decimalPattern('es').format(entry.xp)} XP', style: Tk.body(15, w: FontWeight.w700, color: Tk.rust)),
      ]),
    );
  }
}

/// Próxima insignia por desbloquear (la primera que aún no tienes).
class _NextBadge extends StatelessWidget {
  const _NextBadge();

  @override
  Widget build(BuildContext context) {
    final profile = AppServices.of(context).profile.value;
    final next = profile?.badges.where((b) => !b.earned).firstOrNull;
    if (next == null) return const SizedBox.shrink();
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: Tk.bg, borderRadius: BorderRadius.circular(14)),
          alignment: Alignment.center,
          child: Text(next.emoji, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Insignia '${next.name}'", style: Tk.display(16)),
            const SizedBox(height: 2),
            Text('${next.description}. Desbloquea este sello de mérito.', style: Tk.body(12, height: 1.4)),
          ]),
        ),
      ]),
    );
  }
}

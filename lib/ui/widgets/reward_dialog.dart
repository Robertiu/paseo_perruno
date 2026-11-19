import 'package:material_ui/material_ui.dart';

import '../../domain/models/game.dart';
import '../theme/app_theme.dart';

/// Resumen de lo ganado al guardar un paseo.
Future<void> showRewardDialog(BuildContext context, Reward r) {
  Widget line(IconData icon, Color color, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Tk.body(13, w: FontWeight.w500, color: Tk.ink))),
        ]),
      );

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Tk.bg,
      title: Text(r.levelUp != null ? '¡Nivel ${r.levelUp}!' : '¡Paseo guardado!', style: Tk.display(22)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            tween: Tween(begin: 0, end: r.xp.toDouble()),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text('+${v.round()} XP', style: Tk.display(40, color: Tk.rust)),
          ),
          const SizedBox(height: 8),
          line(Icons.local_fire_department, Tk.flame, 'Racha: ${r.streak} ${r.streak == 1 ? 'día' : 'días'}'),
          if (r.challengeCompleted) line(Icons.flag_outlined, Tk.green, 'Reto del día cumplido (+${r.challengeBonus} XP)'),
          if (r.rank != null) line(Icons.emoji_events_outlined, Tk.blue, 'Posición en el ranking: #${r.rank}'),
          if (r.newBadges.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Nuevas insignias', style: Tk.label()),
            for (final b in r.newBadges)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Tk.card, borderRadius: BorderRadius.circular(Tk.radius)),
                child: Row(children: [
                  Text(b.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(b.name, style: Tk.body(13, w: FontWeight.w700, color: Tk.ink))),
                ]),
              ),
          ],
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('¡Genial!'))],
    ),
  );
}

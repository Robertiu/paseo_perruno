import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../domain/models/game.dart';
import 'badge_icon.dart';

Future<void> showRewardDialog(BuildContext context, Reward r) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final motion = !MediaQuery.disableAnimationsOf(context);
      return AlertDialog(
        scrollable: true,
        title: Text(
            r.levelUp != null ? '¡Nivel ${r.levelUp}!' : '¡Paseo guardado!'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TweenAnimationBuilder<double>(
              duration:
                  motion ? const Duration(milliseconds: 850) : Duration.zero,
              tween: Tween(begin: motion ? 0 : 1, end: 1),
              curve: Curves.easeOutCubic,
              builder: (_, t, __) => Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 118,
                    width: double.infinity,
                    child: Opacity(
                      opacity: math.sin(math.pi * t).clamp(0, 1).toDouble(),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          for (var i = 0; i < 12; i++)
                            Transform.translate(
                              offset: Offset(
                                math.cos(i * math.pi / 6) * 102 * t,
                                math.sin(i * math.pi / 6) * 52 * t,
                              ),
                              child: Icon(Icons.pets,
                                  size: 15,
                                  color: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                    theme.colorScheme.tertiary,
                                  ][i % 3]),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Text('+${(r.xp * t).round()} XP',
                      style: theme.textTheme.displaySmall
                          ?.copyWith(color: theme.colorScheme.primary)),
                ],
              ),
            ),
            Text('Racha de ${r.streak} ${r.streak == 1 ? 'día' : 'días'}'),
            if (r.challengeCompleted)
              Text('Reto del día cumplido (+${r.challengeBonus} XP)'),
            if (r.rank != null) Text('Posición en el ranking: #${r.rank}'),
            if (r.newBadges.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Nuevas insignias', style: theme.textTheme.titleMedium),
              for (final badge in r.newBadges)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(badgeIcon(badge.id),
                      color: theme.colorScheme.tertiary),
                  title: Text(badge.name),
                ),
            ],
          ],
        ),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('¡Genial!'))
        ],
      );
    },
  );
}

import 'package:material_ui/material_ui.dart';

import '../../domain/models/game.dart';

class TrailProgress extends StatelessWidget {
  final Profile profile;

  const TrailProgress({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            Text('Nivel ${profile.level} · ${profile.xp} XP',
                style: theme.textTheme.titleMedium),
            Text(
                'Racha de ${profile.streak} ${profile.streak == 1 ? 'día' : 'días'}',
                style: TextStyle(color: colors.primary)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: profile.levelProgress,
          minHeight: 6,
          borderRadius: BorderRadius.zero,
          semanticsLabel: 'Progreso al nivel ${profile.level + 1}',
        ),
      ],
    );
  }
}

class DailyTrail extends StatelessWidget {
  final DailyChallenge challenge;

  const DailyTrail({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = challenge.completed ? colors.tertiary : colors.secondary;
    return DecoratedBox(
      decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accent, width: 3))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            Icon(
                challenge.completed
                    ? Icons.check_circle_outline
                    : Icons.explore_outlined,
                color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      challenge.completed
                          ? 'Reto del día cumplido'
                          : 'Reto del día',
                      style:
                          theme.textTheme.labelLarge?.copyWith(color: accent)),
                  Text(challenge.title),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('+${challenge.bonusXp} XP',
                style: theme.textTheme.labelLarge?.copyWith(color: accent)),
          ],
        ),
      ),
    );
  }
}

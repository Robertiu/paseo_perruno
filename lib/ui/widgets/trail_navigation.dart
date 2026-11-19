import 'package:material_ui/material_ui.dart';

import '../../core/routes.dart';

class TrailNavigation extends StatelessWidget {
  final String route;
  final VoidCallback? onNewWalk;

  const TrailNavigation({super.key, required this.route, this.onNewWalk});

  Future<void> _select(BuildContext context, int index) async {
    const routes = [AppRoutes.list, AppRoutes.form, AppRoutes.ranking];
    final destination = routes[index];
    if (destination == route) return;
    if (destination == AppRoutes.form) {
      final callback = onNewWalk;
      if (callback != null) {
        callback();
        return;
      }
      final saved = await Navigator.pushNamed(context, AppRoutes.form);
      if (saved == true && context.mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.list);
      }
      return;
    }
    Navigator.pushReplacementNamed(context, destination);
  }

  @override
  Widget build(BuildContext context) {
    final selected = switch (route) {
      AppRoutes.list => 0,
      AppRoutes.ranking => 2,
      _ => null,
    };
    return BottomAppBar(
      padding: EdgeInsets.zero,
      height: 64,
      child: Row(
        children: [
          _destination(context, 0, selected, Icons.pets, 'Paseos'),
          _destination(context, 1, selected, Icons.add, 'Nuevo paseo'),
          _destination(
              context, 2, selected, Icons.emoji_events_outlined, 'Ranking'),
        ],
      ),
    );
  }

  Widget _destination(BuildContext context, int index, int? selected,
      IconData icon, String label) {
    final theme = Theme.of(context);
    final active = index == selected;
    final color =
        active ? theme.colorScheme.primary : theme.colorScheme.onSurface;
    return Expanded(
      child: Semantics(
        selected: active,
        child: InkWell(
          onTap: () => _select(context, index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

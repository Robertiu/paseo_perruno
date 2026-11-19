import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/routes.dart';
import '../../domain/models/game.dart';

class TrailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Future<Profile?>? profile;
  final PreferredSizeWidget? bottom;

  const TrailAppBar(
      {super.key, required this.title, this.profile, this.bottom});

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) => AppBar(
        automaticallyImplyLeading: false,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          _TrailStatus(profile: profile),
          IconButton(
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: ModalRoute.of(context)?.settings.name ==
                    AppRoutes.profile
                ? null
                : () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.profile),
          ),
        ],
        bottom: bottom,
      );
}

class _TrailStatus extends StatefulWidget {
  final Future<Profile?>? profile;
  const _TrailStatus({required this.profile});

  @override
  State<_TrailStatus> createState() => _TrailStatusState();
}

class _TrailStatusState extends State<_TrailStatus> {
  Future<Profile>? _fallback;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.profile == null) {
      _fallback ??= AppServices.of(context).game.profile();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Profile?>(
        future: widget.profile ?? _fallback,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          if (profile == null) return const SizedBox.shrink();
          final theme = Theme.of(context);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nv. ${profile.level}',
                  style: theme.textTheme.labelMedium,
                  semanticsLabel: 'Nivel ${profile.level}'),
              const SizedBox(width: 10),
              Tooltip(
                message:
                    'Racha de ${profile.streak} ${profile.streak == 1 ? 'día' : 'días'}',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_outlined,
                        size: 20, color: theme.colorScheme.primary),
                    Text('${profile.streak}',
                        style: theme.textTheme.labelLarge),
                  ],
                ),
              ),
            ],
          );
        },
      );
}

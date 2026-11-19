import 'package:material_ui/material_ui.dart';

import '../../core/routes.dart';
import '../widgets/trail_app_bar.dart';
import '../widgets/trail_navigation.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const TrailAppBar(title: 'Acerca de'),
      bottomNavigationBar: const TrailNavigation(route: AppRoutes.about),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.pets, size: 58, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text('Paseo Perruno', style: theme.textTheme.displaySmall),
          const Divider(height: 28),
          Text(
            'Guarda cada salida con su foto, sus notas y, si tú quieres, su ubicación. Puedes volver a tus paseos desde la bitácora.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Suma XP al pasear, mantén tu racha y completa el reto del día para ganar insignias.',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

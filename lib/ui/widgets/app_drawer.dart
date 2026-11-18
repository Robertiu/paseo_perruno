import 'package:flutter/material.dart';

import '../../core/routes.dart';

/// Menú lateral principal. Usa [Navigator.pushReplacementNamed] al cambiar
/// de sección raíz para no apilar pantallas.
class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  void _go(BuildContext context, String route) {
    Navigator.pop(context); // cierra el drawer
    if (route != currentRoute) Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: scheme.primaryContainer),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text('🐕 Paseo Perruno',
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.pets),
            title: const Text('Mis paseos'),
            selected: currentRoute == AppRoutes.list,
            onTap: () => _go(context, AppRoutes.list),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de'),
            selected: currentRoute == AppRoutes.about,
            onTap: () => _go(context, AppRoutes.about),
          ),
        ],
      ),
    );
  }
}

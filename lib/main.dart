import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_services.dart';
import 'core/routes.dart';
import 'domain/models/walk_entry.dart';
import 'ui/screens/about_screen.dart';
import 'ui/screens/walk_detail_screen.dart';
import 'ui/screens/walk_form_screen.dart';
import 'ui/screens/walk_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  runApp(AppServices.production(child: const PaseoPerrunoApp()));
}

class PaseoPerrunoApp extends StatelessWidget {
  const PaseoPerrunoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paseo Perruno',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFE08A1E),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.list,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  /// Tabla de rutas. El detalle recibe el [WalkEntry] como argumento y se
  /// anima con un fundido para que el Hero de la foto destaque.
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.list:
        return MaterialPageRoute(builder: (_) => const WalkListScreen(), settings: settings);
      case AppRoutes.form:
        return MaterialPageRoute(builder: (_) => const WalkFormScreen(), settings: settings);
      case AppRoutes.about:
        return MaterialPageRoute(builder: (_) => const AboutScreen(), settings: settings);
      case AppRoutes.detail:
        final entry = settings.arguments as WalkEntry;
        return PageRouteBuilder(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => WalkDetailScreen(entry: entry),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        );
    }
    return null;
  }
}

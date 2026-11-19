import 'package:material_ui/material_ui.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_services.dart';
import 'core/routes.dart';
import 'domain/models/walk_entry.dart';
import 'ui/screens/about_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/ranking_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/walk_detail_screen.dart';
import 'ui/screens/walk_form_screen.dart';
import 'ui/screens/walk_list_screen.dart';
import 'ui/trail_theme.dart';

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
      theme: trailTheme(Brightness.light),
      darkTheme: trailTheme(Brightness.dark),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  /// Tabla de rutas. El detalle y el formulario de edición reciben el [WalkEntry] como argumento y se
  /// anima con un fundido para que el Hero de la foto destaque.
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen(), settings: settings);
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: settings);
      case AppRoutes.list:
        return MaterialPageRoute(builder: (_) => const WalkListScreen(), settings: settings);
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen(), settings: settings);
      case AppRoutes.ranking:
        return MaterialPageRoute(builder: (_) => const RankingScreen(), settings: settings);
      case AppRoutes.form:
        // Con un WalkEntry como argumento el formulario entra en modo edición.
        return MaterialPageRoute(
            builder: (_) => WalkFormScreen(existing: settings.arguments as WalkEntry?), settings: settings);
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

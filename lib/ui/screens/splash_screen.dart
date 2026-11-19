import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/routes.dart';
import '../theme/app_theme.dart';

/// Decide la ruta inicial según haya o no una sesión guardada.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _routing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route();
  }

  Future<void> _route() async {
    if (_routing) return;
    _routing = true;
    final logged = await AppServices.of(context).game.hasSession();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, logged ? AppRoutes.list : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: Tk.rust,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(30), bottomLeft: Radius.circular(30), bottomRight: Radius.circular(8)),
              ),
              child: const Icon(Icons.pets, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 18),
            Text('Paseo Perruno', style: Tk.display(28)),
          ]),
        ),
      );
}

import 'package:material_ui/material_ui.dart';

import '../../core/routes.dart';
import '../widgets/app_drawer.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      drawer: const AppDrawer(currentRoute: AppRoutes.about),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Paseo Perruno es un diario para quienes pasean perros: registra '
          'cada salida con foto, notas dictadas por voz y la ubicación GPS, '
          'para llevar el historial de cuándo y dónde paseó cada perro.',
          style: TextStyle(fontSize: 16, height: 1.4),
        ),
      ),
    );
  }
}

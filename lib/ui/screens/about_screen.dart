import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Reglas de campo: cómo se gana XP, niveles, rachas, retos e insignias.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _rules = [
    (Icons.bolt, 'Puntos XP', 'Cada paseo da 10 XP base, +1 por minuto (hasta 120), +5 con foto, +5 con notas, +5 con ubicación y +2 por cada día de racha (hasta 10).'),
    (Icons.trending_up, 'Niveles', 'El nivel sube con la raíz de tu XP: 100 XP al nivel 2, 400 al nivel 3, 900 al nivel 4 y así sucesivamente.'),
    (Icons.local_fire_department, 'Racha', 'Pasea días seguidos para sumar bonos. Si pasas un día completo sin pasear, la racha caduca sola.'),
    (Icons.flag_outlined, 'Reto del día', 'Cada día hay un reto nuevo. Cumplirlo da XP extra una sola vez.'),
    (Icons.workspace_premium_outlined, 'Insignias', 'Nueve estampas de campo: paseos, rachas, fotos, rutas, paseos largos y nivel.'),
    (Icons.emoji_events_outlined, 'Ranking', 'Compites en un ranking global y en uno semanal que se reinicia cada semana.'),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Acerca de',
      back: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Tk.pad, 20, Tk.pad, 32),
        children: [
          const PageTitle('Paseo Perruno'),
          Text('Un diario para quienes pasean perros: registra cada salida con foto, notas dictadas por voz y ubicación GPS, y conviértela en un juego.', style: Tk.body(14, height: 1.5)),
          const Rule(gap: 20),
          Text('Reglas de campo', style: Tk.display(22)),
          const SizedBox(height: 12),
          for (final (icon, title, text) in _rules)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Tk.card, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: Tk.rust, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: Tk.body(14, w: FontWeight.w700, color: Tk.ink)),
                    const SizedBox(height: 2),
                    Text(text, style: Tk.body(12, height: 1.45)),
                  ]),
                ),
              ]),
            ),
          const Rule(gap: 20),
          Text('Hecho con Flutter, Node.js y Redis Cloud (base de datos NoSQL Clave-Valor).', style: Tk.body(12, height: 1.5)),
        ],
      ),
    );
  }
}

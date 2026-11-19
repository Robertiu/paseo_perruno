import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Avatar cuadrado de esquinas redondeadas con la inicial del nombre.
class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final double radius;
  final Color? border;

  const Avatar({super.key, required this.name, this.size = 32, this.radius = 12, this.border});

  static const _palette = [Tk.rust, Tk.green, Tk.blue, Tk.flame, Tk.rustDeep];

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final color = _palette[name.codeUnits.fold<int>(0, (a, b) => a + b) % _palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border == null ? null : Border.all(color: border!, width: 3),
      ),
      child: Text(initial, style: Tk.display(size * 0.46, color: Colors.white)),
    );
  }
}

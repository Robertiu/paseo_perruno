import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Título grande de pantalla (Fredoka 30).
class PageTitle extends StatelessWidget {
  final String text;
  const PageTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        child: Text(text, style: Tk.display(30)),
      );
}

/// Línea separadora de sección con espacio vertical.
class Rule extends StatelessWidget {
  final double gap;
  const Rule({super.key, this.gap = 16});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: gap),
        child: const Divider(),
      );
}

/// Barra de progreso fina (verde sobre crema).
class ProgressLine extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  const ProgressLine({super.key, required this.value, this.color = Tk.green, this.height = 6});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1).toDouble(),
          minHeight: height,
          color: color,
          backgroundColor: Tk.card,
        ),
      );
}

/// Estado de error con botón de reintento.
class ErrorRetry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorRetry({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: Tk.rust),
            const SizedBox(height: 12),
            Text('$error'.replaceFirst('AppException: ', ''),
                textAlign: TextAlign.center, style: Tk.body(14)),
            const SizedBox(height: 16),
            SizedBox(width: 180, child: FilledButton(onPressed: onRetry, child: const Text('Reintentar'))),
          ]),
        ),
      );
}

/// Tarjeta de fondo crema con esquinas redondeadas.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color = Tk.card});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Tk.radius)),
        child: child,
      );
}

import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../domain/models/walk_entry.dart';
import '../theme/app_theme.dart';

/// Foto del paseo envuelta en [Hero]; la lista y el detalle comparten el
/// mismo [WalkEntry.heroTag] para animar la transición.
class WalkImage extends StatelessWidget {
  final WalkEntry entry;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;

  const WalkImage({
    super.key,
    required this.entry,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = Tk.radius,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: Tk.card,
      child: const Icon(Icons.pets, size: 32, color: Tk.rust),
    );

    return Hero(
      tag: entry.heroTag,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: entry.hasImage
            ? Image.file(File(entry.imagePath!),
                width: width, height: height, fit: fit, errorBuilder: (_, __, ___) => placeholder)
            : placeholder,
      ),
    );
  }
}

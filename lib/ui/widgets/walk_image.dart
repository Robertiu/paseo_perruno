import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/models/walk_entry.dart';

/// Foto del paseo envuelta en [Hero]; la lista y el detalle comparten el
/// mismo [WalkEntry.heroTag] para animar la transición.
class WalkImage extends StatelessWidget {
  final WalkEntry entry;
  final double? width;
  final double? height;
  final BoxFit fit;

  const WalkImage({
    super.key,
    required this.entry,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: const Icon(Icons.pets, size: 32),
    );

    return Hero(
      tag: entry.heroTag,
      child: entry.hasImage
          ? Image.file(
              File(entry.imagePath!),
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, __, ___) => placeholder,
            )
          : placeholder,
    );
  }
}

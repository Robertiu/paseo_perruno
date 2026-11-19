import 'package:material_ui/material_ui.dart';

IconData badgeIcon(String id) => switch (id) {
      'primer-paseo' => Icons.pets,
      'paseador-5' => Icons.directions_walk,
      'paseador-25' => Icons.workspace_premium_outlined,
      'racha-3' => Icons.local_fire_department_outlined,
      'racha-7' => Icons.bolt_outlined,
      'fotografo' => Icons.photo_camera_outlined,
      'explorador' => Icons.explore_outlined,
      'maraton' => Icons.directions_run,
      'nivel-5' => Icons.star_outline,
      _ => Icons.workspace_premium_outlined,
    };

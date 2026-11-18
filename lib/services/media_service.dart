import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/exceptions.dart';

/// Gadget 1: cámara y galería.
///
/// La imagen elegida se copia al directorio de documentos de la app, así la
/// ruta guardada en SQLite sigue válida aunque el archivo temporal se borre.
class MediaService {
  final ImagePicker _picker;

  MediaService([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  Future<String?> takePhoto() => _pick(ImageSource.camera);

  Future<String?> pickFromGallery() => _pick(ImageSource.gallery);

  /// Devuelve la ruta persistente, o null si el usuario canceló.
  Future<String?> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return null;

      final dir = await getApplicationDocumentsDirectory();
      final name = 'paseo_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
      final saved = await File(picked.path).copy(p.join(dir.path, name));
      return saved.path;
    } catch (e) {
      throw MediaException('No se pudo obtener la imagen. Revisa los permisos.', e);
    }
  }
}

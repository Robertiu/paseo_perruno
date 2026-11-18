/// Entidad de dominio: un registro del diario de paseos.
///
/// Es inmutable y no conoce cómo se guarda (SRP): la conversión a/desde
/// mapa existe solo para que la capa de datos pueda persistirla.
class WalkEntry {
  final int? id;
  final String dogName;
  final String notes;
  final int durationMinutes;
  final DateTime createdAt;

  /// Ruta local de la foto guardada en el directorio de la app.
  final String? imagePath;

  /// Coordenadas GPS capturadas al guardar el paseo.
  final double? latitude;
  final double? longitude;

  const WalkEntry({
    this.id,
    required this.dogName,
    required this.notes,
    required this.durationMinutes,
    required this.createdAt,
    this.imagePath,
    this.latitude,
    this.longitude,
  });

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  /// Tag compartido por la lista y el detalle para la animación Hero.
  String get heroTag => 'walk-image-$id';

  WalkEntry copyWith({int? id}) => WalkEntry(
        id: id ?? this.id,
        dogName: dogName,
        notes: notes,
        durationMinutes: durationMinutes,
        createdAt: createdAt,
        imagePath: imagePath,
        latitude: latitude,
        longitude: longitude,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'dog_name': dogName,
        'notes': notes,
        'duration_minutes': durationMinutes,
        'created_at': createdAt.toIso8601String(),
        'image_path': imagePath,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory WalkEntry.fromMap(Map<String, Object?> map) => WalkEntry(
        id: map['id'] as int?,
        dogName: map['dog_name'] as String,
        notes: map['notes'] as String? ?? '',
        durationMinutes: map['duration_minutes'] as int? ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
        imagePath: map['image_path'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
      );
}

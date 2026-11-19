/// Entidad de dominio: un registro del diario de paseos.
///
/// Es inmutable y no conoce cómo se guarda (SRP): la conversión a/desde
/// JSON existe solo para que la capa de datos pueda enviarla y recibirla.
class WalkEntry {
  final String? id;
  final String dogName;
  final String notes;
  final int durationMinutes;
  final DateTime createdAt;

  /// Ruta local de la foto en este dispositivo (la nube solo guarda la referencia).
  final String? imagePath;

  /// Coordenadas GPS capturadas al guardar el paseo.
  final double? latitude;
  final double? longitude;

  /// XP que otorgó este paseo (lo calcula el servidor).
  final int xp;

  const WalkEntry({
    this.id,
    required this.dogName,
    required this.notes,
    required this.durationMinutes,
    required this.createdAt,
    this.imagePath,
    this.latitude,
    this.longitude,
    this.xp = 0,
  });

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  /// Día local (yyyy-MM-dd); el servidor lo usa para rachas y reto diario.
  String get localDay => dayKey(createdAt);

  /// Tag compartido por la lista y el detalle para la animación Hero.
  String get heroTag => 'walk-image-$id';

  WalkEntry copyWith({String? dogName, String? notes, int? durationMinutes}) => WalkEntry(
        id: id,
        dogName: dogName ?? this.dogName,
        notes: notes ?? this.notes,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        createdAt: createdAt,
        imagePath: imagePath,
        latitude: latitude,
        longitude: longitude,
        xp: xp,
      );

  Map<String, Object?> toJson() => {
        'dogName': dogName,
        'notes': notes,
        'durationMinutes': durationMinutes,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'localDay': localDay,
        'imagePath': imagePath,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory WalkEntry.fromJson(Map<String, dynamic> json) => WalkEntry(
        id: json['id'] as String?,
        dogName: json['dogName'] as String,
        notes: json['notes'] as String? ?? '',
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        imagePath: json['imagePath'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        xp: (json['xp'] as num?)?.toInt() ?? 0,
      );
}

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

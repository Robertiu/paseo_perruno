# Paseo Perruno

Diario de paseos de perros hecho con Flutter/Dart. Cada paseo guarda foto,
notas (con dictado por voz), duración y ubicación GPS.

## Requisitos del Parcial 2

| Requisito | Dónde |
|---|---|
| Scaffold, AppBar, Drawer | `lib/ui/screens/*`, `lib/ui/widgets/app_drawer.dart` |
| Routes y Navigator | `lib/main.dart`, `lib/core/routes.dart` |
| Hero lista → detalle | `lib/ui/widgets/walk_image.dart` |
| SQLite | `lib/data/` |
| try-catch y FutureBuilder | repositorio, servicios, `walk_list_screen.dart` |
| Cámara y galería | `lib/services/media_service.dart` |
| Micrófono y dictado | `lib/services/speech_service.dart` |
| GPS, mapa y Google Maps | `lib/services/location_service.dart`, `walk_detail_screen.dart` |

## Arquitectura por capas

```
ui (screens, widgets) → services / domain.repositories (abstracciones)
data (SQLite) implementa domain.repositories
domain (modelos y contratos, sin dependencias de Flutter)
```

Flujo: la pantalla pide datos al `WalkRepository` (abstracción) obtenido de
`AppServices`; `SqliteWalkRepository` los lee de SQLite y devuelve `WalkEntry`.

## Puesta en marcha

Requiere Flutter (canal estable) y un dispositivo o emulador Android.

```bash
flutter pub get
flutter run
```

Los permisos de cámara, micrófono, ubicación e internet ya están declarados en
`android/app/src/main/AndroidManifest.xml` y los textos de uso en
`ios/Runner/Info.plist`. Cámara, dictado y GPS se prueban mejor en un
dispositivo real.

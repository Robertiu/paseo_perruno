# Paseo Perruno

Diario **gamificado** de paseos de perros (Flutter + Node.js) sobre **Redis en la nube**
(modelo NoSQL Clave-Valor). Cada paseo guarda foto, notas (con dictado por voz),
duración y ubicación GPS, y da XP, rachas, insignias, retos diarios y ranking.

## Arquitectura

```
Flutter (app) --HTTP/JSON--> API Node.js (Express + driver oficial `redis`) --TLS--> Redis Cloud / Upstash
```

La app nunca ve las credenciales de la base de datos: solo habla con la API.
`backend/` contiene la API, el seed y las pruebas; `lib/` la app.

## Modelo Clave-Valor (prefijo `paseo:`)

| Clave | Tipo | Uso | TTL |
|---|---|---|---|
| `walker:{id}` | HASH | perfil y contadores (xp, walks, minutes…) | - |
| `walker:byname` | HASH | nombre → id (unicidad con `HSETNX`) | - |
| `walker:{id}:walks` | ZSET | índice de paseos por fecha | - |
| `walk:{id}` | HASH | un paseo | - |
| `walker:{id}:badges` | SET | insignias ganadas | - |
| `walker:{id}:streak` | HASH | racha `{count,lastDay}` | 48 h |
| `session:{token}` | STRING | sesión → walkerId | 30 d (deslizante) |
| `cooldown:{id}` | STRING | anti-farmeo de XP (`SET NX EX`) | 20 s |
| `lb:global` | ZSET | ranking global (score = XP) | - |
| `lb:week:{año-Wnn}` | ZSET | ranking semanal | 21 d |
| `challenge:{día}` | HASH | reto del día | 36 h |
| `challenge:{día}:done` | SET | quién lo completó (bono único) | 36 h |

## Gamificación

- **XP por paseo**: 10 base + 1 por minuto (máx. 120) + 5 foto + 5 notas + 5 ubicación + 2 por día de racha (máx. 10 días).
- **Niveles**: `nivel = floor(sqrt(xp / 100)) + 1`.
- **Racha**: días seguidos con paseo; caduca sola por TTL.
- **Reto diario**: cambia cada día; cumplirlo da XP extra una sola vez.
- **Insignias**: 9 (primer paseo, 5/25 paseos, rachas 3/7, fotógrafo, explorador, maratonista, nivel 5).
- **Ranking** global y semanal con `ZINCRBY` / `ZREVRANGE` / `ZREVRANK`.

## Puesta en marcha

### 1. Base de datos en la nube
Crea una base gratuita en [Redis Cloud](https://redis.io/cloud/) o [Upstash](https://upstash.com/)
y copia su URL (`rediss://default:PASSWORD@HOST:PORT`).

### 2. Backend (Node.js ≥ 20)
```bash
cd backend
npm install
cp .env.example .env        # pega REDIS_URL
npm run seed                # datos iniciales (npm run seed:reset borra paseo:* antes)
npm start                   # http://localhost:3000
npm test                    # reglas del juego
```
El seed crea siete paseadores (Ana, Beto, Carla, Diego, Elena, Fer, Gabo) con paseos, rachas e insignias.

### 3. App Flutter
```bash
flutter pub get
flutter run                                   # emulador Android: usa http://10.0.2.2:3000
flutter run --dart-define=API_URL=https://tu-api.onrender.com   # API desplegada o teléfono real
```
Entra con "Ya tengo cuenta" y el nombre `Ana` para ver datos poblados, o crea una cuenta nueva.

La API puede desplegarse en Render/Railway/Fly (variable `REDIS_URL`); la base de datos ya está en la nube.

## Requisitos del Parcial 2 (previo)

| Requisito | Dónde |
|---|---|
| Scaffold, AppBar, Drawer | `lib/ui/screens/*`, `lib/ui/widgets/app_drawer.dart` |
| Routes y Navigator | `lib/main.dart`, `lib/core/routes.dart` |
| Hero lista → detalle | `lib/ui/widgets/walk_image.dart` |
| Cámara, dictado, GPS y mapa | `lib/services/*`, `walk_detail_screen.dart` |

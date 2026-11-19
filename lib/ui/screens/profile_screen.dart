import 'dart:ui' show PathMetric;

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/routes.dart';
import '../../domain/models/game.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/avatar.dart';
import '../widgets/common.dart';

const _levelTitles = ['Cachorro', 'Olfateador', 'Huellero', 'Rastreador', 'Explorador', 'Guardabosques', 'Maestro de ruta'];
String levelTitle(int level) => _levelTitles[(level - 1).clamp(0, _levelTitles.length - 1)];

/// Perfil gamificado: experiencia, estadísticas, reto e insignias.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Profile>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _fetch();
  }

  Future<Profile> _fetch() async {
    final services = AppServices.of(context);
    final p = await services.game.profile();
    services.profile.value = p;
    return p;
  }

  Future<void> _reload() {
    final future = _fetch();
    setState(() => _future = future);
    return future.then((_) {}, onError: (_) {});
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    try {
      await AppServices.of(context).game.logOut();
    } catch (_) {
      // La sesión local ya se borró; el token remoto caduca por TTL.
    }
    if (!mounted) return;
    AppServices.of(context).profile.value = null;
    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: AppServices.of(context).profile.value?.name ?? 'Mi perfil',
      back: true,
      body: FutureBuilder<Profile>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return ErrorRetry(error: snap.error!, onRetry: _reload);
          return RefreshIndicator(
            color: Tk.rust,
            onRefresh: _reload,
            child: _Body(profile: snap.data!, onLogout: _logout),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Profile profile;
  final VoidCallback onLogout;
  const _Body({required this.profile, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final nf = NumberFormat.decimalPattern('es');
    final nextThreshold = p.xp - p.xpIntoLevel + p.xpForNextLevel;
    final missing = p.xpForNextLevel - p.xpIntoLevel;
    final earned = p.badges.where((b) => b.earned).length;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(Tk.pad, 20, Tk.pad, 32),
      children: [
        PageTitle(p.name),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: Tk.card, borderRadius: BorderRadius.circular(18)),
              child: Avatar(name: p.name, size: 84, radius: 14),
            ),
            Positioned(
              right: -6,
              bottom: -6,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: Tk.rustDeep, borderRadius: BorderRadius.circular(10), border: Border.all(color: Tk.bg, width: 2)),
                child: const Icon(Icons.verified_outlined, size: 16, color: Colors.white),
              ),
            ),
          ]),
          const SizedBox(width: 18),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.explore_outlined, size: 14, color: Tk.green),
                const SizedBox(width: 6),
                Flexible(child: Text('Paseador ${levelTitle(p.level)} · Nvl ${p.level}', style: Tk.body(13, w: FontWeight.w700, color: Tk.green))),
              ]),
              const SizedBox(height: 6),
              Text('Bitácora activa con ${p.walks} ${p.walks == 1 ? 'paseo' : 'paseos'} registrados.', style: Tk.body(13, height: 1.4)),
            ]),
          ),
        ]),
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Experiencia de campo', style: Tk.body(13, color: Tk.ink)),
          Text('${nf.format(p.xp)} / ${nf.format(nextThreshold)} XP', style: Tk.body(13, w: FontWeight.w700, color: Tk.rust)),
        ]),
        const SizedBox(height: 8),
        ProgressLine(value: p.levelProgress, height: 12),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text('Nivel ${p.level}: ${levelTitle(p.level)}', style: Tk.body(10, w: FontWeight.w600, color: Tk.green))),
          Flexible(child: Text('Faltan $missing XP para Nivel ${p.level + 1} (${levelTitle(p.level + 1)})', textAlign: TextAlign.end, style: Tk.body(10, w: FontWeight.w600, color: Tk.green))),
        ]),
        const Rule(gap: 20),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _Stat(label: 'Racha activa', value: '${p.streak} ${p.streak == 1 ? 'día' : 'días'}', color: Tk.rust, icon: Icons.local_fire_department, iconColor: Tk.flame, caption: p.streak > 0 ? '¡No la rompas!' : 'Pasea hoy para empezarla')),
          const SizedBox(width: 16),
          Expanded(child: _Stat(label: 'Paseos totales', value: '${p.walks}', color: Tk.ink, icon: Icons.pets, iconColor: Tk.rust, caption: 'Compañeros guiados')),
        ]),
        const SizedBox(height: 22),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _Stat(label: 'Tiempo sendero', value: nf.format(p.minutes), unit: 'min', color: Tk.green, icon: Icons.timer_outlined, iconColor: Tk.green, caption: '${(p.minutes / 60).round()} hrs al aire libre')),
          const SizedBox(width: 16),
          Expanded(child: _Stat(label: 'Escalafón', value: p.rank == null ? '-' : 'Top #${p.rank}', color: Tk.blue, icon: Icons.military_tech_outlined, iconColor: Tk.blue, caption: 'Ranking global')),
        ]),
        const Rule(gap: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Reto del día', style: Tk.display(22)),
          Text('+${p.challenge.bonusXp} XP', style: Tk.body(15, w: FontWeight.w700, color: Tk.green)),
        ]),
        const SizedBox(height: 8),
        Text(p.challenge.title, style: Tk.display(16, color: Tk.inkSoft)),
        const SizedBox(height: 12),
        Text(p.challenge.completed ? 'Cumplido hoy' : 'Pendiente: aún puedes completarlo', style: Tk.body(12, w: FontWeight.w500, color: p.challenge.completed ? Tk.green : Tk.rust)),
        const Rule(gap: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Álbum de Insignias', style: Tk.display(22)),
              const SizedBox(height: 4),
              Text('$earned de ${p.badges.length} estampas de campo conseguidas', style: Tk.body(12)),
            ]),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Tk.card, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.workspace_premium_outlined, color: Tk.rust),
          ),
        ]),
        const SizedBox(height: 20),
        _BadgeGrid(profile: p),
        const Rule(gap: 24),
        InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.about),
          borderRadius: BorderRadius.circular(Tk.radius),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Tk.card, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.menu_book_outlined, color: Tk.rust, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Acerca de Paseo Perruno', style: Tk.body(15, w: FontWeight.w700, color: Tk.ink)),
                Text('Reglas de campo, puntos XP y mecánicas de paseador', style: Tk.body(12, height: 1.4)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: Tk.inkSoft),
          ]),
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Cerrar sesión de explorador'),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final String caption;
  const _Stat({required this.label, required this.value, required this.color, required this.icon, required this.iconColor, required this.caption, this.unit});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: Tk.body(11, w: FontWeight.w600, color: Tk.ink)),
          Icon(icon, size: 18, color: iconColor),
        ]),
        const SizedBox(height: 12),
        Text.rich(TextSpan(children: [
          TextSpan(text: value, style: Tk.display(26, color: color)),
          if (unit != null) TextSpan(text: ' $unit', style: Tk.body(12)),
        ])),
        const SizedBox(height: 2),
        Text(caption, style: Tk.body(12)),
      ]);
}

/// Icono, color y texto de avance de cada insignia.
class _BadgeStyle {
  final IconData icon;
  final Color color;
  const _BadgeStyle(this.icon, this.color);
}

const _badgeStyles = {
  'primer-paseo': _BadgeStyle(Icons.pets, Tk.rust),
  'paseador-5': _BadgeStyle(Icons.directions_walk, Tk.green),
  'paseador-25': _BadgeStyle(Icons.workspace_premium_outlined, Tk.rustDeep),
  'racha-3': _BadgeStyle(Icons.explore_outlined, Tk.blue),
  'racha-7': _BadgeStyle(Icons.bolt, Tk.flame),
  'fotografo': _BadgeStyle(Icons.photo_camera_outlined, Tk.rustDeep),
  'explorador': _BadgeStyle(Icons.map_outlined, Tk.green),
  'maraton': _BadgeStyle(Icons.directions_run, Tk.blue),
  'nivel-5': _BadgeStyle(Icons.shield_outlined, Tk.rust),
};

String _progressText(String id, Profile p) => switch (id) {
      'paseador-5' => '${p.walks.clamp(0, 5)}/5 paseos',
      'paseador-25' => '${p.walks.clamp(0, 25)}/25 paseos',
      'racha-3' => 'Racha ${p.streak.clamp(0, 3)}/3 d',
      'racha-7' => 'Racha ${p.streak.clamp(0, 7)}/7 d',
      'fotografo' => '${p.photos.clamp(0, 5)}/5 fotos',
      'explorador' => '${p.locations.clamp(0, 5)}/5 rutas',
      'maraton' => 'Paseo >60 min',
      'nivel-5' => 'Nivel ${p.level.clamp(1, 5)}/5',
      _ => 'Bloqueada',
    };

class _BadgeGrid extends StatelessWidget {
  final Profile profile;
  const _BadgeGrid({required this.profile});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 18,
      crossAxisSpacing: 8,
      childAspectRatio: 0.82,
      children: [
        for (final (i, b) in profile.badges.indexed) _BadgeTile(badge: b, index: i, profile: profile),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final GameBadge badge;
  final int index;
  final Profile profile;
  const _BadgeTile({required this.badge, required this.index, required this.profile});

  @override
  Widget build(BuildContext context) {
    final style = _badgeStyles[badge.id] ?? const _BadgeStyle(Icons.star_outline, Tk.rust);
    final shapes = [
      BorderRadius.circular(40),
      const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(22), bottomLeft: Radius.circular(22), bottomRight: Radius.circular(6)),
      BorderRadius.circular(40),
    ];
    final radius = shapes[index % shapes.length];
    return Tooltip(
      message: badge.description,
      child: Column(children: [
        SizedBox(
          width: 80,
          height: 80,
          child: badge.earned
              ? Container(
                  decoration: BoxDecoration(color: style.color, borderRadius: radius),
                  child: Icon(style.icon, color: Colors.white, size: 32),
                )
              : CustomPaint(
                  painter: _DashedBox(radius: index % 2 == 0 ? 40 : 14),
                  child: Center(child: Icon(style.icon, color: Tk.inkSoft.withValues(alpha: 0.6), size: 30)),
                ),
        ),
        const SizedBox(height: 8),
        Text(badge.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: Tk.body(12, w: FontWeight.w500, color: badge.earned ? Tk.ink : Tk.inkSoft.withValues(alpha: 0.8))),
        const SizedBox(height: 2),
        Text(badge.earned ? 'Conseguida' : _progressText(badge.id, profile), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: Tk.body(10, w: FontWeight.w600, color: badge.earned ? style.color : Tk.inkSoft)),
      ]),
    );
  }
}

/// Borde punteado para las insignias aún bloqueadas.
class _DashedBox extends CustomPainter {
  final double radius;
  _DashedBox({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Tk.inkSoft.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final PathMetric m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBox old) => old.radius != radius;
}

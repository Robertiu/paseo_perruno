import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/routes.dart';
import '../trail_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(vsync: this);
  late final _pattern = _PawPattern(_animation);
  bool _routing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routing) return;
    _routing = true;
    _route(MediaQuery.disableAnimationsOf(context));
  }

  Future<bool> _hasSession() async {
    try {
      return await AppServices.of(context).game.hasSession();
    } catch (_) {
      return false;
    }
  }

  Future<void> _route(bool reduceMotion) async {
    final session = _hasSession();
    if (!reduceMotion) {
      await _animation.animateTo(0.58,
          duration: const Duration(milliseconds: 720));
    } else {
      _animation.value = 0.58;
    }
    final logged = await session;
    if (!mounted) return;
    if (!reduceMotion) {
      await _animation.animateTo(1,
          duration: const Duration(milliseconds: 590));
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(
        context, logged ? AppRoutes.list : AppRoutes.login);
  }

  @override
  void dispose() {
    _pattern.dispose();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: trailCoffee,
      body: Semantics(
        label: 'Paseo Perruno, cargando',
        child: SizedBox.expand(
          child: CustomPaint(painter: _pattern),
        ),
      ),
    );
  }
}

class _PawPattern extends CustomPainter {
  final Animation<double> animation;

  _PawPattern(this.animation) : super(repaint: animation);

  final _paw = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: String.fromCharCode(Icons.pets.codePoint),
      style: TextStyle(
        inherit: false,
        fontFamily: Icons.pets.fontFamily,
        package: Icons.pets.fontPackage,
        fontSize: 37,
        color: const Color(0xFFBC825F),
      ),
    ),
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 24.0;
    final columns = (size.width / spacing).ceil();
    final rows = (size.height / spacing).ceil();
    final progress = animation.value;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var row = -1; row <= rows; row++) {
      for (var col = -1; col <= columns; col++) {
        final delay = ((row * 17 + col * 11) % 29) / 29;
        final enter = ((progress - delay * 0.42) / 0.13).clamp(0.0, 1.0);
        final exit = ((progress - 0.62 - delay * 0.26) / 0.12).clamp(0.0, 1.0);
        final scale = Curves.easeOutBack.transform(enter) * (1 - exit);
        if (scale <= 0) continue;
        canvas.save();
        canvas.translate(
            (col + (row.isOdd ? 0.5 : 0)) * spacing, row * spacing);
        canvas.rotate((row + col).isEven ? -0.26 : 0.26);
        canvas.scale(scale);
        _paw.paint(canvas, Offset(-_paw.width / 2, -_paw.height / 2));
        canvas.restore();
      }
    }
    canvas.restore();
  }

  void dispose() => _paw.dispose();

  @override
  bool shouldRepaint(_PawPattern oldDelegate) =>
      oldDelegate.animation != animation;
}

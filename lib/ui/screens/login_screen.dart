import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/exceptions.dart';
import '../../core/routes.dart';
import '../trail_theme.dart';

/// Crear cuenta o entrar con un nombre de paseador. La sesión vive en Redis (con TTL).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool signUp}) async {
    final name = _nameCtrl.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Escribe un nombre de al menos 2 letras.')));
      return;
    }
    final game = AppServices.of(context).game;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      signUp ? await game.signUp(name) : await game.logIn(name);
      if (!mounted) return;
      navigator.pushReplacementNamed(AppRoutes.list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(
          content: Text(
              e is AppException ? e.message : 'No se pudo iniciar sesión.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                      color: trailCoffee, borderRadius: trailCut),
                  child: const Icon(Icons.pets, size: 62, color: trailCream),
                ),
                const SizedBox(height: 20),
                Text('Paseo Perruno',
                    style: text.displaySmall, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('Pasea, gana XP y sube en el ranking',
                    style: text.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameCtrl,
                  maxLength: 20,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(labelText: 'Tu nombre de paseador'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : () => _submit(signUp: true),
                    child: Text(_busy ? 'Conectando…' : 'Crear cuenta'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => _submit(signUp: false),
                    child: const Text('Ya tengo cuenta'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

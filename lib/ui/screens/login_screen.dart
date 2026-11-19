import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/exceptions.dart';
import '../../core/routes.dart';
import '../theme/app_theme.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe un nombre de al menos 2 letras.')));
      return;
    }
    final services = AppServices.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      signUp ? await services.game.signUp(name) : await services.game.logIn(name);
      services.profile.value = null;
      navigator.pushReplacementNamed(AppRoutes.list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo iniciar sesión.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: Tk.rust,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(30), bottomLeft: Radius.circular(30), bottomRight: Radius.circular(8)),
                  ),
                  child: const Icon(Icons.pets, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 20),
              Text('Paseo Perruno', textAlign: TextAlign.center, style: Tk.display(32)),
              const SizedBox(height: 6),
              Text('Pasea, gana XP y sube en el ranking', textAlign: TextAlign.center, style: Tk.body(14)),
              const SizedBox(height: 36),
              Text('Tu nombre de paseador', style: Tk.label()),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                enabled: !_busy,
                maxLength: 20,
                textCapitalization: TextCapitalization.words,
                style: Tk.display(17),
                decoration: const InputDecoration(hintText: 'Ej. David', counterText: '', prefixIcon: Icon(Icons.hiking, color: Tk.rust)),
                onSubmitted: (_) => _submit(signUp: false),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _busy ? null : () => _submit(signUp: true), child: Text(_busy ? 'Conectando…' : 'Crear cuenta')),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: _busy ? null : () => _submit(signUp: false), child: const Text('Ya tengo cuenta')),
            ]),
          ),
        ),
      ),
    );
  }
}

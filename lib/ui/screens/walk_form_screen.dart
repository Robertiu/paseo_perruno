import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/exceptions.dart';
import '../../core/routes.dart';
import '../../domain/models/walk_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/reward_dialog.dart';

/// Nuevo paseo (pestaña) o edición de un paseo existente (pantalla secundaria).
class WalkFormScreen extends StatefulWidget {
  /// Si no es nulo, edita ese paseo (nombre, duración y notas).
  final WalkEntry? existing;

  const WalkFormScreen({super.key, this.existing});

  @override
  State<WalkFormScreen> createState() => _WalkFormScreenState();
}

class _WalkFormScreenState extends State<WalkFormScreen> {
  static const _maxNotes = 300;

  final _formKey = GlobalKey<FormState>();
  late final _dogCtrl = TextEditingController(text: widget.existing?.dogName);
  late final _notesCtrl = TextEditingController(text: widget.existing?.notes);
  late int _minutes = (widget.existing?.durationMinutes ?? 30).clamp(5, 240);

  String? _imagePath;
  bool _listening = false;
  bool _saving = false;
  List<String> _recentDogs = const [];
  String _notesBeforeDictation = '';

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _notesCtrl.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_editing && _recentDogs.isEmpty) _loadRecentDogs();
  }

  Future<void> _loadRecentDogs() async {
    try {
      final walks = await AppServices.of(context).walks.getAll();
      final names = <String>[];
      for (final w in walks) {
        if (!names.contains(w.dogName)) names.add(w.dogName);
      }
      if (mounted) setState(() => _recentDogs = names.take(4).toList());
    } catch (_) {
      // Las sugerencias son opcionales.
    }
  }

  @override
  void dispose() {
    _dogCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _showError(Object e) {
    final msg = e is AppException ? e.message : 'Ocurrió un error inesperado.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Misma fórmula que el servidor (aprox.: la racha final la decide la API).
  int get _estimatedXp {
    final streak = AppServices.of(context).profile.value?.streak ?? 0;
    return 10 +
        (_minutes > 120 ? 120 : _minutes) +
        (_notesCtrl.text.trim().isNotEmpty ? 5 : 0) +
        (_imagePath != null ? 5 : 0) +
        5 +
        2 * (streak < 1 ? 1 : (streak > 10 ? 10 : streak));
  }

  Future<void> _pickImage(bool camera) async {
    final media = AppServices.of(context).media;
    try {
      final path = camera ? await media.takePhoto() : await media.pickFromGallery();
      if (path != null && mounted) setState(() => _imagePath = path);
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _toggleDictation() async {
    final speech = AppServices.of(context).speech;
    if (_listening) {
      await speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    _notesBeforeDictation = _notesCtrl.text.trim();
    try {
      setState(() => _listening = true);
      await speech.start(
        onText: (text, isFinal) {
          if (!mounted) return;
          setState(() {
            final joined = [_notesBeforeDictation, text].where((s) => s.isNotEmpty).join(' ');
            _notesCtrl.text = joined.length > _maxNotes ? joined.substring(0, _maxNotes) : joined;
            if (isFinal) _listening = false;
          });
        },
        onStatus: (status) {
          if (mounted && (status == 'done' || status == 'notListening')) setState(() => _listening = false);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _listening = false);
        _showError(e);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final services = AppServices.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);

    try {
      if (_editing) {
        await services.walks.update(widget.existing!.copyWith(
          dogName: _dogCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          durationMinutes: _minutes,
        ));
        if (mounted) navigator.pop(true);
        return;
      }

      // La ubicación es opcional: si falla, el paseo se guarda sin coordenadas.
      double? lat, lng;
      try {
        final pos = await services.location.currentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      } on LocationException catch (e) {
        if (mounted) _showError(e);
      }

      final saved = await services.walks.insert(WalkEntry(
        dogName: _dogCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        durationMinutes: _minutes,
        createdAt: DateTime.now(),
        imagePath: _imagePath,
        latitude: lat,
        longitude: lng,
      ));
      services.refreshProfile();
      if (!mounted) return;
      await showRewardDialog(context, saved.reward);
      if (mounted) navigator.pushReplacementNamed(AppRoutes.list);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showError(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _editing ? 'Editar paseo' : 'Nuevo paseo';
    return AppShell(
      title: title,
      tab: _editing ? null : AppTab.form,
      back: _editing,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Tk.pad, 20, Tk.pad, 24),
          children: [
            PageTitle(title),
            if (!_editing) ...[
              _PhotoBox(path: _imagePath, onCamera: () => _pickImage(true), onGallery: () => _pickImage(false)),
              const Rule(),
            ],
            Text('Compañero de ruta', style: Tk.body(14, w: FontWeight.w700, color: Tk.ink)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _dogCtrl,
              textCapitalization: TextCapitalization.words,
              style: Tk.display(16),
              decoration: const InputDecoration(hintText: 'Nombre del perro', prefixIcon: Icon(Icons.pets, color: Tk.rust)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
            ),
            if (_recentDogs.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                for (final name in _recentDogs)
                  ActionChip(
                    label: Text(name, style: Tk.body(12, w: FontWeight.w600, color: Tk.green)),
                    backgroundColor: Tk.card,
                    side: BorderSide.none,
                    onPressed: () => setState(() => _dogCtrl.text = name),
                  ),
              ]),
            ],
            const Rule(gap: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Duración de la caminata', style: Tk.body(14, w: FontWeight.w700, color: Tk.ink)),
              Text.rich(TextSpan(children: [
                TextSpan(text: '$_minutes', style: Tk.display(32, color: Tk.rust)),
                TextSpan(text: ' min', style: Tk.body(14)),
              ])),
            ]),
            Slider(
              value: _minutes.toDouble(),
              min: 5,
              max: 240,
              divisions: 47,
              onChanged: (v) => setState(() => _minutes = v.round()),
            ),
            Row(children: [
              for (final add in const [5, 15, 30]) ...[
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _minutes = (_minutes + add).clamp(5, 240)),
                    borderRadius: BorderRadius.circular(Tk.radius),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Tk.card, borderRadius: BorderRadius.circular(Tk.radius)),
                      child: Text('+$add min', style: Tk.body(12, w: FontWeight.w600, color: Tk.ink)),
                    ),
                  ),
                ),
                if (add != 30) const SizedBox(width: 10),
              ],
            ]),
            const Rule(gap: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Notas del sendero', style: Tk.body(14, w: FontWeight.w700, color: Tk.ink)),
              InkWell(
                onTap: _toggleDictation,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: _listening ? Tk.blush : Tk.card, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_listening ? Icons.mic : Icons.mic_none, size: 16, color: Tk.rust),
                    const SizedBox(width: 4),
                    Text(_listening ? 'Escuchando…' : 'Dictar', style: Tk.body(12, w: FontWeight.w600, color: Tk.rust)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              maxLines: 5,
              maxLength: _maxNotes,
              style: Tk.body(14, color: Tk.ink),
              decoration: const InputDecoration(hintText: '¿Qué lugares exploraron? ¿Cómo estuvo su energía?'),
            ),
            if (!_editing) ...[
              const Rule(gap: 12),
              _XpEstimate(xp: _estimatedXp, streak: AppServices.of(context).profile.value?.streak ?? 0),
              const Rule(gap: 12),
              const _GpsNote(),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: Tk.rust),
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.bookmark_added_outlined),
              label: Text(_saving ? 'Guardando…' : (_editing ? 'Guardar cambios' : 'Guardar en la bitácora')),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoBox extends StatelessWidget {
  final String? path;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  const _PhotoBox({required this.path, required this.onCamera, required this.onGallery});

  Widget _action(IconData icon, String text, Color color, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(text, style: Tk.body(12, w: FontWeight.w700, color: color)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Foto', style: Tk.label()),
        Text('Opcional', style: Tk.body(10, w: FontWeight.w600, color: Tk.ink)),
      ]),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        height: 190,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Tk.card, borderRadius: BorderRadius.circular(Tk.radius)),
        child: path != null
            ? Image.file(File(path!), fit: BoxFit.cover)
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.pets, size: 30, color: Tk.rust),
                const SizedBox(height: 12),
                Text('Captura una instantánea del\nexplorador en acción', textAlign: TextAlign.center, style: Tk.body(12, height: 1.4)),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _action(Icons.photo_camera_outlined, 'Tomar foto', Tk.rust, onCamera),
                  _action(Icons.photo_library_outlined, 'Galería', Tk.green, onGallery),
                ]),
              ]),
      ),
      if (path != null)
        Row(children: [
          _action(Icons.photo_camera_outlined, 'Cambiar foto', Tk.rust, onCamera),
          _action(Icons.photo_library_outlined, 'Galería', Tk.green, onGallery),
        ]),
    ]);
  }
}

class _XpEstimate extends StatelessWidget {
  final int xp;
  final int streak;
  const _XpEstimate({required this.xp, required this.streak});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('XP estimado', style: Tk.body(10, w: FontWeight.w600, color: Tk.green)),
            const SizedBox(height: 4),
            Text('Estimado: +$xp XP', style: Tk.display(24, color: Tk.rust)),
            const SizedBox(height: 4),
            Text(
              streak > 0 ? 'El XP final se sincronizará con la racha activa de $streak ${streak == 1 ? 'día' : 'días'}.' : 'El XP final se calcula en el servidor al guardar.',
              style: Tk.body(12, height: 1.4),
            ),
          ]),
        ),
        const SizedBox(width: 16),
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Tk.rust,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6), topRight: Radius.circular(22), bottomLeft: Radius.circular(22), bottomRight: Radius.circular(6)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.military_tech_outlined, color: Tk.blush, size: 20),
            Text('+$xp', style: Tk.body(11, w: FontWeight.w700, color: Tk.blush)),
            Text('Ruta', style: Tk.body(9, color: Tk.blush)),
          ]),
        ),
      ]);
}

class _GpsNote extends StatelessWidget {
  const _GpsNote();

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(color: Tk.card, shape: BoxShape.circle),
          child: const Icon(Icons.satellite_alt, size: 18, color: Tk.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ubicación GPS (opcional)', style: Tk.body(12, w: FontWeight.w700, color: Tk.ink)),
            Text('La bitácora se guardará sin contratiempos aun si caminan fuera de cobertura o sin conexión de datos.',
                style: Tk.body(12, height: 1.4)),
          ]),
        ),
      ]);
}

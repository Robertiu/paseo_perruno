import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/exceptions.dart';
import '../../core/routes.dart';
import '../trail_theme.dart';
import '../../domain/models/walk_entry.dart';
import '../widgets/reward_dialog.dart';

/// Formulario de nuevo paseo: foto (cámara/galería), dictado y GPS al guardar.
class WalkFormScreen extends StatefulWidget {
  /// Si no es nulo, el formulario edita ese paseo (nombre, duración y notas).
  final WalkEntry? existing;

  const WalkFormScreen({super.key, this.existing});

  @override
  State<WalkFormScreen> createState() => _WalkFormScreenState();
}

class _WalkFormScreenState extends State<WalkFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _dogCtrl = TextEditingController(text: widget.existing?.dogName);
  late final _notesCtrl = TextEditingController(text: widget.existing?.notes);
  late final _durationCtrl =
      TextEditingController(text: '${widget.existing?.durationMinutes ?? 30}');

  bool get _editing => widget.existing != null;

  String? _imagePath;
  bool _listening = false;
  bool _saving = false;

  /// Texto que ya había antes de empezar a dictar, para anexar sin borrarlo.
  String _notesBeforeDictation = '';

  @override
  void dispose() {
    _dogCtrl.dispose();
    _notesCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  void _showError(Object e) {
    if (e is AuthException) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
      return;
    }
    final msg = e is AppException ? e.message : 'Ocurrió un error inesperado.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickImage(bool camera) async {
    final media = AppServices.of(context).media;
    try {
      final path =
          camera ? await media.takePhoto() : await media.pickFromGallery();
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
            _notesCtrl.text = [_notesBeforeDictation, text]
                .where((s) => s.isNotEmpty)
                .join(' ');
            if (isFinal) _listening = false;
          });
        },
        onStatus: (status) {
          if (mounted && (status == 'done' || status == 'notListening')) {
            setState(() => _listening = false);
          }
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
    FocusScope.of(context).unfocus();
    final services = AppServices.of(context);
    setState(() => _saving = true);

    if (_editing) {
      try {
        await services.walks.update(widget.existing!.copyWith(
          dogName: _dogCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          durationMinutes: int.parse(_durationCtrl.text),
        ));
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          setState(() => _saving = false);
          _showError(e);
        }
      }
      return;
    }

    try {
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
        durationMinutes: int.parse(_durationCtrl.text),
        createdAt: DateTime.now(),
        imagePath: _imagePath,
        latitude: lat,
        longitude: lng,
      ));
      if (!mounted) return;
      await showRewardDialog(context, saved.reward);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showError(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Editar paseo' : 'Nuevo paseo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_editing) ...[
              _PhotoPicker(
                imagePath: _imagePath,
                onCamera: () => _pickImage(true),
                onGallery: () => _pickImage(false),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _dogCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre del perro',
                prefixIcon: Icon(Icons.pets),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duración (minutos)',
                prefixIcon: Icon(Icons.timer_outlined),
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n <= 0) ? 'Ingresa minutos válidos' : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Notas del paseo',
                alignLabelWithHint: true,
                suffixIcon: IconButton(
                  tooltip: _listening ? 'Detener dictado' : 'Dictar',
                  color: _listening ? Colors.red : null,
                  icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                  onPressed: _toggleDictation,
                ),
              ),
            ),
            if (!_editing) ...[
              const SizedBox(height: 18),
              ListenableBuilder(
                listenable: Listenable.merge([_durationCtrl, _notesCtrl]),
                builder: (context, _) {
                  final minutes = int.tryParse(_durationCtrl.text);
                  if (minutes == null || minutes < 1) {
                    return const SizedBox.shrink();
                  }
                  final xp = 10 +
                      minutes.clamp(1, 120) +
                      (_imagePath == null ? 0 : 5) +
                      (_notesCtrl.text.trim().isEmpty ? 0 : 5);
                  return Text(
                      '+$xp XP base. GPS, racha y reto pueden sumar más.',
                      style: Theme.of(context).textTheme.bodyMedium);
                },
              ),
              const SizedBox(height: 6),
              const Text(
                  'Al guardar, se intenta añadir tu ubicación. Es opcional.'),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_saving
                  ? 'Guardando…'
                  : (_editing ? 'Guardar cambios' : 'Guardar paseo')),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _PhotoPicker({
    required this.imagePath,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: trailCut,
          child: Container(
            height: 200,
            width: double.infinity,
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: imagePath == null
                ? const Icon(Icons.pets, size: 64)
                : Image.file(File(imagePath!), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Cámara'),
            ),
            OutlinedButton.icon(
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Galería'),
            ),
          ],
        ),
      ],
    );
  }
}

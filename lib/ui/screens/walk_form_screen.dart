import 'dart:io';

import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../core/exceptions.dart';
import '../../domain/models/walk_entry.dart';

/// Formulario de nuevo paseo: foto (cámara/galería), dictado y GPS al guardar.
class WalkFormScreen extends StatefulWidget {
  const WalkFormScreen({super.key});

  @override
  State<WalkFormScreen> createState() => _WalkFormScreenState();
}

class _WalkFormScreenState extends State<WalkFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dogCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '30');

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
    final msg = e is AppException ? e.message : 'Ocurrió un error inesperado.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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
            _notesCtrl.text =
                [_notesBeforeDictation, text].where((s) => s.isNotEmpty).join(' ');
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
    final services = AppServices.of(context);
    setState(() => _saving = true);

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

      await services.walks.insert(WalkEntry(
        dogName: _dogCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        durationMinutes: int.parse(_durationCtrl.text),
        createdAt: DateTime.now(),
        imagePath: _imagePath,
        latitude: lat,
        longitude: lng,
      ));
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
      appBar: AppBar(title: const Text('Nuevo paseo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PhotoPicker(
              imagePath: _imagePath,
              onCamera: () => _pickImage(true),
              onGallery: () => _pickImage(false),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dogCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre del perro',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duración (minutos)',
                border: OutlineInputBorder(),
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
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _listening ? 'Detener dictado' : 'Dictar',
                  color: _listening ? Colors.red : null,
                  icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                  onPressed: _toggleDictation,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Guardando…' : 'Guardar paseo'),
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
          borderRadius: BorderRadius.circular(12),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Cámara'),
            ),
            const SizedBox(width: 12),
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

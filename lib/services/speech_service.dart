import 'package:speech_to_text/speech_to_text.dart';

import '../core/exceptions.dart';

/// Gadget 2: micrófono y dictado.
///
/// Envuelve `speech_to_text` (captura el audio del micrófono y lo
/// transcribe) para que los widgets no dependan del paquete.
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _ready = false;

  bool get isListening => _speech.isListening;

  Future<void> _ensureInitialized(void Function(String status)? onStatus) async {
    if (_ready) return;
    try {
      _ready = await _speech.initialize(onStatus: onStatus);
    } catch (e) {
      throw SpeechException('No se pudo iniciar el micrófono.', e);
    }
    if (!_ready) {
      throw const SpeechException('Dictado no disponible o permiso de micrófono denegado.');
    }
  }

  /// Empieza a escuchar. [onText] recibe la transcripción parcial y final.
  Future<void> start({
    required void Function(String text, bool isFinal) onText,
    void Function(String status)? onStatus,
  }) async {
    await _ensureInitialized(onStatus);
    try {
      await _speech.listen(
        listenOptions: SpeechListenOptions(partialResults: true, localeId: 'es_MX'),
        onResult: (r) => onText(r.recognizedWords, r.finalResult),
      );
    } catch (e) {
      throw SpeechException('Falló el dictado.', e);
    }
  }

  Future<void> stop() => _speech.stop();
}

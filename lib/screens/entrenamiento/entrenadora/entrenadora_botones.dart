part of '../entrenadora.dart';

extension EntrenadoraBotones on Entrenadora {
  Future<void> detener() async {
    Logger().i("Deteniendo entrenadora");
    if (_flutterTts != null) {
      _borrarSpeaker = true;
      _isPaused = true;
      await _flutterTts!.stop();
      _flutterTts = null;
    }
  }

  void pausar() {
    Logger().i("Pausando entrenadora");
    _isPaused = true;
    _borrarSpeaker = false;
  }

  void reanudar() {
    _isPaused = false;
    _borrarSpeaker = false;
    if (_flutterTts == null) {
      _flutterTts = FlutterTts();
      _flutterTts?.setLanguage("es-ES");
      _flutterTts?.setSpeechRate(0.5);
      _flutterTts?.setPitch(1.0);
      _flutterTts?.awaitSpeakCompletion(true);
    }
  }

  void setSaltarDescanso(bool value) {
    saltarDescanso = value;
  }
}

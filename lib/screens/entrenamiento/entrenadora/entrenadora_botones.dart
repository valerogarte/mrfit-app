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
    _isPaused = true;
    _borrarSpeaker = false;
  }

  void reanudar() {
    _isPaused = false;
    _borrarSpeaker = false;
    if (_flutterTts == null) {
      _initializeTts();
    }
  }

  void setSaltarDescanso(bool value) {
    saltarDescanso = value;
  }
}

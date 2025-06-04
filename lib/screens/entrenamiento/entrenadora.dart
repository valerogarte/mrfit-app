import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'dart:math';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mrfit/models/entrenamiento/ejercicio_realizado.dart';
import 'package:mrfit/models/entrenamiento/serie_realizada.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'dart:convert';

part 'entrenadora/entrenadora_speaker.dart';
part 'entrenadora/entrenadora_speaker_utils.dart';
part 'entrenadora/entrenadora_botones.dart';

class Entrenadora {
  bool saltarDescanso = false;
  FlutterTts? _flutterTts;
  bool _isPaused = false;
  bool _borrarSpeaker = false;

  bool aviso10Segundos = false;
  bool avisoCuentaAtras = false;
  String entrenadorVoz = '';
  int entrenadorVolumen = 10;

  // Referencia estática privada para el singleton
  static Entrenadora? _singletonInstance;

  // Constructor factory que retorna la instancia única
  factory Entrenadora() {
    // Si ya existe una instancia, la destruimos antes de crear una nueva
    _singletonInstance?.dispose();
    _singletonInstance = Entrenadora._internal();
    return _singletonInstance!;
  }

  // Constructor privado
  Entrenadora._internal() {
    _initializeTts();
    initializeDateFormatting('es_ES', null);
  }

  void _initializeTts() {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) return;

    _flutterTts = FlutterTts()
      ..setLanguage("es-ES")
      ..setSpeechRate(0.5)
      ..setPitch(1.0)
      ..awaitSpeakCompletion(true);

    configure(
      aviso10Segundos: aviso10Segundos,
      avisoCuentaAtras: avisoCuentaAtras,
      entrenadorVoz: entrenadorVoz,
      entrenadorVolumen: entrenadorVolumen,
    );
  }

  /// Configura las preferencias de voz y avisos
  void configure({
    required bool aviso10Segundos,
    required bool avisoCuentaAtras,
    required String entrenadorVoz,
    required int entrenadorVolumen,
  }) {
    this.aviso10Segundos = aviso10Segundos;
    this.avisoCuentaAtras = avisoCuentaAtras;
    this.entrenadorVoz = entrenadorVoz;
    this.entrenadorVolumen = entrenadorVolumen;

    if (entrenadorVoz.isNotEmpty && _flutterTts != null) {
      // try parsing JSON; on failure, use the raw string as name with default locale
      Map<String, String> voiceConfig;
      try {
        final data = jsonDecode(entrenadorVoz) as Map<String, dynamic>;
        voiceConfig = {
          'name': data['name'] as String,
          'locale': data['locale'] as String,
        };
      } catch (_) {
        voiceConfig = {
          'name': entrenadorVoz,
          'locale': 'es-ES',
        };
      }
      _flutterTts!.setVoice(voiceConfig);
    }

    // Ajustar TTS si está inicializado
    if (entrenadorVolumen >= 0 && entrenadorVolumen <= 10 && _flutterTts != null) {
      _flutterTts!.setVolume(entrenadorVolumen / 10.0);
    }
  }

  /// Espera mientras se encuentre en pausa, se pida borrar o, opcionalmente, saltarDescanso.
  /// Devuelve false si se cumple alguna condición de salida, true si termina la espera.
  Future<bool> waitWhileInterrupted({int delayMs = 100}) async {
    while (isPaused || borrarSpeaker || saltarDescanso) {
      await Future.delayed(Duration(milliseconds: delayMs));
      if (borrarSpeaker || saltarDescanso) return false;
    }
    return true;
  }

  /// Libera recursos y destruye la instancia singleton.
  /// Útil para evitar fugas de memoria y reinicializar la entrenadora.
  void dispose() {
    // Libera recursos de TTS si es necesario
    _flutterTts?.stop();
    _flutterTts = null;
    _isPaused = false;
    _borrarSpeaker = false;
    saltarDescanso = false;
    // Limpia la referencia singleton
    if (identical(_singletonInstance, this)) {
      _singletonInstance = null;
    }
  }

  // Agrega getters para exponer el estado de las variables
  bool get isPaused => _isPaused;
  bool get borrarSpeaker => _borrarSpeaker;
}

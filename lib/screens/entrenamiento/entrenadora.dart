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
part 'entrenadora/entrenadora_speaker.dart';
part 'entrenadora/entrenadora_speaker_utils.dart';
part 'entrenadora/entrenadora_botones.dart';

class Entrenadora {
  bool saltarDescanso = false;
  FlutterTts? _flutterTts;
  bool _isPaused = false;
  bool _borrarSpeaker = false;

  // Singleton: Instancia única estática
  static final Entrenadora _instance = Entrenadora._internal();

  // Constructor factory que retorna la instancia única
  factory Entrenadora() => _instance;

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

  // Agrega getters para exponer el estado de las variables
  bool get isPaused => _isPaused;
  bool get borrarSpeaker => _borrarSpeaker;
}

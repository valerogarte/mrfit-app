part of '../entrenadora.dart';

extension EntrenadoraSpeaker on Entrenadora {
  // Método para leer el inicio del entrenamiento
  Future<void> leerInicioEntrenamiento(Entrenamiento entrenamiento, EjercicioRealizado ejercicioR) async {
    // Solo lo leo si existen ejercicios
    if (entrenamiento.ejercicios.isNotEmpty) {
      if (!await waitWhileInterrupted()) return;
      // Cojo las series del ejercicio actual
      // Compruebo si el ejercicio actual tiene todas las series realizadas
      bool ejercicioSinEmpezar = ejercicioR.hasSeriesNoRealizadas();
      String ejercicioNombre = ejercicioR.ejercicio.nombre;

      if (!await waitWhileInterrupted()) return;

      // Solo leerlo si no se ha empezado el ejercicio o no es el primer ejercicio
      final ejercicioIndex = entrenamiento.ejercicios.indexOf(ejercicioR);
      if (ejercicioIndex > 0 || !ejercicioSinEmpezar) {
        if (_flutterTts != null) {
          List<String> opciones = ['Seguimos', 'Continuamos', 'Prosigamos', 'Vamos a continuar', 'Vamos a seguir', 'Vamos a proseguir'];
          String palabra = opciones[Random().nextInt(opciones.length)];
          await _flutterTts!.speak('$palabra en el ejercicio $ejercicioNombre.');
        }
      } else {
        if (ejercicioSinEmpezar) {
          await Future.delayed(const Duration(seconds: 1));
          await leerIntroduccionEntrenamiento(entrenamiento);
          if (_flutterTts != null) {
            await _flutterTts!.speak("Empezaremos con $ejercicioNombre.");
          }
          if (!await waitWhileInterrupted()) return;
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      if (!await waitWhileInterrupted()) return;
    }
  }

  // Método para cuenta atrás + contar las repeticiones
  Future<void> contarRepeticionesAndCuentaAtras(SerieRealizada serieR) async {
    if (_flutterTts != null) {
      // Leer "3, 2, 1"
      await leerCuentaAtras();
      if (!await waitWhileInterrupted()) return;

      // Leer mensaje "Empezamos"
      await leerMensajeEmpezamos();
      if (!await waitWhileInterrupted()) return;

      // Contar las repeticiones
      await contarRepeticionesEjercicio(serieR);
      if (!await waitWhileInterrupted()) return;
    }
  }

  // Método para contar las repeticiones
  Future<void> contarRepeticiones(SerieRealizada serieR, EjercicioRealizado ejercicioR) async {
    if (_flutterTts != null) {
      if (!await waitWhileInterrupted()) return;

      bool realizarPorExtremidad = ejercicioR.ejercicio.realizarPorExtremidad;

      if (realizarPorExtremidad) {
        await leerLadoDelEjercicio("izquierdo");
      }

      await contarRepeticionesAndCuentaAtras(serieR);

      if (realizarPorExtremidad) {
        await leerLadoDelEjercicio("derecho");
        await contarRepeticionesAndCuentaAtras(serieR);
      }

      // Leer "Serie completada"
      await leerSerieCompletada();
      if (!await waitWhileInterrupted()) return;
    }
  }

  // Método para realizar el descanso y la cuenta atrás
  Future<void> realizarDescanso(SerieRealizada serieR, int currentIndex, int totalSeries, List<EjercicioRealizado> ejercicios, int index) async {
    if (_flutterTts != null) {
      // Hora actual en microsegundos
      int horaActual = DateTime.now().microsecondsSinceEpoch;
      if (!await waitWhileInterrupted()) return;

      await leerTiempoDescanso(serieR);
      if (!await waitWhileInterrupted()) return;

      await leerSiguienteSerieOrEjercicio(serieR, currentIndex, totalSeries, ejercicios, index);
      if (!await waitWhileInterrupted()) return;

      int horaFinal = DateTime.now().microsecondsSinceEpoch;
      int tiempoLeer = (horaFinal - horaActual) ~/ 1000000;

      await esperarDescanso(serieR, currentIndex, totalSeries, ejercicios, index, tiempoLeer);

      setSaltarDescanso(false);

      if (!await waitWhileInterrupted()) return;
    }
  }
}

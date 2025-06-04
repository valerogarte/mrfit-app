part of '../entrenadora.dart';
final List<String> completionMessages = [
  '¡Serie completada!',
  '¡Finalizada!',
  '¡Buen trabajo!',
  '¡Hecho!',
  '¡Gran trabajo!',
  '¡Excelente!',
  '¡Logrado!',
  '¡Buen esfuerzo!',
  '¡Bien hecho!',
  '¡Excelente!',
];

final List<String> literalDescanso = ["Descansamos", "Paramos", "Respiro de", "Descanso de"];

final List<String> seriesNumeroLiterales = [
  "primera",
  "segunda",
  "tercera",
  "cuarta",
  "quinta",
  "sexta",
  "séptima",
  "octava",
  "novena",
  "décima",
  "undécima",
  "duodécima",
  "decimotercera",
  "decimocuarta",
  "decimoquinta",
  "decimosexta",
  "decimoséptima",
  "decimoctava",
  "decimonovena",
  "vigésima",
];

final List<String> inicioMessages = ['¡Empezamos!', '¡Manos a la obra!', '¡Vamos!', '¡Adelante!', '¡Arrancamos!', '¡En marcha!', '¡Dale duro!', '¡Comenzamos!', '¡A por ello!', '¡A darlo todo!'];

// Helper function to convert weight to a descriptive string
String pesoLiteral(double peso) {
  if (peso % 1 == 0) {
    return '${peso.toInt()} kilos';
  } else if ((peso * 10) % 10 == 5) {
    int entero = peso.toInt();
    return '$entero kilos y medio';
  } else {
    int entero = peso.toInt();
    int decimal = ((peso % 1) * 10).toInt();
    return '$entero con $decimal kilos';
  }
}

extension EntrenadoraHelpers on Entrenadora {
  // Metodo para leer la introducción del entrenamiento
  Future<void> leerIntroduccionEntrenamiento(Entrenamiento entrenamiento) async {
    if (!await waitWhileInterrupted()) return;
    String entrenamientoNombre = entrenamiento.titulo;
    String diaSemana = DateFormat('EEEE', 'es_ES').format(DateTime.now());
    if (_flutterTts != null) {
      await _flutterTts!.speak('Hoy $diaSemana vamos a realizar el entrenamiento $entrenamientoNombre.');
    }
    if (!await waitWhileInterrupted()) return;
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!await waitWhileInterrupted()) return;
  }

  // Método para leer la descripción de un ejercicio
  Future<void> leerDescripcion(EjercicioRealizado ejercicioR, [EjercicioRealizado? ejercicioRAnterior]) async {
    if (_flutterTts != null) {
      if (!await waitWhileInterrupted()) return;

      // COMPARAR PESO DEL EJERCICIO ANTERIOR Y PRIMERA SERIE NO REALIZADA
      if (ejercicioRAnterior != null && ejercicioRAnterior.series.isNotEmpty) {
        // Obtener última serie sin borrado
        final seriesPrev = ejercicioRAnterior.series.where((s) => s.deleted == false);
        if (seriesPrev.isNotEmpty) {
          final ultimaSerieAnterior = seriesPrev.last;
          final seriesActual = ejercicioR.series.where((s) => s.realizada == false);
          if (seriesActual.isNotEmpty) {
            final primeraSerieNoRealizada = seriesActual.first;
            // Compara pesos
            final equipamiento = ejercicioR.ejercicio.equipamiento;
            if (ultimaSerieAnterior.peso != primeraSerieNoRealizada.peso) {
              if (!await waitWhileInterrupted()) return;
              var nuevoPeso = primeraSerieNoRealizada.peso;

              // 1="Solo cuerpo" y 3="Otros"
              if ({1, 3}.contains(equipamiento.id)) {
                // NO DIGO NADA, solo se usa el cuerpo u equipamiento genérico
              } else {
                if (equipamiento.titulo != ejercicioRAnterior.ejercicio.equipamiento.titulo) {
                  if (nuevoPeso == 0) {
                    await _flutterTts!.speak('Cambia a ${equipamiento.titulo} sin peso.');
                  } else {
                    await _flutterTts!.speak('Cambia a ${equipamiento.titulo} con ${pesoLiteral(nuevoPeso)}.');
                  }
                } else {
                  if (nuevoPeso == 0) {
                    await _flutterTts!.speak('Quita el peso.');
                  } else {
                    await _flutterTts!.speak('Atención, ve cambiando el peso a ${pesoLiteral(nuevoPeso)}.');
                  }
                }
              }

              if (!await waitWhileInterrupted()) return;
            } else {
              if ({1, 3}.contains(equipamiento.id)) {
                // NO DIGO NADA, solo se usa el cuerpo u equipamiento genérico
              } else {
                await Future.delayed(const Duration(milliseconds: 300));
                await _flutterTts!.speak('Mantén el mismo peso.');
              }
            }
          }
        }
      }

      // Verificar si hay al menos una serie no realizada
      bool haySerieNoRealizada = ejercicioR.hasSeriesNoRealizadas();

      if (!await waitWhileInterrupted()) return;

      if (haySerieNoRealizada) {
        await leerSeriesRepesAndPeso(ejercicioR);

        if (!await waitWhileInterrupted()) return;
      }
    }
  }

  // Función para leer "3, 2, 1"
  Future<void> leerCuentaAtras() async {
    if (_flutterTts != null) {
      for (int i = 3; i > 0; i--) {
        if (!await waitWhileInterrupted()) return;
        final stopwatch = Stopwatch()..start();
        if (avisoCuentaAtras) {
          await _flutterTts!.speak('$i');
        }
        stopwatch.stop();
        final duracion = stopwatch.elapsed;

        if (duracion.inMilliseconds < 1000) {
          await Future.delayed(Duration(milliseconds: 1000 - duracion.inMilliseconds));
        }

        if (!await waitWhileInterrupted()) return;
      }
    }
  }

  // Función para leer mensaje "Empezamos"
  Future<void> leerMensajeEmpezamos() async {
    if (_flutterTts != null) {
      if (!await waitWhileInterrupted()) return;
      final randomEmpezamos = Random();
      final messageEmpezamos = inicioMessages[randomEmpezamos.nextInt(inicioMessages.length)];
      await _flutterTts!.speak(messageEmpezamos);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!await waitWhileInterrupted()) return;
    }
  }

  // Función para leer el lado del ejercicio a realizar
  Future<void> leerLadoDelEjercicio(String lado) async {
    if (_flutterTts != null) {
      if (!await waitWhileInterrupted()) return;
      await _flutterTts!.speak("Vamos con el lado $lado");
      await Future.delayed(const Duration(milliseconds: 300));
      if (!await waitWhileInterrupted()) return;
    }
  }

  // Función para contar las repeticiones
  Future<void> contarRepeticionesEjercicio(SerieRealizada serieR) async {
    if (_flutterTts != null) {
      int repeticiones = serieR.repeticiones;

      for (int i = 1; i <= repeticiones; i++) {
        if (!await waitWhileInterrupted()) return;
        if (repeticiones == i) {
          await _flutterTts!.speak('y $i');
        } else {
          await _flutterTts!.speak('$i');
        }
        var velocidadRepeticion = (serieR.velocidadRepeticion * 1000).toInt() - 200;
        if (velocidadRepeticion < 0) {
          velocidadRepeticion = 0;
        }
        await Future.delayed(Duration(milliseconds: velocidadRepeticion));
        if (!await waitWhileInterrupted()) return;
      }
    }
  }

  // Función para leer "Serie completada"
  Future<void> leerSerieCompletada() async {
    if (_flutterTts != null) {
      if (!await waitWhileInterrupted()) return;
      final randomSerieCompletada = Random();
      final messageSerieCompletada = completionMessages[randomSerieCompletada.nextInt(completionMessages.length)];
      await _flutterTts!.speak(messageSerieCompletada);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!await waitWhileInterrupted()) return;
    }
  }

  // Función para leer el tiempo de descanso
  Future<void> leerTiempoDescanso(SerieRealizada serieR) async {
    if (_flutterTts != null) {
      if (!await waitWhileInterrupted()) return;
      int descanso = serieR.descanso;
      if (descanso < 10) {
        return;
      }

      final randomDescanso = Random();
      final mensajeDescanso = literalDescanso[randomDescanso.nextInt(literalDescanso.length)];
      if (descanso >= 60) {
        int minutos = descanso ~/ 60;
        int segundos = descanso % 60;
        String literalMinuto = minutos == 1 ? 'minuto' : 'minutos';
        String mensaje = '$mensajeDescanso $minutos $literalMinuto';
        if (segundos > 0) {
          mensaje += ' y $segundos segundos';
        }
        await _flutterTts!.speak(mensaje);
      } else {
        await _flutterTts!.speak('$mensajeDescanso $descanso segundos');
      }
      if (!await waitWhileInterrupted()) return;
    }
  }

  // Función para leer el siguiente ejercicio o serie
  Future<void> leerSiguienteSerieOrEjercicio(SerieRealizada serieRealizada, int indexSerie, int totalSeries, List<EjercicioRealizado> ejerciciosRList, int indexEjercicio) async {
    if (_flutterTts != null) {
      if (!await waitWhileInterrupted()) return;
      // Si el descanso es menor a 10 segundos, tiene que ser todo muy rápido
      if (serieRealizada.descanso < 10) {
        if (indexSerie == totalSeries - 1) {
          if (indexEjercicio < ejerciciosRList.length - 1) {
            String ejercicioSiguienteNombre = ejerciciosRList[indexEjercicio + 1].ejercicio.nombre;
            await _flutterTts!.speak('Cambiamos a $ejercicioSiguienteNombre.');
          }
        }
        return;
      }

      if (indexSerie == totalSeries - 1) {
        if (indexEjercicio < ejerciciosRList.length - 1) {
          final ejercicioSiguiente = ejerciciosRList[indexEjercicio + 1];
          final ejercicioActual = ejerciciosRList[indexEjercicio]; // Fix: use Map instead of String
          await _flutterTts!.speak('Cambiamos de ejercicio. Vamos con ${ejercicioSiguiente.ejercicio.nombre}.');
          if (!await waitWhileInterrupted()) return;
          await leerDescripcion(ejercicioSiguiente, ejercicioActual);
          return;
        }
      } else if (indexSerie < totalSeries - 1) {
        int seriesRestantes = totalSeries - (indexSerie + 1);
        String mensajeSeriesRestantes = '';
        // Te quedan N series
        if (seriesRestantes == 1) {
          mensajeSeriesRestantes = 'Vamos con la última serie.';
        } else if (seriesRestantes == 1) {
          mensajeSeriesRestantes = 'Vamos con la penúltima serie.';
        } else {
          seriesRestantes = seriesRestantes - 1;
          final serieRestanteLiteral = seriesNumeroLiterales[indexSerie + 1];
          final List<String> mensajesSeriesRestantes = ['Te queda esta serie y $seriesRestantes más.', 'Vamos con la $serieRestanteLiteral serie de $totalSeries.', 'Vamos a por la $serieRestanteLiteral serie. $totalSeries en total.'];
          mensajeSeriesRestantes = mensajesSeriesRestantes[Random().nextInt(mensajesSeriesRestantes.length)];
        }
        if (!await waitWhileInterrupted()) return;
        await _flutterTts!.speak(mensajeSeriesRestantes);
      } else {
        await _flutterTts!.speak('Última serie');
      }
      if (!await waitWhileInterrupted()) return;
      if (indexSerie + 1 < ejerciciosRList[indexEjercicio].series.length) {
        // Comprobar si tengo que cambiar el peso
        if (ejerciciosRList[indexEjercicio].series[indexSerie + 1].peso != ejerciciosRList[indexEjercicio].series[indexSerie].peso) {
          await _flutterTts!.setSpeechRate(0.35);
          var peso = ejerciciosRList[indexEjercicio].series[indexSerie + 1].peso;
          if (peso == 0) {
            await _flutterTts!.speak('Quita el peso.');
          } else {
            await _flutterTts!.speak('Cambia el peso a ${pesoLiteral(peso)}.');
          }
        }
        if (!await waitWhileInterrupted()) return;
        // Repetir a cuántas series vas
        await Future.delayed(Duration(milliseconds: 400));
        if (!await waitWhileInterrupted()) return;
        await _flutterTts!.setSpeechRate(0.5);
      }
      if (!await waitWhileInterrupted()) return;
    }
  }

  // Función para esperar el tiempo de descanso
  Future<void> esperarDescanso(
    SerieRealizada serieR,
    int currentIndex,
    int totalSeries,
    List<EjercicioRealizado> ejercicios,
    int index,
    int tiempoLeer,
  ) async {
    final int descanso = serieR.descanso;
    final int tiempoDecirCuentaAtras = 3;
    final int tiempoTotalDescanso = descanso - tiempoLeer;
    bool avisoDiezSegundosHecho = false;
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed.inSeconds < tiempoTotalDescanso) {
      // Pausa si está en modo pausa o toca borrar
      if (isPaused || borrarSpeaker) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (borrarSpeaker) return;
        continue;
      }

      final segundosRestantes = (tiempoTotalDescanso - stopwatch.elapsed.inSeconds) - 1;

      // Avisar de los 10 segundos restantes
      if (segundosRestantes <= 10 && !avisoDiezSegundosHecho && aviso10Segundos) {
        avisoDiezSegundosHecho = true;

        // Medimos tiempo de hablar "10 segundos"
        if (segundosRestantes == 10) {
          final speakWatch = Stopwatch()..start();
          await _flutterTts!.speak('10 segundos');
          speakWatch.stop();

          // Ajuste para redondear a 1 segundo
          final sobra = 1000 - speakWatch.elapsedMilliseconds;
          if (sobra > 0) {
            await Future.delayed(Duration(milliseconds: sobra));
          }
        }

        if (!await waitWhileInterrupted()) return;

        // Decimos repes
        String repes;
        if (currentIndex + 1 < ejercicios[index].series.length) {
          repes = ejercicios[index].series[currentIndex + 1].repeticiones.toString();
        } else {
          repes = ejercicios[index + 1].series[0].repeticiones.toString();
        }

        final speakWatch2 = Stopwatch()..start();
        if (repes == '1') {
          await _flutterTts!.speak('Vas a una repe.');
        } else {
          await _flutterTts!.speak('Vas a $repes repes.');
        }
        speakWatch2.stop();

        // De nuevo, redondeo para completar 1 segundo
        final sobra2 = 1000 - speakWatch2.elapsedMilliseconds;
        if (sobra2 > 0) {
          await Future.delayed(Duration(milliseconds: sobra2));
        }
      } else if (tiempoDecirCuentaAtras >= segundosRestantes) {
        // Paso a leer la cuenta atrás
        return;
      } else {
        // Si no toca avisar, esperamos un poquito
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    if (!await waitWhileInterrupted()) return;
  }

  // Verificar si hay series no realizadas
  Future<bool> hasSeriesNoRealizadas(List<dynamic> series) async {
    return series.any((serie) => !(serie['realizada'] ?? false));
  }

  // Verificar si hay series no realizadas
  Future<bool> hasTodasSeriesNoRealizadas(List<dynamic> series) async {
    return series.every((serie) => serie['realizada'] == false ? true : false);
  }

  String generarMensajeSeries(EjercicioRealizado ejercicioR) {
    // Filtramos solo las series no realizadas
    final seriesNoRealizadas = ejercicioR.series.where((s) => s.deleted != true && !(s.realizada)).toList();

    List<String> gruposTextos = [];
    int i = 0;

    while (i < seriesNoRealizadas.length) {
      // Tomamos la serie actual
      final actual = seriesNoRealizadas[i];
      final double pesoActual = actual.peso;
      final int repActual = actual.repeticiones;

      // Si estamos en la última o no hay siguiente, creamos grupo solo con esta
      if (i == seriesNoRealizadas.length - 1) {
        gruposTextos.add(_textoGrupo(
          pesoActual,
          [repActual],
          1,
        ));
        break;
      }

      // Miramos la siguiente
      final siguiente = seriesNoRealizadas[i + 1];
      final double pesoSig = siguiente.peso;
      final int repSig = siguiente.repeticiones;

      // Definimos el criterio de agrupación
      // Preferimos agrupar por repeticiones si coinciden; si no, probamos peso
      if (repActual == repSig) {
        // Agrupamos por repeticiones
        final repFijas = repActual;
        List<double> pesos = [];
        int j = i;

        // Mientras se mantengan las mismas repes
        while (j < seriesNoRealizadas.length && seriesNoRealizadas[j].repeticiones == repFijas) {
          pesos.add(seriesNoRealizadas[j].peso);
          j++;
        }

        // Creamos el texto para este grupo
        gruposTextos.add(_textoGrupoPorReps(repFijas, pesos));

        // Saltamos las series que ya agrupamos
        i = j;
      } else if (pesoActual == pesoSig) {
        // Agrupamos por peso
        final pesoFijo = pesoActual;
        List<int> repes = [];
        int j = i;

        // Mientras se mantenga el mismo peso
        while (j < seriesNoRealizadas.length && seriesNoRealizadas[j].peso == pesoFijo) {
          repes.add(seriesNoRealizadas[j].repeticiones);
          j++;
        }

        // Creamos el texto para este grupo
        gruposTextos.add(_textoGrupoPorPeso(pesoFijo, repes));

        i = j;
      } else {
        // No coincide ni reps ni peso con la siguiente;
        // creamos un "grupo" solo con la actual
        gruposTextos.add(_textoGrupo(
          pesoActual,
          [repActual],
          1,
        ));
        i++;
      }
    }

    // Añadimos por cada lado si aplica
    final literalPorCadaLado = (ejercicioR.ejercicio.realizarPorExtremidad) ? ' por cada lado' : '';

    return "Vamos a realizar ${unirElementosConY(gruposTextos)}$literalPorCadaLado.";
  }

  // Si coincide por repeticiones, unificamos pesos
  String _textoGrupoPorReps(int repFijas, List<double> pesos) {
    // Quitamos p.ej. pesos vacíos o valores repetidos si se desea
    // (Aunque igual conviene dejarlos para mantener el orden)
    // Para el ejemplo, usamos set:
    final pesosUnicos = pesos.toSet().toList();
    final totalSeries = pesos.length; // Cada peso, una serie
    final seriesText = totalSeries == 1 ? 'una serie' : '$totalSeries series';

    // Montamos la parte de repeticiones
    final literalRep = (repFijas == 1) ? 'una repetición' : '$repFijas repeticiones';

    // Montamos la parte de pesos
    // "sin peso" si es 0, si no, unimos con "y"
    final pesosText = pesosUnicos.map((p) {
      if (p == 0) return 'sin peso';
      return 'y ${pesoLiteral(p)}';
    }).toList();
    final pesosFinal = (pesosText.length == 1) ? pesosText.first : '${pesosText.sublist(0, pesosText.length - 1).join(', ')} y ${pesosText.last}';

    return "$seriesText a $literalRep $pesosFinal";
  }

  // Si coincide por peso, unificamos repeticiones
  String _textoGrupoPorPeso(double pesoFijo, List<int> repes) {
    final totalSeries = repes.length;
    final seriesText = totalSeries == 1 ? 'una serie' : '$totalSeries series';

    final repesText = repes.map((r) {
      return r == 1 ? 'una repetición' : '$r repeticiones';
    }).toList();

    // Unimos las repeticiones con "y"
    final repesFinal = (repesText.length == 1) ? repesText.first : '${repesText.sublist(0, repesText.length - 1).join(', ')} y ${repesText.last}';

    final pesoText = (pesoFijo == 0) ? 'sin peso' : pesoLiteral(pesoFijo);

    return "$seriesText a $repesFinal $pesoText";
  }

  // Caso suelto, sin coincidencia ni reps ni peso
  String _textoGrupo(double peso, List<int> repes, int count) {
    // En teoría aquí count suele ser 1
    final seriesText = count == 1 ? 'una serie' : '$count series';
    final rep = repes.first; // si es 1
    final literalRep = (rep == 1) ? 'una repetición' : '$rep repeticiones';
    final pesoText = (peso == 0) ? 'sin peso' : pesoLiteral(peso);
    return "$seriesText a $literalRep $pesoText";
  }

  // Modificar 'leerSeriesRepesAndPeso' para aceptar 'series' como parámetro
  Future<void> leerSeriesRepesAndPeso(EjercicioRealizado ejercicioR) async {
    if (_flutterTts == null) return;

    // Generar 'mensajeSeries' internamente usando 'series'
    String mensajeSeries = generarMensajeSeries(ejercicioR);

    if (!await waitWhileInterrupted()) return;
    await _flutterTts!.setSpeechRate(0.4);
    await _flutterTts!.speak(mensajeSeries);
    await _flutterTts!.setSpeechRate(0.5);
    if (!await waitWhileInterrupted()) return;
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // Función auxiliar para unir elementos con comas y "y" antes del último elemento
  String unirElementosConY(List<String> elementos) {
    if (elementos.length == 1) {
      return elementos.first;
    } else if (elementos.length == 2) {
      return elementos.join(' y ');
    } else {
      String last = elementos.removeLast();
      return '${elementos.join(', ')} y $last';
    }
  }

  // Método para anunciar la finalización del entrenamiento
  Future<void> anunciarFinalizacion(Entrenamiento entrenamiento) async {
    if (_flutterTts != null) {
      await _flutterTts!.setSpeechRate(0.45);
      await _flutterTts!.speak('Entrenamiento terminado.');
      await _flutterTts!.speak('Gracias por confiar en MisterFit');
      await _flutterTts!.setSpeechRate(0.5);
      await detener();
    }
  }
}
